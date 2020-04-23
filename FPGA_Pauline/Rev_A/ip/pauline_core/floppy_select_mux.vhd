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
-- File name      : floppy_select_mux.vhd
--
-- Purpose        : floppy line muxer.
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

entity floppy_select_mux is
	port(
		clk         : in std_logic;
		reset_n     : in std_logic;

		line_select : in std_logic_vector(3 downto 0);

		line0       : in std_logic;
		line1       : in std_logic;
		line2       : in std_logic;
		line3       : in std_logic;
		line4       : in std_logic;
		line5       : in std_logic;
		line6       : in std_logic;
		line7       : in std_logic;

		line_out    : out std_logic
		);
end floppy_select_mux;

architecture arch of floppy_select_mux is

begin

	process(line_select) begin
		case line_select is
			when "0000" => line_out <= '0';
			when "0001" => line_out <= '1';
			when "1000" => line_out <= line0;
			when "1001" => line_out <= line1;
			when "1010" => line_out <= line2;
			when "1011" => line_out <= line3;
			when "1100" => line_out <= line4;
			when "1101" => line_out <= line5;
			when "1110" => line_out <= line6;
			when "1111" => line_out <= line7;
			when others => line_out <= '0';
		end case;
	end process;

end arch;
