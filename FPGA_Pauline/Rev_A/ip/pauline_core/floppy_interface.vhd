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
use ieee.STD_LOGIC_ARITH.ALL;

library work;
use work.floppy_lib_package.all;

entity floppy_interface is
	port(
		csi_ci_Clk : in std_logic;
		csi_ci_Reset_n : in std_logic;

		avs_s1_write : in std_logic;
		avs_s1_read : in std_logic;
		avs_s1_byteenable : in std_logic_vector (3 downto 0);
		avs_s1_address : in std_logic_vector (6 downto 0);
		avs_s1_writedata : in std_logic_vector (31 downto 0);
		avs_s1_waitrequest : out std_logic;
		avs_s1_readdata : out std_logic_vector (31 downto 0);
		avs_s1_irq : out std_logic;

		avm_m1_address : out std_logic_vector (31 downto 0);
		avm_m1_readdata : in std_logic_vector (31 downto 0);
		avm_m1_read : out std_logic;
		avm_m1_write : out std_logic;
		avm_m1_writedata : out std_logic_vector (31 downto 0);
		avm_m1_waitrequest : in std_logic;
		avm_m1_readdatavalid : in std_logic;
		avm_m1_byteenable : out std_logic_vector (3 downto 0);
		avm_m1_burstcount : out std_logic_vector (7 downto 0);

		--------------------------------------
		-- User interface buttons/leds/buzzer
		--------------------------------------

		coe_c1_led1_out : out std_logic_vector(3 downto 0);
		coe_c1_led2_out : out std_logic_vector(3 downto 0);

		coe_c1_led1                        : out std_logic;
		coe_c1_led2                        : out std_logic;

		coe_c1_buzzer                      : out std_logic;

		coe_c1_pushbutton0                 : in  std_logic;
		coe_c1_pushbutton1                 : in  std_logic;
		coe_c1_pushbutton2                 : in  std_logic;

		----------------------------
		-- Host floppy port
		----------------------------

		coe_c1_host_o_pin02                : out std_logic;
		coe_c1_host_i_pin02                : in  std_logic;
		coe_c1_host_i_pin04                : in  std_logic;
		coe_c1_host_o_index                : out std_logic;
		coe_c1_host_i_sel                  : in  std_logic_vector(3 downto 0);
		coe_c1_host_i_motor                : in  std_logic;
		coe_c1_host_i_dir                  : in  std_logic;
		coe_c1_host_i_step                 : in  std_logic;
		coe_c1_host_i_write_data           : in  std_logic;
		coe_c1_host_i_write_gate           : in  std_logic;
		coe_c1_host_o_trk00                : out std_logic;
		coe_c1_host_o_wpt                  : out std_logic;
		coe_c1_host_o_data                 : out std_logic;
		coe_c1_host_i_side1                : in  std_logic;
		coe_c1_host_o_pin34                : out std_logic;
		coe_c1_host_i_x68000_sel           : in  std_logic_vector(3 downto 0);
		coe_c1_host_o_pin03                : out std_logic;
		coe_c1_host_i_x68000_eject         : in  std_logic;
		coe_c1_host_i_x68000_lock          : in  std_logic;
		coe_c1_host_i_x68000_ledblink      : in  std_logic;
		coe_c1_host_o_x68000_diskindrive   : out std_logic;
		coe_c1_host_o_x68000_insertfault   : out std_logic;
		coe_c1_host_o_x68000_int           : out std_logic;

		----------------------------
		-- Floppy drive port
		----------------------------

		coe_c1_floppy_i_pin02              : in  std_logic;
		coe_c1_floppy_o_pin02              : out std_logic;
		coe_c1_floppy_o_pin04              : out std_logic;
		coe_c1_floppy_i_index              : in  std_logic;
		coe_c1_floppy_o_sel                : out std_logic_vector(3 downto 0);
		coe_c1_floppy_o_motor              : out std_logic;
		coe_c1_floppy_o_dir                : out std_logic;
		coe_c1_floppy_o_step               : out std_logic;
		coe_c1_floppy_o_write_data         : out std_logic;
		coe_c1_floppy_o_write_gate         : out std_logic;
		coe_c1_floppy_i_trk00              : in  std_logic;
		coe_c1_floppy_i_wpt                : in  std_logic;
		coe_c1_floppy_i_data               : in  std_logic;
		coe_c1_floppy_o_side1              : out std_logic;
		coe_c1_floppy_i_pin34              : in  std_logic;
		coe_c1_floppy_o_x68000_sel         : out std_logic_vector(3 downto 0);
		coe_c1_floppy_i_pin03              : in  std_logic;
		coe_c1_floppy_o_x68000_eject       : out std_logic;
		coe_c1_floppy_o_x68000_lock        : out std_logic;
		coe_c1_floppy_o_x68000_ledblink    : out std_logic;
		coe_c1_floppy_i_x68000_diskindrive : in  std_logic;
		coe_c1_floppy_i_x68000_insertfault : in  std_logic;
		coe_c1_floppy_i_x68000_int         : in  std_logic;

		--------------------------------------
		-- Extra inputs / outputs
		--------------------------------------

		coe_c1_tris_io0_dout               : out std_logic;
		coe_c1_tris_io0_din                : in  std_logic;
		coe_c1_tris_io0_oe                 : out std_logic;

		coe_c1_tris_io1_dout               : out std_logic;
		coe_c1_tris_io1_din                : in  std_logic;
		coe_c1_tris_io1_oe                 : out std_logic;

		coe_c1_tris_io2_dout               : out std_logic;
		coe_c1_tris_io2_din                : in  std_logic;
		coe_c1_tris_io2_oe                 : out std_logic;

		coe_c1_tris_io3_dout               : out std_logic;
		coe_c1_tris_io3_din                : in  std_logic;
		coe_c1_tris_io3_oe                 : out std_logic;

		coe_c1_ext_io_dout                 : out std_logic;
		coe_c1_ext_io_din                  : in  std_logic;

		coe_c1_external_int                : in  std_logic

		);
end floppy_interface;

architecture arch of floppy_interface is

type state_type_read is ( wait_state_read, state_decodread, read_register);
signal state_read_register : state_type_read;

signal index_state : std_logic_vector(3 downto 0);
signal qd_stopmotor_state : std_logic;

signal control_reg : std_logic_vector(31 downto 0);

signal gpio_reg : std_logic_vector(31 downto 0);
signal gpio_oe_reg : std_logic_vector(31 downto 0);

signal images_max_track_regs : lword_array;
signal drives_config_regs : lword_array;
signal drives_track_index_start : lword_array;
signal drives_index_len : lword_array;
signal reset_drives: std_logic_vector(4 downto 0);

signal in_signal_polarity_reg : std_logic_vector(31 downto 0);
signal out_signal_polarity_reg : std_logic_vector(31 downto 0);

signal drv_track_trk00 : std_logic_vector(3 downto 0);
signal drv_data : std_logic_vector(3 downto 0);
signal drv_pin02 : std_logic_vector(3 downto 0);
signal drv_pin34 : std_logic_vector(3 downto 0);
signal drv_write_protect : std_logic_vector(3 downto 0);
signal drv_index : std_logic_vector(3 downto 0);

signal drv_option_diskindrive : std_logic_vector(3 downto 0);
signal drv_option_insertfault : std_logic_vector(3 downto 0);
signal drv_option_int : std_logic_vector(3 downto 0);

signal host_i_side1 : std_logic;
signal host_i_write_data_pulse : std_logic;
signal host_i_write_gate : std_logic;
signal host_i_selx : std_logic_vector(3 downto 0);
signal ext_io_selx_signal : std_logic;
signal host_i_motor : std_logic;
signal host_i_dir : std_logic;
signal host_i_step_pulse : std_logic;
signal host_i_step : std_logic;

signal host_i_dc_rst : std_logic;

signal host_i_x68000_sel : std_logic_vector(3 downto 0);
signal host_i_x68000_eject : std_logic;
signal host_i_x68000_lock : std_logic;
signal host_i_x68000_ledblink : std_logic;

signal host_drv0_qdstopmotor_len: std_logic_vector(31 downto 0);
signal host_drv0_qdstopmotor_start: std_logic_vector(31 downto 0);

signal host_sel_drive_unit: std_logic_vector(3 downto 0);
signal host_motor_drive_unit: std_logic_vector(3 downto 0);

signal ctrl_enable_dump : std_logic;
signal ctrl_enable_write : std_logic;

signal ctrl_sound_gpio : std_logic;

signal raw_in_io: std_logic_vector(5 downto 0);
signal filtered_i_io: std_logic_vector(5 downto 0);
signal invert_io_conf: std_logic_vector(31 downto 0);

signal floppy_port_glitch_filter : std_logic_vector(31 downto 0);
signal host_port_glitch_filter : std_logic_vector(31 downto 0);
signal io_port_glitch_filter : std_logic_vector(31 downto 0);

--
-- Floppy CTRL signals
--

signal floppy_i_trk00 : std_logic;
signal floppy_i_data  : std_logic;
signal floppy_i_wpt   : std_logic;
signal floppy_i_index : std_logic;
signal floppy_i_pin02 : std_logic;
signal floppy_i_pin34 : std_logic;
signal floppy_o_dir   : std_logic;
signal floppy_o_step  : std_logic;
signal floppy_o_write_gate : std_logic;
signal floppy_o_write_data : std_logic;

signal floppy_apple_stepper_phases : std_logic_vector(3 downto 0);
signal floppy_apple_motor_phase_pos : std_logic_vector(1 downto 0);

signal ctrl_control_reg : std_logic_vector(31 downto 0);
signal ctrl_steprate_reg : std_logic_vector(31 downto 0);
signal ctrl_track_reg : std_logic_vector(9 downto 0);
signal ctrl_curtrack_reg : std_logic_vector(9 downto 0);
signal ctrl_head_moving : std_logic;
signal ctrl_head_move_cmd : std_logic;
signal ctrl_head_move_dir : std_logic;
signal continuous_mode_reg : std_logic_vector(31 downto 0);
signal done_reg : std_logic_vector(4 downto 0);

signal drive_sound : std_logic_vector(3 downto 0);
signal ctrl_sound : std_logic;
signal snd_freq_out : std_logic;

signal dump_sample_rate_divisor : std_logic;

signal pop_fifos_in_databus_bus : pop_fifos_in_databus;
signal pop_fifos_in_ctrlbus_bus : pop_fifos_in_ctrlbus;
signal pop_fifos_in_statusbus_bus : pop_fifos_in_statusbus;

signal push_fifos_out_databus_bus : push_fifos_out_databus;
signal push_fifos_out_ctrlbus_bus : push_fifos_out_ctrlbus;
signal push_fifos_out_statusbus_bus : push_fifos_out_statusbus;

signal images_base_address_busses : lword_array;
signal images_track_size_busses : lword_array;
signal drv_cur_track_base_address_busses : lword_array;
signal drv_cur_track_offsets_busses : lword_array;
signal track_positions : lbyte_array;

signal pop_fifo_empty_events : lword_array;
signal push_fifo_full_events : lword_array;

signal in_mux_selectors_regs : muxsel_array;

signal dump_timeout : std_logic;

signal dump_timeout_value : std_logic_vector(31 downto 0);
signal dump_delay_value : std_logic_vector(31 downto 0);

signal floppy_ctrl_extraouts_reg : std_logic_vector(31 downto 0);

signal ignore_index_trigger : std_logic;

signal host_inputs_q1: std_logic_vector(31 downto 0);
signal host_inputs_q2: std_logic_vector(31 downto 0);
signal host_outputs: std_logic_vector(31 downto 0);
signal stream_mux_cfg: std_logic_vector(31 downto 0);

signal floppy_inputs_q1: std_logic_vector(31 downto 0);
signal floppy_inputs_q2: std_logic_vector(31 downto 0);
signal floppy_outputs: std_logic_vector(31 downto 0);

signal mux_out_bus : std_logic_vector(19 downto 0);

signal sound_period : std_logic_vector(31 downto 0);

signal step_signal_width : std_logic_vector(31 downto 0);
signal step_phases_width : std_logic_vector(31 downto 0);
signal step_phases_stop_width : std_logic_vector(31 downto 0);

component floppy_drive
	port(
		clk : in std_logic;
		reset_n : in std_logic;

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

		qd_mode                 : in std_logic;

		drive_sound             : out std_logic;

		led1_out                : out std_logic;
		led2_out                : out std_logic
	);
end component;

component floppy_dumper
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
end component;

component floppy_signal_filter
	port(
		clk                     : in std_logic;
		reset_n                 : in std_logic;

		signal_in               : in std_logic;
		signal_out              : out std_logic;

		filter_level            : in std_logic_vector (31 downto 0);

		invert                  : in std_logic;

		pulse_out_mode          : in std_logic;

		rising_edge             : in std_logic;
		falling_edge            : in std_logic

		);
end component;

component floppy_index_generator
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		track_length            : in std_logic_vector (31 downto 0);

		index_length            : in std_logic_vector (31 downto 0);

		start_track_index       : in std_logic_vector (31 downto 0);

		current_position        : in std_logic_vector (31 downto 0);

		index_out               : out std_logic
		);
end component;

component floppy_select_mux
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
end component;

component floppy_ctrl_stepper
	port (
		clk : in std_logic;
		reset_n : in std_logic;

		floppy_ctrl_step        : out std_logic;
		floppy_ctrl_dir         : out std_logic;
		floppy_ctrl_trk00       : in std_logic;

		floppy_motor_phases     : out std_logic_vector (3 downto 0);
		motor_phases_cnt_vector : out std_logic_vector (1 downto 0);

		step_rate               : in  std_logic_vector (31 downto 0);
		step_width              : in  std_logic_vector (15 downto 0);

		phases_timeout_moving   : in  std_logic_vector (31 downto 0);
		phases_timeout_stopping : in  std_logic_vector (31 downto 0);

		track_pos_cmd           : in  std_logic_vector (9 downto 0);
		move_head_cmd           : in  std_logic;
		move_dir                : in  std_logic;

		cur_track_pos           : out std_logic_vector (9 downto 0);

		moving                  : out std_logic;

		sound                   : out std_logic
		);
end component;

component floppy_dma_master
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
end component;

component gen_mux
	generic (SEL_WIDTH : INTEGER);
port(

	inputs      : in  std_logic_vector((2**SEL_WIDTH)-1 downto 0);
	sel         : in  std_logic_vector(SEL_WIDTH - 1 downto 0);
	out_signal  : out std_logic
	);
end component;

component floppy_sound
	port(
		clk      : in std_logic;
		reset_n  : in std_logic;

		step_sound              : in  std_logic;

		period                  : in  std_logic_vector(31 downto 0);

		sound_out               : out std_logic
		);
end component;

begin

	ctrl_enable_dump <= ctrl_control_reg(20);
	ctrl_enable_write <= ctrl_control_reg(21);
	dump_sample_rate_divisor <= ctrl_control_reg(22);
	ignore_index_trigger <= ctrl_control_reg(23);

	process(in_mux_selectors_regs ,gpio_reg ,mux_out_bus )
	begin

		if( in_mux_selectors_regs(18)(4 downto 0) = "00000")
		then
			coe_c1_led1 <= gpio_reg(0);
		else
			coe_c1_led1 <= mux_out_bus(18);
		end if;

		if( in_mux_selectors_regs(19)(4 downto 0) = "00000")
		then
			coe_c1_led2 <= gpio_reg(1);
		else
			coe_c1_led2 <= mux_out_bus(19);
		end if;

	end process;

	coe_c1_tris_io0_dout <= gpio_reg(2);
	coe_c1_tris_io1_dout <= gpio_reg(3);
	coe_c1_tris_io2_dout <= gpio_reg(4);
	coe_c1_tris_io3_dout <= gpio_reg(5);

	coe_c1_ext_io_dout <= gpio_reg(6);

	ctrl_sound_gpio <= gpio_reg(7);

	coe_c1_tris_io0_oe <= not(gpio_oe_reg(2));
	coe_c1_tris_io1_oe <= not(gpio_oe_reg(3));
	coe_c1_tris_io2_oe <= not(gpio_oe_reg(4));
	coe_c1_tris_io3_oe <= not(gpio_oe_reg(5));

	coe_c1_buzzer <= drive_sound(0) or drive_sound(1) or drive_sound(2) or drive_sound(3) or ctrl_sound or ctrl_sound_gpio or snd_freq_out;

	raw_in_io(0) <= coe_c1_tris_io0_din;
	raw_in_io(1) <= coe_c1_tris_io1_din;
	raw_in_io(2) <= coe_c1_tris_io2_din;
	raw_in_io(3) <= coe_c1_tris_io3_din;
	raw_in_io(4) <= coe_c1_ext_io_din;
	raw_in_io(5) <= coe_c1_external_int;

	process(csi_ci_Clk, csi_ci_Reset_n, control_reg, floppy_ctrl_extraouts_reg ,floppy_outputs,out_signal_polarity_reg, ctrl_control_reg ) begin

		if(control_reg(30) = '0')
		then
			coe_c1_floppy_o_pin02             <= floppy_ctrl_extraouts_reg(0)   xor out_signal_polarity_reg(19);
			coe_c1_floppy_o_pin04             <= floppy_ctrl_extraouts_reg(1)   xor out_signal_polarity_reg(20);
			coe_c1_floppy_o_sel(0)            <= ctrl_control_reg(0)            xor out_signal_polarity_reg(9);
			coe_c1_floppy_o_sel(1)            <= ctrl_control_reg(1)            xor out_signal_polarity_reg(10);
			coe_c1_floppy_o_sel(2)            <= ctrl_control_reg(2)            xor out_signal_polarity_reg(11);
			coe_c1_floppy_o_sel(3)            <= ctrl_control_reg(3)            xor out_signal_polarity_reg(12);
			coe_c1_floppy_o_motor             <= ctrl_control_reg(4)            xor out_signal_polarity_reg(13);
			coe_c1_floppy_o_dir               <= floppy_o_dir                   xor out_signal_polarity_reg(14);
			coe_c1_floppy_o_step              <= floppy_o_step                  xor out_signal_polarity_reg(15);
			coe_c1_floppy_o_write_data        <= floppy_o_write_data            xor out_signal_polarity_reg(16);
			coe_c1_floppy_o_write_gate        <= floppy_o_write_gate            xor out_signal_polarity_reg(17);
			coe_c1_floppy_o_side1             <= ctrl_control_reg(5)            xor out_signal_polarity_reg(18);

			if(control_reg(29) = '0')
			then
				coe_c1_floppy_o_x68000_sel(0) <= floppy_ctrl_extraouts_reg(2)   xor out_signal_polarity_reg(21);
				coe_c1_floppy_o_x68000_sel(1) <= floppy_ctrl_extraouts_reg(3)   xor out_signal_polarity_reg(22);
				coe_c1_floppy_o_x68000_sel(2) <= floppy_ctrl_extraouts_reg(4)   xor out_signal_polarity_reg(23);
				coe_c1_floppy_o_x68000_sel(3) <= floppy_ctrl_extraouts_reg(5)   xor out_signal_polarity_reg(24);
			else
				coe_c1_floppy_o_x68000_sel(0) <= floppy_apple_stepper_phases(0) xor out_signal_polarity_reg(21);
				coe_c1_floppy_o_x68000_sel(1) <= floppy_apple_stepper_phases(1) xor out_signal_polarity_reg(22);
				coe_c1_floppy_o_x68000_sel(2) <= floppy_apple_stepper_phases(2) xor out_signal_polarity_reg(23);
				coe_c1_floppy_o_x68000_sel(3) <= floppy_apple_stepper_phases(3) xor out_signal_polarity_reg(24);
			end if;

			coe_c1_floppy_o_x68000_ledblink   <= floppy_ctrl_extraouts_reg(6)   xor out_signal_polarity_reg(25);
			coe_c1_floppy_o_x68000_lock       <= floppy_ctrl_extraouts_reg(7)   xor out_signal_polarity_reg(26);
			coe_c1_floppy_o_x68000_eject      <= floppy_ctrl_extraouts_reg(8)   xor out_signal_polarity_reg(27);
		else
		-- direct IO / test mode
			coe_c1_floppy_o_pin02             <= not(floppy_outputs(1)); --coe_c1_floppy_o_pin02
			coe_c1_floppy_o_pin04             <= not(floppy_outputs(2)); --coe_c1_floppy_o_pin04
			coe_c1_floppy_o_sel(0)            <= not(floppy_outputs(4)); --coe_c1_floppy_o_sel(0)
			coe_c1_floppy_o_sel(1)            <= not(floppy_outputs(5)); --coe_c1_floppy_o_sel(1)
			coe_c1_floppy_o_sel(2)            <= not(floppy_outputs(6)); --coe_c1_floppy_o_sel(2)
			coe_c1_floppy_o_sel(3)            <= not(floppy_outputs(7)); --coe_c1_floppy_o_sel(3)
			coe_c1_floppy_o_motor             <= not(floppy_outputs(8)); --coe_c1_floppy_o_motor
			coe_c1_floppy_o_dir               <= not(floppy_outputs(9)); --coe_c1_floppy_o_dir
			coe_c1_floppy_o_step              <= not(floppy_outputs(10)); --coe_c1_floppy_o_step
			coe_c1_floppy_o_write_data        <= not(floppy_outputs(11)); --coe_c1_floppy_o_write_data
			coe_c1_floppy_o_write_gate        <= not(floppy_outputs(12)); --coe_c1_floppy_o_write_gate
			coe_c1_floppy_o_side1             <= not(floppy_outputs(16)); --coe_c1_floppy_o_side1
			coe_c1_floppy_o_x68000_sel(0)     <= not(floppy_outputs(18)); --coe_c1_floppy_o_x68000_sel(0)
			coe_c1_floppy_o_x68000_sel(1)     <= not(floppy_outputs(19)); --coe_c1_floppy_o_x68000_sel(1)
			coe_c1_floppy_o_x68000_sel(2)     <= not(floppy_outputs(20)); --coe_c1_floppy_o_x68000_sel(2)
			coe_c1_floppy_o_x68000_sel(3)     <= not(floppy_outputs(21)); --coe_c1_floppy_o_x68000_sel(3)
			coe_c1_floppy_o_x68000_eject      <= not(floppy_outputs(23)); --coe_c1_floppy_o_x68000_eject
			coe_c1_floppy_o_x68000_lock       <= not(floppy_outputs(24)); --coe_c1_floppy_o_x68000_lock
			coe_c1_floppy_o_x68000_ledblink   <= not(floppy_outputs(25)); --coe_c1_floppy_o_x68000_ledblink

		end if;

	end process;

	process(csi_ci_Clk, csi_ci_Reset_n,host_sel_drive_unit,ctrl_control_reg,drv_track_trk00,drv_pin02,drv_pin34,drv_write_protect,drv_index,drv_data,out_signal_polarity_reg )
	begin
		if(control_reg(30) = '0')
		then

			case ( ( host_sel_drive_unit(3) & host_sel_drive_unit(2) & host_sel_drive_unit(1) & host_sel_drive_unit(0) ) and control_reg(3 downto 0) ) is

				when "0001" =>
					coe_c1_host_o_trk00 <= drv_track_trk00(0) xor out_signal_polarity_reg(0);
					coe_c1_host_o_data <= drv_data(0) xor out_signal_polarity_reg(1);
					coe_c1_host_o_wpt <= drv_write_protect(0) xor out_signal_polarity_reg(2);
					coe_c1_host_o_pin02 <= drv_pin02(0) xor out_signal_polarity_reg(3);
					coe_c1_host_o_pin34 <= drv_pin34(0) xor out_signal_polarity_reg(4);
					coe_c1_host_o_index <= drv_index(0) xor out_signal_polarity_reg(5);
					coe_c1_host_o_pin03 <= '0';

				when "0010" =>
					coe_c1_host_o_trk00 <= drv_track_trk00(1) xor out_signal_polarity_reg(0);
					coe_c1_host_o_data <= drv_data(1) xor out_signal_polarity_reg(1);
					coe_c1_host_o_wpt <= drv_write_protect(1) xor out_signal_polarity_reg(2);
					coe_c1_host_o_pin02 <= drv_pin02(1) xor out_signal_polarity_reg(3);
					coe_c1_host_o_pin34 <= drv_pin34(1) xor out_signal_polarity_reg(4);
					coe_c1_host_o_index <= drv_index(1) xor out_signal_polarity_reg(5);
					coe_c1_host_o_pin03 <= '0';

				when "0100" =>
					coe_c1_host_o_trk00 <= drv_track_trk00(2) xor out_signal_polarity_reg(0);
					coe_c1_host_o_data <= drv_data(2) xor out_signal_polarity_reg(1);
					coe_c1_host_o_wpt <= drv_write_protect(2) xor out_signal_polarity_reg(2);
					coe_c1_host_o_pin02 <= drv_pin02(2) xor out_signal_polarity_reg(3);
					coe_c1_host_o_pin34 <= drv_pin34(2) xor out_signal_polarity_reg(4);
					coe_c1_host_o_index <= drv_index(2) xor out_signal_polarity_reg(5);
					coe_c1_host_o_pin03 <= '0';

				when "1000" =>
					coe_c1_host_o_trk00 <= drv_track_trk00(3) xor out_signal_polarity_reg(0);
					coe_c1_host_o_data <= drv_data(3) xor out_signal_polarity_reg(1);
					coe_c1_host_o_wpt <= drv_write_protect(3) xor out_signal_polarity_reg(2);
					coe_c1_host_o_pin02 <= drv_pin02(3) xor out_signal_polarity_reg(3);
					coe_c1_host_o_pin34 <= drv_pin34(3) xor out_signal_polarity_reg(4);
					coe_c1_host_o_index <= drv_index(3) xor out_signal_polarity_reg(5);
					coe_c1_host_o_pin03 <= '0';

				when others =>
					coe_c1_host_o_trk00 <= '0';
					coe_c1_host_o_data <= '0';
					coe_c1_host_o_wpt <= '0';
					coe_c1_host_o_pin02 <= '0';
					coe_c1_host_o_pin34 <= '0';
					coe_c1_host_o_index <= '0';
					coe_c1_host_o_pin03 <= '0';
			end case;
		else
			-- direct IO / test mode
			coe_c1_host_o_pin02 <= not(host_outputs(0));
			coe_c1_host_o_index <= not(host_outputs(3));
			coe_c1_host_o_trk00 <= not(host_outputs(13));
			coe_c1_host_o_wpt   <= not(host_outputs(14));
			coe_c1_host_o_data  <= not(host_outputs(15));
			coe_c1_host_o_pin34 <= not(host_outputs(17));
			coe_c1_host_o_pin03 <= not(host_outputs(22));
		end if;

	end process;

	process(csi_ci_Clk, csi_ci_Reset_n, host_inputs_q1, host_inputs_q2, floppy_inputs_q1, floppy_inputs_q2, floppy_outputs, host_outputs ) begin
		if(csi_ci_Reset_n = '0') then

			host_inputs_q1 <= (others=>'0');
			host_inputs_q2 <= (others=>'0');

			floppy_inputs_q1 <= (others=>'0');
			floppy_inputs_q2 <= (others=>'0');

		elsif(csi_ci_Clk'event and csi_ci_Clk = '1') then

			floppy_inputs_q1 <= (others=>'0');

			floppy_inputs_q1(0) <= not(coe_c1_floppy_i_pin02);
			floppy_inputs_q1(1) <= floppy_outputs(1); --coe_c1_floppy_o_pin02
			floppy_inputs_q1(2) <= floppy_outputs(2); --coe_c1_floppy_o_pin04
			floppy_inputs_q1(3) <= not(coe_c1_floppy_i_index);
			floppy_inputs_q1(4) <= floppy_outputs(4); --coe_c1_floppy_o_sel(0)
			floppy_inputs_q1(5) <= floppy_outputs(5); --coe_c1_floppy_o_sel(1)
			floppy_inputs_q1(6) <= floppy_outputs(6); --coe_c1_floppy_o_sel(2)
			floppy_inputs_q1(7) <= floppy_outputs(7); --coe_c1_floppy_o_sel(3)
			floppy_inputs_q1(8) <= floppy_outputs(8); --coe_c1_floppy_o_motor
			floppy_inputs_q1(9) <= floppy_outputs(9); --coe_c1_floppy_o_dir
			floppy_inputs_q1(10) <= floppy_outputs(10); --coe_c1_floppy_o_step
			floppy_inputs_q1(11) <= floppy_outputs(11); --coe_c1_floppy_o_write_data
			floppy_inputs_q1(12) <= floppy_outputs(12); --coe_c1_floppy_o_write_gate
			floppy_inputs_q1(13) <= not(coe_c1_floppy_i_trk00);
			floppy_inputs_q1(14) <= not(coe_c1_floppy_i_wpt);
			floppy_inputs_q1(15) <= not(coe_c1_floppy_i_data);
			floppy_inputs_q1(16) <= floppy_outputs(16); --coe_c1_floppy_o_side1
			floppy_inputs_q1(17) <= not(coe_c1_floppy_i_pin34);
			floppy_inputs_q1(18) <= floppy_outputs(18); --coe_c1_floppy_o_x68000_sel(0)
			floppy_inputs_q1(19) <= floppy_outputs(19); --coe_c1_floppy_o_x68000_sel(1)
			floppy_inputs_q1(20) <= floppy_outputs(20); --coe_c1_floppy_o_x68000_sel(2)
			floppy_inputs_q1(21) <= floppy_outputs(21); --coe_c1_floppy_o_x68000_sel(3)
			floppy_inputs_q1(22) <= not(coe_c1_floppy_i_pin03);
			floppy_inputs_q1(23) <= floppy_outputs(23); --coe_c1_floppy_o_x68000_eject      : out std_logic;
			floppy_inputs_q1(24) <= floppy_outputs(24); --coe_c1_floppy_o_x68000_lock       : out std_logic;
			floppy_inputs_q1(25) <= floppy_outputs(25); --coe_c1_floppy_o_x68000_ledblink   : out std_logic;
			floppy_inputs_q1(26) <= not(coe_c1_floppy_i_x68000_diskindrive);
			floppy_inputs_q1(27) <= not(coe_c1_floppy_i_x68000_insertfault);
			floppy_inputs_q1(28) <= not(coe_c1_floppy_i_x68000_int);

			floppy_inputs_q2 <= floppy_inputs_q1;

			host_inputs_q1   <= (others=>'0');

			host_inputs_q1(0) <= host_outputs(0); -- coe_c1_host_o_pin02
			host_inputs_q1(1) <= not(coe_c1_host_i_pin02);
			host_inputs_q1(2) <= not(coe_c1_host_i_pin04);
			host_inputs_q1(3) <= host_outputs(3); -- coe_c1_host_o_index
			host_inputs_q1(4) <= not(coe_c1_host_i_sel(0));
			host_inputs_q1(5) <= not(coe_c1_host_i_sel(1));
			host_inputs_q1(6) <= not(coe_c1_host_i_sel(2));
			host_inputs_q1(7) <= not(coe_c1_host_i_sel(3));
			host_inputs_q1(8) <= not(coe_c1_host_i_motor);
			host_inputs_q1(9) <= not(coe_c1_host_i_dir);
			host_inputs_q1(10) <= not(coe_c1_host_i_step);
			host_inputs_q1(11) <= not(coe_c1_host_i_write_data);
			host_inputs_q1(12) <= not(coe_c1_host_i_write_gate);
			host_inputs_q1(13) <= host_outputs(13); -- coe_c1_host_o_trk00
			host_inputs_q1(14) <= host_outputs(14); -- coe_c1_host_o_wpt
			host_inputs_q1(15) <= host_outputs(15); -- coe_c1_host_o_data
			host_inputs_q1(16) <= not(coe_c1_host_i_side1);
			host_inputs_q1(17) <= host_outputs(17); -- coe_c1_host_o_pin34
			host_inputs_q1(18) <= not(coe_c1_host_i_x68000_sel(0));
			host_inputs_q1(19) <= not(coe_c1_host_i_x68000_sel(1));
			host_inputs_q1(20) <= not(coe_c1_host_i_x68000_sel(2));
			host_inputs_q1(21) <= not(coe_c1_host_i_x68000_sel(3));
			host_inputs_q1(22) <= host_outputs(22); -- coe_c1_host_o_pin03
			host_inputs_q1(23) <= not(coe_c1_host_i_x68000_eject);
			host_inputs_q1(24) <= not(coe_c1_host_i_x68000_lock);
			host_inputs_q1(25) <= not(coe_c1_host_i_x68000_ledblink);
			host_inputs_q1(26) <= host_outputs(26); -- coe_c1_host_o_x68000_diskindrive
			host_inputs_q1(27) <= host_outputs(27); -- coe_c1_host_o_x68000_insertfault
			host_inputs_q1(28) <= host_outputs(28); -- coe_c1_host_o_x68000_int

			host_inputs_q2 <= host_inputs_q1;
		end if;
	end process;

	process(csi_ci_Clk, csi_ci_Reset_n, out_signal_polarity_reg, drv_option_diskindrive, drv_option_insertfault, drv_option_int, control_reg  ) begin

		if(control_reg(30) = '0')
		then
			case ( ( host_i_x68000_sel(3) & host_i_x68000_sel(2) & host_i_x68000_sel(1) & host_i_x68000_sel(0) ) and control_reg(3 downto 0) ) is

				when "0001" =>
					coe_c1_host_o_x68000_diskindrive <= drv_option_diskindrive(0) xor out_signal_polarity_reg(6);
					coe_c1_host_o_x68000_insertfault <= drv_option_insertfault(0) xor out_signal_polarity_reg(7);
					coe_c1_host_o_x68000_int <= drv_option_int(0) xor out_signal_polarity_reg(8);

				when "0010" =>
					coe_c1_host_o_x68000_diskindrive <= drv_option_diskindrive(1) xor out_signal_polarity_reg(6);
					coe_c1_host_o_x68000_insertfault <= drv_option_insertfault(1) xor out_signal_polarity_reg(7);
					coe_c1_host_o_x68000_int <= drv_option_int(1) xor out_signal_polarity_reg(8);

				when "0100" =>
					coe_c1_host_o_x68000_diskindrive <= drv_option_diskindrive(2) xor out_signal_polarity_reg(6);
					coe_c1_host_o_x68000_insertfault <= drv_option_insertfault(2) xor out_signal_polarity_reg(7);
					coe_c1_host_o_x68000_int <= drv_option_int(2) xor out_signal_polarity_reg(8);

				when "1000" =>
					coe_c1_host_o_x68000_diskindrive <= drv_option_diskindrive(3) xor out_signal_polarity_reg(6);
					coe_c1_host_o_x68000_insertfault <= drv_option_insertfault(3) xor out_signal_polarity_reg(7);
					coe_c1_host_o_x68000_int <= drv_option_int(3) xor out_signal_polarity_reg(8);

				when others =>
					coe_c1_host_o_x68000_diskindrive <= '0';
					coe_c1_host_o_x68000_insertfault <= '0';
					coe_c1_host_o_x68000_int <= '0';
			end case;
		else
			-- direct IO / test mode
			coe_c1_host_o_x68000_diskindrive <= not(host_outputs(26));
			coe_c1_host_o_x68000_insertfault <= not(host_outputs(27));
			coe_c1_host_o_x68000_int         <= not(host_outputs(28));
		end if;

	end process;

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

floppy_step_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_step,
		signal_out                     => host_i_step_pulse,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(0),

		pulse_out_mode                 => '1',

		rising_edge                    => '0',
		falling_edge                   => '1'
		);

floppy_dir_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_dir,
		signal_out                     => host_i_dir,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(1),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_motor_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_motor,
		signal_out                     => host_i_motor,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(2),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

GEN_FLOPSELFILTER: for i_sel in 0 to 3 generate
floppy_selx_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_sel(i_sel),
		signal_out                     => host_i_selx(i_sel),

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(3),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);
end generate GEN_FLOPSELFILTER;

ext_io_sel_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_ext_io_din,
		signal_out                     => ext_io_selx_signal,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(3),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_write_gate_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_write_gate,
		signal_out                     => host_i_write_gate,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(4),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_write_data_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_write_data,
		signal_out                     => host_i_write_data_pulse,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(5),

		pulse_out_mode                 => '1',

		rising_edge                    => '0',
		falling_edge                   => '1'
		);

floppy_side1_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_side1,
		signal_out                     => host_i_side1,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(6),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

GEN_X68SELMUX: for i_sel in 0 to 3 generate
host_i_x68000_selx_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_x68000_sel(i_sel),
		signal_out                     => host_i_x68000_sel(i_sel),

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(7),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);
end generate GEN_X68SELMUX;

floppy_option_eject_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_x68000_eject,
		signal_out                     => host_i_x68000_eject,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(8),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_option_lock_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_x68000_lock,
		signal_out                     => host_i_x68000_lock,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(9),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_option_blink_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_x68000_ledblink,
		signal_out                     => host_i_x68000_ledblink,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(10),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);


-- -----------------------------------------------------------------------------------------------

floppy_step_dump_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_host_i_step,
		signal_out                     => host_i_step,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => host_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(0),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

-- -----------------------------------------------------------------------------------------------

GEN_IOFILTER: for i_io in 0 to 5 generate
iox_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => raw_in_io(i_io),
		signal_out                     => filtered_i_io(i_io),

		filter_level                   => io_port_glitch_filter,

		invert                         => invert_io_conf(i_io),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);
end generate GEN_IOFILTER;

-- -----------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------

GEN_SELMUX: for i_drive in 0 to 3 generate

drive_select_mux_x : floppy_select_mux
	port map(
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		line_select => drives_config_regs(i_drive)(19  downto 16),

		line0       => host_i_selx(0),
		line1       => host_i_selx(1),
		line2       => host_i_selx(2),
		line3       => host_i_selx(3),
		line4       => host_i_motor,
		line5       => ext_io_selx_signal,
		line6       => '0',
		line7       => '0',

		line_out    => host_sel_drive_unit(i_drive)
		);

end generate GEN_SELMUX;

GEN_MOTMUX: for i_drive in 0 to 3 generate

drive_motor_mux_x : floppy_select_mux
	port map(
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		line_select => drives_config_regs(i_drive)(23  downto 20),

		line0       => host_i_selx(0),
		line1       => host_i_selx(1),
		line2       => host_i_selx(2),
		line3       => host_i_selx(3),
		line4       => host_i_motor,
		line5       => ext_io_selx_signal,
		line6       => '0',
		line7       => '0',

		line_out    => host_motor_drive_unit(i_drive)
		);

end generate GEN_MOTMUX;

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

floppy_ctrl_trk00_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_floppy_i_trk00,
		signal_out                     => floppy_i_trk00,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => floppy_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(11),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_i_data_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_floppy_i_data,
		signal_out                     => floppy_i_data,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => floppy_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(12),

		pulse_out_mode                 => '1',

		rising_edge                    => '0',
		falling_edge                   => '1'
		);

floppy_i_wpt_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_floppy_i_wpt,
		signal_out                     => floppy_i_wpt,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => floppy_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(13),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_i_index_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_floppy_i_index,
		signal_out                     => floppy_i_index,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => floppy_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(14),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_i_pin02_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_floppy_i_pin02,
		signal_out                     => floppy_i_pin02,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => floppy_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(15),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

floppy_i_pin34_filter : floppy_signal_filter
	port map (
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		signal_in                      => coe_c1_floppy_i_pin34,
		signal_out                     => floppy_i_pin34,

		filter_level(31 downto 8)      => (others=>'0'),
		filter_level(7 downto 0)       => floppy_port_glitch_filter(7 downto 0),

		invert                         => in_signal_polarity_reg(16),

		pulse_out_mode                 => '0',

		rising_edge                    => '0',
		falling_edge                   => '0'
		);

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

dmamaster : floppy_dma_master
	port map(
		csi_ci_Clk                     => csi_ci_Clk,
		csi_ci_Reset_n                 => csi_ci_Reset_n,

		avm_m1_address                 => avm_m1_address,
		avm_m1_readdata                => avm_m1_readdata,
		avm_m1_read                    => avm_m1_read,
		avm_m1_write                   => avm_m1_write,
		avm_m1_writedata               => avm_m1_writedata,
		avm_m1_waitrequest             => avm_m1_waitrequest,
		avm_m1_readdatavalid           => avm_m1_readdatavalid,
		avm_m1_byteenable              => avm_m1_byteenable,
		avm_m1_burstcount              => avm_m1_burstcount,

		images_base_address            => images_base_address_busses,
		images_track_size              => images_track_size_busses,
		drv_cur_track_base_address     => drv_cur_track_base_address_busses,
		drv_cur_track_offsets          => drv_cur_track_offsets_busses,

		enable_drives                  => control_reg(4 downto 0),
		continuous_mode                => continuous_mode_reg(4 downto 0),
		done                           => done_reg(4 downto 0),

		pop_fifos_in_databus_if        => pop_fifos_in_databus_bus,
		pop_fifos_in_ctrlbus_if        => pop_fifos_in_ctrlbus_bus,
		pop_fifos_in_statusbus_if      => pop_fifos_in_statusbus_bus,

		push_fifos_out_databus_if      => push_fifos_out_databus_bus,
		push_fifos_out_ctrlbus_if      => push_fifos_out_ctrlbus_bus,
		push_fifos_out_statusbus_if    => push_fifos_out_statusbus_bus,

		pop_fifo_empty_events          => pop_fifo_empty_events,
		push_fifo_full_events          => push_fifo_full_events,

		reset_drives                   => reset_drives
		);

GEN_DRIVES: for i_drive in 0 to 3 generate
floppy_drive_x : floppy_drive
	port map(
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		pop_fifo_in_databus_b          => pop_fifos_in_databus_bus(i_drive),
		pop_fifo_in_ctrlbus_b          => pop_fifos_in_ctrlbus_bus(i_drive),
		pop_fifo_in_statusbus_b        => pop_fifos_in_statusbus_bus(i_drive),
		pop_fifo_in_status_byte        => "000000" & qd_stopmotor_state & index_state(i_drive),

		push_fifo_out_databus_b        => push_fifos_out_databus_bus(i_drive),
		push_fifo_out_ctrlbus_b        => push_fifos_out_ctrlbus_bus(i_drive),
		push_fifo_out_statusbus_b      => push_fifos_out_statusbus_bus(i_drive),

		read_fifo_cur_track_base       => drv_cur_track_base_address_busses(i_drive),

		image_base_address             => images_base_address_busses(i_drive),
		tracks_size                    => images_track_size_busses(i_drive),
		max_track                      => images_max_track_regs(i_drive)(7 downto 0),

		track_position                 => track_positions(i_drive),

		reset_state                    => reset_drives(i_drive),

		floppy_dc_rst                  => host_i_dc_rst,

		floppy_step                    => host_i_step_pulse,
		floppy_dir                     => host_i_dir,
		floppy_motor                   => host_motor_drive_unit(i_drive),
		floppy_select                  => host_sel_drive_unit(i_drive),
		floppy_write_gate              => host_i_write_gate,
		floppy_write_data              => host_i_write_data_pulse,
		floppy_side1                   => host_i_side1,

		floppy_trk00                   => drv_track_trk00(i_drive),
		host_o_data                    => drv_data(i_drive),
		host_o_wpt                     => drv_write_protect(i_drive),
		host_o_index                   => drv_index(i_drive),
		floppy_pin02                   => drv_pin02(i_drive),
		floppy_pin34                   => drv_pin34(i_drive),

		host_i_x68000_sel              => host_i_x68000_sel(0),
		floppy_eject_func              => host_i_x68000_eject,
		floppy_lock_func               => host_i_x68000_lock,
		floppy_blink_func              => host_i_x68000_ledblink,
		floppy_diskindrive             => drv_option_diskindrive(i_drive),
		floppy_insertfault             => drv_option_insertfault(i_drive),
		floppy_int                     => drv_option_int(i_drive),

		disk_in_drive                  => drives_config_regs(i_drive)(12),
		disk_write_protect_sw          => drives_config_regs(i_drive)(13),
		disk_hd_sw                     => drives_config_regs(i_drive)(14),
		disk_ed_sw                     => drives_config_regs(i_drive)(15),
		pin02_config                   => drives_config_regs(i_drive)(3 downto 0),
		pin34_config                   => drives_config_regs(i_drive)(7 downto 4),
		readymask_config               => drives_config_regs(i_drive)(11 downto 8),

		qd_mode                        => drives_config_regs(i_drive)(24),

		drive_sound                    => drive_sound(i_drive),

		led1_out                       => coe_c1_led1_out(i_drive),
		led2_out                       => coe_c1_led2_out(i_drive)
	);
end generate GEN_DRIVES;

GEN_INDEX: for i_drive in 0 to 3 generate
host_o_index_gen_X : floppy_index_generator
	port map(
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		track_length                   => images_track_size_busses(i_drive),

		index_length                   => drives_index_len(i_drive),

		start_track_index              => drives_track_index_start(i_drive),

		current_position               => drv_cur_track_offsets_busses(i_drive),

		index_out                      => index_state(i_drive)
		);
end generate GEN_INDEX;

floppy_qd_stopmotor_gen : floppy_index_generator
	port map(
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		track_length                   => images_track_size_busses(0),

		index_length                   => host_drv0_qdstopmotor_len,

		start_track_index              => host_drv0_qdstopmotor_start,

		current_position               => drv_cur_track_offsets_busses(0),

		index_out                      => qd_stopmotor_state
		);

ctrl_stepper : floppy_ctrl_stepper
	port map
	(
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		floppy_ctrl_step               => floppy_o_step,
		floppy_ctrl_dir                => floppy_o_dir,
		floppy_ctrl_trk00              => floppy_i_trk00,

		floppy_motor_phases            => floppy_apple_stepper_phases,
		motor_phases_cnt_vector        => floppy_apple_motor_phase_pos,

		step_rate                      => ctrl_steprate_reg,
		step_width                     => step_signal_width(15 downto 0),

		phases_timeout_moving          => step_phases_width,
		phases_timeout_stopping        => step_phases_stop_width,

		track_pos_cmd                  => ctrl_track_reg,
		move_head_cmd                  => ctrl_head_move_cmd,
		move_dir                       => ctrl_head_move_dir,

		cur_track_pos                  => ctrl_curtrack_reg,

		moving                         => ctrl_head_moving,

		sound                          => ctrl_sound

		);

GEN_IO_MUX: for i_mux in 0 to 19 generate
mux_x : gen_mux
	generic map (SEL_WIDTH => 5)
	port map
	(
		inputs(0)  => '0',
		inputs(1)  => ctrl_control_reg(0),
		inputs(2)  => ctrl_control_reg(1),
		inputs(3)  => ctrl_control_reg(2),
		inputs(4)  => ctrl_control_reg(3),
		inputs(5)  => ctrl_control_reg(4),
		inputs(6)  => floppy_o_step,
		inputs(7)  => floppy_o_dir,
		inputs(8)  => ctrl_control_reg(5), -- side1
		inputs(9)  => floppy_i_index,
		inputs(10) => floppy_i_pin02,
		inputs(11) => floppy_i_pin34,
		inputs(12) => floppy_i_wpt,
		inputs(13) => floppy_i_data,
		inputs(14) => floppy_o_write_gate,
		inputs(15) => floppy_o_write_data,
		inputs(16) => host_i_selx(0),
		inputs(17) => host_i_selx(1),
		inputs(18) => host_i_selx(2),
		inputs(19) => host_i_selx(3),
		inputs(20) => host_i_motor,
		inputs(21) => host_i_step,
		inputs(22) => host_i_dir,
		inputs(23) => host_i_side1,
		inputs(24) => host_i_write_gate,
		inputs(25) => host_i_write_data_pulse,
		inputs(26) => filtered_i_io(0),
		inputs(27) => filtered_i_io(1),
		inputs(28) => filtered_i_io(2),
		inputs(29) => filtered_i_io(3),
		inputs(30) => filtered_i_io(4),
		inputs(31) => filtered_i_io(5),
		sel        => in_mux_selectors_regs(i_mux)(4 downto 0),
		out_signal => mux_out_bus(i_mux)
	);
end generate GEN_IO_MUX;

floppy_dumper_unit : floppy_dumper
	port map
	(
		clk                            => csi_ci_Clk,
		reset_n                        => csi_ci_Reset_n,

		pop_fifo_in_databus_b          => pop_fifos_in_databus_bus(4),
		pop_fifo_in_ctrlbus_b          => pop_fifos_in_ctrlbus_bus(4),
		pop_fifo_in_statusbus_b        => pop_fifos_in_statusbus_bus(4),

		push_fifo_out_databus_b        => push_fifos_out_databus_bus(4),
		push_fifo_out_ctrlbus_b        => push_fifos_out_ctrlbus_bus(4),
		push_fifo_out_statusbus_b      => push_fifos_out_statusbus_bus(4),

		write_fifo_cur_track_base      => drv_cur_track_base_address_busses(4),

		buffer_base_address            => images_base_address_busses(4),
		buffer_size                    => images_track_size_busses(4),

		reset_state                    => reset_drives(4),
		stop                           => '0',--done_reg(4),

		fast_capture_sig               => mux_out_bus(16),
		slow_capture_bus               => mux_out_bus(15 downto 0),
		trigger_capture_sig            => mux_out_bus(17),

		floppy_write_gate              => floppy_o_write_gate,
		floppy_write_data              => floppy_o_write_data,

		sample_rate_divisor            => dump_sample_rate_divisor,

		enable_dump                    => '1',--ctrl_enable_dump,
		start_write                    => '0',--ctrl_enable_write

		timeout_value                  => dump_timeout_value,
		delay_value                    => dump_delay_value,
		ignore_index_trigger           => ignore_index_trigger,
		timeout                        => dump_timeout
	);

	host_i_dc_rst <= host_i_x68000_sel(0);

	reset_drives(0) <= not(control_reg(15));
	reset_drives(1) <= not(control_reg(15));
	reset_drives(2) <= not(control_reg(15));
	reset_drives(3) <= not(control_reg(15));
	reset_drives(4) <= not(control_reg(14));

	sound_generator : floppy_sound
	port map(
		clk         => csi_ci_Clk,
		reset_n     => csi_ci_Reset_n,

		step_sound  => '0',

		period      => sound_period,

		sound_out   => snd_freq_out
	);

	process(csi_ci_Clk, csi_ci_Reset_n ) begin

		if(csi_ci_Reset_n = '0') then

			state_read_register <= wait_state_read;

			control_reg <= (others => '0');
			continuous_mode_reg <= (others => '1');

			for i in 0 to 4 loop
				images_base_address_busses(i) <= conv_std_logic_vector(900*1024*1024,32); -- 900MB
				images_track_size_busses(i) <= conv_std_logic_vector(624998*2,32); -- 625000*2
			end loop;

			in_signal_polarity_reg <= (others => '0');
			out_signal_polarity_reg <= (others => '0');

			floppy_port_glitch_filter <= conv_std_logic_vector(4,32); -- 80ns @ 50Mhz
			host_port_glitch_filter <= conv_std_logic_vector(4,32); -- 80ns @ 50Mhz
			io_port_glitch_filter <= conv_std_logic_vector(4,32); -- 80ns @ 50Mhz

			invert_io_conf <= (others => '0');

			gpio_reg <= (others => '0');
			gpio_oe_reg <= (others => '0');
			floppy_ctrl_extraouts_reg <= (others => '0');

			sound_period <= (others => '0');

			for i in 0 to 4 loop
				images_max_track_regs(i) <= conv_std_logic_vector(80,32); -- 80 tracks
				drives_config_regs(i) <= (others => '0');
				drives_track_index_start(i) <= (others => '0');
				drives_index_len(i) <= (others => '0');
			end loop;

			for i in 0 to 19 loop
				in_mux_selectors_regs(i) <= (others => '0');
			end loop;

			host_drv0_qdstopmotor_len <= (others => '0');
			host_drv0_qdstopmotor_start <= (others => '0');
			floppy_outputs <= (others => '1');
			host_outputs   <= (others => '1');

			ctrl_control_reg <= (others => '0');

			ctrl_head_move_cmd <= '0';
			ctrl_head_move_dir <= '0';

			step_signal_width <= conv_std_logic_vector(400,32);          -- 8uS
			step_phases_width <= conv_std_logic_vector(700000,32);       -- 14ms
			step_phases_stop_width <= conv_std_logic_vector(1800000,32); -- 36ms

			avs_s1_irq <= '0';

		elsif(csi_ci_Clk 'event and csi_ci_Clk  = '1') then

			avs_s1_irq <= ctrl_control_reg(31);

			ctrl_head_move_cmd <= '0';

			images_max_track_regs(4) <= conv_std_logic_vector(1,32);
			drives_config_regs(4) <= (others=>'0');
			drives_track_index_start(4) <= (others => '0');
			drives_index_len(4) <= (others => '0');

			avs_s1_waitrequest <= '1';

			if ( avs_s1_write = '1') then
				avs_s1_waitrequest <= '0';
				if ( avs_s1_address = "0000000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							control_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0000001") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_base_address_busses(0)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0000010") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_base_address_busses(1)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0000011") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_base_address_busses(2)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0000100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_base_address_busses(3)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0000101") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_track_size_busses(0)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0000110") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_track_size_busses(1)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0000111") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_track_size_busses(2)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0001000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_track_size_busses(3)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0001001") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							in_signal_polarity_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0001010") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							out_signal_polarity_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0001011") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_max_track_regs(0)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0001100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_max_track_regs(1)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0001101") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_max_track_regs(2)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0001110") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_max_track_regs(3)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0010100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_config_regs(0)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0010101") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_config_regs(1)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0010110") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_config_regs(2)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0010111") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_config_regs(3)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_index_len(0)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011001") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_index_len(1)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011010") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_index_len(2)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011011") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_index_len(3)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_track_index_start(0)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011101") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_track_index_start(1)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011110") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_track_index_start(2)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0011111") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							drives_track_index_start(3)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0100000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							host_drv0_qdstopmotor_len((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0100001") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							host_drv0_qdstopmotor_start((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0100011") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							ctrl_control_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0100100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							ctrl_steprate_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0100101") then
					if(avs_s1_byteenable(0) = '1') then
						ctrl_track_reg(7 downto 0) <= avs_s1_writedata(7 downto 0);
					end if;
					if(avs_s1_byteenable(1) = '1') then
						ctrl_track_reg(9 downto 8) <= avs_s1_writedata(9 downto 8);
					end if;
					if(avs_s1_byteenable(2) = '1') then
						ctrl_head_move_cmd <= avs_s1_writedata(16);
						ctrl_head_move_dir <= avs_s1_writedata(17);
					end if;
				elsif ( avs_s1_address = "0100111") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_base_address_busses(4)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0101000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							images_track_size_busses(4)((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0101001") then
				elsif ( avs_s1_address = "0101010") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							continuous_mode_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0101011") then

				elsif ( avs_s1_address = "0110100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							dump_delay_value((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "0110101") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							dump_timeout_value((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1000000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							gpio_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1000001") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							gpio_oe_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1000011") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							floppy_ctrl_extraouts_reg((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1000100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							floppy_outputs((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1000101") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							host_outputs((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1000110") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							in_mux_selectors_regs(i) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1000111") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							in_mux_selectors_regs(4+i) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1001000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							in_mux_selectors_regs(8+i) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1001001") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							in_mux_selectors_regs(12+i) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1001010") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							in_mux_selectors_regs(16+i) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1001011") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							floppy_port_glitch_filter((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1001100") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							host_port_glitch_filter((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;
				elsif ( avs_s1_address = "1001101") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							io_port_glitch_filter((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;

				elsif ( avs_s1_address = "1001110") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							invert_io_conf((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;

				elsif ( avs_s1_address = "1001111") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							sound_period((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;

				elsif ( avs_s1_address = "1010000") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							step_signal_width((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;

				elsif ( avs_s1_address = "1010001") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							step_phases_width((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;

				elsif ( avs_s1_address = "1010010") then
					for i in 0 to 3 loop
						if(avs_s1_byteenable(i) = '1') then
							step_phases_stop_width((((i+1)*8)-1) downto i*8) <= avs_s1_writedata((((i+1)*8)-1) downto i*8);
						end if;
					end loop;

				end if;
			end if;

			case state_read_register is

				when wait_state_read =>
					if(avs_s1_read = '1') then
						state_read_register <= state_decodread;
					end if;

				when state_decodread =>
					if ( avs_s1_address = "0000000") then
						avs_s1_readdata <= control_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0000001") then
						avs_s1_readdata <= images_base_address_busses(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0000010") then
						avs_s1_readdata <= images_base_address_busses(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0000011") then
						avs_s1_readdata <= images_base_address_busses(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0000100") then
						avs_s1_readdata <= images_base_address_busses(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0000101") then
						avs_s1_readdata <= images_track_size_busses(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0000110") then
						avs_s1_readdata <= images_track_size_busses(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0000111") then
						avs_s1_readdata <= images_track_size_busses(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001000") then
						avs_s1_readdata <= images_track_size_busses(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001001") then
						avs_s1_readdata <= in_signal_polarity_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001010") then
						avs_s1_readdata <= out_signal_polarity_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001011") then
						avs_s1_readdata <= images_max_track_regs(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001100") then
						avs_s1_readdata <= images_max_track_regs(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001101") then
						avs_s1_readdata <= images_max_track_regs(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001110") then
						avs_s1_readdata <= images_max_track_regs(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0001111") then
						avs_s1_readdata <= drv_cur_track_base_address_busses(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0010000") then
						avs_s1_readdata <= drv_cur_track_offsets_busses(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0010100") then
						avs_s1_readdata <= drives_config_regs(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0010101") then
						avs_s1_readdata <= drives_config_regs(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0010110") then
						avs_s1_readdata <= drives_config_regs(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0010111") then
						avs_s1_readdata <= drives_config_regs(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011000") then
						avs_s1_readdata <= drives_index_len(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011001") then
						avs_s1_readdata <= drives_index_len(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011010") then
						avs_s1_readdata <= drives_index_len(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011011") then
						avs_s1_readdata <= drives_index_len(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011100") then
						avs_s1_readdata <= drives_track_index_start(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011101") then
						avs_s1_readdata <= drives_track_index_start(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011110") then
						avs_s1_readdata <= drives_track_index_start(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0011111") then
						avs_s1_readdata <= drives_track_index_start(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100000") then
						avs_s1_readdata <= host_drv0_qdstopmotor_len;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100001") then
						avs_s1_readdata <= host_drv0_qdstopmotor_start;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100010") then
						avs_s1_readdata <= "10101010010101011010010111110001";
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100011") then
						avs_s1_readdata <= ctrl_control_reg;
						avs_s1_readdata(6) <= floppy_i_trk00;
						avs_s1_readdata(7) <= floppy_i_data;
						avs_s1_readdata(8) <= floppy_i_wpt;
						avs_s1_readdata(9) <= floppy_i_index;
						avs_s1_readdata(10) <= floppy_i_pin02;
						avs_s1_readdata(11) <= floppy_i_pin34;
						avs_s1_readdata(24) <= dump_timeout;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100100") then
						avs_s1_readdata <= ctrl_steprate_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100101") then
						avs_s1_readdata(9 downto 0) <= ctrl_curtrack_reg;
						avs_s1_readdata(16) <= ctrl_head_moving;
						avs_s1_readdata(17) <= ctrl_head_move_dir;
						avs_s1_readdata(19 downto 18) <= floppy_apple_motor_phase_pos;

						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100110") then
						avs_s1_readdata(9 downto 0) <= ctrl_track_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0100111") then
						avs_s1_readdata(31 downto 0) <= images_base_address_busses(4);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101000") then
						avs_s1_readdata(31 downto 0) <= images_track_size_busses(4);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101001") then
						avs_s1_readdata(31 downto 0) <= drv_cur_track_offsets_busses(4);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101010") then
						avs_s1_readdata(31 downto 0) <= continuous_mode_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101011") then
						avs_s1_readdata <= (others=>'0');
						avs_s1_readdata(4 downto 0) <= done_reg;
						avs_s1_readdata(5) <= dump_timeout;

						avs_s1_readdata(8)  <= push_fifos_out_statusbus_bus(0).push_fifo_empty;
						avs_s1_readdata(9)  <= push_fifos_out_statusbus_bus(1).push_fifo_empty;
						avs_s1_readdata(10) <= push_fifos_out_statusbus_bus(2).push_fifo_empty;
						avs_s1_readdata(11) <= push_fifos_out_statusbus_bus(3).push_fifo_empty;
						avs_s1_readdata(12) <= push_fifos_out_statusbus_bus(4).push_fifo_empty;

						avs_s1_readdata(16) <= pop_fifos_in_statusbus_bus(0).pop_fifo_empty;
						avs_s1_readdata(17) <= pop_fifos_in_statusbus_bus(1).pop_fifo_empty;
						avs_s1_readdata(18) <= pop_fifos_in_statusbus_bus(2).pop_fifo_empty;
						avs_s1_readdata(19) <= pop_fifos_in_statusbus_bus(3).pop_fifo_empty;
						avs_s1_readdata(20) <= pop_fifos_in_statusbus_bus(4).pop_fifo_empty;

						avs_s1_readdata(24) <= push_fifos_out_databus_bus(0).push_fifo_out_status(0);
						avs_s1_readdata(25) <= push_fifos_out_databus_bus(1).push_fifo_out_status(0);
						avs_s1_readdata(26) <= push_fifos_out_databus_bus(2).push_fifo_out_status(0);
						avs_s1_readdata(27) <= push_fifos_out_databus_bus(3).push_fifo_out_status(0);
						avs_s1_readdata(28) <= push_fifos_out_databus_bus(4).push_fifo_out_status(0);

						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101100") then
						avs_s1_readdata <= (others=>'0');
						avs_s1_readdata(7 downto 0) <= track_positions(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101101") then
						avs_s1_readdata <= (others=>'0');
						avs_s1_readdata(7 downto 0) <= track_positions(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101110") then
						avs_s1_readdata <= (others=>'0');
						avs_s1_readdata(7 downto 0) <= track_positions(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0101111") then
						avs_s1_readdata <= (others=>'0');
						avs_s1_readdata(7 downto 0) <= track_positions(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110000") then
						avs_s1_readdata <= drv_cur_track_offsets_busses(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110001") then
						avs_s1_readdata <= drv_cur_track_offsets_busses(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110010") then
						avs_s1_readdata <= drv_cur_track_offsets_busses(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110011") then
						avs_s1_readdata <= drv_cur_track_offsets_busses(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110100") then
						avs_s1_readdata <= dump_delay_value;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110101") then
						avs_s1_readdata <= dump_timeout_value;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110110") then
						avs_s1_readdata <= pop_fifo_empty_events(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0110111") then
						avs_s1_readdata <= pop_fifo_empty_events(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111000") then
						avs_s1_readdata <= pop_fifo_empty_events(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111001") then
						avs_s1_readdata <= pop_fifo_empty_events(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111010") then
						avs_s1_readdata <= pop_fifo_empty_events(4);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111011") then
						avs_s1_readdata <= push_fifo_full_events(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111100") then
						avs_s1_readdata <= push_fifo_full_events(1);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111101") then
						avs_s1_readdata <= push_fifo_full_events(2);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111110") then
						avs_s1_readdata <= push_fifo_full_events(3);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "0111111") then
						avs_s1_readdata <= push_fifo_full_events(4);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1000000") then
						avs_s1_readdata <= gpio_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1000001") then
						avs_s1_readdata <= gpio_oe_reg;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1000010") then
						avs_s1_readdata <= (others=>'0');
						avs_s1_readdata(2) <= coe_c1_tris_io0_din;
						avs_s1_readdata(3) <= coe_c1_tris_io1_din;
						avs_s1_readdata(4) <= coe_c1_tris_io2_din;
						avs_s1_readdata(5) <= coe_c1_tris_io3_din;
						avs_s1_readdata(6) <= coe_c1_ext_io_din;
						avs_s1_readdata(7) <= coe_c1_external_int;

						avs_s1_readdata(8) <= coe_c1_pushbutton0;
						avs_s1_readdata(9) <= coe_c1_pushbutton1;
						avs_s1_readdata(10) <= coe_c1_pushbutton2;

						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1000011") then
						avs_s1_readdata <= floppy_ctrl_extraouts_reg;
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1000100") then
						avs_s1_readdata <= floppy_inputs_q2;
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1000101") then
						avs_s1_readdata <= host_inputs_q2;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1000110") then
						avs_s1_readdata <= in_mux_selectors_regs(3) & in_mux_selectors_regs(2) & in_mux_selectors_regs(1) & in_mux_selectors_regs(0);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1000111") then
						avs_s1_readdata <= in_mux_selectors_regs(7) & in_mux_selectors_regs(6) & in_mux_selectors_regs(5) & in_mux_selectors_regs(4);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1001000") then
						avs_s1_readdata <= in_mux_selectors_regs(11) & in_mux_selectors_regs(10) & in_mux_selectors_regs(9) & in_mux_selectors_regs(8);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1001001") then
						avs_s1_readdata <= in_mux_selectors_regs(15) & in_mux_selectors_regs(14) & in_mux_selectors_regs(13) & in_mux_selectors_regs(12);
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1001010") then
						avs_s1_readdata <= in_mux_selectors_regs(19) & in_mux_selectors_regs(18) & in_mux_selectors_regs(17) & in_mux_selectors_regs(16);
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1001011") then
						avs_s1_readdata <= floppy_port_glitch_filter;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1001100") then
						avs_s1_readdata <= host_port_glitch_filter;
						avs_s1_waitrequest <= '0';
					elsif ( avs_s1_address = "1001101") then
						avs_s1_readdata <= io_port_glitch_filter;
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1001110") then
						avs_s1_readdata <= invert_io_conf;
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1001111") then
						avs_s1_readdata <= sound_period;
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1010000") then
						avs_s1_readdata <= step_signal_width;
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1010001") then
						avs_s1_readdata <= step_phases_width;
						avs_s1_waitrequest <= '0';

					elsif ( avs_s1_address = "1010010") then
						avs_s1_readdata <= step_phases_stop_width;
						avs_s1_waitrequest <= '0';

					end if;

					state_read_register <= read_register;

				when read_register =>
					state_read_register <= wait_state_read;

			end case;

		end if;
	end process;

end arch;
