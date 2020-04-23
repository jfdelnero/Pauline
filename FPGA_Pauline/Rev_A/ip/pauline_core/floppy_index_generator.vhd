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
-- File name      : floppy_index_generator.vhd
--
-- Purpose        : floppy index generator.
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
use ieee.std_logic_arith.ALL;

entity floppy_index_generator is
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		track_length            : in std_logic_vector (31 downto 0);

		index_length            : in std_logic_vector (31 downto 0);

		start_track_index       : in std_logic_vector (31 downto 0);

		current_position        : in std_logic_vector (31 downto 0);

		index_out               : out std_logic
		);
end floppy_index_generator;

architecture arch of floppy_index_generator is

signal track_index : std_logic;

begin
	index_out <= track_index;

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			track_index <= '0';

		elsif(clk'event and clk = '1') then

			track_index <= '0';

			if( start_track_index + index_length > track_length )
			then
				if ( current_position >= start_track_index )
				then
					track_index <= '1';
				elsif( current_position < ( (start_track_index + index_length) - track_length ) )
				then
					track_index <= '1';
				end if;
			else
				if ( current_position >= start_track_index )
				then
					if ( current_position < (start_track_index + index_length) )
					then
						track_index <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;

end arch;
