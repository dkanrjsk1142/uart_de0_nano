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
// 0.03    2020.01.02 I.Yang              make UART_IF to be instance - plan3 complete
// 0.04    2020.01.03 I.Yang              remove RAM read-FF reset condition
//                                        => improve timing issue
// --------------------------------------------------------
// --------------------------------------------------------
// File Name   : UART_ECHO_TOP.v
// Description : UART echo device
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.01.03 I.Yang              reduce function
// --------------------------------------------------------
// --------------------------------------------------------
// File Name   : buffer.v
// Description : buffer controlled by dequeue_wait
//               BUSY_DELAY=2 example
//                        0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23
//                   clk  --__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__--__
//         enqueue_den_i  ____----____________------------________________________________________________________________
//        s_enqueue_addr  0           1               2   3   4                                                           
//            buffer_cnt  0           1       0       1   2   3       2   1   2           1   0   1       0               
//         s_dequeue_den  ________________----____________________--------____________--------________----________________
//        s_dequeue_addr  0                   1                       2   3   2           3   4   3       4               
//s_deq~addr_before_wait  0               1                       2                   3               4                   
//         dequeue_den_o  ____________________----____________________--------____________--------________----____________
//        dequeue_wait_i  ____________________________------------____________--------____________----____________----____
//
//****used by receiving module(check *)       ****                    ****                ****            ****
//     -> exsample receive module can handle only 1 data
//        (dequeue_wait_i signal income from receive module)
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.01.03 I.Yang              reduce function
// 0.02    2020.01.04 I.Yang              add generate - support BUSY_DELAY=0(burst rd)
// 0.03    2020.01.04 I.Yang              support dual-clk
// 0.04    2020.01.11 I.Yang              change name wr/rd -> enqueue/dequeue
//                                        change name busy -> wait
//                                        change name en -> en(data_en)
// 0.05    2020.01.11 I.Yang              change wait handling
//                                            origin : flush after wait
//                                            change : flush without wait and
//                                                     restore dequeue address after wait
// --------------------------------------------------------

`timescale 1ns / 1ps

module buffer #(
	parameter BUF_ADDR_WIDTH = 8, // BUF_SIZE = 2^BUF_ADR_WIDTH
	parameter DATA_BIT_WIDTH = 8, // 
	parameter WAIT_DELAY     = 0  // wait reply delay(0:no wait reply from receive module)
) (
	input  wire                      rst_ni,
	input  wire                      clk_enqueue_i,
	input  wire                      clk_dequeue_i,
	input  wire                      enqueue_den_i,
	input  wire [DATA_BIT_WIDTH-1:0] enqueue_data_i,
	input  wire                      dequeue_wait_i,
	output wire                      dequeue_den_o,
	output wire [DATA_BIT_WIDTH-1:0] dequeue_data_o
);

localparam BUF_SIZE = 2 ** BUF_ADDR_WIDTH;

reg  [DATA_BIT_WIDTH-1:0] RAM [BUF_SIZE-1:0];

reg                       s_enqueue_den_1d;
wire                      s_dequeue_den;
reg                       s_dequeue_den_1d;

reg  [DATA_BIT_WIDTH-1:0] s_enqueue_data_1d;
reg  [DATA_BIT_WIDTH-1:0] s_dequeue_data;

reg  [BUF_ADDR_WIDTH-1:0] s_enqueue_addr;
reg  [BUF_ADDR_WIDTH-1:0] s_dequeue_addr;

reg  [BUF_ADDR_WIDTH-1:0] s_dequeue_addr_before_wait;
wire [BUF_ADDR_WIDTH-1:0] s_dequeue_addr_diff;

reg                       s_dequeue_wait_1d;

// wr address
always @(negedge rst_ni, posedge clk_enqueue_i)
begin
	if(~rst_ni)
		s_enqueue_addr <= {BUF_ADDR_WIDTH{1'b0}};
	else if(clk_enqueue_i) begin
		if (s_enqueue_den_1d)
			s_enqueue_addr <= s_enqueue_addr + 1'b1;
	end
end

// --------------------
// RAM (automatically synthesis)
// --------------------
// input FF for BRAM
always @(negedge rst_ni, posedge clk_enqueue_i)
begin
	if(~rst_ni) begin
		s_enqueue_den_1d  <= 1'b0;
		s_enqueue_data_1d <= {DATA_BIT_WIDTH{1'b0}};
	end else if(clk_enqueue_i) begin
		s_enqueue_den_1d  <= enqueue_den_i;
		s_enqueue_data_1d <= enqueue_data_i;
	end
end

// write
always @(posedge clk_enqueue_i)
begin
	if (s_enqueue_den_1d)
		RAM[s_enqueue_addr] <= s_enqueue_data_1d;
end

// read(1clk-dly)
always @(posedge clk_dequeue_i)
begin
//	if (s_dequeue_den) // del Ver0.05
		s_dequeue_data <= RAM[s_dequeue_addr];
end

// --------------------
// TX
// --------------------
// mod Ver0.05 start
assign s_dequeue_den = ~dequeue_wait_i && s_enqueue_addr != s_dequeue_addr ? 1'b1 : 1'b0;

always @(negedge rst_ni, posedge clk_dequeue_i)
begin
	if(~rst_ni) begin
		s_dequeue_wait_1d <= 1'b0;
		s_dequeue_den_1d  <= 1'b0;
	end else if(clk_dequeue_i) begin
		s_dequeue_wait_1d <= dequeue_wait_i;
		s_dequeue_den_1d  <= s_dequeue_den;
	end
end

always @(negedge rst_ni, posedge clk_dequeue_i)
begin
	if(~rst_ni)
		s_dequeue_addr_before_wait <= {BUF_ADDR_WIDTH{1'b0}};
	else if(clk_dequeue_i) begin
		if (s_dequeue_den & ~s_dequeue_den_1d) // posedge
			s_dequeue_addr_before_wait <= s_dequeue_addr + 1'b1;
		else if (s_dequeue_addr_diff >= WAIT_DELAY[BUF_ADDR_WIDTH-1:0])
			s_dequeue_addr_before_wait <= s_dequeue_addr - WAIT_DELAY[BUF_ADDR_WIDTH-1:0];
	end
end

assign s_dequeue_addr_diff = s_dequeue_addr - s_dequeue_addr_before_wait;

// TX RAM address
always @(negedge rst_ni, posedge clk_dequeue_i)
begin
	if(~rst_ni)
		s_dequeue_addr <= {BUF_ADDR_WIDTH{1'b0}};
	else if(clk_dequeue_i) begin
		if (s_dequeue_den)
			s_dequeue_addr <= s_dequeue_addr + 1'b1;
		else if (dequeue_wait_i & ~s_dequeue_wait_1d) begin // posedge
			s_dequeue_addr <= s_dequeue_addr_before_wait;
		end
	end
end
// mod Ver0.05 end

assign dequeue_data_o = s_dequeue_data;
assign dequeue_den_o  = s_dequeue_den_1d;

endmodule
