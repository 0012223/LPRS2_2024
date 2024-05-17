# pclk = 50.4MHz = 2*xclk = gpu_clk/2
create_clock -name cam_pclk -period 19.841 [get_ports {i_cam_pclk}]
#create_generated_clock -name cam_pclk -source [get_ports {gpu_clk}] -divide_by 2 [get_ports {i_cam_pclk}]
