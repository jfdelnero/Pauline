/*
//
// Copyright (C) 2019-2021 Jean-François DEL NERO
//
// This file is part of the Pauline control software
//
// Pauline control software may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// Pauline control software is free software; you can redistribute it
// and/or modify  it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Pauline control software is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//   See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pauline control software; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
*/

#define MAX_DRIVES 16

#define REG_BASE 0xFF200000
#define REG_BASE_SIZE 4096

#define BIT_CLOCK 25000000 // 25 Mhz
#define FPGA_CLOCK 50000000 // 50 Mhz

#define DUMP_IMAGE_BASE 512*1024*1024

#define DRV0_IMAGE_BASE 600*1024*1024
#define DRV1_IMAGE_BASE 700*1024*1024
#define DRV2_IMAGE_BASE 800*1024*1024
#define DRV3_IMAGE_BASE 900*1024*1024

#define DEFAULT_TRACK_PERIOD 200

#define DEFAULT_TRACK_SIZE  (( (BIT_CLOCK/16) * (DEFAULT_TRACK_PERIOD) ) / 1000)*2

#define DEFAULT_MAX_TRACK 80

#define DEFAULT_INDEX_TIME 2 // 2ms

#define DEFAULT_INDEX_LEN (( (BIT_CLOCK/16) * (DEFAULT_INDEX_TIME) ) / 1000)

#define PIN_CFG_LOW         0
#define PIN_CFG_HIGH        1
#define PIN_CFG_NOTREADY    2
#define PIN_CFG_READY       3
#define PIN_CFG_NOTDENSITY  4
#define PIN_CFG_DENSITY     5
#define PIN_CFG_NOTDC1      6
#define PIN_CFG_DC1         7
#define PIN_CFG_NOTDC2      8
#define PIN_CFG_DC2         9
#define PIN_CFG_NOTDC3      10
#define PIN_CFG_DC3         11
#define PIN_CFG_NOTDC4      12
#define PIN_CFG_DC4         13

#define FLOPPY_LINE_SEL_DS0 (0 | 0x8)
#define FLOPPY_LINE_SEL_DS1 (1 | 0x8)
#define FLOPPY_LINE_SEL_DS2 (2 | 0x8)
#define FLOPPY_LINE_SEL_DS3 (3 | 0x8)
#define FLOPPY_LINE_SEL_MOT (4 | 0x8)
#define FLOPPY_LINE_SEL_OFF (0)
#define FLOPPY_LINE_SEL_ON  (1)

#define CFG_DISK_IN_DRIVE     (0x00000001 << 12)
#define CFG_WRITE_PROTECT_SW  (0x00000001 << 13)
#define CFG_DISK_HD_SW        (0x00000001 << 14)
#define CFG_DISK_ED_SW        (0x00000001 << 15)
#define CFG_QD_MODE           (0x00000001 << 24)

#define CFG_RDYMSK_INDEX      (0x00000001 << 8)
#define CFG_RDYMSK_DATA       (0x00000001 << 9)

#define DUMP_MUX_SEL_NONE           0
#define DUMP_MUX_SEL_FLOPPY_O_SEL0  1
#define DUMP_MUX_SEL_FLOPPY_O_SEL1  2
#define DUMP_MUX_SEL_FLOPPY_O_SEL2  3
#define DUMP_MUX_SEL_FLOPPY_O_SEL3  4
#define DUMP_MUX_SEL_FLOPPY_O_MTON  5
#define DUMP_MUX_SEL_FLOPPY_O_STEP  6
#define DUMP_MUX_SEL_FLOPPY_O_DIR   7
#define DUMP_MUX_SEL_FLOPPY_O_SIDE1 8
#define DUMP_MUX_SEL_FLOPPY_I_INDEX 9
#define DUMP_MUX_SEL_FLOPPY_I_PIN02 10
#define DUMP_MUX_SEL_FLOPPY_I_PIN34 11
#define DUMP_MUX_SEL_FLOPPY_I_WPT   12
#define DUMP_MUX_SEL_FLOPPY_I_DATA  13
#define DUMP_MUX_SEL_FLOPPY_O_WG    14
#define DUMP_MUX_SEL_FLOPPY_O_WD    15
#define DUMP_MUX_SEL_HOST_I_SEL0    16
#define DUMP_MUX_SEL_HOST_I_SEL1    17
#define DUMP_MUX_SEL_HOST_I_SEL2    18
#define DUMP_MUX_SEL_HOST_I_SEL3    19
#define DUMP_MUX_SEL_HOST_I_MTON    20
#define DUMP_MUX_SEL_HOST_I_STEP    21
#define DUMP_MUX_SEL_HOST_I_DIR     22
#define DUMP_MUX_SEL_HOST_I_SIDE1   23
#define DUMP_MUX_SEL_HOST_I_WG      24
#define DUMP_MUX_SEL_HOST_I_WD      25
#define DUMP_MUX_SEL_IO_I_0         26
#define DUMP_MUX_SEL_IO_I_1         27
#define DUMP_MUX_SEL_IO_I_2         28
#define DUMP_MUX_SEL_IO_I_3         29
#define DUMP_MUX_SEL_EXT_I_IO       30
#define DUMP_MUX_SEL_EXT_INT        31

#define DRIVES_INTERFACE_GENERIC_MODE  0
#define DRIVES_INTERFACE_APPLE_II_MODE 1
#define DRIVES_INTERFACE_APPLE_MACINTOSH_MODE 2

#pragma pack(1)
typedef struct _floppy_ip_regs
{
	// control reg
	// bits 3-0  : Drives enable mask
	// bits 4    : Dumper enable mask
	// bit  14   : Enable dump read fifos
	// bit  15   : Enable read fifos
	volatile uint32_t control_reg;

	volatile uint32_t image_base_address_reg[4];
	volatile uint32_t image_track_size_reg[4];

	// in_signal_polarity_reg
	// 0 host_step
	// 1 host_dir
	// 2 host_motor
	// 3 host_sel0,host_sel1,host_sel2,host_sel3
	// 4 host_write_gate
	// 5 host_write_data_pulse
	// 6 host_side1
	// 7 host_option_sel0,host_option_sel1,host_option_sel2,host_option_sel3
	// 8 host_option_eject
	// 9 host_option_lock
	// 10 host_option_blink
	// 11 floppy_trk00
	// 12 floppy_data
	// 13 floppy_wpt
	// 14 floppy_index
	// 15 floppy_pin02
	// 16 floppy_pin34


	volatile uint32_t in_signal_polarity_reg;

	// out_signal_polarity_reg
	// 0 trk00
	// 1 rd data
	// 2 write_protect
	// 3 pin02
	// 4 pin34
	// 5 index
	// 6 diskindrive
	// 7 insertfault
	// 8 option_int
	volatile uint32_t out_signal_polarity_reg;

	volatile uint32_t image_max_track_reg[4];

	volatile uint32_t cur_track_base_address;
	volatile uint32_t address_offset;

	volatile uint32_t RFU_0;
	volatile uint32_t RFU_1;
	volatile uint32_t RFU_2;

	// drive_x_config

	// bits 3-0 : pin02 config
	//              0000 - Low
	//              0001 - High
	//              0010 - nReady
	//              0011 - Ready
	//              0100 - nDensity
	//              0101 - Density
	//              0110 - nDiskChanged 1 (Step only clear)
	//              0111 - DiskChanged 1  (Step only clear)
	//              1000 - nDiskChanged 2 (Step only + timer)
	//              1001 - DiskChanged 2  (Step only + timer)
	//              1010 - nDiskChanged 3 (timer)
	//              1011 - DiskChanged 3  (timer)
	//              1100 - nDiskChanged 4 (floppy_dc_reset)
	//              1101 - DiskChanged 4  (floppy_dc_reset)

	// bits 7-4 : pin34 config
	//              0000 - Low
	//              0001 - High
	//              0010 - nReady
	//              0011 - Ready
	//              0100 - nDensity
	//              0101 - Density
	//              0110 - nDiskChanged 1 (Step only clear)
	//              0111 - DiskChanged 1  (Step only clear)
	//              1000 - nDiskChanged 2 (Step only + timer)
	//              1001 - DiskChanged 2  (Step only + timer)
	//              1010 - nDiskChanged 3 (timer)
	//              1011 - DiskChanged 3  (timer)
	//              1100 - nDiskChanged 4 (floppy_dc_reset)
	//              1101 - DiskChanged 4  (floppy_dc_reset)

	// bits 11-8 : readymask
	//              0 - index
	//              1 - rd data
	//              2 -
	//              3 -

	// bit 12     : disk_in_drive
	// bit 13     : disk_write_protect_sw
	// bit 14     : disk_hd_sw
	// bit 15     : disk_ed_sw

	// bits 19-16 : Line select
	//              0000 - floppy_sel0
	//              0001 - floppy_sel1
	//              0010 - floppy_sel2
	//              0011 - floppy_sel3
	//              0100 - floppy_motor
	//              0101 - off

	// bits 23-20 : Line motor
	//              0000 - floppy_sel0
	//              0001 - floppy_sel1
	//              0010 - floppy_sel2
	//              0011 - floppy_sel3
	//              0100 - floppy_motor

	//              0101 - off

	// bit 24     : qd mode

	volatile uint32_t drive_config[4];
	volatile uint32_t drv_index_len[4];
	volatile uint32_t drv_track_index_start[4];
	volatile uint32_t drv0_qdstopmotor_len;
	volatile uint32_t drv0_qdstopmotor_start;

	volatile uint32_t test_reg;

	volatile uint32_t floppy_ctrl_control;
	volatile uint32_t floppy_ctrl_steprate;
	volatile uint32_t floppy_ctrl_headmove;
	volatile uint32_t floppy_ctrl_curtrack;

	volatile uint32_t floppy_dump_base_address;
	volatile uint32_t floppy_dump_buffer_size;
	volatile uint32_t floppy_dump_cur_track_offset;

	volatile uint32_t floppy_continuous_mode;
	volatile uint32_t floppy_done;

	volatile uint32_t floppy_track_pos[4];
	volatile uint32_t floppy_track_offset[4];

	volatile uint32_t dump_delay_value;
	volatile uint32_t dump_timeout_value;

	volatile uint32_t dma_pop_fifos_empty_event[5];
	volatile uint32_t dma_push_fifos_full_event[5];

	volatile uint32_t gpio_reg;
	volatile uint32_t gpio_oe_reg;

	volatile uint32_t gpio_in_reg;
	volatile uint32_t gpio_extra_out;

	volatile uint32_t floppy_port_io;
	volatile uint32_t host_port_io;

	volatile uint32_t dump_in_mux_sel_3_0;
	volatile uint32_t dump_in_mux_sel_7_4;
	volatile uint32_t dump_in_mux_sel_11_8;
	volatile uint32_t dump_in_mux_sel_15_12;
	volatile uint32_t dump_in_mux_sel_19_16;

	volatile uint32_t floppy_port_glitch_filter;
	volatile uint32_t host_port_glitch_filter;
	volatile uint32_t io_port_glitch_filter;

	volatile uint32_t invert_io_conf;

	volatile uint32_t sound_period;

	volatile uint32_t step_signal_width;
	volatile uint32_t step_phases_width;
	volatile uint32_t step_phases_stop_width;

}floppy_ip_regs;

#pragma pack()


typedef struct _fpga_state
{
	int fd;

	unsigned short * disk_image[4];

	unsigned short * dump_buffer;
	int dump_buffer_size;

	floppy_ip_regs * regs;

	uint32_t last_dump_offset;
	unsigned int bitdelta;
	int chunk_number;

	uint16_t * conv_lut;

	int drive_sel_reg_number[MAX_DRIVES];
	unsigned int drive_sel_bit_mask[MAX_DRIVES];

	int drive_mot_reg_number[MAX_DRIVES];
	unsigned int drive_mot_bit_mask[MAX_DRIVES];

	int drive_headload_reg_number[MAX_DRIVES];
	unsigned int drive_headload_bit_mask[MAX_DRIVES];

	int drive_X68000_opt_sel_reg_number[MAX_DRIVES];
	unsigned int drive_X68000_opt_sel_bit_mask[MAX_DRIVES];

	int drive_max_steps[MAX_DRIVES];
	int drive_current_head_position[MAX_DRIVES];

	int drive_type[MAX_DRIVES];

	HXCFE* libhxcfe;

	pthread_mutex_t io_fpga_mutex;

	int inotify_fd;

	int step_rate;

}fpga_state;

typedef struct dump_state_
{
	int drive_number;
	char drive_description[512];
	char dump_name[512];
	char dump_comment[512];
	char dump_comment2[512];
	char dump_operator[512];
	char dump_driveref[512];
	int start_track;
	int max_track;
	int start_side;
	int max_side;
	int index_synced;
	int index_to_dump_delay;
	int time_per_track;
	int doublestep;
	int sample_rate_hz;
	int current_track;
	int current_side;
}dump_state;

fpga_state * init_fpga();
void reset_fpga(fpga_state * state);
void alloc_image(fpga_state * state, int drive, int track_size,int max_track, uint32_t base, int setfpga);
void alloc_dump_buffer(fpga_state * state, uint32_t base, int buffer_size, int setfpga);
void free_dump_buffer(fpga_state * state);
void deinit_fpga(fpga_state * state);
void set_select_src(fpga_state * state, int drive, int src);
void set_motor_src(fpga_state * state, int drive, int src);
void set_pin02_mode(fpga_state * state, int drive, int mode);
void set_pin34_mode(fpga_state * state, int drive, int mode);
void enable_drive(fpga_state * state, int drive, int enable);

void set_led_src(fpga_state * state, int led, int src);

void floppy_ctrl_move_head(fpga_state * state, int dir, int trk, int drive);

void start_dump(fpga_state * state, uint32_t buffersize, int res, int delay, int ignore_index);
unsigned char * get_next_available_stream_chunk(fpga_state * state, uint32_t * size, dump_state * dstate);

void stop_dump(fpga_state * state);

void print_fpga_regs(fpga_state * state);

void floppy_ctrl_select_drive(fpga_state * state, int drive, int enable);
void floppy_ctrl_motor(fpga_state * state, int drive, int enable);
void floppy_ctrl_headload(fpga_state * state, int drive, int enable);
void floppy_ctrl_side(fpga_state * state, int drive, int side);
void floppy_ctrl_selectbyte(fpga_state * state, unsigned char byte);
int  floppy_head_recalibrate(fpga_state * state, int drive);
int  floppy_head_maxtrack(fpga_state * state, int maxtrack, int drive);

void floppy_ctrl_x68000_option_select_drive(fpga_state * state, int drive, int enable);
void floppy_ctrl_x68000_eject(fpga_state * state, int drive);

void set_extio(fpga_state * state, int io, int oe, int data);
int  setio(fpga_state * fpga, char * name, int state);
int  getio(fpga_state * fpga, char * name);

void test_interface(fpga_state * state);

int get_drive_io(fpga_state * fpga, char * name, int drive, int * regs, unsigned int * bitmask);

void sound(fpga_state * state,int freq, int duration);
void error_sound(fpga_state * state);
