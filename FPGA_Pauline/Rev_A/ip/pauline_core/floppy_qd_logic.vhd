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
-- File name      : floppy_qd_logic.vhd
--
-- Purpose        : Quick Disk Logic.
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

entity floppy_qd_logic is
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		qd_reset                : in std_logic;
		qd_motoron              : in std_logic;

		qd_wg                   : in std_logic;

		qd_rd_head_sw           : in std_logic;
		qd_motor_stop_sw        : in std_logic;

		qd_motor_cmd            : out std_logic;
		qd_ready                : out std_logic

		);
end floppy_qd_logic;

--
-- QD90-128 / QDM-1 / Akai MD280 Quick disk signals description
-- (C) 2019 Jean-François DEL NERO / HxC2001 Floppy Emulator project.
--
-- DB9 Connector: (QD90-128)
--   /MS /WP /MO /RS  WG
--    1   2   3   4   5
--
--       6  7   8   9
--     GND /WD /RY  RD
--
-- Internal connector :
--  - (1-Brown) /WP - (2-Red) /WD - (3-Orange) WG - (4-Yellow) /MO - (5-Green) RD - (6-Blue) /RY - (7-Purple) /MS - (8-Grey) /RS - (9 White) VCC5V - (10-Black) GND -
--
-- (O AL) 1 (7) MS : /Disk Present (Simple switch to gnd + 4.7Ko pull up)
-- (O AH) 2 (1) WP : /Write Protect (Simple switch to gnd + 680o pull up - Lock the write-gate if asserted)
-- (I AL) 3 (4) MO : /Motor ON     (Motor on trigger signal on falling edge - Motor stopped by the stop motor switch if MO not asserted OR if WG is asserted )
-- (I AL) 4 (8) RS : /Reset        (Stop motor if /MO not asserted + clear ready)
-- (I AH) 5 (3) WG : Write Gate    ( If WG is asserted the motor seems to stop at the stop motor switch even if /MO is asserted ! No write occur if the drive is not ready (/RY) and the /Write protect is asserted )
-- -----  6 (10) GND
-- (I AL) 7 (2) WD : /Write Data   ( Falling edge )
-- (O AL) 8 (6) RY : /Ready - Enabled if /MO is asserted and pass the rd head sw signal. Cleared at /RS or when passing the stop motor switch
-- (O AH) 9 (5) RD : Data Read
--          (9) VCC (5v)
--

architecture arch of floppy_qd_logic is

signal qd_motor_state : std_logic;
signal qd_ready_state : std_logic;

signal qd_motoron_q : std_logic;

begin

	qd_motor_cmd <= qd_motor_state;
	qd_ready     <= qd_ready_state;

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			qd_motor_state <= '0';
			qd_ready_state <= '0';
			qd_motoron_q <= '0';

		elsif(clk'event and clk = '1') then

			qd_motoron_q <= qd_motoron;

			if( qd_motoron_q = '0' and qd_motoron = '1' ) -- motor Event
			then
				qd_motor_state <= '1';
			elsif( ( qd_motor_stop_sw = '1' or qd_reset = '1' ) and ( qd_motoron = '0' or qd_wg = '1' ) )
			then
				qd_motor_state <= '0';
			end if;

			if ( qd_rd_head_sw = '1' and qd_motoron = '1' ) -- Passing the read switch : set the ready signal
			then
				qd_ready_state <= '1';
			end if;

			if ( qd_motor_stop_sw = '1' ) -- Passing the motor stop switch : Clear the ready signal
			then
				qd_ready_state <= '0';
			end if;

			if( qd_reset = '1' )
			then
				qd_ready_state <= '0';
			end if;

		end if;
	end process;

end arch;
