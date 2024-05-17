library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ram_common_clk_port0_ro_port1_wo is
	generic (
		ADDR_WIDTH : positive;
		DATA_WIDTH : positive
	);
	port (
		i_clk       : in  std_logic;
		
		i_addr0     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
		o_data0     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		
		i_addr1     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
		i_data1     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		i_we1       : in  std_logic
	);
end entity ram_common_clk_port0_ro_port1_wo;

architecture arch of ram_common_clk_port0_ro_port1_wo is
	type t_array is array(natural range <>) of 
		std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal mem : t_array(0 to 2**ADDR_WIDTH-1);
	
begin

	process(i_clk)
	begin
		if rising_edge(i_clk) then
			o_data0 <= mem(conv_integer(i_addr0));
		end if;
	end process;
	
	process(i_clk)
	begin
		if rising_edge(i_clk) then
			if i_we1 = '1' then
				mem(conv_integer(i_addr1)) <= i_data1;
			end if;
		end if;
	end process;
	
end architecture arch;
