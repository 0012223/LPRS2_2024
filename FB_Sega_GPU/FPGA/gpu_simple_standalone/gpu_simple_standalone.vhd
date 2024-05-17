library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.pix_ctrl_timing_consts.all;

entity gpu_simple_standalone is
	port (
		i_clk        : in  std_logic;
		in_rst       : in  std_logic;
		op_hdmi_clk  : out std_logic;
		on_hdmi_clk  : out std_logic;
		op_hdmi_data : out std_logic_vector(2 downto 0);
		on_hdmi_data : out std_logic_vector(2 downto 0)
	);
end entity gpu_simple_standalone;

architecture arch of gpu_simple_standalone is
	signal pll_rst : std_logic;
	signal n_rst : std_logic;
	signal hdmi_clk : std_logic;
	signal gpu_clk : std_logic;
	
	signal pix_phase : std_logic_vector(1 downto 0);
	signal pix_x : std_logic_vector(9 downto 0);
	signal pix_y : std_logic_vector(9 downto 0);
	signal pix_rgb1 : std_logic_vector(23 downto 0);
	signal pix_rgb2 : std_logic_vector(23 downto 0);
	signal pix_rgb_r0 : std_logic_vector(23 downto 0);
	
	
begin
	
	pll_rst <= not in_rst;
	pll_inst: entity work.PLL
	port map (
		inclk0 => i_clk,
		areset => pll_rst,
		c0 => hdmi_clk,
		c1 => gpu_clk,
		locked => n_rst
	);
	
	pix_ctrl_inst: entity work.pix_ctrl
	generic map (
		DELAY => 1
	)
	port map (
		i_gpu_clk_100MHz => gpu_clk,
		i_hdmi_clk_250MHz => hdmi_clk,
		in_rst => n_rst,
		
		i_pix_sync => '0',
		
		o_pix_phase => pix_phase,
		o_pix_x => pix_x,
		o_pix_y => pix_y,
		i_pix_r => pix_rgb_r0( 7 downto  0),
		i_pix_g => pix_rgb_r0(15 downto  8),
		i_pix_b => pix_rgb_r0(23 downto 16),
		
		op_hdmi_clk => op_hdmi_clk,
		on_hdmi_clk => on_hdmi_clk,
		op_hdmi_data => op_hdmi_data,
		on_hdmi_data => on_hdmi_data
	);
	
	pix_rgb1 <= 
		x"000000" when pix_x < 640/8*1 else -- Black.
		x"0000ff" when pix_x < 640/8*2 else -- Red.
		x"00ff00" when pix_x < 640/8*3 else -- Green.
		x"ff0000" when pix_x < 640/8*4 else -- Blue.
		x"00ffff" when pix_x < 640/8*5 else -- Yellow.
		x"ff00ff" when pix_x < 640/8*6 else -- Magenta.
		x"ffff00" when pix_x < 640/8*7 else -- Cyan.
		x"ffffff"; -- White.
		
	pix_rgb2 <= 
		pix_rgb1 when
			pix_x >= 3 and
			pix_y >= 3 and
			pix_x < PIX_X_DRAW-3 and
			pix_y < PIX_Y_DRAW-3 else
		x"ff0000" when
			pix_x >= 2 and
			pix_y >= 2 and
			pix_x < PIX_X_DRAW-2 and
			pix_y < PIX_Y_DRAW-2 else
		x"00ff00" when
			pix_x >= 1 and
			pix_y >= 1 and
			pix_x < PIX_X_DRAW-1 and
			pix_y < PIX_Y_DRAW-1 else
		x"0000ff";

	process(gpu_clk, n_rst)
	begin
		if n_rst = '0' then
			pix_rgb_r0 <= (others => '0');
		elsif rising_edge(gpu_clk) then
			pix_rgb_r0 <= pix_rgb2;
		end if;
	end process;

end architecture arch;
