library ieee;
use ieee.std_logic_1164.all;

entity delay_vec is
	generic (
		DELAY : natural;
		DATA_WIDTH : positive
	);
	port (
		i_clk      : in  std_logic;
		in_rst     : in  std_logic;
		i_vec      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		o_vec      : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity delay_vec;

architecture arch of delay_vec is
	type t_vec_array is array(natural range <>) of 
		std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal delay_line : t_vec_array(0 to DELAY);
	
begin

	delay_line(0) <= i_vec;
	
	gen_delay: for i in 1 to DELAY generate
		process(i_clk, in_rst)
		begin
			if in_rst = '0' then
				delay_line(i) <= (others => '0');
			elsif rising_edge(i_clk) then
				delay_line(i) <= delay_line(i-1);
			end if;
		end process;
	end generate;
	o_vec <= delay_line(DELAY);
	
end architecture arch;
