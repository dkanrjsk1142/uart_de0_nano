// --------------------------------------------------------
// File Name   : UART_DE0_NANO_TOP.v
// Description : Bench TOP UART_DE0_NANO
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.01.01 I.Yang              Create New
// 0.02    2020.01.19 I.Yang              add uart cts/rts
// --------------------------------------------------------



`timescale 1ns / 1ps

module TB_UART_DE0_NANO_TOP;


// --------------------
// CLK/RST
// --------------------
reg  s_clk_en;
wire s_clk_50m;
wire s_clk_115k;
wire s_clk_16p7;
wire s_rsth;

initial begin
	s_clk_en = 1'b0;
	#100
	s_clk_en = 1'b1;
end

tb_clk #(50000000, 50) u_tb_clk_50m  (s_clk_en, s_clk_50m , s_rsth);
tb_clk #(  115200, 50) u_tb_clk_115k (    1'b1, s_clk_115k,       );
//tb_clk #(    9600, 50) u_tb_clk_115k (    1'b1, s_clk_115k,       );


tb_clk #(   16667, 50) u_tb_clk_16k7 (    1'b1, s_clk_16k7,       );

// --------------------
// cpu
// --------------------
// T.B.D.

// --------------------
// RTL
// --------------------
tri1 s_uart_rx;
tri1 s_uart_tx;
tri1 s_uart_cts;
tri1 s_uart_rts;

reg s_ps2_clk;
reg s_ps2_data;


UART_DE0_NANO U_UART_DE0_NANO(
	.rst_n     (~s_rsth             ), //input  wire rst_n,
	.clk       (s_clk_50m           ), //input  wire clk,

	// uart if
	.uart_rx   (s_uart_rx           ), //input  wire uart_rx,
	.uart_tx   (s_uart_tx           ), //output wire uart_tx
	.uart_cts  (s_uart_cts          ), //output wire uart_cts
	.uart_rts  (s_uart_rts          ), //input  wire uart_rts

	// test RTL
	.host1_uart_rx (s_host_uart      ), // input  wire       host1_uart_rx,
	.host1_uart_tx (s_host_uart      ), // output wire       host1_uart_tx,
	.host2_ps2_clk (s_ps2_clk        ), // input  wire       host2_ps2_clk,
	.host2_ps2_data(s_ps2_data       ), // input  wire       host2_ps2_data,

	// debug
	.led_debug (                    ), //output wire [7:0] led_debug
	.test_pin  (                    )  //output wire test_pin
);

reg [7:0] s_ps2_cntr;
always @(posedge s_rsth, posedge s_clk_16k7)
begin
	if(s_rsth)
		s_ps2_cntr <= 8'b0;
	else if(s_clk_16k7) begin
		s_ps2_cntr <= s_ps2_cntr + 1'b1;
	end
end

always @(s_clk_16k7)
begin
	if(s_ps2_cntr > 8'h0 && s_ps2_cntr < 8'hD)
		s_ps2_clk <= s_clk_16k7;
	else
		s_ps2_clk <= 1'b1;
end
	

always @(posedge s_clk_16k7)
begin
	case(s_ps2_cntr)
		5'h00 : s_ps2_data <= 1'b0;
		5'h01 : s_ps2_data <= 1'b0; // start
		5'h02 : s_ps2_data <= 1'b1;
		5'h03 : s_ps2_data <= 1'b0;
		5'h04 : s_ps2_data <= 1'b1;
		5'h05 : s_ps2_data <= 1'b0;
		5'h06 : s_ps2_data <= 1'b1;
		5'h07 : s_ps2_data <= 1'b0;
		5'h08 : s_ps2_data <= 1'b0;
		5'h09 : s_ps2_data <= 1'b0;
		5'h0A : s_ps2_data <= 1'b0; // pty
		5'h0B : s_ps2_data <= 1'b1; // STOP
		default : s_ps2_data <= 1'b1;
	endcase
end

// --------------------
// Bench
// --------------------
reg        s_data_start;
reg        s_data_start_1d;

reg  [9:0] data_raw [15:0];

reg  [3:0] s_data_cnt;
reg  [3:0] s_bit_cnt;
wire       s_word_end;

reg  [7:0]      s_char;
reg  [16*8-1:0] s_cmd;

reg  s_char_temp;
integer i, j;
initial begin
	//data init
	//data_raw[ 0] <= { 1'b0, 8'h50, 1'b1};
	//data_raw[ 1] <= { 1'b0, 8'hA1, 1'b1};
	//data_raw[ 2] <= { 1'b0, 8'hB0, 1'b1};
	//data_raw[ 3] <= { 1'b0, 8'hA3, 1'b1};
	//data_raw[ 4] <= { 1'b0, 8'h54, 1'b1};
	//data_raw[ 5] <= { 1'b0, 8'hA5, 1'b1};
	//data_raw[ 6] <= { 1'b0, 8'h26, 1'b1};
	//data_raw[ 7] <= { 1'b0, 8'h77, 1'b1};
	//data_raw[ 8] <= { 1'b0, 8'h28, 1'b1};
	//data_raw[ 9] <= { 1'b0, 8'h79, 1'b1};
	//data_raw[10] <= { 1'b0, 8'h2A, 1'b1};
	//data_raw[11] <= { 1'b0, 8'h7B, 1'b1};
	//data_raw[12] <= { 1'b0, 8'h2C, 1'b1};
	//data_raw[13] <= { 1'b0, 8'h7D, 1'b1};
	//data_raw[14] <= { 1'b0, 8'h3E, 1'b1};
	//data_raw[15] <= { 1'b0, 8'h9F, 1'b1};
    s_cmd = "ECHO ABCDE\nYZ QA";
	//bit order swap
	for (i = 0; i < 16; i = i + 1) begin
		for(j = 0; j < 4; j = j + 1) begin
			s_char_temp = s_cmd[i*8+j];
			s_cmd[i*8+j] = s_cmd[(15-i)*8+(7-j)];
			s_cmd[(15-i)*8+(7-j)]= s_char_temp;
		end
	end
	data_raw[ 0] <= { 1'b0, s_cmd[ 0*8+7: 0*8], 1'b1};
	data_raw[ 1] <= { 1'b0, s_cmd[ 1*8+7: 1*8], 1'b1};
	data_raw[ 2] <= { 1'b0, s_cmd[ 2*8+7: 2*8], 1'b1};
	data_raw[ 3] <= { 1'b0, s_cmd[ 3*8+7: 3*8], 1'b1};
	data_raw[ 4] <= { 1'b0, s_cmd[ 4*8+7: 4*8], 1'b1};
	data_raw[ 5] <= { 1'b0, s_cmd[ 5*8+7: 5*8], 1'b1};
	data_raw[ 6] <= { 1'b0, s_cmd[ 6*8+7: 6*8], 1'b1};
	data_raw[ 7] <= { 1'b0, s_cmd[ 7*8+7: 7*8], 1'b1};
	data_raw[ 8] <= { 1'b0, s_cmd[ 8*8+7: 8*8], 1'b1};
	data_raw[ 9] <= { 1'b0, s_cmd[ 9*8+7: 9*8], 1'b1};
	data_raw[10] <= { 1'b0, s_cmd[10*8+7:10*8], 1'b1};
	data_raw[11] <= { 1'b0, s_cmd[11*8+7:11*8], 1'b1};
	data_raw[12] <= { 1'b0, s_cmd[12*8+7:12*8], 1'b1};
	data_raw[13] <= { 1'b0, s_cmd[13*8+7:13*8], 1'b1};
	data_raw[14] <= { 1'b0, s_cmd[14*8+7:14*8], 1'b1};
	data_raw[15] <= { 1'b0, s_cmd[15*8+7:15*8], 1'b1};

	s_data_start <= 1'b0; // manipulate by force
	for (i = 0; i < 16; i = i + 1) begin
		//#150000 // 150us
		#67000 // 67us
		s_data_start <= 1'b1;
		#20000  // 20us
		s_data_start <= 1'b0;
	end
end


always @(posedge s_rsth, posedge s_clk_115k)
begin
	if (s_rsth)
		s_data_start_1d <= 1'b0;
	if (s_clk_115k) begin
		s_data_start_1d <= s_data_start;
	end
end

always @(posedge s_rsth, posedge s_clk_115k)
begin
	if (s_rsth)
		s_data_cnt <= 4'b0;
	if (s_clk_115k) begin
		if (s_word_end)
			s_data_cnt <= s_data_cnt + 4'b1;
	end
end

always @(posedge s_rsth, posedge s_clk_115k)
begin
	if (s_rsth)
		s_bit_cnt <= 4'b0;
	if (s_clk_115k) begin
		if (~s_data_start_1d && s_data_start) // posedge
			s_bit_cnt <= 4'd10;
		//else if (s_bit_cnt > 4'd0 && s_bit_cnt < 4'd11)
		else if (s_bit_cnt > 4'd0)
			s_bit_cnt <= s_bit_cnt - 4'b1;
		else
			s_bit_cnt <= 4'b0;
	end
end

assign s_word_end = s_bit_cnt == 4'd1 ? 1'b1 : 1'b0;

//assign s_uart_rx = s_bit_cnt > 4'd0 && s_bit_cnt < 4'd11 ? data_raw[s_data_cnt][s_bit_cnt-1] : 1'b1;
assign s_uart_rx = |s_bit_cnt ? data_raw[s_data_cnt][s_bit_cnt-1] : 1'bZ;


endmodule
