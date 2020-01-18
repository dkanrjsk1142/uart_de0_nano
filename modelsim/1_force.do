
####################
## for buffer.v async simulation
## this simulation is 2 pattern.
## one   is parameter of "SYNC_MODE" parameter to "async" in u_uart_if/u_rx_buffer
## other is parameter of "SYNC_MODE" parameter to "sync"  in u_uart_if/u_rx_buffer
####################
force -freeze /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_den_i 1 200us, 0 200.5us, 1 201.5us, 0 208us
force -freeze /TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/dequeue_wait_i 1 201us, 0 210us

force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[0]} 1 0, 0 {50000 ps} -r 100000
force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[1]} 1 0, 0 {100000 ps} -r 200000
force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[2]} 1 0, 0 {200000 ps} -r 400000
force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[3]} 1 0, 0 {400000 ps} -r 800000
force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[4]} 1 0, 0 {800000 ps} -r 1600000
force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[5]} 1 0, 0 {1600000 ps} -r 3200000
force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[6]} 1 0, 0 {3200000 ps} -r 6400000
force -freeze {/TB_UART_DE0_NANO_TOP/U_UART_DE0_NANO/u_uart_if/u_rx_buffer/enqueue_data_i[7]} 1 0, 0 {6400000 ps} -r 12800000
