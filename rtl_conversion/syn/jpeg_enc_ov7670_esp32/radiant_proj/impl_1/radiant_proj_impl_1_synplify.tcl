#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology SBTICE40UP
set_option -part iCE40UP5K
set_option -package SG48
#compilation/mapping options
set_option -symbolic_fsm_compiler true
set_option -resource_sharing true

#use verilog 2001 standard option
set_option -vlog_std v2001

#map options
set_option -frequency auto
set_option -maxfan 1000
set_option -auto_constrain_io 0
set_option -retiming false; set_option -pipe true
set_option -force_gsr false
set_option -compiler_compatible 0

set_option -default_enum_encoding default

#timing analysis options



#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#synplifyPro options
set_option -fix_gated_and_generated_clocks 0
set_option -update_models_cp 0
set_option -resolve_multiple_driver 0

#-- set any command lines input by customer

set_option -dup false
set_option -disable_io_insertion false
add_file -verilog {D:/APPS/lscc/radiant/1.0/ip/pmi/pmi.v}
add_file -vhdl -lib pmi {D:/APPS/lscc/radiant/1.0/ip/pmi/pmi.vhd}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/glue_logic/jpeg_data_to_spi.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/glue_logic/jpeg_data_writer.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/glue_logic/sc_fifo.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/glue_logic/yuyv_to_yuv.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/jpeg_enc/jpeg_enc.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/jpeg_enc/jpeg_enc_dct.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/jpeg_enc/jpeg_enc_mem.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/ov7670_esp32/I2C_Interface.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/ov7670_esp32/OV7670_Controller.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/ov7670_esp32/OV7670_Registers.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/ov7670_esp32/spi_slave.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/ov7670_esp32/top.v}
add_file -verilog {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/src/ov7670_esp32/up_spram.v}
set_option -include_path {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/radiant_proj}
#-- top module name
set_option -top_module top

#-- set result format/file last
project -result_format "vm"
project -result_file {E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/radiant_proj/impl_1/radiant_proj_impl_1.vm}

#-- error message log file
project -log_file {radiant_proj_impl_1.srf}
project -run -clean
