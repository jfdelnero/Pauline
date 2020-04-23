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
-- File name      : floppy_ctrl_stepper.vhd
--
-- Purpose        : floppy controller track stepper.
--
--============================================================================-
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 1.0    Jean-François DEL NERO  20 April 2019          First version
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

entity floppy_ctrl_stepper is
	port (
		clk : in std_logic;
		reset_n : in std_logic;

		floppy_ctrl_step        : out std_logic;
		floppy_ctrl_dir         : out std_logic;
		floppy_ctrl_trk00		: in std_logic;

		step_rate               : in  std_logic_vector (31 downto 0);

		track_pos_cmd           : in  std_logic_vector (9 downto 0);
		move_head_cmd           : in  std_logic;
		move_dir                : in  std_logic;

		cur_track_pos           : out std_logic_vector (9 downto 0);

		moving                  : out std_logic;

		sound                   : out std_logic

		);
end  floppy_ctrl_stepper;

------------------------------------------------------------------------------------------

architecture arch of floppy_ctrl_stepper is

	type state_type_stepper is ( wait_cmd, pre_move_head, move_head);

	signal state_stepper_register : state_type_stepper;
	signal move_head_cmd_q : std_logic;
	signal track_pos : std_logic_vector(9 downto 0);
	signal track_pos_cnt : std_logic_vector(9 downto 0);

	signal step_pulse_cnt : std_logic_vector(9 downto 0);
	signal stepper_tick_cnt : std_logic_vector(31 downto 0);
	signal stepper_time_cnt : std_logic_vector(15 downto 0);
	signal stepper_tick_cnt_rst : std_logic;

	signal step_pulse : std_logic;

	signal floppy_ctrl_dir_q : std_logic;

component floppy_sound
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		step_sound              : in  std_logic;

		sound                   : out std_logic
		);
end component;

begin

	cur_track_pos <= track_pos;
	floppy_ctrl_dir <= floppy_ctrl_dir_q;

	ctrl_floppy_sound_generator : floppy_sound
	port map(
		clk => clk,
		reset_n => reset_n,

		step_sound => step_pulse,

		sound  => sound
	);

	process(clk, reset_n ) begin
		if(reset_n = '0') then
			floppy_ctrl_step <= '0';
			step_pulse_cnt <= (others=>'1');
		elsif(clk'event and clk = '1') then

			floppy_ctrl_step <= '0';

			if( step_pulse_cnt < conv_std_logic_vector(200, 10) )
			then
				floppy_ctrl_step <= '1';
			end if;

			if( step_pulse = '1' )
			then
				step_pulse_cnt <= (others=>'0');
			else
				if( step_pulse_cnt /= "1111111111" )
				then
					step_pulse_cnt <= step_pulse_cnt + "0000000001";
				end if;
			end if;
		end if;
	end process;

	process(clk, reset_n ) begin
		if(reset_n = '0') then

			stepper_tick_cnt <= (others=>'0');
			stepper_time_cnt <= (others=>'0');

		elsif(clk'event and clk = '1') then

			if( stepper_tick_cnt_rst = '1' )
			then
				stepper_tick_cnt <= (others=>'0');
				stepper_time_cnt <= (others=>'0');
			else
				stepper_time_cnt <= stepper_time_cnt + conv_std_logic_vector(1, 16);

				if( stepper_time_cnt = conv_std_logic_vector(50, 16) ) -- 1uS
				then
					stepper_time_cnt <= (others=>'0');
					if( step_rate /= stepper_tick_cnt )
					then
						stepper_tick_cnt <= stepper_tick_cnt + conv_std_logic_vector(1, 32);
					end if;
				end if;
			end if;
		end if;
	end process;

	-------------------------------------------------------
	-- Track Circuit
	trackcounter : process(clk,reset_n)
	begin
		if (reset_n='0')
		then
			moving <= '0';
			track_pos <= (others=>'0');
			state_stepper_register <= wait_cmd;
			floppy_ctrl_dir_q <= '0';
			move_head_cmd_q <= '0';
			track_pos_cnt <= (others=>'0');
		elsif (clk='1' and clk'EVENT)
		then
			move_head_cmd_q <= move_head_cmd;

			moving <= '0';
			stepper_tick_cnt_rst <= '1';
			step_pulse <= '0';

			case state_stepper_register is

				when wait_cmd =>
					moving <= '0';
					track_pos_cnt <= (others=>'0');
					if( move_head_cmd_q = '0' and move_head_cmd = '1' )
					then
						floppy_ctrl_dir_q <= move_dir;
						moving <= '1';
						state_stepper_register <= pre_move_head;
					end if;

				when pre_move_head =>
					stepper_tick_cnt_rst <= '0';
					moving <= '1';

					if( stepper_tick_cnt = ("0" & step_rate(31 downto 1)) )
					then

						if( floppy_ctrl_dir_q = '1' )
						then
							if( track_pos /= conv_std_logic_vector(900, 10) )
							then
								track_pos <= track_pos + conv_std_logic_vector(1, 10);

								step_pulse <= '1';
							end if;
						else
							if( track_pos /= conv_std_logic_vector(0, 10) )
							then
								track_pos <= track_pos - conv_std_logic_vector(1, 10);
							end if;

							step_pulse <= '1';
						end if;

						track_pos_cnt <= track_pos_cnt + conv_std_logic_vector(1,10);
						state_stepper_register <= move_head;
					end if;

				when move_head =>
					stepper_tick_cnt_rst <= '0';
					moving <= '1';

					if( stepper_tick_cnt = step_rate(31 downto 0) )
					then
						if (floppy_ctrl_trk00 = '1' )
						then
							track_pos <= (others=> '0');
						end if;

						if( track_pos_cnt /= track_pos_cmd)
						then
							stepper_tick_cnt_rst <= '1';
							state_stepper_register <= pre_move_head;
						else
							state_stepper_register <= wait_cmd;
						end if;

					end if;

				when others =>
					state_stepper_register <= wait_cmd;

			end case;
		end if;
	end process;

end arch;

