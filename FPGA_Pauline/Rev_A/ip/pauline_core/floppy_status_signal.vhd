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
-- File name      : floppy_status_signal.vhd
--
-- Purpose        : status signal generator.
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

entity floppy_status_signal is
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		tick_ms : in std_logic;

		signal_config           : in std_logic_vector(3 downto 0);

		disk_in_drive           : in std_logic;
		step_event              : in std_logic;
		ready_status            : in std_logic;
		density                 : in std_logic;
		reset_dc                : in std_logic;

		signal_out              : out std_logic

		);
end floppy_status_signal;

-- pin02/pin34 _config
-- 0000 - Low
-- 0001 - High
-- 0010 - nReady
-- 0011 - Ready
-- 0100 - nDensity
-- 0101 - Density
-- 0110 - nDiskChanged 1 (Step only clear)
-- 0111 - DiskChanged 1  (Step only clear)
-- 1000 - nDiskChanged 2 (Step only + timer)
-- 1001 - DiskChanged 2  (Step only + timer)
-- 1010 - nDiskChanged 3 (timer)
-- 1011 - DiskChanged 3  (timer)
-- 1100 - nDiskChanged 4 (floppy_dc_reset)
-- 1101 - DiskChanged 4  (floppy_dc_reset)

architecture arch of floppy_status_signal is

signal disk_changed_0 : std_logic;
signal disk_changed_1 : std_logic;
signal disk_changed_2 : std_logic;
signal disk_changed_3 : std_logic;

signal timeout : std_logic_vector(15 downto 0);

begin

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			disk_changed_0 <= '1';
			disk_changed_1 <= '1';
			disk_changed_2 <= '1';
			disk_changed_3 <= '1';
			timeout <= (others=>'0');

		elsif(clk'event and clk = '1') then

			if( disk_in_drive = '0' )
			then
				disk_changed_0 <= '1';
				disk_changed_1 <= '1';
				disk_changed_2 <= '1';
				disk_changed_3 <= '1';
				timeout <= (others=>'0');
			else

				if( step_event = '1' )
				then
					disk_changed_0 <= '0';
					disk_changed_1 <= '0';
				end if;

				if( timeout > conv_std_logic_vector(3000,16) )
				then
					disk_changed_2 <= '0';
					disk_changed_1 <= '0';
				else
					if(tick_ms = '1')
					then
						timeout <= timeout + conv_std_logic_vector(1,16);
					end if;
				end if;

				if( reset_dc = '1' )
				then
					disk_changed_3 <= '0';
				end if;

			end if;

		end if;
	end process;


	process(clk, reset_n ) begin
		if(reset_n = '0') then

			signal_out <= '0';

		elsif(clk'event and clk = '1') then
				if ( signal_config = "0000") then
					signal_out <= '1';                     -- 0000 - Low
				elsif ( signal_config = "0001") then
					signal_out <= '0';                     -- 0001 - High
				elsif ( signal_config = "0010") then
					signal_out <= ready_status;            -- 0010 - nReady
				elsif ( signal_config = "0011") then
					signal_out <= not(ready_status);       -- 0011 - Ready
				elsif ( signal_config = "0100") then
					signal_out <= disk_in_drive;           -- 0100 - nDensity
				elsif ( signal_config = "0101") then
					signal_out <= not(disk_in_drive);      -- 0101 - Density
				elsif ( signal_config = "0110") then
					signal_out <= disk_changed_0;          -- 0110 - nDiskChanged 1 (Step only clear)
				elsif ( signal_config = "0111") then
					signal_out <= not(disk_changed_0);     -- 0111 - DiskChanged 1  (Step only clear)
				elsif ( signal_config = "1000") then
					signal_out <= disk_changed_1;          -- 1000 - nDiskChanged 2 (Step only + timer)
				elsif ( signal_config = "1001") then
					signal_out <= not(disk_changed_1);     -- 1001 - DiskChanged 2  (Step only + timer)
				elsif ( signal_config = "1010") then
					signal_out <= disk_changed_2;          -- 1010 - nDiskChanged 3 (timer)
				elsif ( signal_config = "1011") then
					signal_out <= not(disk_changed_2);     -- 1011 - DiskChanged 3  (timer)
				elsif ( signal_config = "1100") then
					signal_out <= disk_changed_3;          -- 1100 - nDiskChanged 4 (floppy_dc_reset)
				elsif ( signal_config = "1101") then
					signal_out <= not(disk_changed_3);     -- 1101 - DiskChanged 4  (floppy_dc_reset)
				else
					signal_out <= '0';
				end if;
		end if;
	end process;

end arch;
