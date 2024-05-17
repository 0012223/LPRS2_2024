
library ieee;
use ieee.std_logic_1164.all;

entity pix_ctrl is
	generic (
		DELAY : natural
	);
	port (
		i_gpu_clk_100MHz  : in  std_logic;
		i_hdmi_clk_250MHz : in  std_logic;
		in_rst            : in  std_logic;
		
		i_pix_sync  : in  std_logic;
		o_pix_phase : out std_logic_vector(1 downto 0);
		o_pix_x     : out std_logic_vector(9 downto 0);
		o_pix_y     : out std_logic_vector(9 downto 0);
		i_pix_r     : in  std_logic_vector(7 downto 0);
		i_pix_g     : in  std_logic_vector(7 downto 0);
		i_pix_b     : in  std_logic_vector(7 downto 0);
		
		op_hdmi_clk  : out std_logic;
		on_hdmi_clk  : out std_logic;
		op_hdmi_data : out std_logic_vector(2 downto 0);
		on_hdmi_data : out std_logic_vector(2 downto 0)
	);
end entity pix_ctrl;

architecture arch of pix_ctrl is
	
	signal pix_phase : std_logic_vector(1 downto 0);
	signal pix_x     : std_logic_vector(9 downto 0);
	signal pix_y     : std_logic_vector(9 downto 0);
	
	signal pix_phase_delayed : std_logic_vector(1 downto 0);
	signal pix_x_delayed     : std_logic_vector(9 downto 0);
	signal pix_y_delayed     : std_logic_vector(9 downto 0);

begin

	cnt_inst: entity work.pix_ctrl_cnts
	port map (
		i_clk => i_gpu_clk_100MHz,
		in_rst => in_rst,
		i_pix_sync => i_pix_sync,
		o_pix_phase => pix_phase,
		o_pix_x => pix_x,
		o_pix_y => pix_y
	);
	o_pix_phase <= pix_phase;
	o_pix_x <= pix_x;
	o_pix_y <= pix_y;
	
	delay_pix_phase_inst: entity work.delay_vec
	generic map (
		DELAY => DELAY,
		DATA_WIDTH => 2
	)
	port map (
		i_clk => i_gpu_clk_100MHz,
		in_rst => in_rst,
		i_vec => pix_phase,
		o_vec => pix_phase_delayed
	);
	delay_pix_x_inst: entity work.delay_vec
	generic map (
		DELAY => DELAY,
		DATA_WIDTH => 10
	)
	port map (
		i_clk => i_gpu_clk_100MHz,
		in_rst => in_rst,
		i_vec => pix_x,
		o_vec => pix_x_delayed
	);
	delay_pix_y_inst: entity work.delay_vec
	generic map (
		DELAY => DELAY,
		DATA_WIDTH => 10
	)
	port map (
		i_clk => i_gpu_clk_100MHz,
		in_rst => in_rst,
		i_vec => pix_y,
		o_vec => pix_y_delayed
	);

	pack_inst: entity work.pix_ctrl_pack
	port map (
		i_gpu_clk => i_gpu_clk_100MHz,
		i_hdmi_clk => i_hdmi_clk_250MHz,
		in_rst => in_rst,
		
		i_pix_phase => pix_phase_delayed,
		i_pix_x => pix_x_delayed,
		i_pix_y => pix_y_delayed,
		i_pix_r => i_pix_r,
		i_pix_g => i_pix_g,
		i_pix_b => i_pix_b,
		
		op_hdmi_clk => op_hdmi_clk,
		on_hdmi_clk => on_hdmi_clk,
		op_hdmi_data => op_hdmi_data,
		on_hdmi_data => on_hdmi_data
	);

end architecture arch;
