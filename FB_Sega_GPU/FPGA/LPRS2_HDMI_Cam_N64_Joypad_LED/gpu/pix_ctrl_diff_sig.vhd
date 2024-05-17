library ieee;
use ieee.std_logic_1164.all;

entity pix_ctrl_diff_sig is
	port (
		i_clk  : in  std_logic;
		i_sig  : in  std_logic;
		op_sig : out std_logic;
		on_sig : out std_logic
	);
end entity pix_ctrl_diff_sig;

architecture arch of pix_ctrl_diff_sig is
begin
	
	process(i_clk)
	begin
		if rising_edge(i_clk) then
			if i_sig = '1' then
				op_sig <= '1';
				on_sig <= '0';
			else
				op_sig <= '0';
				on_sig <= '1';
			end if;
		end if;
	end process;
	
end architecture arch;
