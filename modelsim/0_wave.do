onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider CMD_PARSER
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/rst_ni
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/clk_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/wr_en_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/wr_data_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/cmd_o
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/out_en_o
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/out_data_o
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/cmd_done
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_wr_en_d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_wr_data_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_wr_data_2d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_state
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_next_state
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_rgn_cmd_en
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_rgn_cmd_en_d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_rgn_cmd_cntr
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_rgn_cmd_cntr_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_buf_clear_flg
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_buf_wr_en
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_buf_wr_addr
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_buf_wr_addr_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_buf_wr_data
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_buf_rd_addr
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_buf_char
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_table_rd_addr
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_table_char
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_table_char_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_diff_flag
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_rgn_cmd
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_confirmed_pls
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_cmd_done_sel
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_data_buf_addr
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_in_data_buf_en
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_in_data_buf_data
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_data_buf_wait
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_out_data_buf_en
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_out_data_buf_data
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_crlf
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd_parser/s_space
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider UART_TOP
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/rst_n
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/clk
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/uart_rx
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/uart_tx
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/led_debug
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/test_pin
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_rx_data
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_tx_data
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_tx_busy
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_cmd
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/s_buf_data
add wave -noupdate -divider BENCH_TOP
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_clk_en
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_clk_50m
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_clk_115k
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_rsth
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_uart_rx
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_uart_tx
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_data_start
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_data_cnt
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_bit_cnt
add wave -noupdate /TB_UART_DE0_NANO_TOP/s_word_end
add wave -noupdate /TB_UART_DE0_NANO_TOP/i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1157003469 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {3675 us}
