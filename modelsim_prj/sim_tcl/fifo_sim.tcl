#run with <source sim_tcl/fifo_sim.tcl>
#restart -force
vsim -gui work.tb_uart_fifo
add wave  \
sim:/tb_uart_fifo/fifo_DUT/int_fifo
add wave  \
sim:/tb_uart_fifo/clk_tb \
sim:/tb_uart_fifo/end_sim \
sim:/tb_uart_fifo/fifo_in_tb \
sim:/tb_uart_fifo/fifo_out_tb \
sim:/tb_uart_fifo/rst_tb \
sim:/tb_uart_fifo/rx_tb \
sim:/tb_uart_fifo/y_valid_tb
run -all

