
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity cam_ov7670_i2c_sender is
	port (
		i_clk   : in    std_logic;
		in_rst  : in    std_logic;
		
		i_id    : in    std_logic_vector(7 downto 0);
		
		i_reg   : in    std_logic_vector(7 downto 0);
		i_value : in    std_logic_vector(7 downto 0);
		i_send  : in    std_logic;
		o_taken : out   std_logic;
		
		o_sioc  : out   std_logic;
		io_siod : inout std_logic
	);
end entity cam_ov7670_i2c_sender;


architecture arch of cam_ov7670_i2c_sender is

	signal divider : std_logic_vector(8 downto 0);
	signal busy_sr : std_logic_vector(31 downto 0);
	signal data_sr : std_logic_vector(31 downto 0);

begin

	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			divider <= (others => '0');
			busy_sr <= (others => '0');
			data_sr <= (others => '1');
			o_taken <= '0';
		elsif rising_edge(i_clk) then
			o_taken <= '0';
			if busy_sr(31) = '0' then
				if i_send = '1' then
					if divider = "000000000" then
						data_sr <= 
							"100" &
							i_id    & '0' &
							i_reg   & '0' &
							i_value & '0' &
							"01";
						busy_sr <= 
							"111" &
							"111111111"   &
							"111111111"   &
							"111111111"   &
							"11";
						o_taken <= '1';
					else
						-- This only happens on powerup.
						divider <= divider + 1;
					end if;
				end if;
			else
				if divider = "111111111" then
					busy_sr <= busy_sr(32-2 downto 0) & '0';
					data_sr <= data_sr(32-2 downto 0) & '1';
					divider <= (others => '0');
				else
					divider <= divider+1;
				end if;
			end if;
		end if;
	end process;

	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			o_sioc <= '1';
		elsif rising_edge(i_clk) then
			if busy_sr(31) = '0' then
				o_sioc <= '1';
			else
				case busy_sr(32-1 downto 32-3) & busy_sr(2 downto 0) is
					when "111"&"111" => -- start seq #1
						case divider(8 downto 7) is
							when "00"   => o_sioc <= '1';
							when "01"   => o_sioc <= '1';
							when "10"   => o_sioc <= '1';
							when others => o_sioc <= '1';
						end case;
					when "111"&"110" => -- start seq #2
						case divider(8 downto 7) is
							when "00"   => o_sioc <= '1';
							when "01"   => o_sioc <= '1';
							when "10"   => o_sioc <= '1';
							when others => o_sioc <= '1';
						end case;
					when "111"&"100" => -- start seq #3
						case divider(8 downto 7) is
							when "00"   => o_sioc <= '0';
							when "01"   => o_sioc <= '0';
							when "10"   => o_sioc <= '0';
							when others => o_sioc <= '0';
						end case;
					when "110"&"000" => -- end seq #1
						case divider(8 downto 7) is
							when "00"   => o_sioc <= '0';
							when "01"   => o_sioc <= '1';
							when "10"   => o_sioc <= '1';
							when others => o_sioc <= '1';
						end case;
					when "100"&"000" => -- end seq #2
						case divider(8 downto 7) is
							when "00"   => o_sioc <= '1';
							when "01"   => o_sioc <= '1';
							when "10"   => o_sioc <= '1';
							when others => o_sioc <= '1';
						end case;
					when "000"&"000" => -- Idle
						case divider(8 downto 7) is
							when "00"   => o_sioc <= '1';
							when "01"   => o_sioc <= '1';
							when "10"   => o_sioc <= '1';
							when others => o_sioc <= '1';
						end case;
					when others      =>
						case divider(8 downto 7) is
							when "00"   => o_sioc <= '0';
							when "01"   => o_sioc <= '1';
							when "10"   => o_sioc <= '1';
							when others => o_sioc <= '0';
						end case;
				end case;
			end if;
		end if;
	end process;

	-- io_siod process
	process(busy_sr, data_sr(31))
	begin
		if
			busy_sr(11 downto 10) = "10" or 
			busy_sr(20 downto 19) = "10" or 
			busy_sr(29 downto 28) = "10" 
		then
			io_siod <= 'Z';
		else
			io_siod <= data_sr(31);
		end if;
	end process;

end architecture;
