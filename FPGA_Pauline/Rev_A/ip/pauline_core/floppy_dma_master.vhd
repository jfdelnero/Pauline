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
-- File name      : floppy_interface.vhd
--
-- Purpose        : floppy drive instances.
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

library work;
use work.floppy_lib_package.all;

--
-- Fifo size : 4096 words  ->
-- 4096 words @ (50Mhz/2)/16 bits shifter =  640ns * 4096 = 2,62 ms
--
-- Burst size : 128 Word -> 512 bytes
-- 128 word @ (50Mhz/2)/16 bits shifter =  640ns * 128 = 81,920 us
--
-- "almost full" value : 4096 - 128 = 3968
--

entity floppy_dma_master is
	port(
		csi_ci_Clk : in std_logic;
		csi_ci_Reset_n : in std_logic;

		avm_m1_address : out std_logic_vector (31 downto 0);
		avm_m1_readdata : in std_logic_vector (31 downto 0);
		avm_m1_read : out std_logic;
		avm_m1_write : out std_logic;
		avm_m1_writedata : out std_logic_vector (31 downto 0);
		avm_m1_waitrequest : in std_logic;
		avm_m1_readdatavalid : in std_logic;
		avm_m1_byteenable : out std_logic_vector (3 downto 0);
		avm_m1_burstcount : out std_logic_vector (7 downto 0);

		images_base_address : in lword_array;
		images_track_size : in lword_array;
		drv_cur_track_base_address : in lword_array;
		drv_cur_track_offsets : out lword_array;

		enable_drives : in std_logic_vector (4 downto 0);
		continuous_mode : in std_logic_vector (4 downto 0);
		done : out std_logic_vector (4 downto 0);

		pop_fifos_in_databus_if : out pop_fifos_in_databus;
		pop_fifos_in_ctrlbus_if : out pop_fifos_in_ctrlbus;
		pop_fifos_in_statusbus_if : in pop_fifos_in_statusbus;

		push_fifos_out_databus_if : in push_fifos_out_databus;
		push_fifos_out_ctrlbus_if : out push_fifos_out_ctrlbus;
		push_fifos_out_statusbus_if : in push_fifos_out_statusbus;

		pop_fifo_empty_events : out lword_array;
		push_fifo_full_events : out lword_array;

		reset_drives : in std_logic_vector (4 downto 0)
		);
end floppy_dma_master;

architecture arch of floppy_dma_master is

type   state_type_master is ( state_master_wait_write,state_master_wait_write2,state_master_wait_read,state_master_wait_read2, state_master_idle);
signal state_master_register : state_type_master;

signal writedata : std_logic_vector(31 downto 0);
signal busaddress : std_logic_vector(31 downto 0);

signal drv_cur_track_address : lword_array;

signal read_wrrq_delay: std_logic;

signal address_offsets : lword_array;

signal drive_index : integer range 0 to 15;

signal fifos_in_almostfull_index : integer range 0 to 15;
signal fifos_out_empty_index : integer range 0 to 15;

signal fifos_in_allfull : std_logic;
signal filos_out_allempty : std_logic;

signal burst_count: std_logic_vector(7 downto 0);

signal done_q: std_logic_vector(4 downto 0);

signal pop_fifo_empty_events_q : lword_array;
signal previous_empty_events_state: std_logic_vector(4 downto 0);

signal push_fifo_full_events_q : lword_array;
signal previous_full_events_state: std_logic_vector(4 downto 0);

signal burst_size : std_logic_vector(31 downto 0);

begin

	avm_m1_address <= busaddress;
	avm_m1_writedata <= writedata;
	avm_m1_byteenable <= "1111";
	drv_cur_track_offsets <= address_offsets;
	done <= done_q;
	pop_fifo_empty_events <= pop_fifo_empty_events_q;
	push_fifo_full_events <= push_fifo_full_events_q;

	burst_size <= images_track_size(drive_index) - conv_std_logic_vector(512,32);

	process(csi_ci_Clk, csi_ci_Reset_n, pop_fifos_in_statusbus_if, enable_drives, done_q ) begin
		if(csi_ci_Reset_n = '0') then

			fifos_in_almostfull_index <= 0;
			fifos_in_allfull <= '1';

		elsif(csi_ci_Clk 'event and csi_ci_Clk  = '1') then

			if( pop_fifos_in_statusbus_if(0).pop_fifo_almostfull = '0' and enable_drives(0) = '1' and done_q(0) = '0' )
			then
				fifos_in_almostfull_index <= 0;
				fifos_in_allfull <= '0';
			elsif( pop_fifos_in_statusbus_if(1).pop_fifo_almostfull = '0' and enable_drives(1) = '1' and done_q(1) = '0' )
			then
				fifos_in_almostfull_index <= 1;
				fifos_in_allfull <= '0';
			elsif( pop_fifos_in_statusbus_if(2).pop_fifo_almostfull = '0' and enable_drives(2) = '1' and done_q(2) = '0' )
			then
				fifos_in_almostfull_index <= 2;
				fifos_in_allfull <= '0';
			elsif( pop_fifos_in_statusbus_if(3).pop_fifo_almostfull = '0' and enable_drives(3) = '1' and done_q(3) = '0' )
			then
				fifos_in_almostfull_index <= 3;
				fifos_in_allfull <= '0';
			elsif( pop_fifos_in_statusbus_if(4).pop_fifo_almostfull = '0' and enable_drives(4) = '1' and done_q(4) = '0' )
			then
				fifos_in_almostfull_index <= 4;
				fifos_in_allfull <= '0';
			else
				fifos_in_almostfull_index <= 0;
				fifos_in_allfull <= '1';
			end if;
		end if;
	end process;


	process(csi_ci_Clk, csi_ci_Reset_n, push_fifos_out_statusbus_if, enable_drives, done_q, reset_drives ) begin
		if(csi_ci_Reset_n = '0') then

			filos_out_allempty <= '1';
			fifos_out_empty_index <= 0;

		elsif(csi_ci_Clk 'event and csi_ci_Clk  = '1') then

			if( push_fifos_out_statusbus_if(0).push_fifo_empty = '0' and enable_drives(0) = '1' and done_q(0) = '0' and reset_drives(0) = '0')
			then
				fifos_out_empty_index <= 0;
				filos_out_allempty <= '0';
			elsif( push_fifos_out_statusbus_if(1).push_fifo_empty = '0' and enable_drives(1) = '1' and done_q(1) = '0' and reset_drives(1) = '0')
			then
				fifos_out_empty_index <= 1;
				filos_out_allempty <= '0';
			elsif( push_fifos_out_statusbus_if(2).push_fifo_empty = '0' and enable_drives(2) = '1' and done_q(2) = '0' and reset_drives(2) = '0')
			then
				fifos_out_empty_index <= 2;
				filos_out_allempty <= '0';
			elsif( push_fifos_out_statusbus_if(3).push_fifo_empty = '0' and enable_drives(3) = '1' and done_q(3) = '0' and reset_drives(3) = '0')
			then
				fifos_out_empty_index <= 3;
				filos_out_allempty <= '0';
			elsif( push_fifos_out_statusbus_if(4).push_fifo_empty = '0' and enable_drives(4) = '1' and done_q(4) = '0' and reset_drives(4) = '0')
			then
				fifos_out_empty_index <= 4;
				filos_out_allempty <= '0';
			else
				fifos_out_empty_index <= 0;
				filos_out_allempty <= '1';
			end if;
		end if;
	end process;

	process(csi_ci_Clk, csi_ci_Reset_n ) begin
		if(csi_ci_Reset_n = '0') then

			state_master_register <= state_master_idle;

			busaddress <= conv_std_logic_vector(900*1024*1024,32); -- 900MB
			writedata <= "10101010101010101010101000000000";
			avm_m1_read <= '0';
			avm_m1_write <= '0';

			drive_index <= 0;

			for i in 0 to 4 loop
				drv_cur_track_address(i) <= (others=>'0');
				address_offsets(i) <= (others=>'0');
				pop_fifos_in_ctrlbus_if(i).pop_fifo_in_wr <= '0';
				push_fifos_out_ctrlbus_if(i).push_fifo_out_rq <= '0';
				pop_fifos_in_databus_if(i).pop_fifo_in_address <= (others=>'0');
				pop_fifos_in_databus_if(i).pop_fifo_in_data <= (others=>'0');
				pop_fifos_in_databus_if(i).pop_fifo_in_status <= (others=>'0');
				done_q(i) <= '0';
			end loop;

			read_wrrq_delay <= '0';
			avm_m1_burstcount <= (others=>'0');

			burst_count  <= (others=>'0');

		elsif(csi_ci_Clk 'event and csi_ci_Clk  = '1') then

			for i in 0 to 4 loop
				pop_fifos_in_ctrlbus_if(i).pop_fifo_in_wr <= '0';
				push_fifos_out_ctrlbus_if(i).push_fifo_out_rq <= '0';
			end loop;

			avm_m1_read <= '0';
			avm_m1_write <= '0';

			for i in 0 to 4 loop
				if(enable_drives(i) = '0')
				then
					done_q(i) <= '0';
				end if;
			end loop;

			case state_master_register is

				when state_master_idle =>

					for i in 0 to 4 loop
						pop_fifos_in_ctrlbus_if(i).pop_fifo_in_wr <= '0';
						push_fifos_out_ctrlbus_if(i).push_fifo_out_rq <= '0';
					end loop;

					avm_m1_read <= '0';
					avm_m1_write <= '0';
					read_wrrq_delay <= '0';

					if( enable_drives(0) = '1' or enable_drives(1) = '1' or enable_drives(2) = '1' or enable_drives(3) = '1' or enable_drives(4) = '1' )
					then
						if( fifos_in_allfull = '0' )
						then
							drive_index <= fifos_in_almostfull_index;
							state_master_register <= state_master_wait_read;
						elsif( filos_out_allempty = '0' )
						then
							push_fifos_out_ctrlbus_if(fifos_out_empty_index).push_fifo_out_rq <= '1';
							drive_index <= fifos_out_empty_index;

							state_master_register <= state_master_wait_write;
						end if;
					else
						state_master_register <= state_master_idle;
					end if;

-------------------------------------------------------------------------------------------

				when state_master_wait_write =>

					writedata <=  push_fifos_out_databus_if(drive_index).push_fifo_out_data;
					busaddress <= push_fifos_out_databus_if(drive_index).push_fifo_out_address;
					avm_m1_burstcount <= "00000001";
					avm_m1_write <= '1';
					read_wrrq_delay <= '1';

					--if(push_fifos_out_statusbus_if(drive_index).push_fifo_usedw > "000010000000")
					--then
					--	avm_m1_burstcount <= "10000000";
					--	burst_count  <= "01111111";
					--else
					--	avm_m1_burstcount <= "00000001";
					--	burst_count  <= "01111111";
					--end if;

					--avm_m1_write <= '1';

					state_master_register <= state_master_wait_write2;

				when state_master_wait_write2 =>
					avm_m1_burstcount <= conv_std_logic_vector(1,8);
					avm_m1_write <= '1';

					if ( avm_m1_waitrequest = '0' )
					then
						avm_m1_write <= '0';
						state_master_register <= state_master_idle;
					end if;

-------------------------------------------------------------------------------------------

				when state_master_wait_read =>

					busaddress <= drv_cur_track_address(drive_index);

					if( drive_index /= 4) then
					avm_m1_read <= '1';
					end if;

					read_wrrq_delay <= '1';

					if( address_offsets(drive_index) < ( images_track_size(drive_index) - conv_std_logic_vector(512,32) ) ) --and pop_fifos_in_statusbus_if(drive_index).pop_fifo_almostfull = '0')
					then
						avm_m1_burstcount <= conv_std_logic_vector(128,8);
						burst_count  <= conv_std_logic_vector(127,8);
					else
						avm_m1_burstcount <= burst_size(9 downto 2) + conv_std_logic_vector(1,8);
						burst_count  <= burst_size(9 downto 2);
					end if;

					if( (read_wrrq_delay = '1' and avm_m1_waitrequest ='0' ) or (drive_index = 4) )
					then
						state_master_register <= state_master_wait_read2;
					end if;

					if (reset_drives(drive_index) = '1')
					then
						state_master_register <= state_master_idle;
					end if;

				when state_master_wait_read2 =>

					if ( avm_m1_readdatavalid = '1' or (drive_index = 4) )
					then
						pop_fifos_in_databus_if(drive_index).pop_fifo_in_address <= drv_cur_track_address(drive_index);
						if( (drive_index = 4) ) then
							pop_fifos_in_databus_if(drive_index).pop_fifo_in_data <= (others=>'0');
						else
							pop_fifos_in_databus_if(drive_index).pop_fifo_in_data <= avm_m1_readdata;
						end if;
						pop_fifos_in_databus_if(drive_index).pop_fifo_in_status <= "00000000"; --
						pop_fifos_in_ctrlbus_if(drive_index).pop_fifo_in_wr <= '1';

						if( address_offsets(drive_index) >= images_track_size(drive_index) )
						then
							if(continuous_mode(drive_index) = '1')
							then
								address_offsets(drive_index) <= (others=>'0');
								drv_cur_track_address(drive_index) <= drv_cur_track_base_address(drive_index);
							else
								done_q(drive_index) <= '1';
								address_offsets(drive_index) <= images_track_size(drive_index);
								drv_cur_track_address(drive_index) <= drv_cur_track_base_address(drive_index) + images_track_size(drive_index);
							end if;
						else
							address_offsets(drive_index) <= address_offsets(drive_index) + conv_std_logic_vector(4,32);
							drv_cur_track_address(drive_index) <= drv_cur_track_address(drive_index) + conv_std_logic_vector(4,32);
						end if;

						burst_count <= burst_count - conv_std_logic_vector(1,8);

						if ( burst_count = conv_std_logic_vector(0,8) )
						then
							state_master_register <= state_master_idle;
						else
							state_master_register <= state_master_wait_read2;
						end if;

						if(done_q(drive_index) = '1')
						then
							state_master_register <= state_master_idle;
						end if;

						if( (drive_index = 4) ) then
							state_master_register <= state_master_idle;
						end if;

					end if;

					if (reset_drives(drive_index) = '1')
					then
						state_master_register <= state_master_idle;
					end if;

				when others =>
					state_master_register <= state_master_idle;

			end case;

			for i in 0 to 4 loop
				if( reset_drives(i) = '1' )
				then
					drv_cur_track_address(i) <= images_base_address(i);
					address_offsets(i) <= (others=>'0');
				end if;
			end loop;

		end if;
	end process;

GEN_POPFIFODBG: for i in 0 to 4 generate
	process(csi_ci_Clk, csi_ci_Reset_n ) begin
		if(csi_ci_Reset_n = '0') then
			pop_fifo_empty_events_q(i) <= (others=>'0');
			previous_empty_events_state(i) <= '1';
		elsif(csi_ci_Clk 'event and csi_ci_Clk  = '1') then
			if( (previous_empty_events_state(i) /= pop_fifos_in_statusbus_if(i).pop_fifo_empty) and pop_fifos_in_statusbus_if(i).pop_fifo_empty = '1' ) then
				pop_fifo_empty_events_q(i) <= pop_fifo_empty_events_q(i) + conv_std_logic_vector(1,32);
			end if;
			previous_empty_events_state(i) <= pop_fifos_in_statusbus_if(i).pop_fifo_empty;
		end if;
	end process;
end generate GEN_POPFIFODBG;

GEN_PUSHFIFODBG: for i in 0 to 4 generate
	process(csi_ci_Clk, csi_ci_Reset_n ) begin
		if(csi_ci_Reset_n = '0') then
			push_fifo_full_events_q(i) <= (others=>'0');
			previous_full_events_state(i) <= '1';
		elsif(csi_ci_Clk 'event and csi_ci_Clk  = '1') then
			if( (previous_full_events_state(i) /= push_fifos_out_statusbus_if(i).push_fifo_empty) and push_fifos_out_statusbus_if(i).push_fifo_empty = '1' ) then
				push_fifo_full_events_q(i) <= push_fifo_full_events_q(i) + conv_std_logic_vector(1,32);
			end if;
			previous_full_events_state(i) <= push_fifos_out_statusbus_if(i).push_fifo_empty;
		end if;
	end process;
end generate GEN_PUSHFIFODBG;

end arch;
