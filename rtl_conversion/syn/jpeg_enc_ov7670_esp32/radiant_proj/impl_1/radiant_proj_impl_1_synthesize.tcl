if {[catch {

# define run engine funtion
source [file join {D:/APPS/lscc/radiant/1.0} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) 1
set para(prj_dir) "E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/radiant_proj"
# synthesize IPs
# synthesize VMs
# synthesize top design
file delete -force -- radiant_proj_impl_1.vm radiant_proj_impl_1.ldc
run_engine synpwrap -prj "radiant_proj_impl_1_synplify.tcl" -log "radiant_proj_impl_1.srf"
run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o radiant_proj_impl_1.udb radiant_proj_impl_1.vm] "E:/upwork/gnarly_grey/GitHub/JPEG_Encoder/rtl_conversion/syn/jpeg_enc_ov7670_esp32/radiant_proj/impl_1/radiant_proj_impl_1.ldc"

} out]} {
   runtime_log $out
   exit 1
}
