
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

-- Universal counter.
entity counter is
	generic(
		-- Counter count in range [0, CNT_MOD) i.e. CNT_MOD clock periods.
		constant CNT_MOD  : positive;
		constant CNT_BITS : positive
	);
	port(
		i_clk  : in  std_logic;
		in_rst : in  std_logic;
		
		i_rst  : in  std_logic;
		i_en   : in  std_logic;
		o_cnt  : out std_logic_vector(CNT_BITS-1 downto 0);
		o_tc   : out std_logic
	);
end entity;

architecture counter_arch of counter is

	signal cnt      : std_logic_vector(CNT_BITS-1 downto 0);
	signal tc       : std_logic;
	signal add      : std_logic_vector(CNT_BITS-1 downto 0);
	signal wrap_mux : std_logic_vector(CNT_BITS-1 downto 0);
	signal en_mux   : std_logic_vector(CNT_BITS-1 downto 0);
	signal rst_mux  : std_logic_vector(CNT_BITS-1 downto 0);

begin
	assert CNT_BITS >= integer(ceil(log2(real(CNT_MOD))))
		report "Not enougth bits CNT_BITS for modulo CNT_MOD!"
		severity failure;
	assert CNT_BITS <= integer(ceil(log2(real(CNT_MOD))))
		report "Too much bits CNT_BITS for modulo CNT_MOD!"
		severity warning;

	-- Register.
	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			cnt <= (others => '0');
		elsif rising_edge(i_clk) then
			cnt <=  rst_mux;
		end if;
	end process;
		
	-- Terminal count comparator.
	tc <= '1' when cnt = CNT_MOD-1 else '0';
	
		-- Incrementer.
	add <= cnt + 1;
	
	-- Wrapping mux. When terminal count occurs, wrap to 0.
	wrap_mux <= add when tc = '0' else (others => '0');
	
	-- Enable mux. If counter is disabled, write to register the same value.
	en_mux <= wrap_mux when i_en = '1' else cnt;
	
	-- User reset mux. 
	rst_mux <= en_mux when i_rst = '0' else (others => '0');
	
	-- Daisy chain enable and terminal count.
	o_tc <= tc and i_en;
	
	o_cnt <= cnt;

end architecture;
