// --------------------------------------------------------
// File Name   : uart_if.v
// Description : UART Interface
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.01.02 I.Yang              Create New
// 0.02    2020.01.02 I.Yang              complete prototype test(baud rate - 115200only)
// 0.03    2020.01.03 I.Yang              modify parameterized baud rate
// 0.04    2020.01.03 I.Yang              reduce TX busy period(for burst tx)
// 0.05    2020.01.03 I.Yang              fix latched circuit
// 0.06    2020.01.11 I.Yang              fix tx_data latch timing
// 0.07    2020.01.19 I.Yang              add rts/cts
//                                        add tx/rx buffer
//                                        add parameter for tx/rx buffer
//                                        add rx_wait_i pin(for rx buffer)
// --------------------------------------------------------

`timescale 1ns / 1ps

module uart_if #(
	parameter SYS_CLK_FREQ      = 50000000, // default = 115200baud @ 50MHz
	parameter BAUD_RATE         = 115200,
	parameter CNT_BITWIDTH      = 9,        // ceil(log2(SYS_CLK_FREQ/BAUD_RATE))
	parameter RX_BUF_ADDR_WIDTH = 8,        // buffer size = 2^RX_BUF_ADDR_WIDTH
	parameter TX_BUF_ADDR_WIDTH = 8,        // buffer size = 2^TX_BUF_ADDR_WIDTH
	parameter RX_WAIT_DELAY     = 2         // wait reply delay(0:no wait reply from receive module)
) (
	input  wire       rst_ni,
	input  wire       clk_i,

	input  wire       uart_rx_i,
    output wire       uart_cts_o,

	output reg        uart_tx_o,
    input  wire       uart_rts_i, // if disconnected, pull-up high(no-wait)

	output wire       rx_irq_o,   // rx_irq(1clk pulse)
	output wire [7:0] rx_data_o,  // 
	input  wire       rx_wait_i,  // 

	input  wire       tx_irq_i,   // tx_irq(1clk pulse)
	input  wire [7:0] tx_data_i,  // 
	output wire       tx_busy_o   // 1:ignore tx_irq
);

localparam [CNT_BITWIDTH-1:0] p_num_clk_cntr_max  = (SYS_CLK_FREQ / BAUD_RATE) - 1;
localparam [CNT_BITWIDTH-1:0] p_num_clk_cntr_half = (SYS_CLK_FREQ / BAUD_RATE) / 2;

reg  [ 1:0] s_uart_rx_d;
reg         s_rx_en;
reg  [CNT_BITWIDTH-1:0] s_rx_bit_cntr;
reg  [ 3:0] s_rx_word_cntr;
wire        s_rx_fetch_tmg;
reg  [ 7:0] s_rx_data;

reg        s_rx_irq;
reg  [7:0] s_rx_data_1d;

wire       s_rx_buf_irq;
wire [7:0] s_rx_buf_data;

wire       s_rx_buf_full;

wire       s_tx_wait;

wire       s_tx_buf_irq;
wire [7:0] s_tx_buf_data;

reg  [ 1:0] s_tx_irq_d;
reg  [ 7:0] s_tx_data;
reg  [ 7:0] s_tx_data_1d;
reg         s_tx_en;
reg  [CNT_BITWIDTH-1:0] s_tx_bit_cntr;
reg  [ 3:0] s_tx_word_cntr;
wire        s_tx_fetch_tmg;


// --------------------
// rx
// --------------------

// rx data shift register
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_uart_rx_d  <= 2'b11;
	else if(clk_i)
		s_uart_rx_d  <= {s_uart_rx_d[0] , uart_rx_i};
end

// receive state(by start bit)
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_en  <= 1'b0;
	else if(clk_i) begin
		if (s_rx_word_cntr == 4'd9 && s_rx_fetch_tmg) // not parity
			s_rx_en  <= 1'b0;
		else if (s_uart_rx_d == 2'b10) // negedge
			s_rx_en  <= 1'b1;
	end
end

// bit counter
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_bit_cntr <= {CNT_BITWIDTH{1'b0}};
	else if(clk_i) begin
		if (~s_rx_en || s_rx_bit_cntr == p_num_clk_cntr_max)
			s_rx_bit_cntr <= {CNT_BITWIDTH{1'b0}};
		else
			//s_rx_bit_cntr <= s_rx_bit_cntr + {{CNT_BITWIDTH-1{1'b0}}, 1'b1};
			s_rx_bit_cntr <= s_rx_bit_cntr + 1'b1;
	end
end

assign s_rx_fetch_tmg = s_rx_bit_cntr == p_num_clk_cntr_half ? 1'b1 : 1'b0;

// word counter
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_word_cntr  <= 4'b0;
	else if(clk_i) begin
		if (~s_rx_en)
			s_rx_word_cntr  <= 4'b0;
		else if(s_rx_fetch_tmg)
				s_rx_word_cntr  <= s_rx_word_cntr + 4'b1;
	end
end

// convert s/p
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_data <= 8'hFF;
	else if(clk_i) begin
		if (s_rx_fetch_tmg && s_rx_word_cntr != 4'd9)
			s_rx_data <= {s_uart_rx_d[1], s_rx_data[7:1]};
	end
end

// rx complete irq
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_irq  <= 1'b0;
	//if(clk_i) begin -- mod Ver0.05
	else if(clk_i) begin
		if (s_rx_word_cntr == 4'd9 && s_rx_fetch_tmg)
			s_rx_irq <= 1'b1;
		else
			s_rx_irq <= 1'b0;
	end
end

// rx data latch
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_data_1d <= 8'b0;
	//if(clk_i) begin -- mod Ver0.05
	else if(clk_i) begin
		if (s_rx_word_cntr == 4'd9 && s_rx_fetch_tmg)
			s_rx_data_1d <= s_rx_data; // latch
	end
end

buffer #(
	.SYNC_MODE            ("sync"              ), // parameter SYNC_MODE      =  "sync", // "async" : (clk_enqueue_i - clk_dequeue_i is different clk) / "sync" : (same clk)

	.BUF_ADDR_WIDTH       (RX_BUF_ADDR_WIDTH   ), // parameter BUF_ADDR_WIDTH = 8, // BUF_SIZE = 2^BUF_ADR_WIDTH
	.DATA_BIT_WIDTH       (8                   ), // parameter DATA_BIT_WIDTH = 8, // 
	.WAIT_DELAY           (RX_WAIT_DELAY       )  // parameter WAIT_DELAY     = 0  // wait reply delay(0:no wait reply from receive module)
) u_rx_buffer (
	.rst_ni               (rst_ni              ), // input  wire                      rst_ni,
	.clk_enqueue_i        (clk_i               ), // input  wire                      clk_enqueue_i,
	.clk_dequeue_i        (clk_i               ), // input  wire                      clk_dequeue_i,
	.enqueue_den_i        (s_rx_irq            ), // input  wire                      enqueue_den_i,
	.enqueue_data_i       (s_rx_data_1d        ), // input  wire [DATA_BIT_WIDTH-1:0] enqueue_data_i,
	.is_queue_full_o      (s_rx_buf_full       ), // output wire                      is_queue_full_o,
	.dequeue_wait_i       (rx_wait_i           ), // input  wire                      dequeue_wait_i,
	.dequeue_den_o        (s_rx_buf_irq        ), // output wire                      dequeue_den_o,
	.dequeue_data_o       (s_rx_buf_data       ), // output wire [DATA_BIT_WIDTH-1:0] dequeue_data_o,
	.is_queue_empty_o     (                    )  // output wire                      is_queue_empty_o // loosy empty status(there is some delay after queue is empty)
);

assign uart_cts_o = ~s_rx_buf_full;

assign rx_irq_o  = s_rx_buf_irq;
assign rx_data_o = s_rx_buf_data;

// --------------------
// TX
// --------------------

assign s_tx_wait = ~uart_rts_i | s_tx_en;


buffer #(
	.SYNC_MODE            ("sync"              ), // parameter SYNC_MODE      =  "sync", // "async" : (clk_enqueue_i - clk_dequeue_i is different clk) / "sync" : (same clk)
	.BUF_ADDR_WIDTH       (TX_BUF_ADDR_WIDTH   ), // parameter BUF_ADDR_WIDTH = 8, // BUF_SIZE = 2^BUF_ADR_WIDTH
	.DATA_BIT_WIDTH       (8                   ), // parameter DATA_BIT_WIDTH = 8, // 
	.WAIT_DELAY           (2                   )  // parameter WAIT_DELAY     = 0  // wait reply delay(0:no wait reply from receive module)
) u_tx_buffer (
	.rst_ni               (rst_ni              ), // input  wire                      rst_ni,
	.clk_enqueue_i        (clk_i               ), // input  wire                      clk_enqueue_i,
	.clk_dequeue_i        (clk_i               ), // input  wire                      clk_dequeue_i,
	.enqueue_den_i        (tx_irq_i            ), // input  wire                      enqueue_den_i,
	.enqueue_data_i       (tx_data_i           ), // input  wire [DATA_BIT_WIDTH-1:0] enqueue_data_i,
	.is_queue_full_o      (tx_busy_o           ), // output wire                      is_queue_full_o,
	.dequeue_wait_i       (s_tx_wait           ), // input  wire                      dequeue_wait_i,
	.dequeue_den_o        (s_tx_buf_irq        ), // output wire                      dequeue_den_o,
	.dequeue_data_o       (s_tx_buf_data       ), // output wire [DATA_BIT_WIDTH-1:0] dequeue_data_o,
	.is_queue_empty_o     (                    )  // output wire                      is_queue_empty_o // loosy empty status(there is some delay after queue is empty)
);

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_tx_irq_d   <= 2'b0;
		s_tx_data    <= 8'b0;
		s_tx_data_1d <= 8'b0;
	end else if(clk_i) begin
		s_tx_irq_d <= {s_tx_irq_d[0], s_tx_buf_irq};
		s_tx_data  <= s_tx_buf_data;
		if (s_tx_irq_d == 2'b01) // posedge
			s_tx_data_1d <= s_tx_data;
	end
end

// transmit state(by start bit)
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_tx_en  <= 1'b0;
	else if(clk_i) begin
		//if (s_tx_word_cntr == 4'd10 && s_tx_fetch_tmg) // not parity -- mod Ver0.04
		if (s_tx_word_cntr == 4'd9 && s_tx_fetch_tmg) // not parity
			s_tx_en  <= 1'b0;
		else if (s_tx_irq_d == 2'b01) // posedge
			s_tx_en  <= 1'b1;
	end
end

// bit counter
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_tx_bit_cntr <= {CNT_BITWIDTH{1'b0}};
	else if(clk_i) begin
		if (~s_tx_en || s_tx_bit_cntr == p_num_clk_cntr_max)
			s_tx_bit_cntr <= {CNT_BITWIDTH{1'b0}};
		else
			//s_tx_bit_cntr <= s_tx_bit_cntr + {{(CNT_BITWIDTH-1){1'b0}}, 1'b1};
			s_tx_bit_cntr <= s_tx_bit_cntr + 1'b1;
	end
end

assign s_tx_fetch_tmg = s_tx_bit_cntr == p_num_clk_cntr_max ? 1'b1 : 1'b0; // not delay but !=0

// word counter
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_tx_word_cntr  <= 4'b0;
	else if(clk_i) begin
		if (~s_tx_en)
			s_tx_word_cntr  <= 4'b0;
		else if(s_tx_fetch_tmg)
				s_tx_word_cntr  <= s_tx_word_cntr + 4'b1;
	end
end

// convert p/s
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		uart_tx_o <= 1'b1;
	else if(clk_i) begin
		case (s_tx_word_cntr)
			4'h1 : uart_tx_o <= 1'b0; // start bit
			4'h2 , 4'h3 , 4'h4 , 4'h5 , 
			4'h6 , 4'h7 , 4'h8 , 4'h9 : 
				   uart_tx_o <= s_tx_data_1d[s_tx_word_cntr-2];
			4'hA : uart_tx_o <= 1'b1; // stop bit
			default : uart_tx_o <= 1'b1;
		endcase
	end
end

endmodule
