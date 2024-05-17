library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.pix_ctrl_timing_consts.all;

entity pix_ctrl_cnts is
	port (
		i_clk        : in  std_logic;
		in_rst       : in  std_logic;
		i_pix_sync   : in  std_logic;
		o_pix_phase  : out std_logic_vector(1 downto 0);
		o_pix_x      : out std_logic_vector(9 downto 0);
		o_pix_y      : out std_logic_vector(9 downto 0)
	);
end entity pix_ctrl_cnts;

architecture arch of pix_ctrl_cnts is
	
	signal pix_phase      : std_logic_vector(1 downto 0);
	signal tc_pix_phase   : std_logic;
	signal add_pix_phase  : std_logic_vector(1 downto 0);
	signal next_pix_phase : std_logic_vector(1 downto 0);
		
	signal pix_x      : std_logic_vector(9 downto 0);
	signal tc_pix_x   : std_logic;
	signal wrap_pix_x : std_logic_vector(9 downto 0);
	signal en_pix_x   : std_logic_vector(9 downto 0);
	signal next_pix_x : std_logic_vector(9 downto 0);
	
	signal pix_y      : std_logic_vector(9 downto 0);
	signal tc_pix_y   : std_logic;
	signal wrap_pix_y : std_logic_vector(9 downto 0);
	signal en_pix_y   : std_logic_vector(9 downto 0);
	signal next_pix_y : std_logic_vector(9 downto 0);
	
begin

	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			pix_phase <= (others => '0');
		elsif rising_edge(i_clk) then
			pix_phase <= next_pix_phase;
		end if;
	end process;
	tc_pix_phase <= '1' when pix_phase = 3 else '0';
	add_pix_phase <= pix_phase + 1;
	next_pix_phase <= (others => '0') when i_pix_sync = '1' else add_pix_phase;
	o_pix_phase <= pix_phase;

	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			pix_x <= (others => '0');
		elsif rising_edge(i_clk) then
			pix_x <= next_pix_x;
		end if;
	end process;
	tc_pix_x <= '1' when pix_x = PIX_X_ALL-1 else '0';
	wrap_pix_x <= (others => '0') when tc_pix_x = '1' else pix_x + 1;
	en_pix_x <= wrap_pix_x when tc_pix_phase = '1' else pix_x;
	next_pix_x <= (others => '0') when i_pix_sync = '1' else en_pix_x;
	o_pix_x <= pix_x;
	
	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			pix_y <= (others => '0');
		elsif rising_edge(i_clk) then
			pix_y <= next_pix_y;
		end if;
	end process;
	tc_pix_y <= '1' when pix_y = PIX_Y_ALL-1 else '0';
	wrap_pix_y <= (others => '0') when tc_pix_y = '1' else pix_y + 1;
	en_pix_y <= 
		wrap_pix_y when tc_pix_x = '1' and tc_pix_phase = '1' else
		pix_y;
	next_pix_y <= (others => '0') when i_pix_sync = '1' else en_pix_y;
	o_pix_y <= pix_y;
	
end architecture arch;
