onerror { resume }
transcript off
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/c_state}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/n_state}
add wave -noreg -logic {/tb_je_ip/dut/yty_req}
add wave -noreg -logic {/tb_je_ip/dut/yty_rd}
add wave -noreg -logic {/tb_je_ip/dut/je_wr}
add wave -noreg -logic {/tb_je_ip/dut/je_en}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/jedw_addr}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/yty_addr}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/jdts_addr}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/jpeg_size}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/jedw_data}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/je_data}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/yty_data}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/hd_data}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/hd_addr}
add wave -noreg -logic {/tb_je_ip/dut/je_rd}
add wave -noreg -logic {/tb_je_ip/dut/je_valid}
add wave -noreg -logic {/tb_je_ip/dut/je_done}
add wave -noreg -logic {/tb_je_ip/dut/jedw_wr}
add wave -noreg -logic {/tb_je_ip/dut/yty_ready}
add wave -noreg -logic {/tb_je_ip/dut/jedf_empty}
add wave -noreg -logic {/tb_je_ip/dut/mem_wr_acc}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/jedf_do}
add wave -noreg -logic {/tb_je_ip/dut/jedf_mem_wr}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/je_done_fl}
add wave -noreg -logic {/tb_je_ip/dut/clk}
add wave -noreg -logic {/tb_je_ip/dut/reset_n}
add wave -noreg -logic {/tb_je_ip/dut/conv_start}
add wave -noreg -logic {/tb_je_ip/dut/conv_end}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/data_out}
add wave -noreg -logic {/tb_je_ip/dut/data_rd}
add wave -noreg -logic {/tb_je_ip/dut/mem_write_en}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/mem_write_data}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/mem_write_addr}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/mem_read_data}
add wave -noreg -hexadecimal -literal {/tb_je_ip/dut/mem_read_addr}
cursor "Cursor 1" 0ns  
transcript on
