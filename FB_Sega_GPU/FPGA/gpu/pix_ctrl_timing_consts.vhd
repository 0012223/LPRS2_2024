
package pix_ctrl_timing_consts is

	-- Standard VGA: (640+16+96+48)*(480+10+2+33)*60
	-- OV7670: (640+19+80+45)*(480+10+3+17)*60
	-- For standard VGA 25.175 MHz clock in needed, here 25.2 MHz is used.
	-- Tweaking these constants could help with some monitors.
	
	constant PIX_X_DRAW   : positive := 640;
	constant PIX_X_FRONT  : positive := 19;
	constant PIX_X_SYNC   : positive := 80;
	constant PIX_X_BACK   : positive := 45;
	constant PIX_X_ALL    : positive := 
		PIX_X_DRAW + PIX_X_FRONT + PIX_X_SYNC + PIX_X_BACK;
	
	constant PIX_Y_DRAW   : positive := 480;
	constant PIX_Y_FRONT  : positive := 10;
	constant PIX_Y_SYNC   : positive := 3;
	constant PIX_Y_BACK   : positive := 17;
	constant PIX_Y_ALL    : positive := 
		PIX_Y_DRAW + PIX_Y_FRONT + PIX_Y_SYNC + PIX_Y_BACK;

end package pix_ctrl_timing_consts;
