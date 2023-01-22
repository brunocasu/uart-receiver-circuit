#run with <source sim_tcl/env_sim.tcl>
#restart -force
vsim -gui work.tb_uart_rx
add wave  \
sim:/tb_uart_rx/end_sim \
sim:/tb_uart_rx/clk_tb \
sim:/tb_uart_rx/rst_tb \
sim:/tb_uart_rx/rx_tb \
sim:/tb_uart_rx/y_tb \
sim:/tb_uart_rx/y_valid_tb \
sim:/tb_uart_rx/uart_rx_DUT/control_DUT/rx_control_fsm_state \
sim:/tb_uart_rx/uart_rx_DUT/synch_DUT/rx_synch_fsm_state \
sim:/tb_uart_rx/uart_rx_DUT/buff_DUT/rx_buff_fsm_state \
sim:/tb_uart_rx/uart_rx_DUT/synch_DUT/bit_count \
sim:/tb_uart_rx/uart_rx_DUT/synch_DUT/uart_data_out \
sim:/tb_uart_rx/uart_rx_DUT/buff_DUT/data_buffer_out
add wave  \
sim:/tb_uart_rx/uart_rx_DUT/synch_DUT/frame_start_out \
sim:/tb_uart_rx/uart_rx_DUT/synch_DUT/frame_stop_out
add wave  \
sim:/tb_uart_rx/uart_rx_DUT/synch_DUT/data_ready_out
add wave  \
sim:/tb_uart_rx/uart_rx_DUT/synch_DUT/frame_error_out
add wave  \
sim:/tb_uart_rx/uart_rx_DUT/buff_DUT/parity_error_out
run -all

