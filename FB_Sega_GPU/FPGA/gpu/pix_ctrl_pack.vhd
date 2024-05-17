library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.pix_ctrl_timing_consts.all;

entity pix_ctrl_pack is
	port (
		i_gpu_clk    : in  std_logic;
		i_hdmi_clk   : in  std_logic;
		in_rst       : in  std_logic;
		
		i_pix_phase  : in  std_logic_vector(1 downto 0);
		i_pix_x      : in  std_logic_vector(9 downto 0);
		i_pix_y      : in  std_logic_vector(9 downto 0);
		i_pix_r      : in  std_logic_vector(7 downto 0);
		i_pix_g      : in  std_logic_vector(7 downto 0);
		i_pix_b      : in  std_logic_vector(7 downto 0);
		
		op_hdmi_clk  : out std_logic;
		on_hdmi_clk  : out std_logic;
		op_hdmi_data : out std_logic_vector(2 downto 0);
		on_hdmi_data : out std_logic_vector(2 downto 0)
	);
end entity pix_ctrl_pack;


architecture arch of pix_ctrl_pack is
	signal pix_en : std_logic;
	signal draw_en   : std_logic;
	signal pix_r_d1  : std_logic_vector(7 downto 0);
	signal pix_g_d1  : std_logic_vector(7 downto 0);
	signal pix_b_d1  : std_logic_vector(7 downto 0);
	
	signal tmds_r : std_logic_vector(9 downto 0);
	signal tmds_g : std_logic_vector(9 downto 0);
	signal tmds_b : std_logic_vector(9 downto 0);
	
	signal shift_cnt      : std_logic_vector(3 downto 0);
	signal shift_next_cnt : std_logic_vector(3 downto 0);
	signal shift_tc       : std_logic;
	
	signal serial_clk      : std_logic;
	signal next_serial_clk : std_logic;
	
	signal serial_r  : std_logic;
	signal serial_g  : std_logic;
	signal serial_b  : std_logic;
	
begin
	
	
	process(i_gpu_clk, in_rst)
	begin
		if in_rst = '0' then
			pix_en <= '0';
		elsif rising_edge(i_gpu_clk) then
			if i_pix_phase = 3 then
				pix_en <= '1';
			else
				pix_en <= '0';
			end if;
		end if;
	end process;
	
	process(i_gpu_clk, in_rst)
	begin
		if in_rst = '0' then
			draw_en <= '0';
		elsif rising_edge(i_gpu_clk) then
			if i_pix_y >= 0 and i_pix_y < PIX_Y_DRAW and
				i_pix_x >= 0 and i_pix_x < PIX_X_DRAW then
				draw_en <= '1';
			else
				draw_en <= '0';
			end if;
		end if;
	end process;
	
	process(i_gpu_clk, in_rst)
	begin
		if in_rst = '0' then
			pix_r_d1 <= (others => '0');
			pix_g_d1 <= (others => '0');
			pix_b_d1 <= (others => '0');
		elsif rising_edge(i_gpu_clk) then
			pix_r_d1 <= i_pix_r;
			pix_g_d1 <= i_pix_g;
			pix_b_d1 <= i_pix_b;
		end if;
	end process;

	
	r_enc_inst: entity work.pix_ctrl_encoder
	port map (
		i_clk => i_gpu_clk,
		in_rst => in_rst,
		i_en => pix_en,
		i_data => pix_r_d1,
		i_draw_en => draw_en,
		i_c0 => '0',
		i_c1 => '0',
		o_encoded => tmds_r
	);

	g_enc_inst: entity work.pix_ctrl_encoder
	port map (
		i_clk => i_gpu_clk,
		in_rst => in_rst,
		i_en => pix_en,
		i_data => pix_g_d1,
		i_draw_en => draw_en,
		i_c0 => '0',
		i_c1 => '0',
		o_encoded => tmds_g
	);
	
	b_enc_inst: entity work.pix_ctrl_encoder
	port map (
		i_clk => i_gpu_clk,
		in_rst => in_rst,
		i_en => pix_en,
		i_data => pix_b_d1,
		i_draw_en => draw_en,
		i_c0 => '0',
		i_c1 => '0',
		o_encoded => tmds_b
	);


	process(i_hdmi_clk, in_rst)
	begin
		if in_rst = '0' then
			shift_cnt <= (others => '0');
		elsif rising_edge(i_hdmi_clk) then
			shift_cnt <= shift_next_cnt;
		end if;
	end process;
	shift_tc <= '1' when shift_cnt = 10-1 else '0';
	shift_next_cnt <= (others => '0') when shift_tc = '1' else shift_cnt + 1;
	
	process(i_hdmi_clk, in_rst)
	begin
		if in_rst = '0' then
			serial_clk <= '0';
		elsif rising_edge(i_hdmi_clk) then
			serial_clk <= next_serial_clk;
		end if;
	end process;
	next_serial_clk <= '1' when shift_cnt < 5 else '0';
	

	r_piso_inst: entity work.pix_ctrl_piso
	generic map(
		DATA_WIDTH => 10
	)
	port map (
		i_clk => i_hdmi_clk,
		in_rst => in_rst,
		i_load => shift_tc,
		i_parallel => tmds_r,
		o_serial => serial_r
	);
	
	g_piso_inst: entity work.pix_ctrl_piso
	generic map(
		DATA_WIDTH => 10
	)
	port map (
		i_clk => i_hdmi_clk,
		in_rst => in_rst,
		i_load => shift_tc,
		i_parallel => tmds_g,
		o_serial => serial_g
	);

	b_piso_inst: entity work.pix_ctrl_piso
	generic map(
		DATA_WIDTH => 10
	)
	port map (
		i_clk => i_hdmi_clk,
		in_rst => in_rst,
		i_load => shift_tc,
		i_parallel => tmds_b,
		o_serial => serial_b
	);


	clk_ds_inst: entity work.pix_ctrl_diff_sig
	port map (
		i_clk => i_hdmi_clk,
		i_sig => serial_clk,
		op_sig => op_hdmi_clk,
		on_sig => on_hdmi_clk
	);
	
	r_ds_inst: entity work.pix_ctrl_diff_sig
	port map (
		i_clk => i_hdmi_clk,
		i_sig => serial_r,
		op_sig => op_hdmi_data(2),
		on_sig => on_hdmi_data(2)
	);
	
	g_ds_inst: entity work.pix_ctrl_diff_sig
	port map (
		i_clk => i_hdmi_clk,
		i_sig => serial_g,
		op_sig => op_hdmi_data(0),
		on_sig => on_hdmi_data(0)
	);
	
	b_ds_inst: entity work.pix_ctrl_diff_sig
	port map (
		i_clk => i_hdmi_clk,
		i_sig => serial_b,
		op_sig => op_hdmi_data(1),
		on_sig => on_hdmi_data(1)
	);
	
end architecture arch;
