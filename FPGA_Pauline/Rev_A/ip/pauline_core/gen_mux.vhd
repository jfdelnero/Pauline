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
-- File name      : gen_mux.vhd
--
-- Purpose        : generic multiplexer.
--
--============================================================================-
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 1.0    Jean-François DEL NERO  31 October 2020          First version
--------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_mux is
	generic (SEL_WIDTH : INTEGER);
port(

	inputs      : in  std_logic_vector((2**SEL_WIDTH)-1 downto 0);
	sel         : in  std_logic_vector(SEL_WIDTH - 1 downto 0);
	out_signal  : out std_logic
	);
end gen_mux;

architecture rtl of gen_mux is

type t_array_mux is array (0 to (2**SEL_WIDTH)-1) of std_logic;
signal array_mux  : t_array_mux;

begin

	process(inputs) begin
		for i in 0 to (2**SEL_WIDTH)-1 loop
			array_mux(i)  <= inputs(i);
		end loop;
	end process;

	out_signal <= array_mux(to_integer(unsigned(sel)));

end rtl;
