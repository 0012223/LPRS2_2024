
library ieee;
use ieee.std_logic_1164.all;
use work.gpu_types.all;

entity cam_ov7670 is
	port (
		i_gpu_clk      : in    std_logic; -- 100.8MHz
		in_rst         : in    std_logic;
		
		i_reconfigure  : in    std_logic;
		
		-- To camera.
		o_cam_xclk     : out   std_logic;
		on_cam_rst     : out   std_logic;
		o_cam_pwdn     : out   std_logic;
		o_cam_sioc     : out   std_logic;
		io_cam_siod    : inout std_logic;
		i_cam_pclk     : in    std_logic;
		i_cam_vsync    : in    std_logic;
		i_cam_href     : in    std_logic;
		i_cam_data     : in    std_logic_vector(7 downto 0);
		
		o_cfg_done     : out   std_logic;
		
		-- To GPU.
		o_gpu_sync     : out   std_logic;
		o_gpu_rgb      : out   t_rgb565
	);
end entity cam_ov7670;

architecture arch of cam_ov7670 is

begin
	
	sccb_ctrl_inst: entity work.cam_ov7670_sccb_ctrl
	port map(
		i_clk         => i_gpu_clk,
		in_rst        => in_rst,
		
		i_reconfigure => i_reconfigure,
		
		o_cam_xclk    => o_cam_xclk,
		on_cam_rst    => on_cam_rst,
		o_cam_pwdn    => o_cam_pwdn,
		o_cam_sioc    => o_cam_sioc,
		io_cam_siod   => io_cam_siod,
		
		o_cfg_done    => o_cfg_done
	);
	
	capture_inst: entity work.cam_ov7670_capture
	port map(
		in_rst      => in_rst,
		
		i_cam_pclk  => i_cam_pclk,
		i_cam_vsync => i_cam_vsync,
		i_cam_href  => i_cam_href,
		i_cam_data  => i_cam_data,
		
		i_gpu_clk   => i_gpu_clk,
		o_gpu_sync  => o_gpu_sync,
		o_gpu_rgb   => o_gpu_rgb
	);

end architecture arch;
