// --------------------------------------------------------
// File Name   : hex2ascii.v
// Description : hex 2 ascii converter
//               if input 0xA3, output 'A'(0x41) '3'(0x33)
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.02.18 I.Yang              Create New
// --------------------------------------------------------

module hex2ascii #(
	parameter HEX_BIT_WIDTH =  2 // 
) (
	input  wire        rst_ni,
	input  wire        clk_i,

	input  wire        hex_den_i,
	input  wire  [HEX_BIT_WIDTH*4-1:0] hex_data_i,
	output wire        cvt_busy_o,

	output wire        ascii_den_o,
	output wire  [7:0] ascii_data_o
);

localparam CNTR_BIT_WIDTH = 
   (HEX_BIT_WIDTH<=32'h00000002)? 1  : (HEX_BIT_WIDTH<=32'h00000004)? 2  : (HEX_BIT_WIDTH<=32'h00000008)? 3  : (HEX_BIT_WIDTH<=32'h00000010)? 4  :
   (HEX_BIT_WIDTH<=32'h00000020)? 5  : (HEX_BIT_WIDTH<=32'h00000040)? 6  : (HEX_BIT_WIDTH<=32'h00000080)? 7  : (HEX_BIT_WIDTH<=32'h00000100)? 8  :
   (HEX_BIT_WIDTH<=32'h00000200)? 9  : (HEX_BIT_WIDTH<=32'h00000400)? 10 : (HEX_BIT_WIDTH<=32'h00000800)? 11 : (HEX_BIT_WIDTH<=32'h00001000)? 12 :
   (HEX_BIT_WIDTH<=32'h00002000)? 13 : (HEX_BIT_WIDTH<=32'h00004000)? 14 : (HEX_BIT_WIDTH<=32'h00008000)? 15 : (HEX_BIT_WIDTH<=32'h00010000)? 16 :
   (HEX_BIT_WIDTH<=32'h00020000)? 17 : (HEX_BIT_WIDTH<=32'h00040000)? 18 : (HEX_BIT_WIDTH<=32'h00080000)? 19 : (HEX_BIT_WIDTH<=32'h00100000)? 20 :
   (HEX_BIT_WIDTH<=32'h00200000)? 21 : (HEX_BIT_WIDTH<=32'h00400000)? 22 : (HEX_BIT_WIDTH<=32'h00800000)? 23 : (HEX_BIT_WIDTH<=32'h01000000)? 24 :
   (HEX_BIT_WIDTH<=32'h02000000)? 25 : (HEX_BIT_WIDTH<=32'h04000000)? 26 : (HEX_BIT_WIDTH<=32'h08000000)? 27 : (HEX_BIT_WIDTH<=32'h10000000)? 28 :
   (HEX_BIT_WIDTH<=32'h20000000)? 29 : (HEX_BIT_WIDTH<=32'h40000000)? 30 : (HEX_BIT_WIDTH<=32'h80000000)? 31 : (HEX_BIT_WIDTH<=32'hFFFFFFFF)? 32 :
   -1;

reg  [1:0]                 s_hex_den_d;
reg  [HEX_BIT_WIDTH*4-1:0] s_hex_data;

wire                       s_hex_den_rz;

reg  [CNTR_BIT_WIDTH-1:0]  s_cvt_cntr;
reg                        s_cvt_en;
reg  [HEX_BIT_WIDTH*4-1:0] s_sft_data;
reg                        s_ascii_den;
reg  [7:0]                 s_ascii_data;

// --------------------
// wr_en_i / wr_data_i delay until state shift
// --------------------
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_hex_den_d <= 2'b0;
		s_hex_data  <= {HEX_BIT_WIDTH*4{1'b0}};
	end else if(clk_i) begin
		s_hex_den_d <= {s_hex_den_d[0], hex_den_i};
		s_hex_data  <= hex_data_i;
	end
end

assign s_hex_den_rz = (s_hex_den_d == 2'b01) ? 1'b1 : 1'b0;

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_cvt_cntr <= {CNTR_BIT_WIDTH{1'b0}};
	end else if(clk_i) begin
		if (s_hex_den_rz)
			s_cvt_cntr <= 1'b1;
		else if (s_cvt_cntr != HEX_BIT_WIDTH[CNTR_BIT_WIDTH-1:0])
			s_cvt_cntr <= s_cvt_cntr + 1'b1;
	end
end

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_cvt_en <= 1'b0;
	end else if(clk_i) begin
		if (s_hex_den_rz)
			s_cvt_en <= 1'b1;
		else if (s_cvt_cntr == HEX_BIT_WIDTH[CNTR_BIT_WIDTH-1:0])
			s_cvt_en <= 1'b0;
	end
end

assign cvt_busy_o = s_cvt_en;

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_sft_data <= {HEX_BIT_WIDTH*4{1'b0}};
	end else if(clk_i) begin
		if (s_hex_den_rz)
			s_sft_data <= s_hex_data;
		else
			s_sft_data <= s_sft_data << 4;
	end
end

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_ascii_den  <= 1'b0;
		s_ascii_data <= 8'b0;
	end else if(clk_i) begin
		s_ascii_den  <= s_cvt_en;
		case(s_sft_data[(HEX_BIT_WIDTH*4-1):((HEX_BIT_WIDTH-1)*4)])
			4'h0, 4'h1, 4'h2, 4'h3, 4'h4,
			4'h5, 4'h6, 4'h7, 4'h8, 4'h9:
				s_ascii_data <= {4'h3, s_sft_data[(HEX_BIT_WIDTH*4-1):((HEX_BIT_WIDTH-1)*4)]};
			4'hA: s_ascii_data <= 8'h41;
			4'hB: s_ascii_data <= 8'h42;
			4'hC: s_ascii_data <= 8'h43;
			4'hD: s_ascii_data <= 8'h44;
			4'hE: s_ascii_data <= 8'h45;
			4'hF: s_ascii_data <= 8'h46;
		endcase
	end
end

assign ascii_den_o  = s_ascii_den;
assign ascii_data_o = s_ascii_data;


endmodule
