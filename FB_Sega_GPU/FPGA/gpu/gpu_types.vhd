
library ieee;
use ieee.std_logic_1164.all;

package gpu_types is
	
	subtype t_rgb888 is std_logic_vector(23 downto 0);
	subtype t_rgb565 is std_logic_vector(15 downto 0);
	subtype t_rgb333 is std_logic_vector(8 downto 0);
	subtype t_pix_phase is std_logic_vector(1 downto 0);
	subtype t_pix_x is std_logic_vector(9 downto 0);
	subtype t_pix_y is std_logic_vector(9 downto 0);

end package gpu_types;
