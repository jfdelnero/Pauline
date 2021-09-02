-------------------------------------------------------------------------------
------------H----H--X----X-----CCCCC-----22222----0000-----0000-----11---------
-----------H----H----X-X-----C--------------2---0----0---0----0---1-1----------
----------HHHHHH-----X------C----------22222---0----0---0----0-----1-----------
---------H----H----X--X----C----------2-------0----0---0----0-----1------------
--------H----H---X-----X---CCCCC-----22222----0000-----0000----11111-----------
-------------------------------------------------------------------------------
------- Contact: hxc2001 at hxc2001.com ----------- https://hxc2001.com -------
------- (c) 2019-2021 Jean-François DEL NERO ----------------------------------
--============================================================================-
-- Pauline
-- Disk archiving and Floppy disk drive simulator system.
--
-- https://hxc2001.com
-- HxC2001   -   2019 - 2021
--
-- Design units   :
--
-- File name      : noise_generator.vhd
--
-- Purpose        : noise generator used to emulate flakey/weak bits
--
--============================================================================-
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 1.0    Jean-François DEL NERO  2 September 2021          First version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.ALL;

entity noise_generator is
	port(
		clk       : in std_logic;
		reset_n   : in std_logic;

		noise_out : out std_logic
		);
end noise_generator;

architecture arch of noise_generator is

signal noise_shift_reg     : std_logic_vector(16 downto 0) := "10000000000000000";
signal noise_feedback      : std_logic;

begin

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			noise_shift_reg <= "10000000000000000";

		elsif(clk'event and clk = '1') then

			noise_feedback  <= noise_shift_reg(3) xor noise_shift_reg(0);
			noise_shift_reg <= noise_feedback & noise_shift_reg(16 downto 1);
			noise_out       <= noise_shift_reg(0);

		end if;
	end process;

end arch;
