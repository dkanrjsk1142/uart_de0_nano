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
// 0.06    2020.01.14 I.Yang              
// --------------------------------------------------------

module UART_DE0_NANO #(
	parameter SIM_MODE = 0 // 0: array ROM, 1:ip-core ROM(for read .mif)
) (

	input  wire       rst_n,
	input  wire       clk,
	input  wire       uart_rx,
	output wire       uart_tx,
	output wire [7:0] led_debug,
	output wire       test_pin
);

//uart_if
wire        s_rx_en;
wire [ 7:0] s_rx_data;
wire        s_tx_en;
wire [ 7:0] s_tx_data;
wire        s_tx_busy;

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
	.uart_tx_o            (uart_tx     ), // output reg        uart_tx_o,

	.rx_irq_o             (s_rx_en     ), // output reg        rx_irq_o,   // rx_irq(1clk pulse)
	.rx_data_o            (s_rx_data   ), // output reg  [7:0] rx_data_o,  // 
	.tx_irq_i             (s_tx_en     ), // input  wire       tx_irq_i,   // tx_irq(1clk pulse)
	.tx_data_i            (s_tx_data   ), // input  wire [7:0] tx_data_i,  // 
	.tx_busy_o            (s_tx_busy   )  // output wire       tx_busy_o   // 1:ignore tx_irq
);

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


always @(*) begin
	case(s_cmd)
		CMD_ECHO:
			begin
				s_tx_buf_en   <= s_buf_en;
				s_tx_buf_data <= s_buf_data;
			end
		default:
			begin
				s_tx_buf_en   <= 1'b0;
				s_tx_buf_data <= 8'b0;
			end
	endcase
end

buffer #(
	.BUF_ADDR_WIDTH       (8              ), // parameter BUF_ADDR_WIDTH = 8, // BUF_SIZE = 2^BUF_ADR_WIDTH
	.DATA_BIT_WIDTH       (8              ), // parameter DATA_BIT_WIDTH = 8, // 
	.WAIT_DELAY           (2              )  // parameter WAIT_DELAY     = 0  // wait reply delay(0:no wait reply from receive module)
) u_buffer_uart_tx_fifo (
	.rst_ni               (rst_n          ), // input  wire                      rst_ni,
	.clk_enqueue_i        (clk            ), // input  wire                      clk_enqueue_i,
	.clk_dequeue_i        (clk            ), // input  wire                      clk_dequeue_i,
	.enqueue_den_i        (s_tx_buf_en    ), // input  wire                      enqueue_den_i,
	.enqueue_data_i       (s_tx_buf_data  ), // input  wire [DATA_BIT_WIDTH-1:0] enqueue_data_i,
	.dequeue_wait_i       (s_tx_busy      ), // input  wire                      dequeue_wait_i,
	.dequeue_den_o        (s_tx_en        ), // output wire                      dequeue_den_o,
	.dequeue_data_o       (s_tx_data      )  // output wire [DATA_BIT_WIDTH-1:0] dequeue_data_o
);


// Debug
//assign led_debug = s_rx_data;
assign led_debug = {uart_rx, uart_tx, 1'b1, s_cmd};
assign test_pin  = uart_tx;


endmodule
