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
-- File name      : trackcore.vhd
--
-- Purpose        : track stepper.
--
--============================================================================-
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 1.0    Jean-François DEL NERO  20 April 2019          First version
-- 1.1    Jean-François DEL NERO  12 November 2021       Double step support
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity trackcore is
	port (
		clk                     : in std_logic;
		reset_n                 : in std_logic;

		image_base_address      : in std_logic_vector (31 downto 0);
		tracks_size             : in std_logic_vector (31 downto 0);
		max_tracks_pos          : in std_logic_vector (7 downto 0);

		cur_tracks_base         : out std_logic_vector (31 downto 0);

		FLOPPY_DRIVE_SELECT     : in std_logic;

		HEADTRACKPOSITION       : out std_logic_vector(7 downto 0); -- track position value

		HEADMOVED               : out std_logic;

		drive_head_step         : out std_logic;

		ackheadmove             : in std_logic;
		FLOPPY_STEP             : in std_logic;   -- Step command
		FLOPPY_DIR              : in std_logic;   -- Step direction
		FLOPPY_TRK00            : out std_logic;  -- Track 0 indicator

		step_sound              : out std_logic;

		double_step_mode        : in std_logic;

		clear_cnt               : in std_logic
		);
end  trackcore;

------------------------------------------------------------------------------------------

architecture arch of trackcore is

	signal track00signal : std_logic;
	signal trackposition : std_logic_vector(7 downto 0);
	signal tracks_base : std_logic_vector(31 downto 0);
	signal internal_step : std_logic;
	signal double_step_ff : std_logic;
	signal delayed_dir_sig : std_logic;


begin

	FLOPPY_TRK00 <= track00signal and FLOPPY_DRIVE_SELECT;
	cur_tracks_base <= image_base_address + tracks_base;
	-------------------------------------------------------


	internal_step_gen : process(FLOPPY_STEP,FLOPPY_DIR,FLOPPY_DRIVE_SELECT,double_step_mode,clk,reset_n)
	begin
		if (reset_n='0')
		then
			internal_step <= '0';
			double_step_ff <= '0';
			delayed_dir_sig <= '0';
		else
			internal_step <= '0';
			delayed_dir_sig <= FLOPPY_DIR;

			if( FLOPPY_DRIVE_SELECT = '1' )
			then

				if( FLOPPY_STEP = '1' )
				then

					if( double_step_mode = '0' )
					then
						internal_step <= '1';
					else

						if( double_step_ff = '1' )
						then
							internal_step <= '1';
						end if;

						double_step_ff <= not(double_step_ff);

					end if;

				end if;

			end if;
		end if;
	end process;

	-- Track Circuit
	trackcounter : process(FLOPPY_STEP,FLOPPY_DIR,trackposition,clk,reset_n)
	begin
		if (reset_n='0')
		then

			track00signal<='1';
			drive_head_step <= '0';
			step_sound <= '0';
			trackposition<=(others=>'0');
			tracks_base <= (others=>'0');

		elsif (clk='1' and clk'EVENT)
		then

			drive_head_step <= '0';
			step_sound <= '0';

			if(ackheadmove='1')
			then
				HEADMOVED<='0';
			end if;

			if(internal_step='1')
			then

				HEADMOVED<='1';
				drive_head_step <= '1';

				if( delayed_dir_sig = '1' )
				then

					if( trackposition < max_tracks_pos )
					then
						trackposition <= trackposition + conv_std_logic_vector(1, 8);
						tracks_base <= tracks_base + tracks_size;
						step_sound <= '1';
					end if;

				else

					if ( trackposition /= conv_std_logic_vector(0, 8) )
					then
						step_sound <= '1';
						trackposition <= trackposition - conv_std_logic_vector(1, 8);
					end if;

					if ( ( trackposition /= conv_std_logic_vector(1, 8) ) and ( trackposition /= conv_std_logic_vector(0, 8) ) )
					then
						tracks_base <= tracks_base - tracks_size;
					else
						tracks_base <= (others=>'0');
					end if;
				end if;

			end if;

			if(trackposition = conv_std_logic_vector(0, 8))
			then
				track00signal<='1';
			else
				track00signal<='0';
			end if;

			if(clear_cnt='1')
			then
				trackposition <= conv_std_logic_vector(0, 8);
				tracks_base <= (others=>'0');
				track00signal<='1';
			end if;

		end if;
	end process;

	HEADTRACKPOSITION<=trackposition;

end arch;
