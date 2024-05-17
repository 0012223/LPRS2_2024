
library ieee;
use ieee.std_logic_1164.all;
use work.gpu_types.all;

entity cam_ov7670_capture is
	port (
		in_rst    : in  std_logic;
		
		i_cam_pclk  : in  std_logic;
		i_cam_vsync : in  std_logic;
		i_cam_href  : in  std_logic;
		i_cam_data  : in  std_logic_vector(7 downto 0);
		
		i_gpu_clk   : in  std_logic;
		o_gpu_sync  : out std_logic;
		o_gpu_rgb   : out t_rgb565
	);
end entity cam_ov7670_capture;

architecture arch of cam_ov7670_capture is

	signal vsync       : std_logic;
	signal href        : std_logic;
	signal d           : std_logic_vector(7 downto 0);
	
	signal vsync_d1    : std_logic;
	signal href_d1     : std_logic;
	
	signal vsync_re    : std_logic;
	signal href_re     : std_logic;
	
	type t_state is (WAITING_FOR_VSYNC, WAITING_FIRST_HREF);
	signal state       : t_state;
	signal next_state  : t_state;

	signal sync        : std_logic;
	signal next_sync   : std_logic;
	
	signal bgr_sr      : std_logic_vector(15 downto 0);
	signal next_bgr_sr : std_logic_vector(15 downto 0);
	
	signal rgb         : t_rgb565;
	signal next_rgb    : t_rgb565;

	signal sync_m      : std_logic;
	signal sync_s      : std_logic;
	signal rgb_m       : t_rgb565;
	signal rgb_s       : t_rgb565;

begin
	
	----
	-- i_cam_pclk domain.
	
	-- Latching.
	process(i_cam_pclk, in_rst)
	begin
		if in_rst = '0' then
			vsync <= '0';
			href  <= '0';
			d     <= (others => '0');
		elsif falling_edge(i_cam_pclk) then
			vsync <= i_cam_vsync;
			href  <= i_cam_href;
			d     <= i_cam_data;
		end if;
	end process;
	
	process(i_cam_pclk, in_rst)
	begin
		if in_rst = '0' then
			vsync_d1 <= '0';
			href_d1  <= '0';
		elsif falling_edge(i_cam_pclk) then
			vsync_d1 <= vsync;
			href_d1  <= href;
		end if;
	end process;
	
	vsync_re <= (not vsync_d1) and vsync; 
	href_re  <= (not href_d1 ) and href;
	
	process(i_cam_pclk, in_rst)
	begin
		if in_rst = '0' then
			state <= WAITING_FOR_VSYNC;
		elsif falling_edge(i_cam_pclk) then
			state <= next_state;
		end if;
	end process;
	process(state, vsync_re, sync)
	begin
		case state is
			when WAITING_FOR_VSYNC =>
				if vsync_re = '1' then
					next_state <= WAITING_FIRST_HREF;
				else
					next_state <= state; -- Still waithing.
				end if;
			when WAITING_FIRST_HREF =>
				if sync = '1' then
					next_state <= WAITING_FOR_VSYNC;
				else
					next_state <= state; -- Still waithing.
				end if;
		end case;
	end process;
	
	next_sync <= href_re when state = WAITING_FIRST_HREF else '0';
	process(i_cam_pclk, in_rst)
	begin
		if in_rst = '0' then
			sync <= '0';
		elsif falling_edge(i_cam_pclk) then
			sync <= next_sync;
		end if;
	end process;
	
	next_bgr_sr <= bgr_sr(7 downto 0) & d;
	process(i_cam_pclk, in_rst)
	begin
		if in_rst = '0' then
			bgr_sr <= (others => '0');
		elsif falling_edge(i_cam_pclk) then
			bgr_sr <= next_bgr_sr;
		end if;
	end process;
	
	-- Swap channels.
	next_rgb <= 
		bgr_sr(4 downto 0) &
		bgr_sr(10 downto 5) &
		bgr_sr(15 downto 11);
	process(i_cam_pclk, in_rst)
	begin
		if in_rst = '0' then
			rgb <= (others => '0');
		elsif falling_edge(i_cam_pclk) then
			rgb <= next_rgb;
		end if;
	end process;
	
	
	
	----
	-- i_gpu_clk domain.
	
	process(i_gpu_clk, in_rst)
	begin
		if in_rst = '0' then
			sync_m <= '0';
			sync_s <= '0';
			rgb_m  <= (others => '0');
			rgb_s  <= (others => '0');
		elsif falling_edge(i_cam_pclk) then
			sync_m <= sync;
			sync_s <= sync_m;
			rgb_m  <= rgb;
			rgb_s  <= rgb_m;
		end if;
	end process;
	o_gpu_sync <= sync_s;
	o_gpu_rgb  <= rgb_s;
	
end architecture arch;
