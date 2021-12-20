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

		window_period           : in  std_logic_vector(15 downto 0);
		window_phase_correction : in  std_logic_vector(15 downto 0);

		reshaped_window_mode    : in  std_logic;
		window_delay            : in  std_logic_vector(15 downto 0);
		window_width            : in  std_logic_vector(15 downto 0);
		window_polarity         : in  std_logic;

		phase_select            : in  std_logic;

		window_clk              : out std_logic
	);
end floppy_fm_data_separator;

architecture arch of floppy_fm_data_separator is

signal raw_data_tick : std_logic;
signal raw_data_q : std_logic;

signal data_bit_window : std_logic;
signal reshaped_data_bit_window : std_logic;

signal pulse_event : std_logic;

signal window_event : std_logic;

signal window_cnt : std_logic_vector(15 downto 0);

signal window_delay_cnt : std_logic_vector(15 downto 0);
signal window_width_cnt : std_logic_vector(15 downto 0);
signal data_bit_window_q : std_logic;

--
--                   C   D   C   D   C   D   C 
--Floppy Data    : __|___|___|___|___|___|___|_
--                      ___     ___     ___
--Data separator : ____|   |___|   |___|   |___
--(data_bit_window)
--

begin

	-- direct or reshaped signal selector
	process(clk, reset_n ) begin
		if(reshaped_window_mode = '0')
		then
			window_clk <= data_bit_window xor window_polarity;
		else
			window_clk <= reshaped_data_bit_window xor window_polarity;
		end if;
	end process;

	-- window phase selector
	process(clk, reset_n ) begin
		if(reset_n = '0') then
			window_event <= '0';
		elsif(clk'event and clk = '1') then

			data_bit_window_q <= data_bit_window;
			window_event <= '0';

			if(phase_select='0')
			then
				if( data_bit_window_q = '0' and data_bit_window = '1' )
				then
					window_event <= '1';
				end if;
			else
				if( data_bit_window_q = '1' and data_bit_window = '0' )
				then
					window_event <= '1';
				end if;
			end if;
		end if;
	end process;

	-- window additionnal delay
	process(clk, reset_n ) begin
		if(reset_n = '0') then
			window_delay_cnt <= (others=>'1');
		elsif(clk'event and clk = '1') then

			if(window_delay_cnt < window_delay)
			then
				window_delay_cnt <= window_delay_cnt + conv_std_logic_vector(1,16);
			end if;

			if(window_event = '1')
			then
				window_delay_cnt <= (others=>'0');
			end if;

		end if;
	end process;

	-- window signal width
	process(clk, reset_n ) begin
		if(reset_n = '0') then
			window_width_cnt <= (others=>'1');
		elsif(clk'event and clk = '1') then

			reshaped_data_bit_window <= '0';

			if(window_delay_cnt = window_delay)
			then
				if(window_width_cnt < window_width)
				then
					reshaped_data_bit_window <= '1';
					window_width_cnt <= window_width_cnt + conv_std_logic_vector(1,16);
				end if;
			end if;

			if(window_event = '1')
			then
				window_width_cnt <= (others=>'0');
			end if;

		end if;
	end process;

	-- FM data separator
	process(clk, reset_n ) begin
		if(reset_n = '0') then

			raw_data_q <= raw_data;
			pulse_event <= '0';
			data_bit_window <= '0';

		elsif(clk'event and clk = '1') then

			raw_data_q <= raw_data;

			window_cnt <= window_cnt + conv_std_logic_vector(1,16);

			if( (window_cnt >= window_period) )
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

			if( window_period = conv_std_logic_vector(0,16) )
			then
				pulse_event <= '0';
				data_bit_window <= '0';
				window_cnt <= (others=>'0');
			end if;

		end if;
	end process;

end arch;
