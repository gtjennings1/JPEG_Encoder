
#Begin clock constraint
define_clock -name {top|pclk} {p:top|pclk} -period 105008.000 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 52504.000 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {top|clk_24m} {n:top|clk_24m} -period 7.466 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 3.733 -route 0.000 
#End clock constraint
