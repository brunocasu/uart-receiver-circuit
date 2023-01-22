#run with <source sim_tcl/break_sim.tcl>
restart -force
vsim -gui work.tb_break_counter
add wave  \
sim:/tb_break_counter/clk_tb \
sim:/tb_break_counter/end_sim \
sim:/tb_break_counter/out_tb \
sim:/tb_break_counter/rst_tb \
sim:/tb_break_counter/rx_tb
run -all

