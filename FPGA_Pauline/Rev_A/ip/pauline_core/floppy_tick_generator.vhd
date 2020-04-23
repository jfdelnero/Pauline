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
-- File name      : floppy_tick_generator.vhd
--
-- Purpose        : us,ms,s tick generator.
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

entity floppy_tick_generator is
	port(
		clk                     : in std_logic;
		reset_n                 : in std_logic;

		sync                    : in  std_logic;

		tick_us                 : out std_logic;

		tick_ms                 : out std_logic;

		tick_s                  : out std_logic
		);
end floppy_tick_generator;

architecture arch of floppy_tick_generator is

signal tick_us_cnt : std_logic_vector(31 downto 0);
signal tick_ms_cnt : std_logic_vector(31 downto 0);
signal tick_s_cnt : std_logic_vector(31 downto 0);

begin

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			tick_us_cnt <= (others=>'0');
			tick_us <= '0';

		elsif(clk'event and clk = '1') then

			if( sync = '1' )
			then
				tick_us_cnt <= (others=>'0');
				tick_us <= '0';
			else
				tick_us_cnt <= tick_us_cnt + conv_std_logic_vector(1,32);
				tick_us <= '0';

				if( tick_us_cnt >= conv_std_logic_vector(50,32) )
				then
					tick_us <= '1';
					tick_us_cnt <= (others=>'0');
				end if;
			end if;

		end if;
	end process;

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			tick_ms_cnt <= (others=>'0');
			tick_ms <= '0';

		elsif(clk'event and clk = '1') then

			if( sync = '1' )
			then
				tick_ms_cnt <= (others=>'0');
				tick_ms <= '0';
			else
				tick_ms_cnt <= tick_ms_cnt + conv_std_logic_vector(1,32);
				tick_ms <= '0';

				if( tick_ms_cnt >= conv_std_logic_vector(50000,32) )
				then
					tick_ms <= '1';
					tick_ms_cnt <= (others=>'0');
				end if;
			end if;

		end if;
	end process;

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			tick_s_cnt <= (others=>'0');
			tick_s <= '0';

		elsif(clk'event and clk = '1') then

			if( sync = '1' )
			then
				tick_s_cnt <= (others=>'0');
				tick_s <= '0';
			else
				tick_s_cnt <= tick_s_cnt + conv_std_logic_vector(1,32);
				tick_s <= '0';

				if( tick_s_cnt >= conv_std_logic_vector(50000000,32) )
				then
					tick_s <= '1';
					tick_s_cnt <= (others=>'0');
				end if;
			end if;

		end if;
	end process;

end arch;
