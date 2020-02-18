// --------------------------------------------------------
// File Name   : ps2_dev_if.v
// Description : PS/2 Device Interface(not-Host)
//               role of Device : generate CLK both TX/RX
//               DEV->HOST : DATA is read on falling edge CLK ***TX***
//               HOST->DEV : DATA is read on rising  edge CLK ***RX***
//               process each byte
//               ->don't care chunk of data
//               ->no resend(TX)
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.02.11 I.Yang              Create New(from PS_2__KEYBOARD_IO)
// 0.01    2020.02.14 I.Yang              1st draft
// --------------------------------------------------------
// --------------------------------------------------------
// File Name   : ps2_rx_if.v
// Description : PS/2 testing rtl
//               receive device's tx-data
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.02.16 I.Yang              change rx timing(fl->rz)
//                                        remove rx host wait sequence
// --------------------------------------------------------

`timescale 1ns / 1ps

module ps2_rx_if (
	input  wire       rst_ni,
	input  wire       clk_i,

	input  wire       ps2_rx_clk_i,
	input  wire       ps2_rx_data_i,

    output wire       rx_en_o,
    output wire [7:0] rx_data_o,
    output wire       rx_pty_err_o  // parity error
);

localparam [2:0] FSM_IDLE      = 3'h0;
localparam [2:0] FSM_TX        = 3'h1;
localparam [2:0] FSM_TX_OK     = 3'h2; // not word, but chunk
localparam [2:0] FSM_RX_PRE_REQ= 3'h3; // host drive clk-GND
localparam [2:0] FSM_RX_REQ    = 3'h4; // request from host(clk-GND >100us)
localparam [2:0] FSM_RX        = 3'h5; // contain ACK - when parity error, not issue ACK
localparam [2:0] FSM_RX_OK     = 3'h6; // 

wire       s_trg_5us;
wire       s_trg_10us;
wire       s_trg_100us;


reg  [3:0] s_line_idle_cntr;
reg        s_line_idle;

reg  [2:0] s_next_state;
reg  [2:0] s_state;
reg        s_ps2_dev_clk_gen_en;
reg        s_ps2_dev_clk;
reg  [5:0] s_ps2_dev_clk_cntr;
reg  [4:0] s_ps2_dev_clk_bit_cntr;

wire       s_ps2_dev_clk_rz;
wire       s_ps2_dev_clk_fl;

wire       s_ps2_dev_clk_bit_cntr_max;
wire       s_ps2_dev_clk_gen_end;
reg  [1:0] s_ps2_dev_clk_d;
wire       s_host_drive_clk_gnd;
reg  [2:0] s_ps2_rx_clk_d;
reg  [1:0] s_ps2_rx_data_d;
wire       s_ps2_rx_clk_rz;
wire       s_ps2_rx_clk_fl;
reg  [3:0] s_rx_req_check_cntr;
wire       s_rx_req_check;
reg        s_host_wait_clk;
reg  [3:0] s_rx_bit_cntr;
reg  [7:0] s_rx_data_sft;
reg        s_rx_pty_ok;
reg  [7:0] s_rx_data_lat;
reg        s_rx_pty_ok_lat;
reg        s_rx_ack;
wire       s_tx_busy;
reg        s_tx_fail;
reg  [1:0] s_tx_en_d;
reg  [7:0] s_tx_data;
wire       s_tx_en_rz;
reg  [7:0] s_tx_data_lat;
reg        s_tx_data_serial;

//         freq      base 1 2  3 4 5
trg_cntr #(50000000,5,2,10,0,0,0) u_trg_cntr(rst_ni, clk_i, 1'b1, s_trg_5us, s_trg_10us, s_trg_100us, , , );

// monitor line idle
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_line_idle_cntr <= 3'b0;
		s_line_idle      <= 1'b0;
	end else if(clk_i) begin
		if(s_ps2_rx_clk_d[1] == 1'b0 || s_ps2_rx_data_d[1] == 1'b0) begin
			s_line_idle_cntr <= 3'b0;
			s_line_idle      <= 1'b0;
		end else if(s_trg_10us) begin
			if(s_line_idle_cntr < 3'h5) begin // 50us
				s_line_idle_cntr <= s_line_idle_cntr + 1'b1;
				s_line_idle      <= 1'b0;
			end else begin
				s_line_idle_cntr <= s_line_idle_cntr;
				s_line_idle      <= 1'b1;
			end
		end
	end
end


// --------------------
// FSM
// --------------------
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_next_state <= FSM_IDLE;
	else if(clk_i) begin
		case (s_state)
			FSM_IDLE:
				begin
					if (s_ps2_rx_clk_fl)
						s_next_state <= FSM_RX;
					else
						s_next_state <= s_next_state;
				end
			FSM_RX:
				begin
					if(s_ps2_rx_clk_rz && s_rx_bit_cntr == 4'hA)
						s_next_state <= FSM_RX_OK;
					else if (s_line_idle)
						s_next_state <= FSM_IDLE;
					else
						s_next_state <= s_next_state;
				end
			FSM_RX_OK:
				begin
					if (s_line_idle)
						s_next_state <= FSM_IDLE;
					else
						s_next_state <= s_next_state;
				end
			default:
				s_next_state <= FSM_IDLE;
		endcase
	end
end

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_state <= FSM_IDLE;
	else if(clk_i)
		s_state <= s_next_state;
end

// --------------------
// RX
// --------------------
// input FF
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_ps2_rx_clk_d  <= 3'd0;
		s_ps2_rx_data_d <= 2'd0;
	end else if(clk_i) begin
		s_ps2_rx_clk_d <= {s_ps2_rx_clk_d[1:0], ps2_rx_clk_i};
		s_ps2_rx_data_d <= {s_ps2_rx_data_d[0], ps2_rx_data_i};
	end
end

assign s_ps2_rx_clk_rz = s_ps2_rx_clk_d[2:1] == 2'b01 ? 1'b1 : 1'b0;
assign s_ps2_rx_clk_fl = s_ps2_rx_clk_d[2:1] == 2'b10 ? 1'b1 : 1'b0;

// rx bit cntr
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_bit_cntr <=  4'b0;
	else if(clk_i) begin
		if(s_state == FSM_RX) begin
			if(s_ps2_rx_clk_rz)
				s_rx_bit_cntr <=  s_rx_bit_cntr + 1'b1;
		end else 
			s_rx_bit_cntr <=  4'b0;
	end
end

// rx shift regiester
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_rx_data_sft <= 8'hFF;
		s_rx_pty_ok   <= 1'b0;
	end else if(clk_i) begin
		if(s_ps2_rx_clk_rz) begin
			case(s_rx_bit_cntr)
				4'h0:
					begin
						s_rx_data_sft <= 8'hFF; // initial
						s_rx_pty_ok   <= 1'b0;
					end
				4'h1, 4'h2, 4'h3, 4'h4,
				4'h5, 4'h6, 4'h7, 4'h8:
					begin
						s_rx_data_sft <= {s_ps2_rx_data_d[1], s_rx_data_sft[7:1]};
						s_rx_pty_ok   <= 1'b0;
					end
				4'h9:
					begin
						s_rx_data_sft <= s_rx_data_sft;
						s_rx_pty_ok   <= (s_ps2_rx_data_d[1] == ~^s_rx_data_sft);
					end
				4'hA: // stop bit
					begin
						s_rx_data_sft <= s_rx_data_sft;
						s_rx_pty_ok   <= s_rx_pty_ok;
					end
				default:
					begin
						s_rx_data_sft <= 8'hFF; // initial
						s_rx_pty_ok   <= 1'b0;
					end
			endcase
		end
	end
end

// latch received data
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_rx_data_lat   <= 8'hFF;
		s_rx_pty_ok_lat <= 1'b0;
	end else if(clk_i) begin
		if(s_ps2_rx_clk_fl) begin
			if(s_rx_bit_cntr == 4'hA) begin
				s_rx_data_lat   <= s_rx_data_sft;
				s_rx_pty_ok_lat <= s_rx_pty_ok;
			end
		end
	end
end

// rx ack
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rx_ack <= 1'b1;
	else if(clk_i) begin
		if(s_state == FSM_RX) begin
			if(s_ps2_rx_clk_rz) begin
				if(s_rx_bit_cntr == 4'hA)
					s_rx_ack <= ~s_rx_pty_ok_lat;
//					s_rx_ack <= 1'b0;
				else
					s_rx_ack <= 1'b1;
			end else
				s_rx_ack <= 1'b1;
		end else
			s_rx_ack <= 1'b1;
	end
end

assign rx_en_o = ~s_rx_ack;
assign rx_data_o = s_rx_data_lat;
assign rx_pty_err_o = ~s_rx_pty_ok_lat;



endmodule
