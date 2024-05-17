# Create input clock which is 12MHz.
create_clock -name i_clk -period 83.333 [get_ports {i_clk}]

derive_pll_clocks
derive_clock_uncertainty

# Do not do any timming optimization on pins.
set_false_path -from [get_ports {i*}]
set_false_path -from * -to [get_ports {o*}]