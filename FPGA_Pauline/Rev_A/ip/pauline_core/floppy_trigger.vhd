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
-- File name      : floppy_trigger.vhd
--
-- Purpose        : Event delay box.
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

entity floppy_trigger is
	port(
		clk                     : in std_logic;
		reset_n                 : in std_logic;

		signal_in               : in std_logic;
		signal_out              : out std_logic;

		timeout_out             : out std_logic;

		delay                   : in std_logic_vector (31 downto 0);

		timeout                 : in std_logic_vector (31 downto 0);

		invert                  : in std_logic;

		pulse_out_mode          : in std_logic;

		rising_edge             : in std_logic;
		falling_edge            : in std_logic;

		clear_event             : in std_logic

		);
end floppy_trigger;

architecture arch of floppy_trigger is

signal signal_in_q1 : std_logic;

signal signal_delay_cnt : std_logic_vector(31 downto 0);
signal signal_timeout_cnt : std_logic_vector(31 downto 0);

signal signal_out_state : std_logic;
signal signal_out_state_q : std_logic;
signal signal_pulse_out : std_logic;

signal event_state : std_logic;
signal timeout_state : std_logic;

signal tick_us : std_logic;

component floppy_tick_generator
	port(
		clk                     : in std_logic;
		reset_n                 : in std_logic;

		sync                    : in  std_logic;

		tick_us                 : out std_logic;

		tick_ms                 : out std_logic;

		tick_s                  : out std_logic
		);
end component;

begin

	trigger_tick_generator : floppy_tick_generator
	port map
	(
		clk     => clk,
		reset_n => reset_n,

		sync    => clear_event,

		tick_us => tick_us,

		tick_ms => open,

		tick_s  => open
	);

	timeout_out <= timeout_state;

	process(clk, reset_n, signal_in, signal_in_q1 ) begin
		if(reset_n = '0') then

			signal_in_q1 <= '0';

		elsif(clk'event and clk = '1') then

			signal_in_q1 <= signal_in;

		end if;
	end process;

	process(clk, reset_n, signal_in_q1 ) begin
		if(reset_n = '0') then

			event_state <= '0';

		elsif(clk'event and clk = '1') then

			if ( clear_event = '1' )
			then
				event_state <= '0';
			else
				if( signal_in /= signal_in_q1 )
				then
					if( rising_edge = '1' and signal_in_q1 = '0')
					then
						event_state <= '1';
					end if;

					if( falling_edge = '1' and signal_in_q1 = '1')
					then
						event_state <= '1';
					end if;
				end if;
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

	process(clk, reset_n, signal_delay_cnt, delay ) begin
		if(reset_n = '0') then

			signal_out_state <= '0';
			signal_delay_cnt <= (others=>'0');

			signal_pulse_out <= '0';
			signal_out_state_q <= '0';

		elsif(clk'event and clk = '1') then

			signal_out_state_q <= signal_out_state;
			signal_pulse_out <= '0';

			if(event_state = '0')
			then
				signal_delay_cnt <= (others=>'0');
				signal_out_state <= '0';
				signal_out_state_q <= '0';
			else
				if( signal_delay_cnt < delay )
				then
					if( tick_us = '1' )
					then
						signal_delay_cnt <= signal_delay_cnt + "00000000000000000000000000000001";
					end if;
				else
					signal_out_state <= '1';
				end if;
			end if;

			if( signal_out_state /= signal_out_state_q  and signal_out_state ='1')
			then
				signal_pulse_out <= '1';
			end if;
		end if;
	end process;

	process(clk, reset_n, signal_timeout_cnt, timeout ) begin
		if(reset_n = '0') then

			signal_timeout_cnt <= (others=>'0');
			timeout_state <= '0';

		elsif(clk'event and clk = '1') then

			if(event_state = '0')
			then
				if( signal_timeout_cnt < timeout )
				then
					if( tick_us = '1' )
					then
						signal_timeout_cnt <= signal_timeout_cnt + "00000000000000000000000000000001";
					end if;
				else
					timeout_state <= '1';
				end if;
			else
				signal_timeout_cnt <= (others=>'0');
			end if;

			if ( clear_event = '1' )
			then
				timeout_state <= '0';
				signal_timeout_cnt <= (others=>'0');
			end if;

		end if;
	end process;

end arch;
