
library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.gpu_types.all;

entity main is
	port (
		i_clk           : in    std_logic; -- 100 MHz
		in_rst          : in    std_logic;
		
		p_cnt 			 : inout std_logic_vector(63 downto 0);
		
		i_cam_rgb       : in    t_rgb888;
		i_pix_phase     : in    t_pix_phase;
		i_pix_x         : in    t_pix_x;
		i_pix_y         : in    t_pix_y;
		o_pix_rgb       : out   t_rgb888;
		
		io_n64_joypad_2 : inout std_logic;
		buttons			 : in		std_logic_vector(33 downto 0);
		
		o_led           : out   std_logic_vector(7 downto 0)
	);
end entity main;

architecture arch of main is
	constant CLOCK_FREQ 		: integer := 100_000_000/60;
	constant PERIOD 			: integer := CLOCK_FREQ;
	constant SCREEN_WIDTH	: integer := 640;
	constant SCREEN_HEIGHT	: integer := 480;
	constant output_black 		: t_rgb888 := x"000000";
	constant output_blue 		: t_rgb888 := x"ff0000";
	constant output_green 		: t_rgb888 := x"00ff00";
	constant output_white 		: t_rgb888 := x"ffffff";
	
	------------ BALL ----------------
	constant ball_size  		: integer := 15;
	constant MAX_SPEED		: integer := 6;
	
	signal ball_speed 		: integer := 0;
	
	signal ball_x				: integer := SCREEN_WIDTH/2 - ball_size/2;
	signal ball_y 				: integer := SCREEN_HEIGHT/2 - ball_size/2;
	signal ball_vel_x 		: integer := 0;
	signal ball_vel_y 		: integer := 0;
	
	----------- PLAYER ---------------
	
	constant player_speed 	: integer := 4;
	
	constant player_h  	 	: integer := SCREEN_HEIGHT/3 ;
	constant player_w  		: integer := 5;
	constant player1_x  		: integer := 40;
	constant player2_x  		: integer := SCREEN_WIDTH - player1_x - player_w;
	
	signal player1_y  		: integer := SCREEN_HEIGHT/2 - player_h/2;
	signal player2_y  		: integer := SCREEN_HEIGHT/2 - player_h/2;
	
	---------- SCOREBOARD ------------
	
	constant rect_win_w 		: integer := 10;		
	constant rect_win_h 		: integer := 10;
	
	constant rect_win_y 		: integer := 15;
	
	constant rect_win_player_2_1_x : integer := SCREEN_WIDTH/2 + 20;
	constant rect_win_player_2_2_x : integer := rect_win_player_2_1_x + rect_win_w + 10;
	constant rect_win_player_2_3_x : integer := rect_win_player_2_2_x + rect_win_w + 10;
	constant rect_win_player_2_4_x : integer := rect_win_player_2_3_x + rect_win_w + 10;
	
	constant rect_win_player_1_1_x : integer := SCREEN_WIDTH/2 - 20;
	constant rect_win_player_1_2_x : integer := rect_win_player_1_1_x - rect_win_w - 10;
	constant rect_win_player_1_3_x : integer := rect_win_player_1_2_x - rect_win_w - 10;
	constant rect_win_player_1_4_x : integer := rect_win_player_1_3_x - rect_win_w - 10;
	
	---------- GAME STATE ------------
	signal game_counter 		: integer := 0;
	
	signal win_cnt_1  		: integer := 0;
	signal win_cnt_2  		: integer := 0;
	
	signal start				: integer := 0;
	signal finished   		: integer := 0;
	signal winner     		: integer := 0;
	
begin
	--Resolution: 640 x 480 (4:3)
	
	process(i_clk)
	begin
	  if rising_edge(i_clk) then
			game_counter <= game_counter + 1;
			if game_counter = PERIOD - 1 then
				game_counter <= 0;
				
				if finished = 1 then -- Reset the game state after the game is over
					finished <= 0;
					start <= 0;
					ball_speed <= 0;
					ball_vel_x <= 0;
					ball_vel_y <= 0;
					ball_x <= SCREEN_WIDTH/2 - ball_size/2;
					ball_y <= SCREEN_HEIGHT/2 - ball_size/2;
					player1_y <= 240 - player_h/2;
					player2_y <= 240 - player_h/2;
				end if;
				
				if start = 1 then -- Unpause the game when an input is processed
					start <= 2;
					ball_speed <= MAX_SPEED;
					ball_vel_x <= MAX_SPEED-1;
					ball_vel_y <= MAX_SPEED;
				end if;
				
				if ball_x + ball_vel_x > SCREEN_WIDTH-ball_size then -- If the ball touches the right edge, player 1 wins
					winner <= 1;
				end if;
				
				if (ball_x + ball_vel_x < 0) then -- If the ball touches the left edge, player 2 wins
					winner <= 2;
				end if;
				
				if ball_y + ball_vel_y > SCREEN_HEIGHT-ball_size then -- Touching the ceiling reflects the ball downwards
					ball_vel_y <= -ball_speed;
				end if;
				
				if (ball_y + ball_vel_y < 0) then -- Touching the floor reflects the ball upwards
					ball_vel_y <= ball_speed;
				end if;
				
				if (ball_y + ball_vel_y + ball_size > player1_y and ball_y + ball_vel_y < player1_y + player_h) then
					if (ball_x + ball_vel_x < player1_x + player_w and ball_x + ball_vel_x + ball_size > player1_x) then -- If the ball touches player1, it gets reflected to the left
						ball_x <= player1_x + player_w;
						ball_vel_x <= ball_speed-1;
					end if;
				end if;
				
				if (ball_y + ball_vel_y + ball_size > player2_y and ball_y + ball_vel_y < player2_y + player_h) then
					if (ball_x + ball_vel_x + ball_size > player2_x and ball_x + ball_vel_x < player2_x + player_w) then -- If the ball touches player1, it gets reflected to the right
						ball_x <= player2_x - ball_size;
						ball_vel_x <= -(ball_speed-1);
					end if;
				end if;
				
				if (buttons(5) = '1') then -- UP button
					if start = 0 then -- If the game is paused, unpause it
						start <= 1;
					end if;
					if (player1_y > 0) then -- Update the player's position
						player1_y <= player1_y - player_speed;
					end if;
				elsif (buttons(6) = '1') then -- DOWN button
					if start = 0 then
						start <= 1;
					end if;
					if (player1_y < SCREEN_HEIGHT - player_h) then
						player1_y <= player1_y + player_speed;
					end if;
				end if;
				
				if (buttons(13) = '1' and buttons(14) = '1') then -- Both C_UP and C_DOWN
					if start = 0 then
						start <= 1;
					end if;
				elsif (buttons(13) = '1') then -- C_UP button
					if start = 0 then
						start <= 1;
					end if;
					if (player2_y > 0) then
						player2_y <= player2_y - player_speed;
					end if;
				elsif (buttons(14) = '1') then -- C_DOWN button
					if start = 0 then
						start <= 1;
					end if;					
					if (player2_y < SCREEN_HEIGHT - player_h) then
						player2_y <= player2_y + player_speed;
					end if;
				end if;
				
				if winner = 0 then -- If nobody is the winner, the game runs normally
					ball_x <= ball_x + ball_vel_x;
					ball_y <= ball_y + ball_vel_y; 
				else
					winner <= 0;
					ball_vel_x <= -ball_vel_x; -- Invert the horizontal velocity to avoid death loops
					
					if winner = 1 then
						win_cnt_1 <= win_cnt_1 + 1;
						if win_cnt_1 > 3 then
							win_cnt_1 <= 0;
							win_cnt_2 <= 0;
							finished <= 1;
						end if;
						
					elsif winner = 2 then
						win_cnt_2 <= win_cnt_2 + 1;
						if win_cnt_2 > 3 then
							win_cnt_1 <= 0;
							win_cnt_2 <= 0;
							finished <= 1;
						end if;
					end if;
					
					ball_x <= SCREEN_WIDTH/2 - ball_size/2; -- Reset the ball back to the starting position.
					ball_y <= SCREEN_HEIGHT/2 - ball_size/2;
				end if;
			end if;
	  end if;
	end process;
	
	process (i_pix_x, i_pix_y)
	begin
		if (i_pix_x < ball_x + ball_size and i_pix_x > ball_x and -- Render the ball
		i_pix_y < ball_y + ball_size and i_pix_y > ball_y) 
		or 
		(i_pix_x < player1_x + player_w and i_pix_x > player1_x and	-- Render player 1
		i_pix_y < player1_y + player_h and i_pix_y > player1_y) 
		or 
		(i_pix_x < player2_x + player_w and i_pix_x > player2_x and -- Render player 2
		i_pix_y < player2_y + player_h and i_pix_y > player2_y) 
		then
			o_pix_rgb <= output_black;
		else
			o_pix_rgb <= output_white;
		end if;
		
		-- Render the scoreboard for player 1
		if (i_pix_x > rect_win_player_1_1_x and i_pix_x < rect_win_player_1_1_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_1 >= 1 then	
			o_pix_rgb <= output_green;
		elsif (i_pix_x > rect_win_player_1_2_x and i_pix_x < rect_win_player_1_2_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_1 >= 2 then
			o_pix_rgb <= output_green;
		elsif (i_pix_x > rect_win_player_1_3_x and i_pix_x < rect_win_player_1_3_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_1 >= 3 then
			o_pix_rgb <= output_green;
		elsif (i_pix_x > rect_win_player_1_4_x and i_pix_x < rect_win_player_1_4_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_1 >= 4 then
			o_pix_rgb <= output_green;
		end if;
		
		-- Render the scoreboard for player 2
		if (i_pix_x > rect_win_player_2_1_x and i_pix_x < rect_win_player_2_1_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_2 >= 1 then	
			o_pix_rgb <= output_blue;
		elsif (i_pix_x > rect_win_player_2_2_x and i_pix_x < rect_win_player_2_2_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_2 >= 2 then
			o_pix_rgb <= output_blue;
		elsif (i_pix_x > rect_win_player_2_3_x and i_pix_x < rect_win_player_2_3_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_2 >= 3 then
			o_pix_rgb <= output_blue;
		elsif (i_pix_x > rect_win_player_2_4_x and i_pix_x < rect_win_player_2_4_x + rect_win_w and i_pix_y > rect_win_y and i_pix_y < rect_win_y + rect_win_h) and win_cnt_2 >= 4 then
			o_pix_rgb <= output_blue;
		end if;
	
	end process;
end architecture arch;
