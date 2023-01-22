#run with <source sim_tcl/buff_sim.tcl>
#restart -force
vsim -gui work.tb_rx_buff
add wave  \
sim:/tb_rx_buff/clear_buff_tb \
sim:/tb_rx_buff/clk_tb \
sim:/tb_rx_buff/data_in_tb \
sim:/tb_rx_buff/data_ready_tb \
sim:/tb_rx_buff/en_tb \
sim:/tb_rx_buff/end_sim \
sim:/tb_rx_buff/rst_tb
add wave  \
sim:/tb_rx_buff/rx_buff_DUT/data_buffer_out \
sim:/tb_rx_buff/rx_buff_DUT/rx_buff_fsm_state \
sim:/tb_rx_buff/rx_buff_DUT/xor_in \
sim:/tb_rx_buff/rx_buff_DUT/xor_out
add wave  \
sim:/tb_rx_buff/rx_buff_DUT/parity_error_out
run -all

