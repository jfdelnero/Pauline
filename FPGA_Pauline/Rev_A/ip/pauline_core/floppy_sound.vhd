-------------------------------------------------------------------------------
------------H----H--X----X-----CCCCC-----22222----0000-----0000-----11---------
-----------H----H----X-X-----C--------------2---0----0---0----0---1-1----------
----------HHHHHH-----X------C----------22222---0----0---0----0-----1-----------
---------H----H----X--X----C----------2-------0----0---0----0-----1------------
--------H----H---X-----X---CCCCC-----22222----0000-----0000----11111-----------
-------------------------------------------------------------------------------
------- Contact: hxc2001 at hxc2001.com ----------- https://hxc2001.com -------
------- (c) 2019-2020 Jean-François DEL NERO ----------------------------------
--============================================================================-
-- Pauline
-- Disk archiving and Floppy disk drive simulator system.
--
-- https://hxc2001.com
-- HxC2001   -   2019 - 2020
--
-- Design units   :
--
-- File name      : floppy_sound.vhd
--
-- Purpose        : floppy sound generator.
--
--============================================================================-
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 1.0    Jean-François DEL NERO  20 April 2019          First version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity floppy_sound is
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		step_sound              : in  std_logic;

		sound                   : out std_logic
		);
end floppy_sound;

architecture arch of floppy_sound is

signal cnt : std_logic_vector(31 downto 0);

begin

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			cnt <= (others=>'0');
			sound <= '0';

		elsif(clk'event and clk = '1') then

			sound <= '0';

			if( (cnt /= conv_std_logic_vector(0,32)) or step_sound = '1' )
			then
				cnt <= cnt + conv_std_logic_vector(1,32);
				sound <= '1';
				if( cnt >= conv_std_logic_vector(50000,32) )
				then
					cnt <= (others=>'0');
				end if;
			end if;

		end if;
	end process;

end arch;
