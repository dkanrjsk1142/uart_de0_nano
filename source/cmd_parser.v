// --------------------------------------------------------
// File Name   : cmd_parser.v
// Description : custom command partser
//               CMD-DATA pair
//                                       0x20              0xD   0xA
//               format : (something CMD) (something DATA)(\r or \l)
//               STM    : 1. Idle
//                        2. CMD receive
//                        3. CMD receive end
//                        4. Data receive
//                        5. RAW Data receive
//               event condition : 
//                        1 -> 1 : [0x20 | 0x0A | 0x0D] ASCII
//                        1 -> 2 : except [0x20 | 0x0A | 0x0D] ASCII
//                        2 -> 1 : [0x0A | 0x0D] ASCII.
//                        2 -> 3 : [0x20] ASCII.
//                        3 -> 1 : [0x0A | 0x0D] ASCII or CMD:unknown CMD.
//                        3 -> 4 : except [0x20] ASCII.
//                        4 -> 1 : [0x0A | 0x0D] ASCII.
//                        4 -> 5 : [0x0A | 0x0D] ASCII and CMD:"RAW", DATA:sequencial data "unique-key(32word)"
//                        5 -> 1 : sequenceial data "unique-key(32word)"
//               len CMD : 32
//               #   CMD : 32(general 30 + idle 1 + unknown 1)
//
//               CMD_NO  CMD(min:2, max:32word) DATA(max 256word)        Description
//                    0. -                      -                        Unused(spaceholder)
//                    1. ECHO                   *                        echo income data to TX
//                    2. RAW_DIR                0~1F(hex)                select module for RAW data stream
//                    3. RAW                    unique-key(32word)       start RAW data stream receive mode
//                    4. unique-key(32word)     (no-DATA)                end   RAW data stream receive mode
//                    5. REG_WRITE              ADDR(hex) DATA(hex)      write DATA to ADDR in DEL_SELed device
//                    6. REG_READ               ADDR(hex)                write DATA to ADDR in DEL_SELed device(DATA_WIDTH=32bit)
//                 7~29. Reserved               Reserved                 Reserved
//                   30. *                      *                        Busy(necessery?)
//                   31. *                      *                        Unknown
// --------------------------------------------------------
// Ver     Date       Author              Comment
// 0.01    2020.01.03 I.Yang              Create New
// 0.02    2020.01.05 I.Yang              1st prototype(CMD only, DATA not supported)
// 0.03    2020.01.13 I.Yang              fully support command "ECHO"
// 0.04    2020.01.13 I.Yang              add parameter CMD_IGNORE_CASE
// --------------------------------------------------------

module cmd_parser #(
	parameter CMD_IGNORE_CASE      =  1, // 1: ignore-case, 0:restrict check case
	parameter CMD_TABLE_ADDR_WIDTH =  6,
	parameter REG_READ_TIMEOUT_CLK = 31, // if rd_den(read data enable-from device) is not inputed, timeout after value of this parameter.
	parameter SIM_MODE             =  0  // 0: array ROM, 1:ip-core ROM(for read .mif)
) (
	input  wire        rst_ni,
	input  wire        clk_i,

	//income data
	input  wire        wr_en_i,
	input  wire  [7:0] wr_data_i,

	output wire  [4:0] cmd_o,

	output wire        out_en_o,
	output wire  [7:0] out_data_o,

//	output wire [31:0] dev_sel,    // select device/module (one-shot)

	input  wire [31:0] cmd_done    // bit_no == CMD_NO.
);

reg  [ 1:0] s_wr_en_d;

reg  [ 7:0] s_wr_data_1d;
reg  [ 7:0] s_wr_data_2d;

reg  [ 2:0] s_state;
reg  [ 2:0] s_next_state;

localparam CMD_TABLE_DEPTH = 2 ** CMD_TABLE_ADDR_WIDTH;

reg  [ 7:0] CMD_BUF   [ 31:0];
reg  [ 7:0] CMD_TABLE [CMD_TABLE_DEPTH-1:0] /* synthesis ram_init_file = "./source/cmd_parser_cmd_table.mif" */;

localparam [2:0] FSM_IDLE             = 3'h0;
localparam [2:0] FSM_CMD_RECEIVE      = 3'h1;
localparam [2:0] FSM_CMD_RECEIVE_END  = 3'h2;
localparam [2:0] FSM_DATA_RECEIVE     = 3'h3;
localparam [2:0] FSM_RAW_DATA_RECEIVE = 3'h4;

localparam [5:0] CMD_UNUSED           = 5'h00;
localparam [5:0] CMD_ECHO             = 5'h01;
localparam [5:0] CMD_RAW_DIR          = 5'h02;
localparam [5:0] CMD_RAW              = 5'h03;
localparam [5:0] CMD_RAW_END          = 5'h04;
localparam [5:0] CMD_UNKNOWN          = 5'h1F;


reg         s_rgn_cmd_en;
reg  [ 1:0] s_rgn_cmd_en_d;
reg  [ 4:0] s_rgn_cmd_cntr;
reg  [ 4:0] s_rgn_cmd_cntr_1d;

reg         s_cmd_buf_clear_flg;
reg         s_cmd_buf_wr_en;
reg  [ 4:0] s_cmd_buf_wr_addr;
reg  [ 4:0] s_cmd_buf_wr_addr_1d;
reg  [ 7:0] s_cmd_buf_wr_data;
reg  [ 4:0] s_cmd_buf_rd_addr;
reg  [ 7:0] s_cmd_buf_char;
reg  [CMD_TABLE_ADDR_WIDTH-1:0] s_cmd_table_rd_addr;
reg  [ 7:0] s_cmd_table_char;
reg  [ 7:0] s_cmd_table_char_1d;
reg         s_cmd_diff_flag;
reg  [ 4:0] s_rgn_cmd;
reg  [ 4:0] s_cmd;
reg         s_cmd_confirmed_pls;


reg         s_cmd_done_sel;


reg  [ 7:0] s_data_buf_addr;


reg         s_in_data_buf_en;
reg  [ 7:0] s_in_data_buf_data;

reg         s_data_buf_wait;
wire        s_out_data_buf_en;
wire [ 7:0] s_out_data_buf_data;


// --------------------
// wr_en_i / wr_data_i delay until state shift
// --------------------
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_wr_en_d <= 2'b0;
		s_wr_data_1d <= 8'b0;
		s_wr_data_2d <= 8'b0;
	end else if(clk_i) begin
		s_wr_en_d <= {s_wr_en_d[0], wr_en_i};
		s_wr_data_1d <= wr_data_i;
		s_wr_data_2d <= s_wr_data_1d;
	end
end

// --------------------
// FSM
// --------------------
assign s_crlf  = wr_data_i == 8'h0A || wr_data_i == 8'h0D ? 1'b1 : 1'b0;
assign s_space = wr_data_i == 8'h20  ? 1'b1 : 1'b0;

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_next_state <= FSM_IDLE;
	else if(clk_i) begin
		if (wr_en_i) begin
			case (s_state)
				FSM_IDLE:
					if (s_crlf | s_space)
						s_next_state <= s_state;
					else
						s_next_state <= FSM_CMD_RECEIVE;
				FSM_CMD_RECEIVE:
					if (s_space)
						s_next_state <= FSM_CMD_RECEIVE_END;
					else if (s_crlf)
						s_next_state <= FSM_IDLE; // no-Data CMD
					else
						s_next_state <= s_state;
				FSM_CMD_RECEIVE_END:
					if (s_crlf || s_rgn_cmd == CMD_UNKNOWN) // no-Data CMD or unknown CMD
						s_next_state <= FSM_IDLE;
					else if (~s_space)
						s_next_state <= FSM_DATA_RECEIVE;
					else
						s_next_state <= s_state;
				FSM_DATA_RECEIVE:
					if (s_crlf) begin
						if (s_rgn_cmd == CMD_RAW)
							s_next_state <= FSM_RAW_DATA_RECEIVE;
						else
							s_next_state <= FSM_IDLE;
					end
					else
						s_next_state <= s_state;
				FSM_RAW_DATA_RECEIVE:
					if (s_rgn_cmd == CMD_RAW_END)
						s_next_state <= FSM_IDLE;
					else
						s_next_state <= s_state;
				default:
					s_next_state <= FSM_IDLE;
			endcase
		end
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
// CMD ctrl
// CMD buffer : Big-Endian
// CMD size : 2 to 32 word
//            -> min limit : first word is incomed at FSM_IDLE.
//               max limit : size of BRAM contain CMD list.
// goal of algorithm : reduce time < reduce space (because UART's speed is slow)
// timechart
//         CMD_BUF   "ECH"                               "ECHO"               "ECHO "(contain space)
//         wr_en_i __--_______________ ~ ________ ~ _____--_______________ ~ _--_____________________
//       CMD_NO  1 ______diff_________ ~ ________ ~ _________diff_________ ~ _____diff_______________
//       CMD_NO  2 __________diff_____ ~ ________ ~ _____________diff_____ ~ _________diff___________
//       CMD_NO  3 ______________diff_ ~ ________ ~ _________________diff_ ~ _____________diff_______
//             ...                                                                                 
//       CMD_NO 30 ___________________ ~ __diff__ ~ ______________________ ~ ________________________
//           s_rgn_cmd 0x1F______________________________________0x01_______________LATCH 0x01___________
//         s_state FSM_CMD_RECEIVE______________________________________________FSM_CMD_RECEIVE_END__
//
// *CMD_NO 0 or 31 need another method to recognize.
//
// --------------------
// cmd latch timing
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_confirmed_pls <= 1'b0;
	else if(clk_i) begin
		if (s_state == FSM_CMD_RECEIVE && s_next_state == FSM_CMD_RECEIVE_END)
			s_cmd_confirmed_pls <= 1'b1;
		else
			s_cmd_confirmed_pls <= 1'b0;
	end
end

// recognize cmd enable
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_rgn_cmd_en   <= 1'b0;
		s_rgn_cmd_en_d <= 2'b0;
	end else if(clk_i) begin
		if (wr_en_i)
			s_rgn_cmd_en <= 1'b1;
		else if (s_rgn_cmd_cntr == 5'h1F) // CMD:unknown
			s_rgn_cmd_en <= 1'b0;

		s_rgn_cmd_en_d <= {s_rgn_cmd_en_d[0],  s_rgn_cmd_en};
	end
end

// cmd cntr
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_rgn_cmd_cntr    <= 5'b0;
		s_rgn_cmd_cntr_1d <= 5'b0;
	end else if(clk_i) begin
		if (s_rgn_cmd_en) begin
			if (s_cmd_table_char == 8'h20) // seperator(space)
				s_rgn_cmd_cntr <= s_rgn_cmd_cntr + 1'b1;
		end else
			s_rgn_cmd_cntr <= 5'b0;

		s_rgn_cmd_cntr_1d <= s_rgn_cmd_cntr;
	end
end

// cmd buffer clear
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_buf_clear_flg <= 1'b0;
	else if(clk_i) begin
		if(s_cmd_confirmed_pls) // clear buffer
			s_cmd_buf_clear_flg <= 1'b1;
		else if (s_cmd_buf_wr_addr == 5'h1F)
			s_cmd_buf_clear_flg <= 1'b0;
	end
end

// CMD buffer counter
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_cmd_buf_wr_addr    <= 5'b0;
		s_cmd_buf_wr_addr_1d <= 5'b0;
	end else if(clk_i) begin
		if (s_cmd_confirmed_pls)
			s_cmd_buf_wr_addr <= 5'b0;
		else if (s_cmd_buf_clear_flg) // clear buffer
			s_cmd_buf_wr_addr <= s_cmd_buf_wr_addr + 1'b1;
		else if (s_wr_en_d[1]) begin
			if (s_state == FSM_IDLE)
				s_cmd_buf_wr_addr <= 5'b0;
			else if (s_state == FSM_CMD_RECEIVE || s_state == FSM_RAW_DATA_RECEIVE)
				s_cmd_buf_wr_addr <= s_cmd_buf_wr_addr + 1'b1;
		end
		s_cmd_buf_wr_addr_1d <= s_cmd_buf_wr_addr;
	end
end

// each cmd's character counter
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_buf_rd_addr <= 5'b0;
	else if(clk_i) begin
		if (s_rgn_cmd_en) begin
			if (s_cmd_table_char == 8'h20) // seperator(space)
				s_cmd_buf_rd_addr <= 5'b0;
			else
				s_cmd_buf_rd_addr <= s_cmd_buf_rd_addr + 1'b1;
		end else
			s_cmd_buf_rd_addr <= 5'b0;
	end
end

// --------------------
// RAM - Auto synthesis
// --------------------
// wr enable
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_buf_wr_en   <= 1'b0;
	else if(clk_i) begin
		if(wr_en_i && (s_state == FSM_IDLE || s_state == FSM_CMD_RECEIVE || s_state == FSM_RAW_DATA_RECEIVE))
			s_cmd_buf_wr_en   <= 1'b1;
		else if(s_cmd_buf_clear_flg)
			s_cmd_buf_wr_en   <= 1'b1;
		else
			s_cmd_buf_wr_en   <= 1'b0;
	end
end

// wr data
generate if(CMD_IGNORE_CASE == 1) begin
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_buf_wr_data <= 8'b0;
	else if(clk_i) begin
		if(s_cmd_buf_clear_flg)
			s_cmd_buf_wr_data <= 8'b0;
		else
			if(wr_data_i > 8'h61 && wr_data_i <= 8'h7A)
				s_cmd_buf_wr_data <= wr_data_i ^ 8'h20; // lower to upper
			else
				s_cmd_buf_wr_data <= wr_data_i;
		end
	end
end
else
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_buf_wr_data <= 8'b0;
	else if(clk_i) begin
		if(s_cmd_buf_clear_flg)
			s_cmd_buf_wr_data <= 8'b0;
		else
			s_cmd_buf_wr_data <= wr_data_i;
		
	end
end
endgenerate

// CMD buffer write
always @(posedge clk_i)
begin
	if(clk_i) begin
		if(s_cmd_buf_wr_en)
			CMD_BUF[s_cmd_buf_wr_addr_1d] <= s_cmd_buf_wr_data;
	end
end

// CMD buffer read
always @(posedge clk_i)
begin
	if(clk_i) begin
		s_cmd_buf_char <= CMD_BUF[s_cmd_buf_rd_addr];
	end
end
// --------------------

// cmd table traversal address
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_table_rd_addr <= {CMD_TABLE_ADDR_WIDTH{1'b0}};
	else if(clk_i) begin
		if (s_rgn_cmd_en)
			s_cmd_table_rd_addr <= s_cmd_table_rd_addr + 1'b1;
		else
			s_cmd_table_rd_addr <= {CMD_TABLE_ADDR_WIDTH{1'b0}};
	end
end

// --------------------
// ROM - Auto synthesis
// --------------------
// read cmd table
generate
if (SIM_MODE == 1) // for read memory initialization file(.mif)
begin
	wire [7:0] s_cmd_table_char_sim;
	CMD_TABLE_FOR_SIM U_CMD_TABLE(
		.address (s_cmd_table_rd_addr ), // input	[5:0]  address;
		.clock   (clk_i               ), // input	  clock;
		.rden    (s_rgn_cmd_en        ), // input	  rden;
		.q       (s_cmd_table_char_sim)  // output	[7:0]  q
	);
	always @(*) s_cmd_table_char <= s_cmd_table_char_sim;
end
else
begin
	always @(posedge clk_i)
	begin
		if(clk_i) begin
			if (s_rgn_cmd_en)
				s_cmd_table_char <= CMD_TABLE[s_cmd_table_rd_addr];
		end
	end
end
endgenerate
// --------------------

// cmd table read data delay(for same timing with buf)
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_table_char_1d <= 8'b0;
	else if(clk_i)
		s_cmd_table_char_1d <= s_cmd_table_char;
end

// string diff flag
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_diff_flag <= 1'b1;
	else if(clk_i) begin
		if (s_rgn_cmd_en) begin
			if (s_cmd_table_char_1d == 8'h20) begin
				if (s_cmd_table_char == 8'h20) // null CMD
					s_cmd_diff_flag <= 1'b1;
				else                           // CMD rgn start
					s_cmd_diff_flag <= 1'b0;
			end else if (!s_cmd_diff_flag && s_cmd_table_char_1d == s_cmd_buf_char)
				s_cmd_diff_flag <= 1'b0;
			else
				s_cmd_diff_flag <= 1'b1;
		end else
			s_cmd_diff_flag <= 1'b1;
	end
end

// recognized cmd by income data
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_rgn_cmd <= CMD_UNKNOWN;
	else if(clk_i) begin
		if (s_rgn_cmd_en_d == 2'b01) // reset at start rgn
			s_rgn_cmd <= CMD_UNUSED;
		else if (s_cmd_table_char_1d == 8'h20 && !s_cmd_diff_flag) // CMD string same
			s_rgn_cmd <= s_rgn_cmd_cntr_1d;
	end
end

// cmd
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd <= CMD_UNKNOWN;
	else if(clk_i) begin
		if(s_cmd_done_sel)
			s_cmd <= CMD_UNKNOWN;
		else if(s_cmd_confirmed_pls) begin
			if (s_rgn_cmd == CMD_UNUSED)
				s_cmd <= CMD_UNKNOWN;
			else
				s_cmd <= s_rgn_cmd;
		end
	end
end

assign cmd_o = s_cmd;

// cmd finish condition
// when current state's cmd_done signal income,
// clear s_cmd (to unknown)
// some cmd is clear by internal state transition.
always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_cmd_done_sel <= 1'b0;
	else if(clk_i) begin
		case(s_cmd)
			CMD_UNUSED:  // transit CMD_UNKNOWN
				s_cmd_done_sel <= 1'b1;
			CMD_ECHO:    // done by internal signal
				if(s_next_state == FSM_IDLE)
					s_cmd_done_sel <= 1'b1;
			CMD_RAW_DIR: // done by internal signal
				if(s_next_state == FSM_IDLE)
					s_cmd_done_sel <= 1'b1;
			//CMD_RAW:   // transit IDLE by CMD_RAW_END
			CMD_RAW_END: // done by internal signal
				if(s_next_state == FSM_IDLE)
					s_cmd_done_sel <= 1'b1;
			CMD_UNKNOWN: // Disable
				s_cmd_done_sel <= 1'b0;
			default:     // transit CMD_UNKNOWN
				s_cmd_done_sel <= 1'b1;
		endcase
	end
end


// --------------------
// DATA Ctrl
// DATA buffer : FIFO
//
// CMD              BUFFER USAGE
// ECHO           : non-delay flush wr_data_i to out_data_o(delay unit : word)
// RAW_DIR        : non-delay flush(same ECHO) s_cmd_buf_char to out_data_o
// RAW            : store unique key(not use to buffer)        #####out_dat_i:delay 32words to check unique-key
// RAW_END        : same RAW
//
// --------------------

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni) begin
		s_in_data_buf_en   <= 1'b0;
		s_in_data_buf_data <= 8'b0;
	end else if(clk_i) begin
		if (s_state == FSM_DATA_RECEIVE) begin
			case(s_cmd)
				//CMD_UNUSED:
				CMD_ECHO:    // done by internal signal
					begin
						s_in_data_buf_en   <= s_wr_en_d[1];
						s_in_data_buf_data <= s_wr_data_2d;
					end
				//CMD_RAW_DIR: // done by internal signal
				//CMD_RAW:   // transit IDLE by CMD_RAW_END
				//CMD_RAW_END: // done by internal signal
				//CMD_UNKNOWN: // Disable
				default:     // transit CMD_UNKNOWN
					begin
						s_in_data_buf_en   <= 1'b0;
						s_in_data_buf_data <= 8'b0;
					end
			endcase
		end
	end
end

always @(negedge rst_ni, posedge clk_i)
begin
	if(~rst_ni)
		s_data_buf_wait <= 1'b0;
	else if(clk_i) begin
		s_data_buf_wait <= 1'b0;
	end
end

buffer #(
	.BUF_ADDR_WIDTH       (8                    ), // parameter BUF_ADDR_WIDTH = 8, // BUF_SIZE = 2^BUF_ADR_WIDTH
	.DATA_BIT_WIDTH       (8                    ), // parameter DATA_BIT_WIDTH = 8, // 
	.WAIT_DELAY           (1                    )  // parameter WAIT_DELAY     = 0  // wait reply delay(0:no wait reply from receive module)
) u_data_buffer (                                
	.rst_ni               (rst_ni               ), // input  wire                      rst_ni,
	.clk_enqueue_i        (clk_i                ), // input  wire                      clk_enqueue_i,
	.clk_dequeue_i        (clk_i                ), // input  wire                      clk_dequeue_i,
	.enqueue_den_i        (s_in_data_buf_en     ), // input  wire                      enqueue_den_i,
	.enqueue_data_i       (s_in_data_buf_data   ), // input  wire [DATA_BIT_WIDTH-1:0] enqueue_data_i,
	.dequeue_wait_i       (s_data_buf_wait      ), // input  wire                      dequeue_wait_i,
	.dequeue_den_o        (s_out_data_buf_en    ), // output wire                      dequeue_den_o,
	.dequeue_data_o       (s_out_data_buf_data  )  // output wire [DATA_BIT_WIDTH-1:0] dequeue_data_o
);

//// --------------------
//// RAM - Auto synthesis
//// --------------------
//// Unique data write
//always @(posedge clk_i)
//begin
//	if(clk_i) begin
//		if(wr_en_i &&
//			(s_state == FSM_IDLE || s_state == FSM_CMD_RECEIVE || s_state == FSM_RAW_DATA_RECEIVE))
//			CMD_BUF[s_cmd_buf_wr_addr] <= wr_data_i;
//	end
//end
//
//// Unique data read
//always @(posedge clk_i)
//begin
//	if(clk_i) begin
//		s_cmd_buf_char <= CMD_BUF[s_cmd_buf_rd_addr];
//	end
//end
//// --------------------

assign out_en_o   = s_out_data_buf_en;
assign out_data_o = s_out_data_buf_data;

// --------------------
// function - ascii(hex) to hex-binary
// --------------------
function ascii2bin(input [7:0] ascii);
	case(ascii)
		8'h30, 8'h31, 8'h32, 8'h33, 8'h34,
		8'h35, 8'h36, 8'h37, 8'h38, 8'h39:
			ascii2bin = ascii[3:0];
		8'h41, 8'h42, 8'h43, 8'h44, 8'h45, 8'h46:
			ascii2bin = 4'h9 + ascii[3:0];
		default:
			ascii2bin = 4'b0;
	endcase
endfunction



endmodule

//               CMD_NO  CMD(min:2, max:32word) DATA(max 256word)        Description
//                    0. -                      -                        Unused(spaceholder)
//                    1. ECHO                   *                        echo income data to TX
//                    2. RAW_DIR                0~1F(hex)                select module for RAW data stream
//                    3. RAW                    unique-key(32word)       start RAW data stream receive mode
//                    4. unique-key(32word)     (no-DATA)                end   RAW data stream receive mode
//                    5. REG_WRITE              ADDR(hex) DATA(hex)      write DATA to ADDR in DEL_SELed device
//                    6. REG_READ               ADDR(hex)                write DATA to ADDR in DEL_SELed device(DATA_WIDTH=32bit)
//                 7~29. Reserved               Reserved                 Reserved
//                   30. *                      *                        Busy(necessery?)
//                   31. *                      *                        Unknown


