library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity pix_ctrl_piso is
	generic (
		DATA_WIDTH : positive
	);
	port (
		i_clk      : in  std_logic;
		in_rst     : in  std_logic;
		i_load     : in  std_logic;
		i_parallel : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		o_serial   : out std_logic
	);
end entity pix_ctrl_piso;

architecture arch of pix_ctrl_piso is
	signal reg         : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal shifted     : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal next_reg    : std_logic_vector(DATA_WIDTH-1 downto 0);
begin

	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			reg <= (others => '0');
		elsif rising_edge(i_clk) then
			reg <= next_reg;
		end if;
	end process;
	shifted <= '0' & reg(DATA_WIDTH-1 downto 1);
	next_reg <= i_parallel when i_load = '1' else shifted;
	
	o_serial <= reg(0);
	
end architecture arch;
