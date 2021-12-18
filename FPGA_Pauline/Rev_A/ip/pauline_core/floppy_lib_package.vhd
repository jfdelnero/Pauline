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
-- File name      : floppy_lib_package.vhd
--
-- Purpose        : types/packages definitions.
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

package floppy_lib_package is

  constant c_PIXELS : integer := 65536;

  type  lword_array is array (0 to 4) of std_logic_vector(31 downto 0);
  type  lbyte_array is array (0 to 4) of std_logic_vector(7 downto 0);

  type  muxsel_array is array (0 to 19) of std_logic_vector(7 downto 0);

  type pop_fifo_in_databus is record
    pop_fifo_in_data : std_logic_vector(31 downto 0);
    pop_fifo_in_address : std_logic_vector(31 downto 0);
    pop_fifo_in_status : std_logic_vector(7 downto 0);
  end record pop_fifo_in_databus;

  type pop_fifo_in_ctrlbus is record
	pop_fifo_in_wr : std_logic;
  end record pop_fifo_in_ctrlbus;

  type pop_fifo_in_statusbus is record
	pop_fifo_almostfull : std_logic;
	pop_fifo_full : std_logic;
	pop_fifo_empty : std_logic;
  end record pop_fifo_in_statusbus;

  type push_fifo_out_databus is record
    push_fifo_out_data : std_logic_vector(31 downto 0);
    push_fifo_out_address : std_logic_vector(31 downto 0);
    push_fifo_out_status : std_logic_vector(7 downto 0);
  end record push_fifo_out_databus;

  type push_fifo_out_ctrlbus is record
	push_fifo_out_rq : std_logic;
  end record push_fifo_out_ctrlbus;

  type push_fifo_out_statusbus is record
	push_fifo_empty : std_logic;
	push_fifo_full : std_logic;
	push_fifo_usedw : std_logic_vector(11 downto 0);
  end record push_fifo_out_statusbus;

  type pop_fifos_in_databus is array (0 to 4) of pop_fifo_in_databus;
  type pop_fifos_in_ctrlbus is array (0 to 4) of pop_fifo_in_ctrlbus;
  type pop_fifos_in_statusbus is array (0 to 4) of pop_fifo_in_statusbus;

  type push_fifos_out_databus is array (0 to 4) of push_fifo_out_databus;
  type push_fifos_out_ctrlbus is array (0 to 4) of push_fifo_out_ctrlbus;
  type push_fifos_out_statusbus is array (0 to 4) of push_fifo_out_statusbus;

  type hs_index_pos_array is array (0 to 31) of std_logic_vector(31 downto 0);

  component example_component is
    port (
      i_data  : in  std_logic;
      o_rsult : out std_logic);
  end component example_component;

  function Bitwise_AND (
    i_vector : in std_logic_vector(3 downto 0))
    return std_logic;

end package floppy_lib_package;

-- Package Body Section
package body floppy_lib_package is

  function Bitwise_AND (
    i_vector : in std_logic_vector(3 downto 0)
    )
    return std_logic is
  begin
    return (i_vector (0) and i_vector (1) and i_vector (2) and i_vector (3));
  end;

end package body floppy_lib_package;