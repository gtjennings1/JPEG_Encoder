
#Begin clock constraint
define_clock -name {top|pclk} {p:top|pclk} -period 61.056 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 30.528 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {top|clk_24m} {n:top|clk_24m} -period 41.660 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 20.830 -route 0.000 
#End clock constraint
