#run with <source sim_tcl/control_sim.tcl>
vsim -gui work.tb_rx_control
add wave  \
sim:/tb_rx_control/break_tb \
sim:/tb_rx_control/clk_tb \
sim:/tb_rx_control/end_sim \
sim:/tb_rx_control/frame_error_tb \
sim:/tb_rx_control/frame_start_tb \
sim:/tb_rx_control/frame_stop_tb \
sim:/tb_rx_control/parity_error_tb \
sim:/tb_rx_control/rst_tb \
sim:/tb_rx_control/rx_tb
add wave  \
sim:/tb_rx_control/rx_control_DUT/rx_control_fsm_state

run -all

