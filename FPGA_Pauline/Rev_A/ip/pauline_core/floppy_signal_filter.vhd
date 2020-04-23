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
-- File name      : floppy_signal_filter.vhd
--
-- Purpose        : async signal filter.
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

entity floppy_signal_filter is
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		signal_in               : in std_logic;
		signal_out              : out std_logic;

		filter_level            : in std_logic_vector (31 downto 0);

		invert                  : in std_logic;

		pulse_out_mode          : in std_logic;

		rising_edge             : in std_logic;
		falling_edge            : in std_logic

		);
end floppy_signal_filter;

architecture arch of floppy_signal_filter is

signal signal_in_q1 : std_logic;
signal signal_in_q2 : std_logic;
signal signal_in_q3 : std_logic;

signal signal_filter_cnt : std_logic_vector(31 downto 0);

signal signal_out_state : std_logic;
signal signal_pulse_out : std_logic;


begin

	process(clk, reset_n, signal_in, signal_in_q1, signal_in_q2 ) begin
		if(reset_n = '0') then

			signal_in_q1 <= '0';
			signal_in_q2 <= '0';
			signal_in_q3 <= '0';

		elsif(clk'event and clk = '1') then

			signal_in_q1 <= signal_in;
			signal_in_q2 <= signal_in_q1;
			signal_in_q3 <= signal_in_q2;

		end if;
	end process;


	process(clk, reset_n, signal_in_q3, signal_filter_cnt, filter_level ) begin
		if(reset_n = '0') then

			signal_out_state <= '0';
			signal_filter_cnt <= (others=>'0');
			signal_pulse_out <= '0';

		elsif(clk'event and clk = '1') then

			signal_pulse_out <= '0';

			if( signal_out_state /= signal_in_q3 )
			then

				if( signal_filter_cnt < filter_level )
				then

					signal_filter_cnt <= signal_filter_cnt + conv_std_logic_vector(1,32);

				else

					signal_out_state <= signal_in_q3;

					if( rising_edge = '1' and signal_in_q3 = '1')
					then
						signal_pulse_out <= '1';
					end if;

					if( falling_edge = '1' and signal_in_q3 = '0')
					then
						signal_pulse_out <= '1';
					end if;

				end if;

			else
				signal_filter_cnt <= (others=>'0');
			end if;

		end if;
	end process;


	process(pulse_out_mode, signal_out_state, invert, signal_pulse_out) begin
		if(pulse_out_mode = '0')
		then
			signal_out <= signal_out_state xor invert;
		else
			signal_out <= signal_pulse_out;
		end if;
	end process;

end arch;
