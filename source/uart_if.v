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
// --------------------------------------------------------

`timescale 1ns / 1ps

module uart_if #(
	parameter SYS_CLK_FREQ = 50000000, // default = 115200baud @ 50MHz
	parameter BAUD_RATE    = 115200,
	parameter CNT_BITWIDTH = 9         // ceil(log2(SYS_CLK_FREQ/BAUD_RATE))
) (
	input  wire       rst_ni,
	input  wire       clk_i,

	input  wire       uart_rx_i,
	output reg        uart_tx_o,

	output wire       rx_irq_o,   // rx_irq(1clk pulse)
	output wire [7:0] rx_data_o,  // 
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

assign rx_irq_o  = s_rx_irq;
assign rx_data_o = s_rx_data_1d;

// --------------------
// TX
// --------------------

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_tx_irq_d   <= 2'b0;
		s_tx_data    <= 8'b0;
		s_tx_data_1d <= 8'b0;
	end else if(clk_i) begin
		s_tx_irq_d <= {s_tx_irq_d[0], tx_irq_i};
		s_tx_data  <= tx_data_i;
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

assign tx_busy_o = s_tx_en;

endmodule
