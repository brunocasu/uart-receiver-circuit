#run with <source sim_tcl/synch_sim.tcl>
#restart -force
vsim -gui work.tb_rx_synch
add wave  \
sim:/tb_rx_synch/clk_tb \
sim:/tb_rx_synch/en_tb \
sim:/tb_rx_synch/end_sim \
sim:/tb_rx_synch/synch_rst_tb \
sim:/tb_rx_synch/rx_tb \
sim:/tb_rx_synch/shift_reg_tb
add wave  \
sim:/tb_rx_synch/rx_synch_DUT/rx_synch_fsm_state
add wave  \
sim:/tb_rx_synch/rx_synch_DUT/bit_count
run -all

