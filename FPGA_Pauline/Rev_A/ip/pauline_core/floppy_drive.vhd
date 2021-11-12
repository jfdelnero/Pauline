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
-- File name      : floppy_drive.vhd
--
-- Purpose        : Main part of the floppy drive simulator.
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
use ieee.numeric_std.all;

library work;
use work.floppy_lib_package.all;

entity floppy_drive is
	port(
		clk                     : in std_logic;
		reset_n                 : in std_logic;

		pop_fifo_in_databus_b   : in pop_fifo_in_databus;
		pop_fifo_in_ctrlbus_b   : in pop_fifo_in_ctrlbus;
		pop_fifo_in_statusbus_b : out pop_fifo_in_statusbus;
		pop_fifo_in_status_byte : in std_logic_vector (7 downto 0);

		push_fifo_out_databus_b : out push_fifo_out_databus;
		push_fifo_out_ctrlbus_b : in push_fifo_out_ctrlbus;
		push_fifo_out_statusbus_b : out push_fifo_out_statusbus;

		read_fifo_cur_track_base: out std_logic_vector(31 downto 0);

		image_base_address      : in std_logic_vector (31 downto 0);
		tracks_size             : in std_logic_vector (31 downto 0);
		max_track               : in std_logic_vector (7 downto 0);

		track_position          : out std_logic_vector (7 downto 0);

		reset_state             : in std_logic;

		floppy_dc_rst           : in std_logic;

		floppy_step             : in std_logic;
		floppy_dir              : in std_logic;
		floppy_motor            : in std_logic;
		floppy_select           : in std_logic;
		floppy_write_gate       : in std_logic;
		floppy_write_data       : in std_logic;
		floppy_side1            : in std_logic;

		floppy_trk00            : out std_logic;
		host_o_data             : out std_logic;
		host_o_wpt              : out std_logic;
		host_o_index            : out std_logic;
		floppy_pin02            : out std_logic;
		floppy_pin34            : out std_logic;

		host_i_x68000_sel       : in std_logic;
		floppy_eject_func       : in std_logic;
		floppy_lock_func        : in std_logic;
		floppy_blink_func       : in std_logic;
		floppy_diskindrive      : out std_logic;
		floppy_insertfault      : out std_logic;
		floppy_int              : out std_logic;

		disk_in_drive           : in std_logic;
		disk_write_protect_sw   : in std_logic;
		disk_hd_sw              : in std_logic;
		disk_ed_sw              : in std_logic;
		pin02_config            : in std_logic_vector(3 downto 0);
		pin34_config            : in std_logic_vector(3 downto 0);
		readymask_config        : in std_logic_vector(3 downto 0);
		double_step_mode        : in std_logic;

		qd_mode                 : in std_logic;

		drive_sound             : out std_logic;

		led1_out                : out std_logic;
		led2_out                : out std_logic

		);
end floppy_drive;

architecture arch of floppy_drive is

signal track_pos : std_logic_vector(7 downto 0);
signal cur_tracks_base : std_logic_vector(31 downto 0);
signal rd_fifo_full : std_logic;
signal fiforeadcnt : std_logic_vector(5 downto 0);

signal out_shifter_side0 : std_logic_vector(32 downto 0);
signal out_shifter_side1 : std_logic_vector(32 downto 0);

signal out_address_q1 : std_logic_vector(31 downto 0);
signal out_address_q2 : std_logic_vector(31 downto 0);

signal in_shifter_side0 : std_logic_vector(15 downto 0);
signal in_shifter_side1 : std_logic_vector(15 downto 0);

signal out_index_shifter : std_logic_vector(31 downto 0);
signal out_qd_stopmotor_shifter : std_logic_vector(31 downto 0);

signal data_pulse_cnt : std_logic_vector(7 downto 0);

signal floppy_data_rd : std_logic;

signal floppy_data_side0_pulse : std_logic;
signal floppy_data_side1_pulse : std_logic;

signal write_flag : std_logic;

signal write_stream_side0 : std_logic;
signal write_stream_side1 : std_logic;

signal floppy_write_data_q1 : std_logic;
signal clock_div : std_logic;

signal drive_ready : std_logic;

signal drive_head_step : std_logic;

signal tick_us : std_logic;
signal tick_ms : std_logic;
signal tick_s : std_logic;

signal step_sound : std_logic;

signal motor_on_cnt : std_logic_vector(31 downto 0);

signal qd_ready : std_logic;
signal qd_motor : std_logic;

signal drive_motor : std_logic;

signal read_fifo_data : std_logic_vector(71 downto 0);
signal read_fifo_rq : std_logic;

signal write_fifo_data  : std_logic_vector(71 downto 0);
signal write_fifo_wr : std_logic;

signal weakbit_noise_sig : std_logic;
signal noise_gen_signal : std_logic;

signal write_protect_state : std_logic;

component floppy_sound
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		step_sound              : in  std_logic;

		period                  : in  std_logic_vector(31 downto 0);

		sound_out               : out std_logic
		);
end component;

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

component trackcore
	port
	(
		clk                     : in std_logic;
		reset_n                 : in std_logic;

		image_base_address      : in std_logic_vector (31 downto 0);
		tracks_size             : in std_logic_vector (31 downto 0);
		max_tracks_pos          : in std_logic_vector (7 downto 0);

		cur_tracks_base         : out std_logic_vector (31 downto 0);

		FLOPPY_DRIVE_SELECT     : in std_logic;

		HEADTRACKPOSITION       : out std_logic_vector(7 downto 0); -- track position value

		HEADMOVED               : out std_logic;

		drive_head_step         : out std_logic;

		ackheadmove             : in std_logic;
		FLOPPY_STEP             : in std_logic;   -- Step command
		FLOPPY_DIR              : in std_logic;   -- Step direction
		FLOPPY_TRK00            : out std_logic;  -- Track 0 indicator

		step_sound              : out std_logic;

		double_step_mode        : in std_logic;

		clear_cnt               : in std_logic
	);
end component;

component floppy_status_signal
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		tick_ms : in std_logic;

		signal_config           : in std_logic_vector(3 downto 0);

		disk_in_drive           : in std_logic;
		step_event              : in std_logic;
		ready_status            : in std_logic;
		density                 : in std_logic;
		reset_dc                : in std_logic;

		signal_out              : out std_logic
	);
end component;

component floppy_qd_logic
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
end component;

component fifo_floppy_read
	port
	(
		clock       : IN STD_LOGIC ;
		data        : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdreq       : IN STD_LOGIC ;
		sclr        : IN STD_LOGIC ;
		wrreq       : IN STD_LOGIC ;
		almost_full : OUT STD_LOGIC ;
		empty       : OUT STD_LOGIC ;
		full        : OUT STD_LOGIC ;
		q           : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		usedw       : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
end component;

component status_fifo
	PORT
	(
		clock       : IN STD_LOGIC ;
		data        : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdreq       : IN STD_LOGIC ;
		sclr        : IN STD_LOGIC ;
		wrreq       : IN STD_LOGIC ;
		almost_full : OUT STD_LOGIC ;
		empty       : OUT STD_LOGIC ;
		full        : OUT STD_LOGIC ;
		q           : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		usedw       : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
end component;

component noise_generator is
	port(
		clk       : in std_logic;
		reset_n   : in std_logic;

		noise_out : out std_logic
	);
end component;

begin

	process(clk, reset_n, qd_mode, floppy_motor, qd_motor ) begin
		if( qd_mode = '0' )
		then
			drive_motor <= floppy_motor;
		else
			drive_motor <= qd_motor;
		end if;
	end process;

	track_position <= track_pos;

	floppy_int <= '0';
	floppy_insertfault <= '0';
	floppy_diskindrive <= '0';

	write_protect_state <= disk_write_protect_sw or not(disk_in_drive);

	host_o_wpt <= write_protect_state;

	host_o_index <= out_index_shifter(31) and (not(readymask_config(0)) or drive_ready);
	host_o_data <= floppy_data_rd and drive_motor and (not(readymask_config(1)) or drive_ready);

	floppy_data_side0_pulse <= out_shifter_side0(30);
	floppy_data_side1_pulse <= out_shifter_side1(30);

	led1_out <= floppy_select;

	read_fifo_cur_track_base <= cur_tracks_base;

	tick_generator : floppy_tick_generator
	port map
	(
		clk => clk,
		reset_n => reset_n,

		sync => '0',

		tick_us => tick_us,

		tick_ms => tick_ms,

		tick_s => tick_s
	);

	floppy_sound_generator : floppy_sound
	port map(
		clk => clk,
		reset_n => reset_n,

		step_sound => step_sound,

		period     => (others=>'0'),

		sound_out  => drive_sound
	);

	pin02_generator : floppy_status_signal
	port map
	(
		clk => clk,
		reset_n => reset_n,

		tick_ms => tick_ms,

		signal_config => pin02_config,

		disk_in_drive => disk_in_drive,
		step_event => drive_head_step,
		ready_status => drive_ready,
		density => disk_hd_sw,
		reset_dc => floppy_dc_rst,

		signal_out => floppy_pin02
	);

	pin34_generator : floppy_status_signal
	port map
	(
		clk => clk,
		reset_n => reset_n,

		tick_ms => tick_ms,

		signal_config => pin34_config,

		disk_in_drive => disk_in_drive,
		step_event => drive_head_step,
		ready_status => drive_ready,
		density => disk_hd_sw,
		reset_dc => floppy_dc_rst,

		signal_out => floppy_pin34
	);

	qd_logic : floppy_qd_logic
	port map
	(
		clk               => clk,
		reset_n           => reset_n,

		qd_reset          => floppy_step,
		qd_motoron        => floppy_motor,

		qd_wg             => floppy_write_gate and not(disk_write_protect_sw),

		qd_rd_head_sw     => out_index_shifter(31),
		qd_motor_stop_sw  => out_qd_stopmotor_shifter(31),

		qd_motor_cmd      => qd_motor,
		qd_ready          => qd_ready

		);

	track_stepper : trackcore
	port map
	(
		clk => clk,
		reset_n => reset_n,

		image_base_address => image_base_address,
		tracks_size => tracks_size,
		max_tracks_pos => max_track,

		cur_tracks_base => cur_tracks_base,

		FLOPPY_DRIVE_SELECT => floppy_select,
		HEADTRACKPOSITION => track_pos,
		HEADMOVED => open,
		drive_head_step => drive_head_step,
		ackheadmove => '0',
		FLOPPY_STEP => floppy_step,
		FLOPPY_DIR => floppy_dir,
		FLOPPY_TRK00 => floppy_trk00,

		step_sound => step_sound,

		double_step_mode => double_step_mode,

		clear_cnt => reset_state
	);

	weakbit_noise_gen : noise_generator
	port map
	(
		clk => clk,
		reset_n => reset_n,

		noise_out => weakbit_noise_sig
	);

	process(floppy_side1, floppy_write_gate, floppy_write_data, floppy_data_side0_pulse, floppy_data_side1_pulse, floppy_write_data_q1 ) begin
		if( floppy_side1 = '0' )
		then
			if( floppy_write_gate = '1' and write_protect_state = '0' )
			then
				write_stream_side0 <= (floppy_write_data or floppy_write_data_q1);
				write_stream_side1 <= floppy_data_side1_pulse;
			else
				write_stream_side0 <= floppy_data_side0_pulse;
				write_stream_side1 <= floppy_data_side1_pulse;
			end if;
		else
			if( floppy_write_gate = '1' and write_protect_state = '0' )
			then
				write_stream_side0 <= floppy_data_side0_pulse;
				write_stream_side1 <= (floppy_write_data or floppy_write_data_q1);
			else
				write_stream_side0 <= floppy_data_side0_pulse;
				write_stream_side1 <= floppy_data_side1_pulse;
			end if;
		end if;

	end process;

	------------------------------------------------
	-- Motor ON -> Ready delay
	process(clk, reset_n, qd_ready, floppy_motor, tick_ms, motor_on_cnt ) begin
		if(reset_n = '0') then
			drive_ready <= '0';
			motor_on_cnt <= (others=>'0');
		elsif(clk'event and clk = '1') then

			if ( qd_mode = '1' )
			then
				drive_ready <= qd_ready;
			else
				drive_ready <= '0';

				if( floppy_motor = '1' )
				then
					if( motor_on_cnt < conv_std_logic_vector(400,32) )
					then
						if( tick_ms = '1')
						then
							motor_on_cnt <= motor_on_cnt + conv_std_logic_vector(1,32);
						end if;
					else
						drive_ready <= '1';
					end if;
				else
					motor_on_cnt <= (others=>'0');
				end if;
			end if;
		end if;
	end process;

	------------------------------------------------
	process(clk, reset_n, out_shifter_side0, out_shifter_side1  ) begin
		if(reset_n = '0') then
			fiforeadcnt <= (others=>'0');
			read_fifo_rq <= '0';
			write_fifo_wr <= '0';
			write_flag <= '0';

			out_shifter_side0 <= (others=>'0');
			out_shifter_side1 <= (others=>'0');
			out_index_shifter <= (others=>'0');
			out_qd_stopmotor_shifter <= (others=>'0');

			out_address_q1 <= (others=>'0');
			out_address_q2 <= (others=>'0');

			clock_div <= '0';
			floppy_write_data_q1 <= '0';
			led2_out <= '0';

		elsif(clk'event and clk = '1') then

			read_fifo_rq <= '0';
			write_fifo_wr <= '0';

			if(reset_state = '1')
			then
				clock_div <= '0';
				floppy_write_data_q1 <= '0';
				fiforeadcnt <= (others=>'0');

				out_shifter_side0 <= (others=>'0');
				out_shifter_side1 <= (others=>'0');
				out_index_shifter <= (others=>'0');
				out_qd_stopmotor_shifter <= (others=>'0');
				out_address_q1 <= (others=>'0');
				out_address_q2 <= (others=>'0');
			else

				clock_div <= not(clock_div);

				floppy_write_data_q1 <= floppy_write_data;

				if( clock_div = '1' and drive_motor = '1' )
				then

					fiforeadcnt <= fiforeadcnt + "000001";

					out_shifter_side0 <= out_shifter_side0(31 downto 0) & '0';
					out_shifter_side1 <= out_shifter_side1(31 downto 0) & '0';
					noise_gen_signal  <= weakbit_noise_sig;

					out_index_shifter <= out_index_shifter(30 downto 0) & '0';
					out_qd_stopmotor_shifter <= out_qd_stopmotor_shifter(30 downto 0) & '0';

					in_shifter_side0 <= in_shifter_side0(14 downto 0) & write_stream_side0;
					in_shifter_side1 <= in_shifter_side1(14 downto 0) & write_stream_side1;

					if(floppy_write_gate = '1' and floppy_select = '1' and write_protect_state = '0')
					then
						write_flag <= '1';
						led2_out <= '1';
					else
						led2_out <= '0';
					end if;

					if( fiforeadcnt = "001111" )
					then
						fiforeadcnt <= (others=>'0');

						out_shifter_side0(15 downto 0) <= read_fifo_data(15 downto  0);
						out_shifter_side1(15 downto 0) <= read_fifo_data(31 downto 16);

						out_address_q1 <= read_fifo_data(63 downto 32);
						out_address_q2 <= out_address_q1;

						if( read_fifo_data(64) = '1')
						then
							out_index_shifter(15 downto 0) <= (others=>'1');
						else
							out_index_shifter(15 downto 0) <= (others=>'0');
						end if;

						if( read_fifo_data(65) = '1')
						then
							out_qd_stopmotor_shifter(15 downto 0) <= (others=>'1');
						else
							out_qd_stopmotor_shifter(15 downto 0) <= (others=>'0');
						end if;

						if(write_flag = '1')
						then
							write_fifo_wr <= '1';
							write_fifo_data <= "00000000" & out_address_q2 & in_shifter_side1 & in_shifter_side0;
						end if;

						write_flag <= '0';

						read_fifo_rq <='1';
					end if;

				end if;
			end if;
		end if;
	end process;

	process(clk, reset_n ) begin
		if(reset_n = '0') then
			floppy_data_rd <= '0';
			data_pulse_cnt <= (others=>'0');
		elsif(clk'event and clk = '1') then

			floppy_data_rd <= '0';

			if(reset_state = '1')
			then

				data_pulse_cnt <= (others=>'0');

			else

				if( data_pulse_cnt < "00001010" )
				then
					floppy_data_rd <= '1';
				end if;

				if( floppy_side1 = '1' )
				then
					if( ( out_shifter_side1(31) = '1' and out_shifter_side1(32) = '0' and out_shifter_side1(30) = '0' ) or
					    ( out_shifter_side1(31) = '1' and ( out_shifter_side1(32) = '1' or out_shifter_side1(30) = '1' ) and noise_gen_signal = '1' ) )
					then
						data_pulse_cnt <= (others=>'0');
					else
						if( data_pulse_cnt /= "11111111" )
						then
							data_pulse_cnt <= data_pulse_cnt + "00000001";
						end if;
					end if;
				else

					if( ( out_shifter_side0(31) = '1' and out_shifter_side0(32) = '0' and out_shifter_side0(30) = '0' ) or
					    ( out_shifter_side0(31) = '1' and ( out_shifter_side0(32) = '1' or out_shifter_side0(30) = '1' ) and noise_gen_signal = '1' ) )
					then
						data_pulse_cnt <= (others=>'0');
					else
						if( data_pulse_cnt /= "11111111" )
						then
							data_pulse_cnt <= data_pulse_cnt + "00000001";
						end if;
					end if;
				end if;

			end if;
		end if;
	end process;

floppy_read_fifo_data: fifo_floppy_read
	Port map(
		clock => clk,
		data =>  pop_fifo_in_databus_b.pop_fifo_in_data,
		rdreq => read_fifo_rq,
		sclr => reset_state,
		wrreq => pop_fifo_in_ctrlbus_b.pop_fifo_in_wr,
		almost_full => pop_fifo_in_statusbus_b.pop_fifo_almostfull,
		empty => pop_fifo_in_statusbus_b.pop_fifo_empty,
		full => pop_fifo_in_statusbus_b.pop_fifo_full,
		q => read_fifo_data(31 downto 0),
		usedw => open
	);

floppy_read_fifo_address: fifo_floppy_read
	Port map(
		clock => clk,
		data =>  pop_fifo_in_databus_b.pop_fifo_in_address,
		rdreq => read_fifo_rq,
		sclr => reset_state,
		wrreq => pop_fifo_in_ctrlbus_b.pop_fifo_in_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => read_fifo_data(63 downto 32),
		usedw => open
	);

status_fifo_read: status_fifo
	Port map(
		clock => clk,
		data =>  pop_fifo_in_status_byte,-- & qd_stopmotor_state & index_state,!!!
		rdreq => read_fifo_rq,
		sclr => reset_state,
		wrreq => pop_fifo_in_ctrlbus_b.pop_fifo_in_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => read_fifo_data(71 downto 64),
		usedw => open
	);

floppy_write_fifo_data: fifo_floppy_read
	Port map(
		clock => clk,
		data =>  write_fifo_data(31 downto 0),
		rdreq => push_fifo_out_ctrlbus_b.push_fifo_out_rq,
		sclr => reset_state,
		wrreq => write_fifo_wr,
		almost_full => open,
		empty => push_fifo_out_statusbus_b.push_fifo_empty,
		full => push_fifo_out_statusbus_b.push_fifo_full,
		q => push_fifo_out_databus_b.push_fifo_out_data,
		usedw => push_fifo_out_statusbus_b.push_fifo_usedw
	);

floppy_write_fifo_address: fifo_floppy_read
	Port map(
		clock => clk,
		data =>  write_fifo_data(63 downto 32),
		rdreq => push_fifo_out_ctrlbus_b.push_fifo_out_rq,
		sclr => reset_state,
		wrreq => write_fifo_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => push_fifo_out_databus_b.push_fifo_out_address,
		usedw => open
	);

floppy_write_fifo_status: status_fifo
	Port map(
		clock => clk,
		data =>  write_fifo_data(71 downto 64),
		rdreq => push_fifo_out_ctrlbus_b.push_fifo_out_rq,
		sclr => reset_state,
		wrreq => write_fifo_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => push_fifo_out_databus_b.push_fifo_out_status,
		usedw => open
	);

end arch;
