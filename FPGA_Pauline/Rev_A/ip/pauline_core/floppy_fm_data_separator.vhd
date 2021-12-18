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
-- File name      : floppy_fm_data_seperator.vhd
--
-- Purpose        : floppy FM data separator circuit.
--
--============================================================================-
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 1.0    Jean-François DEL NERO  15 December 2021          First version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity floppy_fm_data_separator is
	port(
		clk                     : in  std_logic;
		reset_n                 : in  std_logic;

		raw_data                : in  std_logic;

		window_size             : in  std_logic_vector(15 downto 0);
		window_phase_correction : in  std_logic_vector(15 downto 0);

		window_clk              : out std_logic
	);
end floppy_fm_data_separator;

architecture arch of floppy_fm_data_separator is

signal raw_data_tick : std_logic;
signal raw_data_q : std_logic;

signal data_bit_window : std_logic;

signal pulse_event : std_logic;

signal window_cnt : std_logic_vector(15 downto 0);

begin

	window_clk <= data_bit_window;

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			raw_data_q <= raw_data;
			pulse_event <= '0';
			data_bit_window <= '0';

		elsif(clk'event and clk = '1') then

			raw_data_q <= raw_data;

			window_cnt <= window_cnt + conv_std_logic_vector(1,16);

			if( (window_cnt >= window_size) )
			then

				window_cnt <= (others=>'0');

				data_bit_window <= not(data_bit_window);

				if(pulse_event = '0')
				then
					-- No pulse during previous period -> data bit
					-- the next one should be a clock bit
					data_bit_window <= '0';
				end if;

				pulse_event <= '0';

			end if;

			if(raw_data_q = '0' and raw_data = '1')
			then
				pulse_event <= '1';
				window_cnt <= window_phase_correction;
			end if;

			if( window_size = conv_std_logic_vector(0,16) )
			then
				pulse_event <= '0';
				data_bit_window <= '0';
				window_cnt <= (others=>'0');
			end if;

		end if;
	end process;

end arch;
