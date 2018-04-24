onerror { resume }
transcript off
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/spram}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/pclk}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/reset_n}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/pixel_wr_disable}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/img_req}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/spi_rd_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/c_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/n_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/mem_datar}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty_req}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty_rd}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je_wr}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je_en}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw_addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty_addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts_addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw_data}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je_data}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty_data}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/esp32_spi_data}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/hd_data}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/hd_addr}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je_rd}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je_valid}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je_done}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw_wr}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/mem_wr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/mem_dataw}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/mem_addrw}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/mem_addrr}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/img_rdy}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/esp32_spi_rd}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/file_in}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/r}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty_ready}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/eoi_check_reg}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/file_out}
add wave -named_row "YTY"
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/c_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/n_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/img_col}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/img_x}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/img_row}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/img_y}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/addr_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/col_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/row_cnt}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/addr_lsb}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/last_blk}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/img_req_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/yuyv}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/ff_wr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/ff_din}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/eof}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/reset}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/fifo_level}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/fetch_memory}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/col_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/row_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/addr_inc}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/row_chg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/blk_chg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/img_req_pe}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/clk}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/reset_n}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/img_req}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/data}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/mem_wr}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/ready}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/yty/je_rd}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/yty/je_data}
add wave -named_row "JE"
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_out_reg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/img_valid_reg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/img_valid_reg_fl}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/img_done_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/byte_count}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/header_rom_d}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/du_ram_we}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/du_ram_aw}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/QNT_DU}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dct_comp_sel}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dct_comp_idx}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dct_idx_cnt}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/DCY}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/DCU}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/DCV}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/diff_DC}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/zzdu_ram_we}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/zzdu_ram_ar}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dcht_bc_rom_a}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dcht_bb_rom_a}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/acht_bc_rom_a}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/acht_bb_rom_a}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_x}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_col}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_y}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_row}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_col_p}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_col_p_fl1}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_col_p_fl2}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/col_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/row_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/col_cnt_fl1}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/row_cnt_fl1}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/col_cnt_fl2}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/row_cnt_fl2}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/load_du_done_fl}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/fb_rd_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/qz_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/c_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/n_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/b_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/fb_addr_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/wb_bit_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/wb_bc_tmp}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/wb_bit_buf}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/wb_bb_tmp}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/wb_c}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/cb_bb_mask}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/cb_bit_buf}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/cb_bb_tmp}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/cb_bit_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/end0pos}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/du_ac0}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/ac_idx}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/ac0_idx}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/ac0_cnt}
add wave -noreg -logic -signed2 {/tb_jpeg_enc_w_gluelogic/je/last_du}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/last_du_p}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/header_tx_done}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/zzdu_ram_do}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/inc_img_col_p}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/rst_img_col_p}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/col_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/row_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/inc_row_cnt}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/load_du_done}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/dct_done}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/qz_done}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/diff_dc_zero}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/diff_dc_neg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/bit_cnt_gte_8}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/byte_out_eq_255}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/check_next_element}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/e0p_zero}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/inc_ac0_idx}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/inc_ac0_cnt}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/ac0_cnt_gte_16}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/e0p_ne_63}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/du_ac_neg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/last_comp}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/du_ram_do}
add wave -noreg -hexadecimal -literal -signed2 {/tb_jpeg_enc_w_gluelogic/je/fdtbl_rom_d}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/zzidx_rom_d}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dcht_bc_rom_d}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/acht_bc_rom_d}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dcht_bb_rom_d}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/acht_bb_rom_d}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/start_dct}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/du_ram_a_dct}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dctdu_ram_aw}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dctdu_ram_ar_dct}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dctdu_ram_ar}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/dctdu_ram_we}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dctdu_ram_di}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/dctdu_ram_do}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/clk}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/reset_n}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/conv_en}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/fb_data}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/fb_rd}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/img_out}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/hd_addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/je/hd_data}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/img_valid}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/je/img_done}
add wave -named_row "JEDW"
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/addr_lsb}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/col_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/row_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/col_idx}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/col_x}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/row_idx}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/row_y}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/addr_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/data_reg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/we_reg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/col_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/row_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/chg_col}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/chg_row}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/chg_blk}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/clk}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/reset_n}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/je_valid}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/je_data}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/je_done}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jedw/data}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jedw/we}
add wave -named_row "JDTS"
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/c_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/n_state}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/hd_addr_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/je_addr_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/eoi_reg}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/spi_data_reg}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/addr_lsb}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/col_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/row_cnt}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/col_idx}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/col_x}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/row_idx}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/row_y}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/col_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/row_max}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/chg_col}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/chg_row}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/chg_blk}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/rst_rcb}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/header_done}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/eoi}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/clk}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/reset_n}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/je_done}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/hd_addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/hd_data}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/je_addr}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/je_data}
add wave -noreg -logic {/tb_jpeg_enc_w_gluelogic/jdts/spi_rd}
add wave -noreg -hexadecimal -literal {/tb_jpeg_enc_w_gluelogic/jdts/spi_data}
cursor "Cursor 1" 0ns  
transcript on
