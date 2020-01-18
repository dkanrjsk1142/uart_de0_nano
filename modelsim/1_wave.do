onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider <NULL>
add wave -noupdate -divider uart_if
add wave -noupdate -divider buffer_rx
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/rst_ni
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/clk_enqueue_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/clk_dequeue_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_den_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/is_queue_full_o
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/dequeue_wait_i
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/dequeue_den_o
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/dequeue_data_o
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/is_queue_empty_o
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_enqueue_den_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_dequeue_den
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_dequeue_den_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_enqueue_data_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_dequeue_data
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_enqueue_addr
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_dequeue_addr
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_dequeue_addr_before_wait
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_dequeue_addr_diff
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_dequeue_wait_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_full
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_full_d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/s_empty
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/genblk1/s_enqueue_addr_gray
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/genblk1/s_dequeue_addr_gray
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/genblk1/s_enqueue_addr_gray_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/genblk1/s_dequeue_addr_gray_1d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/genblk1/s_enqueue_addr_gray_2d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/genblk1/s_dequeue_addr_gray_2d
add wave -noupdate /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/genblk1/s_enqueue_addr_gray_3d
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
WaveRestoreCursors {{Cursor 1} {299999622 ps} 0}
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
WaveRestoreZoom {0 ps} {315 us}
