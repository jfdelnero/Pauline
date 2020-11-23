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
-- File name      : floppy_dumper.vhd
--
-- Purpose        : floppy drive dumper simulator.
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

entity floppy_dumper is
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		pop_fifo_in_databus_b     : in pop_fifo_in_databus;
		pop_fifo_in_ctrlbus_b     : in pop_fifo_in_ctrlbus;
		pop_fifo_in_statusbus_b   : out pop_fifo_in_statusbus;

		push_fifo_out_databus_b   : out push_fifo_out_databus;
		push_fifo_out_ctrlbus_b   : in push_fifo_out_ctrlbus;
		push_fifo_out_statusbus_b : out push_fifo_out_statusbus;

		write_fifo_cur_track_base : out std_logic_vector(31 downto 0);

		buffer_base_address       : in std_logic_vector (31 downto 0);
		buffer_size               : in std_logic_vector (31 downto 0);

		reset_state               : in std_logic;
		stop                      : in std_logic;

		fast_capture_sig          : in std_logic;
		slow_capture_bus          : in std_logic_vector(15 downto 0);
		trigger_capture_sig       : in std_logic;

		floppy_write_gate         : out std_logic;
		floppy_write_data         : out std_logic;

		sample_rate_divisor       : in  std_logic;

		enable_dump               : in  std_logic;
		start_write               : in  std_logic;

		timeout_value             : in std_logic_vector (31 downto 0);
		delay_value               : in std_logic_vector (31 downto 0);
		ignore_index_trigger      : in std_logic;
		timeout                   : out std_logic
		);
end floppy_dumper;

architecture arch of floppy_dumper is

signal rd_fifo_full : std_logic;
signal fiforeadcnt : std_logic_vector(5 downto 0);

signal out_shifter_side0 : std_logic_vector(31 downto 0);

signal out_address_q1 : std_logic_vector(31 downto 0);
signal out_address_q2 : std_logic_vector(31 downto 0);

signal out_status_q1 : std_logic_vector(7 downto 0);
signal out_status_q2 : std_logic_vector(7 downto 0);

signal in_shifter_side0 : std_logic_vector(15 downto 0);
signal in_ios_state : std_logic_vector(15 downto 0);

signal data_pulse_cnt : std_logic_vector(7 downto 0);

signal floppy_data_wr : std_logic;

signal write_flag : std_logic;

signal read_stream_side0 : std_logic;

signal clock_div : std_logic;

signal drive_ready : std_logic;

signal drive_head_step : std_logic;

signal step_sound : std_logic;

signal motor_on_cnt : std_logic_vector(31 downto 0);

signal write_enabled : std_logic;

signal write_fifo_data : std_logic_vector(71 downto 0);
signal read_fifo_data : std_logic_vector(71 downto 0);

signal read_fifo_wr : std_logic;
signal write_fifo_rq : std_logic;

signal pop_fifo_empty : std_logic;

signal pop_fifo_data_valid_q1 : std_logic;
signal pop_fifo_data_valid_q2 : std_logic;
signal pop_fifo_data_valid_q3 : std_logic;

signal index_trigger_signal : std_logic;
signal index_timeout_signal : std_logic;

signal pre_charged_state : std_logic;
signal pre_charged_state_q1 : std_logic;
signal pre_charged_state_q2 : std_logic;

component fifo_floppy_read
	port
	(
		clock       : IN STD_LOGIC ;
		data        : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdreq       : IN STD_LOGIC ;
		sclr        : IN STD_LOGIC ;
		wrreq       : IN STD_LOGIC ;
		almost_full     : OUT STD_LOGIC ;
		empty       : OUT STD_LOGIC ;
		full        : OUT STD_LOGIC ;
		q       : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
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
		almost_full     : OUT STD_LOGIC ;
		empty       : OUT STD_LOGIC ;
		full        : OUT STD_LOGIC ;
		q       : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		usedw       : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
end component;

component floppy_trigger
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
end component;

begin

	floppy_write_data <= floppy_data_wr;

	write_fifo_cur_track_base <= buffer_base_address;

	timeout <= index_timeout_signal;

	------------------------------------------------
	process(clk, reset_n ) begin
		if(reset_n = '0') then
			fiforeadcnt <= (others=>'0');
			write_fifo_rq <= '0';
			read_fifo_wr <= '0';
			write_flag <= '0';

			out_shifter_side0 <= (others=>'0');

			out_address_q1 <= (others=>'0');
			out_address_q2 <= (others=>'0');

			out_status_q1 <= (others=>'0');
			out_status_q2 <= (others=>'0');

			clock_div <= '0';

			write_enabled <= '0';

			pop_fifo_data_valid_q1 <= '0';
			pop_fifo_data_valid_q2 <= '0';
			pop_fifo_data_valid_q3 <= '0';

			pre_charged_state_q1 <= '0';
			pre_charged_state_q2 <= '0';

			in_ios_state <= (others=>'0');
			pre_charged_state <= '0';

		elsif(clk'event and clk = '1') then

			read_stream_side0 <= fast_capture_sig;

			write_fifo_rq <= '0';
			read_fifo_wr <= '0';

			if(reset_state = '1')
			then
				clock_div <= '0';
				fiforeadcnt <= (others=>'0');

				pop_fifo_data_valid_q1 <= '0';
				pop_fifo_data_valid_q2 <= '0';
				pop_fifo_data_valid_q3 <= '0';

				pre_charged_state_q1 <= '0';
				pre_charged_state_q2 <= '0';

				out_shifter_side0 <= (others=>'0');

				out_address_q1 <= (others=>'0');
				out_address_q2 <= (others=>'0');

				out_status_q1 <= (others=>'0');
				out_status_q2 <= (others=>'0');

				write_flag <= '0';

				in_ios_state <= slow_capture_bus;

				write_enabled <= '0';

				pre_charged_state <= '0';

			else

				clock_div <= not(clock_div);

				if( (clock_div = '1' or sample_rate_divisor = '0') and (enable_dump = '1' or write_enabled = '1') and (stop = '0') and ( index_trigger_signal = '1' or ignore_index_trigger = '1') )
				then

					fiforeadcnt <= fiforeadcnt + "000001";

					out_shifter_side0 <= out_shifter_side0(30 downto 0) & '0';

					if(sample_rate_divisor = '0')
					then
						in_shifter_side0 <= in_shifter_side0(14 downto 0) & (read_stream_side0);
					else
						in_shifter_side0 <= in_shifter_side0(14 downto 0) & (read_stream_side0 or fast_capture_sig);
					end if;

					if(enable_dump = '1' or start_write = '1')
					then
						write_flag <= '1';
					end if;

					if( fiforeadcnt = "001111" )
					then
						fiforeadcnt <= (others=>'0');

						out_shifter_side0(15 downto 0) <= write_fifo_data(15 downto  0);

						pop_fifo_data_valid_q1 <= not(pop_fifo_empty);
						pop_fifo_data_valid_q2 <= pop_fifo_data_valid_q1;
						pop_fifo_data_valid_q3 <= pop_fifo_data_valid_q2;

						pre_charged_state_q1 <= pre_charged_state;
						pre_charged_state_q2 <= pre_charged_state_q1;

						out_address_q1 <= write_fifo_data(63 downto 32);
						out_address_q2 <= out_address_q1;

						out_status_q1 <= write_fifo_data(71 downto 64);
						out_status_q2 <= out_status_q1;

						if(pre_charged_state_q2 = '1' and write_flag = '1' and pop_fifo_data_valid_q2 = '1' and out_status_q2(0) = '0')
						then
							read_fifo_wr <= '1';
						end if;

						read_fifo_data <= "00000000" & out_address_q2 & slow_capture_bus & in_shifter_side0;

						in_ios_state <= slow_capture_bus;

						write_flag <= '0';

						if(pop_fifo_empty = '0')
						then
							pre_charged_state <= '1';
							write_fifo_rq <='1';
						end if;

					end if;

				end if;
			end if;
		end if;
	end process;

	process(clk, reset_n ) begin
		if(reset_n = '0') then
			floppy_data_wr <= '0';
			data_pulse_cnt <= (others=>'0');
		elsif(clk'event and clk = '1') then

			floppy_write_gate <= '0';
			if(write_enabled = '1' and stop = '0')
			then
				floppy_write_gate <= '1';
			end if;

			floppy_data_wr <= '0';

			if(reset_state = '1' or stop = '1')
			then
				data_pulse_cnt <= (others=>'0');
				floppy_write_gate <= '0';
			else
				if( data_pulse_cnt < "00001010" )
				then
					if(write_enabled = '1')
					then
						floppy_data_wr <= '1';
					end if;
				end if;

				if( out_shifter_side0(31) = '1' )
				then
					data_pulse_cnt <= (others=>'0');
				else
					if( data_pulse_cnt /= "11111111" )
					then
						data_pulse_cnt <= data_pulse_cnt + conv_std_logic_vector(1,8);
					end if;
				end if;

			end if;
		end if;
	end process;

index_trigger : floppy_trigger
	port map(
		clk          => clk,
		reset_n      => reset_n,

		signal_in    => trigger_capture_sig,
		signal_out   => index_trigger_signal,

		timeout_out  => index_timeout_signal,

		delay        => delay_value,

		timeout      => timeout_value,

		invert       => '0',

		pulse_out_mode => '0',

		rising_edge  => '1',
		falling_edge => '0',

		clear_event  => (reset_state or ignore_index_trigger)
		);

floppy_read_fifo_data: fifo_floppy_read
	Port map(
		clock        => clk,
		data         => pop_fifo_in_databus_b.pop_fifo_in_data,
		rdreq        => write_fifo_rq,
		sclr         => reset_state,
		wrreq        => pop_fifo_in_ctrlbus_b.pop_fifo_in_wr,
		almost_full  => pop_fifo_in_statusbus_b.pop_fifo_almostfull,
		empty        => pop_fifo_empty,
		full         => pop_fifo_in_statusbus_b.pop_fifo_full,
		q            => write_fifo_data(31 downto 0),
		usedw        => open
	);

floppy_read_fifo_address: fifo_floppy_read
	Port map(
		clock => clk,
		data =>  pop_fifo_in_databus_b.pop_fifo_in_address,
		rdreq => write_fifo_rq,
		sclr => reset_state,
		wrreq => pop_fifo_in_ctrlbus_b.pop_fifo_in_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => write_fifo_data(63 downto 32),
		usedw => open
	);

status_fifo_read: status_fifo
	Port map(
		clock => clk,
		data =>  pop_fifo_in_databus_b.pop_fifo_in_status, -- "00000000",-- & qd_stopmotor_state & index_state,!!!
		rdreq => write_fifo_rq,
		sclr => reset_state,
		wrreq => pop_fifo_in_ctrlbus_b.pop_fifo_in_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => write_fifo_data(71 downto 64),
		usedw => open
	);

floppy_write_fifo_data: fifo_floppy_read
	Port map(
		clock => clk,
		data =>  read_fifo_data(31 downto 0),
		rdreq => push_fifo_out_ctrlbus_b.push_fifo_out_rq,
		sclr => reset_state,
		wrreq => read_fifo_wr,
		almost_full => open,
		empty => push_fifo_out_statusbus_b.push_fifo_empty,
		full => push_fifo_out_statusbus_b.push_fifo_full,
		q => push_fifo_out_databus_b.push_fifo_out_data,
		usedw => push_fifo_out_statusbus_b.push_fifo_usedw
	);

floppy_write_fifo_address: fifo_floppy_read
	Port map(
		clock => clk,
		data =>  read_fifo_data(63 downto 32),
		rdreq => push_fifo_out_ctrlbus_b.push_fifo_out_rq,
		sclr => reset_state,
		wrreq => read_fifo_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => push_fifo_out_databus_b.push_fifo_out_address,
		usedw => open
	);

floppy_write_fifo_status: status_fifo
	Port map(
		clock => clk,
		data =>  read_fifo_data(71 downto 64),
		rdreq => push_fifo_out_ctrlbus_b.push_fifo_out_rq,
		sclr => reset_state,
		wrreq => read_fifo_wr,
		almost_full => open,
		empty => open,
		full => open,
		q => push_fifo_out_databus_b.push_fifo_out_status,
		usedw => open
	);

end arch;
