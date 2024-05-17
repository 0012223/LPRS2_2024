library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pix_ctrl_encoder is
	port (
		i_clk     : in  std_logic;
		in_rst    : in  std_logic;
		i_en      : in  std_logic;
		i_data    : in  std_logic_vector(7 downto 0);
		i_draw_en : in  std_logic;
		i_c0      : in  std_logic;
		i_c1      : in  std_logic;
		o_encoded : out std_logic_vector(9 downto 0)
	);
end entity pix_ctrl_encoder;

architecture arch of pix_ctrl_encoder is
	type t_wide_array is array(natural range <>) of 
		std_logic_vector(3 downto 0);
	
	---------------------------------------------------------------------------
	-- Stage 0
	
	signal b8_s0 : std_logic_vector(7 downto 0);
	signal b8_w_s0 : t_wide_array(7 downto 0);
	
	signal b8_num_of_1s_s0 : std_logic_vector(3 downto 0);
	
	signal b8_r0 : std_logic_vector(7 downto 0);
	signal b8_num_of_1s_r0 : std_logic_vector(3 downto 0);
	signal draw_en_r0 : std_logic;
	signal c0_r0 : std_logic;
	signal c1_r0 : std_logic;
	
	---------------------------------------------------------------------------
	-- Stage 1
		
	signal sign_data_num_of_1_s1 : std_logic;
	
	signal b9_s1 : std_logic_vector(8 downto 0);
	signal b9_w_s1 : t_wide_array(8 downto 0);
	
	signal b9_num_of_1s_s1 : std_logic_vector(3 downto 0);
	signal b9_num_of_0s_s1 : std_logic_vector(3 downto 0);
	
	signal b9_r1 : std_logic_vector(8 downto 0);
	signal b9_num_of_1s_r1 : std_logic_vector(3 downto 0);
	signal b9_num_of_0s_r1 : std_logic_vector(3 downto 0);
	signal draw_en_r1 : std_logic;
	signal c0_r1 : std_logic;
	signal c1_r1 : std_logic;
	
	---------------------------------------------------------------------------
	-- Stage 2
	
	-- Disparity counter, MSB is the sign bit.
	signal cnt_r2 : std_logic_vector(4 downto 0);
	
	signal eq_0s_and_1s_s2 : std_logic;
	signal ne_0s_and_1s_s2 : std_logic;
	
	signal c1c0_s2 : std_logic_vector(1 downto 0);
	signal b10_r2 : std_logic_vector(9 downto 0);
	
begin
	---------------------------------------------------------------------------
	-- Stage 0
	
	b8_s0 <= i_data;

	-- Count number of ones.
	gen_b8_w: for i in 0 to 7 generate
		b8_w_s0(i) <= "000" & b8_s0(i downto i);
	end generate;
	b8_num_of_1s_s0 <= b8_w_s0(0) + b8_w_s0(1) + b8_w_s0(2) + b8_w_s0(3)
		 + b8_w_s0(4) + b8_w_s0(5) + b8_w_s0(6) + b8_w_s0(7);
	
	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			b8_r0 <= (others => '0');
			b8_num_of_1s_r0 <= (others => '0');
			draw_en_r0 <= '0';
			c0_r0 <= '0';
			c1_r0 <= '0';
		elsif rising_edge(i_clk) then
			if i_en = '1' then
	 			b8_r0 <= b8_s0;
				b8_num_of_1s_r0 <= b8_num_of_1s_s0;
				draw_en_r0 <= i_draw_en;
				c0_r0 <= i_c0;
				c1_r0 <= i_c1;
			end if;
		end if;
	end process;
	
	---------------------------------------------------------------------------
	-- Stage 1

	-- First pass though and test the num of 1.
	sign_data_num_of_1_s1 <= 
		'1' when b8_num_of_1s_r0 > x"4" or
				(b8_num_of_1s_r0 = x"4" and b8_r0(0) = '0') else 
		'0';

	-- Make a 9-bit signal.
	process(sign_data_num_of_1_s1, b8_r0, b9_s1)
	begin
		if (sign_data_num_of_1_s1 = '1') then
			b9_s1(0) <= b8_r0(0);
			b9_s1(1) <= (b9_s1(0) xnor b8_r0(1));
			b9_s1(2) <= (b9_s1(1) xnor b8_r0(2));
			b9_s1(3) <= (b9_s1(2) xnor b8_r0(3));
			b9_s1(4) <= (b9_s1(3) xnor b8_r0(4));
			b9_s1(5) <= (b9_s1(4) xnor b8_r0(5));
			b9_s1(6) <= (b9_s1(5) xnor b8_r0(6));
			b9_s1(7) <= (b9_s1(6) xnor b8_r0(7));
			b9_s1(8) <= '0';
		else
			b9_s1(0) <= b8_r0(0);
			b9_s1(1) <= b9_s1(0) xor b8_r0(1);
			b9_s1(2) <= b9_s1(1) xor b8_r0(2);
			b9_s1(3) <= b9_s1(2) xor b8_r0(3);
			b9_s1(4) <= b9_s1(3) xor b8_r0(4);
			b9_s1(5) <= b9_s1(4) xor b8_r0(5);
			b9_s1(6) <= b9_s1(5) xor b8_r0(6);
			b9_s1(7) <= b9_s1(6) xor b8_r0(7);
			b9_s1(8) <= '1';
		end if;
	end process;
	
	
	gen_b9_w: for I in 0 to 8 generate
		b9_w_s1(i) <= "000" & b9_s1(i downto i);
	end generate;
	b9_num_of_1s_s1 <= b9_w_s1(0) + b9_w_s1(1) + b9_w_s1(2) + b9_w_s1(3) +
		b9_w_s1(4) + b9_w_s1(5) + b9_w_s1(6) + b9_w_s1(7);
	b9_num_of_0s_s1 <= x"8" - b9_num_of_1s_s1;
	
	process (i_clk, in_rst)
	begin
		if in_rst = '0' then
			b9_r1 <= (others => '0');
			b9_num_of_1s_r1 <= (others => '0');
			b9_num_of_0s_r1 <= (others => '0');
			draw_en_r1 <= '0';
			c0_r1 <= '0';
			c1_r1 <= '0';
		elsif rising_edge(i_clk) then
			if i_en = '1' then
				b9_r1 <= b9_s1;
				b9_num_of_1s_r1 <= b9_num_of_1s_s1;
				b9_num_of_0s_r1 <= b9_num_of_0s_s1;
				draw_en_r1 <= draw_en_r0;
				c0_r1 <= c0_r0;
				c1_r1 <= c1_r0;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------------
	-- Stage 2
	
	eq_0s_and_1s_s2 <= 
		'1' when cnt_r2 = "00000" or b9_num_of_1s_r1 = b9_num_of_0s_r1 else
		'0';

	ne_0s_and_1s_s2 <=
		'1' when
			(cnt_r2(4) = '0' and b9_num_of_1s_r1 > b9_num_of_0s_r1) or
			(cnt_r2(4) = '1' and b9_num_of_0s_r1 > b9_num_of_1s_r1) else
		'0';

	c1c0_s2 <= c1_r1 & c0_r1;
	
	-- Make a 10-bit signal.
	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			b10_r2 <= (others => '0');
			cnt_r2	 <= (others => '0');
		elsif rising_edge(i_clk) then
			if i_en = '1' then
				if draw_en_r1 = '1' then
					if eq_0s_and_1s_s2 = '1' then
						b10_r2(9) <= not b9_r1(8);
						b10_r2(8) <= b9_r1(8);
						if b9_r1(8) = '1' then
							b10_r2(7 downto 0) <= b9_r1(7 downto 0);
							cnt_r2 <= cnt_r2 + 
								b9_num_of_1s_r1 - b9_num_of_0s_r1;
						else
							b10_r2(7 downto 0) <= not b9_r1(7 downto 0);
							cnt_r2 <= cnt_r2 + 
								b9_num_of_0s_r1 - b9_num_of_1s_r1;
						end if;
					elsif ne_0s_and_1s_s2 = '1' then
						b10_r2(9)		  <= '1';
						b10_r2(8)		  <= b9_r1(8);
						b10_r2(7 downto 0) <= not b9_r1(7 downto 0);
						cnt_r2 <= cnt_r2 + (b9_r1(8) & '0') + 
							(b9_num_of_0s_r1 - b9_num_of_1s_r1);
					else
						b10_r2(9)		  <= '0';
						b10_r2(8)		  <= b9_r1(8);
						b10_r2(7 downto 0) <= b9_r1(7 downto 0);
						cnt_r2 <= cnt_r2 - (not b9_r1(8) & '0') + 
							(b9_num_of_1s_r1 - b9_num_of_0s_r1);
					end if;
				else
					case c1c0_s2 is
						when "00"   => b10_r2 <= "1101010100";
						when "01"   => b10_r2 <= "0010101011";
						when "10"   => b10_r2 <= "0101010100";
						when others => b10_r2 <= "1010101011";
					end case;
					cnt_r2 <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	
	o_encoded <= b10_r2;

end architecture arch;
