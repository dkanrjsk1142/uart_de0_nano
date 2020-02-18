// --------------------------------------------------------
// File Name   : trg_cntr.v
// Description : trigger generator
//               SYS_CLK_FREQ = at least 1MHz
//               parameter's minimum unit = 1us
//               if parameter=0, disable counter(stuck GND)
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.01.02 I.Yang              Create New
// --------------------------------------------------------

// --------------------------------------------------------
// macro for PARAMETER(not use for synthesis)
`ifndef CLOG2
`define CLOG2(x) \
   (x <= 32'h00000002) ? 1  : (x <= 32'h00000004) ? 2  : (x <= 32'h00000008) ? 3  : (x <= 32'h00000010) ? 4  : \
   (x <= 32'h00000020) ? 5  : (x <= 32'h00000040) ? 6  : (x <= 32'h00000080) ? 7  : (x <= 32'h00000100) ? 8  : \
   (x <= 32'h00000200) ? 9  : (x <= 32'h00000400) ? 10 : (x <= 32'h00000800) ? 11 : (x <= 32'h00001000) ? 12 : \
   (x <= 32'h00002000) ? 13 : (x <= 32'h00004000) ? 14 : (x <= 32'h00008000) ? 15 : (x <= 32'h00010000) ? 16 : \
   (x <= 32'h00020000) ? 17 : (x <= 32'h00040000) ? 18 : (x <= 32'h00080000) ? 19 : (x <= 32'h00100000) ? 20 : \
   (x <= 32'h00200000) ? 21 : (x <= 32'h00400000) ? 22 : (x <= 32'h00800000) ? 23 : (x <= 32'h01000000) ? 24 : \
   (x <= 32'h02000000) ? 25 : (x <= 32'h04000000) ? 26 : (x <= 32'h08000000) ? 27 : (x <= 32'h10000000) ? 28 : \
   (x <= 32'h20000000) ? 29 : (x <= 32'h40000000) ? 30 : (x <= 32'h80000000) ? 31 : (x <= 32'hFFFFFFFF) ? 32 : \
   -1
`endif
// --------------------------------------------------------

`timescale 1ns / 1ps

module trg_cntr #(
	parameter SYS_CLK_FREQ = 50000000, // 50MHz
	parameter TMG_BASE_1US = 5,        // base tmg :   5us
	parameter TMG_1      = 2,        // 1st  tmg :  10us =  2 * base tmg
	parameter TMG_2      = 10,       // 2nd  tmg : 100us = 10 * 1st  tmg
	parameter TMG_3      = 0,        // 3rd  tmg : disable
	parameter TMG_4      = 0,        // 4th  tmg : disable
	parameter TMG_5      = 0         // 5th  tmg : disable
) (
	input  wire       rst_ni,
	input  wire       clk_i,

	input  wire       trg_en_i, // 0:all cntr reset

	output wire       trg_base_o,
	output wire       trg_1st_o,
	output wire       trg_2nd_o,
	output wire       trg_3rd_o,
	output wire       trg_4th_o,
	output wire       trg_5th_o
);

localparam TMG_BASE_CNTR_MAX = TMG_BASE_1US * (SYS_CLK_FREQ / 1000000);
//localparam TMG_BASE_CNTR_BIT_WIDTH = CLOG2(TMG_BASE_CNTR_MAX);
localparam TMG_BASE_CNTR_BIT_WIDTH = 
   (TMG_BASE_CNTR_MAX<=32'h00000002)? 1  : (TMG_BASE_CNTR_MAX<=32'h00000004)? 2  : (TMG_BASE_CNTR_MAX<=32'h00000008)? 3  : (TMG_BASE_CNTR_MAX<=32'h00000010)? 4  :
   (TMG_BASE_CNTR_MAX<=32'h00000020)? 5  : (TMG_BASE_CNTR_MAX<=32'h00000040)? 6  : (TMG_BASE_CNTR_MAX<=32'h00000080)? 7  : (TMG_BASE_CNTR_MAX<=32'h00000100)? 8  :
   (TMG_BASE_CNTR_MAX<=32'h00000200)? 9  : (TMG_BASE_CNTR_MAX<=32'h00000400)? 10 : (TMG_BASE_CNTR_MAX<=32'h00000800)? 11 : (TMG_BASE_CNTR_MAX<=32'h00001000)? 12 :
   (TMG_BASE_CNTR_MAX<=32'h00002000)? 13 : (TMG_BASE_CNTR_MAX<=32'h00004000)? 14 : (TMG_BASE_CNTR_MAX<=32'h00008000)? 15 : (TMG_BASE_CNTR_MAX<=32'h00010000)? 16 :
   (TMG_BASE_CNTR_MAX<=32'h00020000)? 17 : (TMG_BASE_CNTR_MAX<=32'h00040000)? 18 : (TMG_BASE_CNTR_MAX<=32'h00080000)? 19 : (TMG_BASE_CNTR_MAX<=32'h00100000)? 20 :
   (TMG_BASE_CNTR_MAX<=32'h00200000)? 21 : (TMG_BASE_CNTR_MAX<=32'h00400000)? 22 : (TMG_BASE_CNTR_MAX<=32'h00800000)? 23 : (TMG_BASE_CNTR_MAX<=32'h01000000)? 24 :
   (TMG_BASE_CNTR_MAX<=32'h02000000)? 25 : (TMG_BASE_CNTR_MAX<=32'h04000000)? 26 : (TMG_BASE_CNTR_MAX<=32'h08000000)? 27 : (TMG_BASE_CNTR_MAX<=32'h10000000)? 28 :
   (TMG_BASE_CNTR_MAX<=32'h20000000)? 29 : (TMG_BASE_CNTR_MAX<=32'h40000000)? 30 : (TMG_BASE_CNTR_MAX<=32'h80000000)? 31 : (TMG_BASE_CNTR_MAX<=32'hFFFFFFFF)? 32 :
   -1;
//localparam TMG_1_CNTR_BIT_WIDTH  = CLOG2(TMG_1);
localparam TMG_1_CNTR_BIT_WIDTH  =
   (TMG_1<=32'h00000002)? 1  : (TMG_1<=32'h00000004)? 2  : (TMG_1<=32'h00000008)? 3  : (TMG_1<=32'h00000010)? 4  :
   (TMG_1<=32'h00000020)? 5  : (TMG_1<=32'h00000040)? 6  : (TMG_1<=32'h00000080)? 7  : (TMG_1<=32'h00000100)? 8  :
   (TMG_1<=32'h00000200)? 9  : (TMG_1<=32'h00000400)? 10 : (TMG_1<=32'h00000800)? 11 : (TMG_1<=32'h00001000)? 12 :
   (TMG_1<=32'h00002000)? 13 : (TMG_1<=32'h00004000)? 14 : (TMG_1<=32'h00008000)? 15 : (TMG_1<=32'h00010000)? 16 :
   (TMG_1<=32'h00020000)? 17 : (TMG_1<=32'h00040000)? 18 : (TMG_1<=32'h00080000)? 19 : (TMG_1<=32'h00100000)? 20 :
   (TMG_1<=32'h00200000)? 21 : (TMG_1<=32'h00400000)? 22 : (TMG_1<=32'h00800000)? 23 : (TMG_1<=32'h01000000)? 24 :
   (TMG_1<=32'h02000000)? 25 : (TMG_1<=32'h04000000)? 26 : (TMG_1<=32'h08000000)? 27 : (TMG_1<=32'h10000000)? 28 :
   (TMG_1<=32'h20000000)? 29 : (TMG_1<=32'h40000000)? 30 : (TMG_1<=32'h80000000)? 31 : (TMG_1<=32'hFFFFFFFF)? 32 :
   -1;
//localparam TMG_2_CNTR_BIT_WIDTH  = CLOG2(TMG_2);
localparam TMG_2_CNTR_BIT_WIDTH  =
   (TMG_2<=32'h00000002)? 1  : (TMG_2<=32'h00000004)? 2  : (TMG_2<=32'h00000008)? 3  : (TMG_2<=32'h00000010)? 4  :
   (TMG_2<=32'h00000020)? 5  : (TMG_2<=32'h00000040)? 6  : (TMG_2<=32'h00000080)? 7  : (TMG_2<=32'h00000100)? 8  :
   (TMG_2<=32'h00000200)? 9  : (TMG_2<=32'h00000400)? 10 : (TMG_2<=32'h00000800)? 11 : (TMG_2<=32'h00001000)? 12 :
   (TMG_2<=32'h00002000)? 13 : (TMG_2<=32'h00004000)? 14 : (TMG_2<=32'h00008000)? 15 : (TMG_2<=32'h00010000)? 16 :
   (TMG_2<=32'h00020000)? 17 : (TMG_2<=32'h00040000)? 18 : (TMG_2<=32'h00080000)? 19 : (TMG_2<=32'h00100000)? 20 :
   (TMG_2<=32'h00200000)? 21 : (TMG_2<=32'h00400000)? 22 : (TMG_2<=32'h00800000)? 23 : (TMG_2<=32'h01000000)? 24 :
   (TMG_2<=32'h02000000)? 25 : (TMG_2<=32'h04000000)? 26 : (TMG_2<=32'h08000000)? 27 : (TMG_2<=32'h10000000)? 28 :
   (TMG_2<=32'h20000000)? 29 : (TMG_2<=32'h40000000)? 30 : (TMG_2<=32'h80000000)? 31 : (TMG_2<=32'hFFFFFFFF)? 32 :
   -1;
//localparam TMG_3_CNTR_BIT_WIDTH  = CLOG2(TMG_3);
localparam TMG_3_CNTR_BIT_WIDTH  =
   (TMG_3<=32'h00000002)? 1  : (TMG_3<=32'h00000004)? 2  : (TMG_3<=32'h00000008)? 3  : (TMG_3<=32'h00000010)? 4  :
   (TMG_3<=32'h00000020)? 5  : (TMG_3<=32'h00000040)? 6  : (TMG_3<=32'h00000080)? 7  : (TMG_3<=32'h00000100)? 8  :
   (TMG_3<=32'h00000200)? 9  : (TMG_3<=32'h00000400)? 10 : (TMG_3<=32'h00000800)? 11 : (TMG_3<=32'h00001000)? 12 :
   (TMG_3<=32'h00002000)? 13 : (TMG_3<=32'h00004000)? 14 : (TMG_3<=32'h00008000)? 15 : (TMG_3<=32'h00010000)? 16 :
   (TMG_3<=32'h00020000)? 17 : (TMG_3<=32'h00040000)? 18 : (TMG_3<=32'h00080000)? 19 : (TMG_3<=32'h00100000)? 20 :
   (TMG_3<=32'h00200000)? 21 : (TMG_3<=32'h00400000)? 22 : (TMG_3<=32'h00800000)? 23 : (TMG_3<=32'h01000000)? 24 :
   (TMG_3<=32'h02000000)? 25 : (TMG_3<=32'h04000000)? 26 : (TMG_3<=32'h08000000)? 27 : (TMG_3<=32'h10000000)? 28 :
   (TMG_3<=32'h20000000)? 29 : (TMG_3<=32'h40000000)? 30 : (TMG_3<=32'h80000000)? 31 : (TMG_3<=32'hFFFFFFFF)? 32 :
   -1;
//localparam TMG_4_CNTR_BIT_WIDTH  = CLOG2(TMG_4);
localparam TMG_4_CNTR_BIT_WIDTH  =
   (TMG_4<=32'h00000002)? 1  : (TMG_4<=32'h00000004)? 2  : (TMG_4<=32'h00000008)? 3  : (TMG_4<=32'h00000010)? 4  :
   (TMG_4<=32'h00000020)? 5  : (TMG_4<=32'h00000040)? 6  : (TMG_4<=32'h00000080)? 7  : (TMG_4<=32'h00000100)? 8  :
   (TMG_4<=32'h00000200)? 9  : (TMG_4<=32'h00000400)? 10 : (TMG_4<=32'h00000800)? 11 : (TMG_4<=32'h00001000)? 12 :
   (TMG_4<=32'h00002000)? 13 : (TMG_4<=32'h00004000)? 14 : (TMG_4<=32'h00008000)? 15 : (TMG_4<=32'h00010000)? 16 :
   (TMG_4<=32'h00020000)? 17 : (TMG_4<=32'h00040000)? 18 : (TMG_4<=32'h00080000)? 19 : (TMG_4<=32'h00100000)? 20 :
   (TMG_4<=32'h00200000)? 21 : (TMG_4<=32'h00400000)? 22 : (TMG_4<=32'h00800000)? 23 : (TMG_4<=32'h01000000)? 24 :
   (TMG_4<=32'h02000000)? 25 : (TMG_4<=32'h04000000)? 26 : (TMG_4<=32'h08000000)? 27 : (TMG_4<=32'h10000000)? 28 :
   (TMG_4<=32'h20000000)? 29 : (TMG_4<=32'h40000000)? 30 : (TMG_4<=32'h80000000)? 31 : (TMG_4<=32'hFFFFFFFF)? 32 :
   -1;
//localparam TMG_5_CNTR_BIT_WIDTH  = CLOG2(TMG_5);
localparam TMG_5_CNTR_BIT_WIDTH  =
   (TMG_5<=32'h00000002)? 1  : (TMG_5<=32'h00000004)? 2  : (TMG_5<=32'h00000008)? 3  : (TMG_5<=32'h00000010)? 4  :
   (TMG_5<=32'h00000020)? 5  : (TMG_5<=32'h00000040)? 6  : (TMG_5<=32'h00000080)? 7  : (TMG_5<=32'h00000100)? 8  :
   (TMG_5<=32'h00000200)? 9  : (TMG_5<=32'h00000400)? 10 : (TMG_5<=32'h00000800)? 11 : (TMG_5<=32'h00001000)? 12 :
   (TMG_5<=32'h00002000)? 13 : (TMG_5<=32'h00004000)? 14 : (TMG_5<=32'h00008000)? 15 : (TMG_5<=32'h00010000)? 16 :
   (TMG_5<=32'h00020000)? 17 : (TMG_5<=32'h00040000)? 18 : (TMG_5<=32'h00080000)? 19 : (TMG_5<=32'h00100000)? 20 :
   (TMG_5<=32'h00200000)? 21 : (TMG_5<=32'h00400000)? 22 : (TMG_5<=32'h00800000)? 23 : (TMG_5<=32'h01000000)? 24 :
   (TMG_5<=32'h02000000)? 25 : (TMG_5<=32'h04000000)? 26 : (TMG_5<=32'h08000000)? 27 : (TMG_5<=32'h10000000)? 28 :
   (TMG_5<=32'h20000000)? 29 : (TMG_5<=32'h40000000)? 30 : (TMG_5<=32'h80000000)? 31 : (TMG_5<=32'hFFFFFFFF)? 32 :
   -1;

wire s_trg_base_tick;
wire s_trg_1st_tick;
wire s_trg_2nd_tick;
wire s_trg_3rd_tick;
wire s_trg_4th_tick;
wire s_trg_5th_tick;

// base cntr
reg  [TMG_BASE_CNTR_BIT_WIDTH-1:0] s_base_cntr;
reg                                s_base_trg;
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_base_cntr <= {(TMG_BASE_CNTR_BIT_WIDTH){1'b0}};
		s_base_trg  <= 1'b0;
	end else if(clk_i) begin
		if(trg_en_i) begin
			if(s_trg_base_tick) begin
				s_base_cntr <= {(TMG_BASE_CNTR_BIT_WIDTH){1'b0}};
				s_base_trg  <= 1'b1;
			end else begin
				s_base_cntr <= s_base_cntr + 1'b1;
				s_base_trg  <= 1'b0;
			end
		end else begin
			s_base_cntr <= {(TMG_BASE_CNTR_BIT_WIDTH){1'b0}};
			s_base_trg  <= 1'b0;
		end
	end
end

assign s_trg_base_tick = (s_base_cntr == (TMG_BASE_CNTR_MAX[TMG_BASE_CNTR_BIT_WIDTH-1:0] - 1'b1)) ? 1'b1 : 1'b0;

assign trg_base_o = s_base_trg;

// 1st cntr
generate if(TMG_1 != 0)
begin
	reg  [TMG_1_CNTR_BIT_WIDTH-1:0] s_1st_cntr;
	reg                             s_1st_trg;
	always @(negedge rst_ni, posedge clk_i)
	begin
		if(~rst_ni) begin
			s_1st_cntr <= {(TMG_1_CNTR_BIT_WIDTH){1'b0}};
			s_1st_trg  <= 1'b0;
		end else if(clk_i) begin
			if(trg_en_i) begin
				if(s_trg_1st_tick) begin
					s_1st_cntr <= {(TMG_1_CNTR_BIT_WIDTH){1'b0}};
					s_1st_trg  <= 1'b1;
				end else if(s_trg_base_tick) begin
					s_1st_cntr <= s_1st_cntr + 1'b1;
					s_1st_trg  <= 1'b0;
				end
			end else begin
				s_1st_cntr <= {(TMG_1_CNTR_BIT_WIDTH){1'b0}};
				s_1st_trg  <= 1'b0;
			end
		end
	end
	assign s_trg_1st_tick = (s_trg_base_tick && s_1st_cntr == (TMG_1[TMG_1_CNTR_BIT_WIDTH-1:0] - 1'b1)) ? 1'b1 : 1'b0;

	assign trg_1st_o = s_trg_1st_tick;
end else begin
	assign s_trg_1st_tick = 1'b0;
	assign trg_1st_o = 1'b0;
end
endgenerate

// 2nd cntr
generate if(TMG_1 != 0 && TMG_2 != 0)
begin
	reg  [TMG_2_CNTR_BIT_WIDTH-1:0] s_2nd_cntr;
	reg                             s_2nd_trg;
	always @(negedge rst_ni, posedge clk_i)
	begin
		if(~rst_ni) begin
			s_2nd_cntr <= {(TMG_2_CNTR_BIT_WIDTH){1'b0}};
			s_2nd_trg  <= 1'b0;
		end else if(clk_i) begin
			if(trg_en_i) begin
				if(s_trg_2nd_tick) begin
					s_2nd_cntr <= {(TMG_2_CNTR_BIT_WIDTH){1'b0}};
					s_2nd_trg  <= 1'b1;
				end else if(s_trg_1st_tick) begin
					s_2nd_cntr <= s_2nd_cntr + 1'b1;
					s_2nd_trg  <= 1'b0;
				end
			end else begin
				s_2nd_cntr <= {(TMG_2_CNTR_BIT_WIDTH){1'b0}};
				s_2nd_trg  <= 1'b0;
			end
		end
	end
	assign s_trg_2nd_tick = (s_trg_1st_tick && s_2nd_cntr == (TMG_2[TMG_2_CNTR_BIT_WIDTH-1:0] - 1'b1)) ? 1'b1 : 1'b0;

	assign trg_2nd_o = s_trg_2nd_tick;
end else begin
	assign s_trg_2nd_tick = 1'b0;
	assign trg_2nd_o = 1'b0;
end
endgenerate

// 3rd cntr
generate if(TMG_1 != 0 && TMG_2 != 0 && TMG_3 != 0)
begin
	reg  [TMG_3_CNTR_BIT_WIDTH-1:0] s_3rd_cntr;
	reg                             s_3rd_trg;
	always @(negedge rst_ni, posedge clk_i)
	begin
		if(~rst_ni) begin
			s_3rd_cntr <= {(TMG_3_CNTR_BIT_WIDTH){1'b0}};
			s_3rd_trg  <= 1'b0;
		end else if(clk_i) begin
			if(trg_en_i) begin
				if(s_trg_3rd_tick) begin
					s_3rd_cntr <= {(TMG_3_CNTR_BIT_WIDTH){1'b0}};
					s_3rd_trg  <= 1'b1;
				end else if(s_trg_2nd_tick) begin
					s_3rd_cntr <= s_3rd_cntr + 1'b1;
					s_3rd_trg  <= 1'b0;
				end
			end else begin
				s_3rd_cntr <= {(TMG_3_CNTR_BIT_WIDTH){1'b0}};
				s_3rd_trg  <= 1'b0;
			end
		end
	end
	assign s_trg_3rd_tick = (s_trg_2nd_tick && s_3rd_cntr == (TMG_3[TMG_3_CNTR_BIT_WIDTH-1:0] - 1'b1)) ? 1'b1 : 1'b0;

	assign trg_3rd_o = s_trg_3rd_tick;
end else begin
	assign s_trg_3rd_tick = 1'b0;
	assign trg_3rd_o = 1'b0;
end
endgenerate

// 4th cntr
generate if(TMG_1 != 0 && TMG_2 != 0 && TMG_3 != 0 && TMG_4 != 0)
begin
	reg  [TMG_4_CNTR_BIT_WIDTH-1:0] s_4th_cntr;
	reg                             s_4th_trg;
	always @(negedge rst_ni, posedge clk_i)
	begin
		if(~rst_ni) begin
			s_4th_cntr <= {(TMG_4_CNTR_BIT_WIDTH){1'b0}};
			s_4th_trg  <= 1'b0;
		end else if(clk_i) begin
			if(trg_en_i) begin
				if(s_trg_4th_tick) begin
					s_4th_cntr <= {(TMG_4_CNTR_BIT_WIDTH){1'b0}};
					s_4th_trg  <= 1'b1;
				end else if(s_trg_3rd_tick) begin
					s_4th_cntr <= s_4th_cntr + 1'b1;
					s_4th_trg  <= 1'b0;
				end
			end else begin
				s_4th_cntr <= {(TMG_4_CNTR_BIT_WIDTH){1'b0}};
				s_4th_trg  <= 1'b0;
			end
		end
	end
	assign s_trg_4th_tick = (s_trg_3rd_tick && s_4th_cntr == (TMG_4[TMG_4_CNTR_BIT_WIDTH-1:0] - 1'b1)) ? 1'b1 : 1'b0;

	assign trg_4th_o = s_trg_4th_tick;
end else begin
	assign s_trg_4th_tick = 1'b0;
	assign trg_4th_o = 1'b0;
end
endgenerate

// 5th cntr
generate if(TMG_1 != 0 && TMG_2 != 0 && TMG_3 != 0 && TMG_4 != 0 && TMG_5 != 0)
begin
	reg  [TMG_5_CNTR_BIT_WIDTH-1:0] s_5th_cntr;
	reg                             s_5th_trg;
	always @(negedge rst_ni, posedge clk_i)
	begin
		if(~rst_ni) begin
			s_5th_cntr <= {(TMG_5_CNTR_BIT_WIDTH){1'b0}};
			s_5th_trg  <= 1'b0;
		end else if(clk_i) begin
			if(trg_en_i) begin
				if(s_trg_5th_tick) begin
					s_5th_cntr <= s_5th_cntr + 1'b1;
					s_5th_trg  <= 1'b0;
				end else if(s_trg_4th_tick) begin
					s_5th_cntr <= {(TMG_5_CNTR_BIT_WIDTH){1'b0}};
					s_5th_trg  <= 1'b1;
				end
			end else begin
				s_5th_cntr <= {(TMG_5_CNTR_BIT_WIDTH){1'b0}};
				s_5th_trg  <= 1'b0;
			end
		end
	end
	assign s_trg_5th_tick = (s_trg_4th_tick && s_5th_cntr == (TMG_5[TMG_5_CNTR_BIT_WIDTH-1:0] - 1'b1)) ? 1'b1 : 1'b0;

	assign trg_5th_o = s_trg_5th_tick;
end else begin
	assign s_trg_5th_tick = 1'b0;
	assign trg_5th_o = 1'b0;
end
endgenerate

endmodule
