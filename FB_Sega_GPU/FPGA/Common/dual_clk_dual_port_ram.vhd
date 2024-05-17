library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dual_clk_dual_port_ram is
	generic (
		ADDR_WIDTH : positive;
		DATA_WIDTH : positive
	);
	port (
		i_clk_a      : in  std_logic;
		i_addr_a     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
		o_data_a     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		i_data_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		i_we_a       : in  std_logic;
		
		i_clk_b      : in  std_logic;
		i_addr_b     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
		o_data_b     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		i_data_b     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		i_we_b       : in  std_logic
	);
end entity dual_clk_dual_port_ram;

architecture arch of dual_clk_dual_port_ram is
	type t_mem is array(0 to 2**ADDR_WIDTH-1) of 
		std_logic_vector(DATA_WIDTH-1 downto 0);
	
	shared variable mem : t_mem;
	
begin

	process(i_clk_a)
	begin
		if rising_edge(i_clk_a) then
			if i_we_a = '1' then
				mem(conv_integer(i_addr_a)) := i_data_a;
			end if;
			o_data_a <= mem(conv_integer(i_addr_a));
		end if;
	end process;
	
	process(i_clk_b)
	begin
		if rising_edge(i_clk_b) then
			if i_we_b = '1' then
				mem(conv_integer(i_addr_b)) := i_data_b;
			end if;
			o_data_b <= mem(conv_integer(i_addr_b));
		end if;
	end process;
	
end architecture arch;
