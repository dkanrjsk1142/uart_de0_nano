// --------------------------------------------------------
// File Name   : UART_DE0_NANO.v
// Description : UART(115200) echo device - prototype
//               next plan1 - SW event based echo device
//               next plan2 - make parameterized RTL(freq, baud rate, parity existance, etc.)
//               next plan3 - remove ram(remain Only IF)
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.01.01 I.Yang              Create New
// 0.02    2020.01.01 I.Yang              complete prototype test
// 0.03    2020.01.02 I.Yang              make module "uart_if" to be instance - plan3 complete
// 0.04    2020.01.03 I.Yang              remove RAM read-FF reset condition
//                                        => improve timing issue
// 0.05    2020.01.03 I.Yang              make module "buffer" to be instance
// 0.06    2020.01.19 I.Yang              add uart rts/cts pin
//                                        remove uart_tx_buffer(uart_if contain buffer)
// 0.07    2020.01.19 I.Yang              set Hi to uart cts pin(not use flow control)
// --------------------------------------------------------

module UART_DE0_NANO #(
	parameter SIM_MODE = 0 // 0: array ROM, 1:ip-core ROM(for read .mif)
) (

	input  wire       rst_n,
	input  wire       clk,

	// uart if
	input  wire       uart_rx,
	output wire       uart_tx,
    output wire       uart_cts,
    input  wire       uart_rts,


	// test RTL
	input  wire       host1_uart_rx,
	output wire       host1_uart_tx,
	input  wire       host2_ps2_clk,
	input  wire       host2_ps2_data,

	// debug
	output wire [7:0] led_debug,
	output wire       test_pin
);

//uart_if
wire        s_rx_en;
wire [ 7:0] s_rx_data;
reg         s_tx_en;
reg  [ 7:0] s_tx_data;
wire        s_tx_busy;

wire        s_ign_uart_rts = 1'b1; // 1:ignore rts / 0:use rts
wire        s_uart_rts;

//cmd_parser
wire [ 4:0] s_cmd;

localparam [5:0] CMD_UNUSED           = 5'h00;
localparam [5:0] CMD_ECHO             = 5'h01;
localparam [5:0] CMD_RAW_DIR          = 5'h02;
localparam [5:0] CMD_RAW              = 5'h03;
localparam [5:0] CMD_RAW_END          = 5'h04;
localparam [5:0] CMD_UNKNOWN          = 5'h1F;

wire        s_buf_en;
wire [ 7:0] s_buf_data;

reg         s_tx_buf_en;
reg  [ 7:0] s_tx_buf_data;


wire        s_host1_rx_en;
wire [ 7:0] s_host1_rx_data;
reg         s_host1_tx_en;
reg  [ 7:0] s_host1_tx_data;

wire        s_host2_rx_en;
wire [ 7:0] s_host2_rx_data;
wire        s_host2_rx_ascii_en;
wire [ 7:0] s_host2_rx_ascii_data;

uart_if #(
	.SYS_CLK_FREQ         (50000000    ), // parameter SYS_CLK_FREQ = 50000000, // default = 115200baud @ 50MHz
	.BAUD_RATE            (115200      ), // parameter BAUD_RATE    = 115200,
	.CNT_BITWIDTH         (9           )  // parameter CNT_BITWIDTH = 9         // ceil(log2(SYS_CLK_FREQ/BAUD_RATE))
	//.BAUD_RATE            (9600        ), // parameter BAUD_RATE    = 115200,
	//.CNT_BITWIDTH         (13          )  // parameter CNT_BITWIDTH = 9         // ceil(log2(SYS_CLK_FREQ/BAUD_RATE))
) u_uart_if(
	.rst_ni               (rst_n       ), // input  wire       rst_n,
	.clk_i                (clk         ), // input  wire       clk,

	.uart_rx_i            (uart_rx     ), // input  wire       uart_rx_i,
	.uart_cts_o           (uart_cts    ), // output wire       uart_cts_o,

	.uart_tx_o            (uart_tx     ), // output reg        uart_tx_o,
	.uart_rts_i           (s_uart_rts  ), // input  wire       uart_rts_i,

	.rx_irq_o             (s_rx_en     ), // output wire       rx_irq_o,   // rx_irq(1clk pulse)
	.rx_data_o            (s_rx_data   ), // output wire [7:0] rx_data_o,  // 
	.rx_wait_i            (1'b0        ), // input  wire [7:0] rx_data_o,  // ************************will connect cmd_parser

	.tx_irq_i             (s_tx_en     ), // input  wire       tx_irq_i,   // tx_irq(1clk pulse)
	.tx_data_i            (s_tx_data   ), // input  wire [7:0] tx_data_i,  // 
	.tx_busy_o            (s_tx_busy   )  // output wire       tx_busy_o   // 1:ignore tx_irq
);

assign s_uart_rts = s_ign_uart_rts | uart_rts;

cmd_parser #(
	.CMD_IGNORE_CASE      (1           ), // parameter CMD_IGNORE_CASE      =  1, // 1: ignore-case, 0:restrict check case
	.CMD_TABLE_ADDR_WIDTH (6           ), // parameter CMD_TABLE_ADDR_WIDTH = 6
	.REG_READ_TIMEOUT_CLK (31          ), // parameter REG_READ_TIMEOUT_CLK = 31, // if rd_den(read data enable-from device) is not inputed, timeout after value of this parameter.
	.SIM_MODE             (SIM_MODE    )  // 0: array ROM, 1:ip-core ROM(for read .mif)
) s_cmd_parser (
	.rst_ni               (rst_n       ), // input  wire        rst_ni,
	.clk_i                (clk         ), // input  wire        clk_i,

	//income data
	.wr_en_i              (s_rx_en     ), // input  wire        wr_en_i,
	.wr_data_i            (s_rx_data   ), // input  wire  [7:0] wr_data_i,

	.cmd_o                (s_cmd       ), // output wire  [4:0] cmd_o,

	.out_en_o             (s_buf_en    ), // output wire        out_en_i,
	.out_data_o           (s_buf_data  ), // output wire  [7:0] out_data_i,

	.cmd_done             (32'b0       )  // input  wire [31:0] cmd_valid_o
);

wire s_insert_enter;
reg [2:0] s_insert_enter_cntr;

always @(*) begin
	case(s_cmd)
		CMD_ECHO:
			begin
				s_tx_en   <= s_buf_en;
				s_tx_data <= s_buf_data;
			end
		default:
			begin
//				s_tx_en   <= 1'b0;
//				s_tx_data <= 8'b0;
//				s_tx_en   <= s_host1_rx_en  ;
//				s_tx_data <= s_host1_rx_data;
				if(s_insert_enter) begin
					s_tx_en   <= 1'b1;
					s_tx_data <= (s_insert_enter_cntr == 3'h5) ? 8'hD : 8'hA;
				end else begin
					s_tx_en   <= s_host2_rx_ascii_en  ;
					s_tx_data <= s_host2_rx_ascii_data;
				end
			end
	endcase
end

reg  [31:0] s_raw_dir;
initial s_raw_dir <= 32'b1;

// --------------------
// TEST RTL
// --------------------

always @(negedge rst_n, posedge clk) begin
	if(~rst_n) begin
		s_host1_tx_en   <= 1'b0;
		s_host1_tx_data <= 8'b0;
	end else if (clk) begin
//		if (s_cmd == CMD_RAW && s_raw_dir[0]) begin
//			s_host1_tx_en   <= s_buf_en;
//			s_host1_tx_data <= s_buf_data;
		if (1'b1) begin
			s_host1_tx_en   <= s_rx_en;
			s_host1_tx_data <= s_rx_data;
		end else begin
			s_host1_tx_en   <= 1'b0;
			s_host1_tx_data <= 8'b0;
		end
	end
end

uart_if #(
	.SYS_CLK_FREQ         (50000000       ), // parameter SYS_CLK_FREQ = 50000000, // default = 115200baud @ 50MHz
	.BAUD_RATE            (115200         ), // parameter BAUD_RATE    = 115200,
	.CNT_BITWIDTH         (9              )  // parameter CNT_BITWIDTH = 9         // ceil(log2(SYS_CLK_FREQ/BAUD_RATE))
) u_host_uart_if(
	.rst_ni               (rst_n          ), // input  wire       rst_n,
	.clk_i                (clk            ), // input  wire       clk,

	.uart_rx_i            (host1_uart_rx  ), // input  wire       uart_rx_i,
	.uart_cts_o           (               ), // output wire       uart_cts_o,

	.uart_tx_o            (host1_uart_tx  ), // output reg        uart_tx_o,
	.uart_rts_i           (1'b1           ), // input  wire       uart_rts_i,

	.rx_irq_o             (s_host1_rx_en  ), // output wire       rx_irq_o,   // rx_irq(1clk pulse)
	.rx_data_o            (s_host1_rx_data), // output wire [7:0] rx_data_o,  // 
	.rx_wait_i            (1'b0           ), // input  wire [7:0] rx_data_o,  //

	.tx_irq_i             (s_host1_tx_en  ), // input  wire       tx_irq_i,   // tx_irq(1clk pulse)
	.tx_data_i            (s_host1_tx_data), // input  wire [7:0] tx_data_i,  // 
	.tx_busy_o            (               )  // output wire       tx_busy_o   // 1:ignore tx_irq
);


ps2_rx_if u_ps2_rx_if (
	.rst_ni         (rst_n            ), // input  wire       rst_ni,
	.clk_i          (clk              ), // input  wire       clk_i,

	.ps2_rx_clk_i   (host2_ps2_clk    ), // input  wire       ps2_rx_clk_i,
	.ps2_rx_data_i  (host2_ps2_data   ), // input  wire       ps2_rx_data_i,

    .rx_en_o        (s_host2_rx_en    ), // output wire       rx_en_o,
    .rx_data_o      (s_host2_rx_data  ), // output wire [7:0] rx_data_o,
    .rx_pty_err_o   (s_rx_pty_err     )  // output wire       rx_pty_err_o, // parity error
);

wire s_trg_400us;

//         freq      base 1 2  3 4 5
trg_cntr #(50000000,400,0,0,0,0,0) u_trg_cntr(rst_n, clk, 1'b1, s_trg_400us, , , , , );

always @(negedge rst_n, posedge clk)
begin
	if(~rst_n)
		s_insert_enter_cntr <= 3'b0;
	else if(clk) begin
		if(s_host2_rx_en)
			s_insert_enter_cntr <= 3'b0;
		else if(~&s_insert_enter_cntr && s_trg_400us)
			s_insert_enter_cntr <= s_insert_enter_cntr + 1'b1;
	end
end
		
assign s_insert_enter = (s_trg_400us && (s_insert_enter_cntr == 3'h5 || s_insert_enter_cntr == 3'h6)) ? 1'b1 : 1'b0;

hex2ascii #(2) u_host2_hex2ascii (rst_n, clk, s_host2_rx_en, s_host2_rx_data, , s_host2_rx_ascii_en, s_host2_rx_ascii_data);


// Debug
//assign led_debug = s_rx_data;
assign led_debug = {s_rx_pty_err, uart_tx, 1'b1, s_cmd};
assign test_pin  = uart_tx;

endmodule
