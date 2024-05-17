
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;

entity cam_ov7670_sccb_ctrl is
	port (
		i_clk         : in    std_logic; -- 100.8MHz
		in_rst        : in    std_logic;
		
		i_reconfigure : in    std_logic;
		
		o_cam_xclk    : out   std_logic;
		on_cam_rst    : out   std_logic;
		o_cam_pwdn    : out   std_logic;
		-- SCCB is I2C like bus.
		o_cam_sioc    : out   std_logic;
		io_cam_siod   : inout std_logic;
		
		o_cfg_done    : out   std_logic
);
end cam_ov7670_sccb_ctrl;


architecture arch of cam_ov7670_sccb_ctrl is

	-- device write ID; see datasheet of camera module;
	constant CAM_ADDR      : std_logic_vector(7 downto 0) := x"42";

	
	signal clk_div         : std_logic_vector(1 downto 0);
	
	type t_ctrl_state is (RST, SEND_CFG_START, SEND_CFG, RUN);
	signal ctrl_state      : t_ctrl_state;
	signal next_ctrl_state : t_ctrl_state;
	signal pause_en        : std_logic;
	signal pause_done      : std_logic;	
	
	signal send_start      : std_logic;
	signal send_end        : std_logic;
	
	signal cmd             : std_logic_vector(15 downto 0);
	signal taken           : std_logic;
	signal send            : std_logic;
	
	
begin
	
	process(i_clk)
	begin
		if rising_edge(i_clk) then
			clk_div <= clk_div + 1;
		end if;
	end process;
	o_cam_xclk <= clk_div(1);
	
	process(i_clk, in_rst)
	begin
		if in_rst = '0' then
			ctrl_state <= RST;
		elsif rising_edge(i_clk) then
			ctrl_state <= next_ctrl_state;
		end if;
	end process;
	
	process(ctrl_state, pause_done, send_end, i_reconfigure)
	begin
		case ctrl_state is
			when RST =>
				if pause_done = '1' then
					next_ctrl_state <= SEND_CFG_START;
				else
					next_ctrl_state <= ctrl_state;
				end if;
			when SEND_CFG_START =>
				next_ctrl_state <= SEND_CFG;
			when SEND_CFG =>
				if send_end = '1' then
					next_ctrl_state <= RUN;
				else
					next_ctrl_state <= ctrl_state;
				end if;
			when RUN =>
				if i_reconfigure = '1' then
					next_ctrl_state <= RST;
				else
					next_ctrl_state <= ctrl_state;
				end if;
		end case;
	end process;
	
	with ctrl_state select pause_en <=
		'1' when RST,
		'0' when others;
	
	pause_inst: entity work.counter
	generic map(
		CNT_MOD  => 100, -- 1us
		CNT_BITS => 7
	)
	port map(
		i_clk  => i_clk,
		in_rst => in_rst,
		
		i_rst  => '0',
		i_en   => pause_en,
		o_cnt  => open,
		o_tc   => pause_done
	);
	
	with ctrl_state select on_cam_rst <=
		'0' when RST,
		'1' when others;
		
	o_cam_pwdn <= '0';
	
	with ctrl_state select send_start <=
		'1' when SEND_CFG_START,
		'0' when others;

	cfg_regs_inst: entity work.cam_ov7670_cfg_regs
	port map(
		i_clk        => i_clk,
		in_rst       => in_rst,
		
		i_resend     => send_start,
		o_send_end   => send_end,
		
		o_cmd        => cmd,
		i_advance    => taken
	);
	
	send <= not send_end;
	o_cfg_done <= send_end;

	i2c_sender_inst: entity work.cam_ov7670_i2c_sender
	port map(
		i_clk   => i_clk,
		in_rst   => in_rst,
		
		i_id    => CAM_ADDR,
		
		i_reg   => cmd(15 downto 8),
		i_value => cmd(7 downto 0),
		i_send  => send,
		o_taken => taken,
		
		o_sioc  => o_cam_sioc,
		io_siod => io_cam_siod
	);
	
end architecture;
