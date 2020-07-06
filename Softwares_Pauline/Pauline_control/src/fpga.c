/*
//
// Copyright (C) 2019-2020 Jean-François DEL NERO
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include <stdint.h>
#include <pthread.h>

#include "libhxcfe.h"

#include "fpga.h"
#include "dump_chunk.h"
#include "ios.h"

static void prepare_LUT(uint16_t * lut)
{
	int i,a,b;
	memset(lut,0x00,64*1024 * sizeof(uint16_t));

	i = 0x8000;
	b = 0;
	a = 16;
	while(i)
	{
		lut[i] = (b<<8) | a;
		i = i >> 1;
		b++;
		a--;
	}
}

int get_drive_io(fpga_state * fpga, char * name, int drive, int * regs, unsigned int * bitmask)
{
	char str[512];
	char * var;
	int index;

	sprintf(str,name,drive);

	var = hxcfe_getEnvVar( fpga->libhxcfe, (char *)str, NULL );

	if(var)
	{
		index = get_io_index(var);

		if(index  >= 0)
		{
			get_io_address(index, regs, bitmask);
			return 0;
		}
	}

	return -1;
}

int setio(fpga_state * fpga, char * name, int state)
{
	int index;
	int reg;
	unsigned int bitmask;

	bitmask = 0x00000000;
	reg = 0x40;

	index = get_io_index(name);

	if(index  >= 0)
	{
		get_io_address(index, &reg, &bitmask);

		if(state)
			*(((volatile uint32_t*)(fpga->regs)) + reg) |= (bitmask);
		else
			*(((volatile uint32_t*)(fpga->regs)) + reg) &= ~(bitmask);

		return 0;
	}

	return -1;
}

fpga_state * init_fpga()
{
	fpga_state *state;
	int i;
	size_t pagesize;
	off_t page_base;
	off_t page_offset;

	state = malloc( sizeof(fpga_state) );
	if(!state)
		return NULL;

	memset(state,0,sizeof(fpga_state) );

	state->fd = open("/dev/mem",  O_RDWR | O_SYNC);
	if( state->fd >= 0)
	{
		// Truncate offset to a multiple of the page size, or mmap will fail.
		pagesize = sysconf(_SC_PAGE_SIZE);

		page_base = (REG_BASE / pagesize) * pagesize;
		page_offset = REG_BASE - page_base;

		state->regs = (floppy_ip_regs *)mmap(NULL, page_offset + REG_BASE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, state->fd, page_base);
		if(state->regs == MAP_FAILED)
		{
			printf("ERROR : Can't mmap fpga regs !\n");
			close(state->fd);
			free(state);
			return NULL;
		}
	}
	else
	{
		printf("ERROR : Can't open /dev/mem !\n");
		free(state);
		return NULL;
	}

	state->conv_lut = malloc(64 * 1024 * sizeof(uint16_t));

	prepare_LUT(state->conv_lut);

	for(i=0;i<MAX_DRIVES;i++)
	{
		state->drive_sel_reg_number[i] = 0x40;
		state->drive_sel_bit_mask[i] = 0x00000000;

		state->drive_mot_reg_number[i] = 0x40;
		state->drive_mot_bit_mask[i] = 0x00000000;

		state->drive_X68000_opt_sel_reg_number[i] = 0x40;
		state->drive_X68000_opt_sel_bit_mask[i] = 0x00000000;
	}

	pthread_mutex_init ( &state->io_fpga_mutex, NULL);

	return state;
}

void reset_fpga(fpga_state * state)
{
	int i;

	if(!state)
		return;

	state->regs->control_reg = 0x00000000;

	state->regs->control_reg = 0x00008000;

	state->regs->image_base_address_reg[0] = DRV0_IMAGE_BASE;
	state->regs->image_base_address_reg[1] = DRV1_IMAGE_BASE;
	state->regs->image_base_address_reg[2] = DRV2_IMAGE_BASE;
	state->regs->image_base_address_reg[3] = DRV3_IMAGE_BASE;

	for(i=0;i<1;i++)
	{
		state->regs->image_track_size_reg[i] = DEFAULT_TRACK_SIZE;
		state->regs->image_max_track_reg[i] = DEFAULT_MAX_TRACK;
		state->regs->drv_track_index_start[i] = 0;
		state->regs->drv_index_len[i] = DEFAULT_INDEX_LEN;
	}

	state->regs->drv0_qdstopmotor_len = 0;
	state->regs->drv0_qdstopmotor_start = 0;

	state->regs->drive_config[0] = (FLOPPY_LINE_SEL_OFF << 20) | (FLOPPY_LINE_SEL_OFF << 16) | CFG_DISK_HD_SW | (CFG_RDYMSK_DATA) | (PIN_CFG_NOTDC1<<4) | PIN_CFG_NOTDENSITY;
	state->regs->drive_config[1] = (FLOPPY_LINE_SEL_OFF << 20) | (FLOPPY_LINE_SEL_OFF << 16) | CFG_DISK_HD_SW | (CFG_RDYMSK_DATA) | (PIN_CFG_NOTDC1<<4) | PIN_CFG_NOTDENSITY;
	state->regs->drive_config[2] = (FLOPPY_LINE_SEL_OFF << 20) | (FLOPPY_LINE_SEL_OFF << 16) | CFG_DISK_HD_SW | (CFG_RDYMSK_DATA) | (PIN_CFG_NOTDC1<<4) | PIN_CFG_NOTDENSITY;
	state->regs->drive_config[3] = (FLOPPY_LINE_SEL_OFF << 20) | (FLOPPY_LINE_SEL_OFF << 16) | CFG_DISK_HD_SW | (CFG_RDYMSK_DATA) | (PIN_CFG_NOTDC1<<4) | PIN_CFG_NOTDENSITY;

	state->regs->in_signal_polarity_reg = 0x00000000;
	state->regs->out_signal_polarity_reg = 0x00000000;

	printf("drive_config[0] = 0x%.8X\n",state->regs->drive_config[0]);
}

void alloc_image(fpga_state * state, int drive, int track_size,int max_track, uint32_t base, int setfpga)
{
	int i;
	size_t pagesize;
	off_t page_base;
	off_t page_offset;
	uint32_t *tmp_ptr;

	if(!state)
		return;

	if(setfpga)
	{
		state->regs->image_base_address_reg[drive] = base;
		state->regs->image_track_size_reg[drive] = track_size;
		state->regs->image_max_track_reg[drive] = max_track;
	}
	else
	{
		base = state->regs->image_base_address_reg[drive];
		track_size = state->regs->image_track_size_reg[drive];
		max_track = state->regs->image_max_track_reg[drive];
	}

	pagesize = sysconf(_SC_PAGE_SIZE);

	page_base = (base / pagesize) * pagesize;
	page_offset = base - page_base;

	state->disk_image[drive] = mmap(NULL, page_offset + (track_size * max_track), PROT_READ | PROT_WRITE, MAP_SHARED, state->fd, page_base);
	if( state->disk_image[drive] == MAP_FAILED )
	{
		perror("map failed !");
		return;
	}

	if(setfpga)
	{
		tmp_ptr = (uint32_t *)state->disk_image[drive];
		i = ((track_size/sizeof(uint32_t)) * max_track)/4;
		while(i--)
		{
			*tmp_ptr++ = 0x00000000;
			*tmp_ptr++ = 0x00000000;
			*tmp_ptr++ = 0x00000000;
			*tmp_ptr++ = 0x00000000;
		}
	}
}

void alloc_dump_buffer(fpga_state * state, uint32_t base, int buffer_size, int setfpga)
{
	int i;
	size_t pagesize;
	off_t page_base;
	off_t page_offset;
	uint32_t *tmp_ptr;

	if(!state)
		return;

	if(setfpga)
	{
		state->regs->floppy_dump_base_address = base;
		state->regs->floppy_dump_buffer_size = buffer_size;
	}
	else
	{
		base = state->regs->floppy_dump_base_address;
		buffer_size = state->regs->floppy_dump_buffer_size;
	}

	pagesize = sysconf(_SC_PAGE_SIZE);

	page_base = (base / pagesize) * pagesize;
	page_offset = base - page_base;

	if(!state->dump_buffer)
	{
		state->dump_buffer_size = page_offset + buffer_size;
		state->dump_buffer = mmap(NULL, page_offset + buffer_size, PROT_READ | PROT_WRITE, MAP_SHARED, state->fd, page_base);
		if( state->dump_buffer == MAP_FAILED )
		{
			perror("map failed !");
			return;
		}
	}

	if(setfpga)
	{
		tmp_ptr = (uint32_t *)state->dump_buffer;
		i = ((buffer_size/sizeof(uint32_t)))/4;
		while(i--)
		{
			*tmp_ptr++ = 0x00000000;
			*tmp_ptr++ = 0x00000000;
			*tmp_ptr++ = 0x00000000;
			*tmp_ptr++ = 0x00000000;
		}
	}
}

void free_dump_buffer(fpga_state * state)
{
	if(state->dump_buffer)
	{
		munmap(state->dump_buffer, state->dump_buffer_size);
		state->dump_buffer = NULL;
	}
}

void deinit_fpga(fpga_state * state)
{
	if(state)
	{
		if(state->conv_lut)
			free(state->conv_lut);

		free(state);
	}
}

void floppy_ctrl_select_drive(fpga_state * state, int drive, int enable)
{
	pthread_mutex_lock( &state->io_fpga_mutex );

	if(enable)
		*(((volatile uint32_t*)(state->regs)) + state->drive_sel_reg_number[drive&3]) |= (state->drive_sel_bit_mask[drive&3]);
	else
		*(((volatile uint32_t*)(state->regs)) + state->drive_sel_reg_number[drive&3]) &= ~(state->drive_sel_bit_mask[drive&3]);

	pthread_mutex_unlock( &state->io_fpga_mutex );

}

void floppy_ctrl_motor(fpga_state * state, int drive, int enable)
{
	pthread_mutex_lock( &state->io_fpga_mutex );

	if(enable)
		*(((volatile uint32_t*)(state->regs)) + state->drive_mot_reg_number[drive&3]) |= (state->drive_mot_bit_mask[drive&3]);
	else
		*(((volatile uint32_t*)(state->regs)) + state->drive_mot_reg_number[drive&3]) &= ~(state->drive_mot_bit_mask[drive&3]);

	pthread_mutex_unlock( &state->io_fpga_mutex );

}

void floppy_ctrl_selectbyte(fpga_state * state, unsigned char byte)
{
	pthread_mutex_lock( &state->io_fpga_mutex );

	state->regs->floppy_ctrl_control = ( (state->regs->floppy_ctrl_control & ~0x1F) | (byte & 0x1F));

	pthread_mutex_unlock( &state->io_fpga_mutex );
}


void floppy_ctrl_side(fpga_state * state, int drive, int side)
{
	pthread_mutex_lock( &state->io_fpga_mutex );

	if(side)
		state->regs->floppy_ctrl_control |=  (0x20);
	else
		state->regs->floppy_ctrl_control &= ~(0x20);

	pthread_mutex_unlock( &state->io_fpga_mutex );

}


void floppy_ctrl_move_head(fpga_state * state, int dir, int trk)
{
	pthread_mutex_lock( &state->io_fpga_mutex );

	state->regs->floppy_ctrl_steprate = 12000;
	state->regs->floppy_ctrl_headmove = 0x10000 | ((dir&1)<<17) | (trk & 0x1FF);

	pthread_mutex_unlock( &state->io_fpga_mutex );

	while(state->regs->floppy_ctrl_headmove & 0x10000)
	{

	}
}

int floppy_head_recalibrate(fpga_state * state)
{
	int i;

	i = 0;
	while( !(state->regs->floppy_ctrl_control & (0x1<<6)) && i < 160 )
	{
		floppy_ctrl_move_head(state, 0, 1);
		usleep(10000);
		i++;
	}

	if(i>=160)
		return -1;

	for(i=0;i<4;i++)
	{
		floppy_ctrl_move_head(state, 1, 1);
		usleep(12000);
	}

	if( (state->regs->floppy_ctrl_control & (0x1<<6)) )
		return -2;

	i = 0;
	while( !(state->regs->floppy_ctrl_control & (0x1<<6)) && i < 5 )
	{
		floppy_ctrl_move_head(state, 0, 1);
		usleep(12000);
		i++;
	}

	if(i>=5)
		return -3;

	return 0;
}

void set_select_src(fpga_state * state, int drive, int src)
{
	uint32_t tmp;

	if(state)
	{
		pthread_mutex_lock( &state->io_fpga_mutex );

		tmp = state->regs->drive_config[drive&3];
		tmp &= ~(0xF << 16);
		tmp |= ((src&0xF) << 16);
		state->regs->drive_config[drive&3] = tmp;

		pthread_mutex_unlock( &state->io_fpga_mutex );
	}
}

void set_motor_src(fpga_state * state, int drive, int src)
{
	uint32_t tmp;

	if(state)
	{
		pthread_mutex_lock( &state->io_fpga_mutex );

		tmp = state->regs->drive_config[drive&3];
		tmp &= ~(0xF << 20);
		tmp |= ((src&0xF) << 20);
		state->regs->drive_config[drive&3] = tmp;

		pthread_mutex_unlock( &state->io_fpga_mutex );
	}
}

void enable_drive(fpga_state * state, int drive, int enable)
{
	uint32_t tmp;

	if(state)
	{
		pthread_mutex_lock( &state->io_fpga_mutex );

		tmp = state->regs->control_reg;

		if(enable)
			tmp |= (0x1<<(drive&3));
		else
			tmp &= ~(0x1<<(drive&3));

		tmp = tmp | 0x8000;

		state->regs->control_reg = tmp;

		pthread_mutex_unlock( &state->io_fpga_mutex );
	}
}

void start_dump(fpga_state * state, uint32_t buffersize, int res, int delay, int ignore_index)
{
	uint32_t tmp;

	pthread_mutex_lock( &state->io_fpga_mutex );

	state->regs->dump_timeout_value = 2000 * 1000; // 2s
	state->regs->dump_delay_value = delay; // 100ms

	state->regs->control_reg &= ~0x4010;
	state->regs->floppy_ctrl_control &= ~(0x3 << 20);

	state->last_dump_offset = 0x00000000;

	pthread_mutex_unlock( &state->io_fpga_mutex );

	alloc_dump_buffer(state, DUMP_IMAGE_BASE , buffersize, 1);

	pthread_mutex_lock( &state->io_fpga_mutex );

	state->regs->floppy_continuous_mode = state->regs->floppy_continuous_mode & ~0x10;

	tmp = state->regs->control_reg;
	tmp = tmp | 0x4010;
	state->regs->control_reg = tmp;

	if(res)
		state->regs->floppy_ctrl_control &= ~(0x1 << 22);
	else
		state->regs->floppy_ctrl_control |= (0x1 << 22);

	if(!ignore_index)
		state->regs->floppy_ctrl_control &= ~(0x1 << 23);
	else
		state->regs->floppy_ctrl_control |= (0x1 << 23);

	state->regs->floppy_ctrl_control |= (0x1 << 21);
	usleep(100);
	state->regs->floppy_ctrl_control |= (0x1 << 20);

	pthread_mutex_unlock( &state->io_fpga_mutex );
}

#define CHUNCK_MAX_SIZE ((((50000000/16)*4) / 16) & ~3) // a chunk size = 1/16 seconds @ 50Mhz

unsigned char * get_next_available_stream_chunk(fpga_state * state, uint32_t * size)
{
	uint32_t packed_size;
	unsigned char * ptr;
	int samplerate;
	int chunk_size;

	while( ((state->regs->floppy_dump_cur_track_offset - state->last_dump_offset) < CHUNCK_MAX_SIZE) && !(state->regs->floppy_done & ((0x01 << 4) | (0x01 << 5))) )
	{
		usleep(1000);
	}

	if( state->regs->floppy_done & (0x01 << 5) )
	{
		printf("Error : Index timeout...\n");
		return NULL;
	}

	packed_size = 0;

	if( state->regs->floppy_ctrl_control & (0x1 << 22) )
		samplerate = 25000000;
	else
		samplerate = 50000000;

	if( state->regs->floppy_dump_buffer_size - state->last_dump_offset > CHUNCK_MAX_SIZE)
		chunk_size = CHUNCK_MAX_SIZE;
	else
		chunk_size = state->regs->floppy_dump_buffer_size - state->last_dump_offset;

	if(chunk_size>0)
	{
		ptr = generate_chunk(state, (uint16_t*)&state->dump_buffer[state->last_dump_offset/2], (uint32_t)chunk_size, &packed_size, state->chunk_number,samplerate,&state->bitdelta);
		if(ptr)
		{
			state->last_dump_offset += chunk_size;
			state->chunk_number++;
			*size = packed_size;
			return ptr;
		}
	}

	return NULL;
}

void stop_dump(fpga_state * state)
{

}

void print_fpga_regs(fpga_state * state)
{
	int i;

	printf("FPGA Registers :\n");

	printf("control_reg : 0x%.8X\n",state->regs->control_reg);

	for(i=0;i<4;i++)
	{
		//printf("DMA POP FIFO %d empty event : %ul\n",i,state->regs->dma_pop_fifos_empty_event[i]);
	}

	for(i=0;i<5;i++)
	{
		//printf("DMA PUSH FIFO %d full event : %ul\n",i,state->regs->dma_push_fifos_full_event[i]);
	}

	for(i=0;i<4;i++)
	{
		printf("-- Drive %d : --\n",i);
		printf("image_base_address_reg : 0x%.8X\n",state->regs->image_base_address_reg[i]);
		printf("image_track_size_reg : 0x%.8X\n",state->regs->image_track_size_reg[i]);
		printf("image_max_track_reg : 0x%.8X\n",state->regs->image_max_track_reg[i]);
		printf("floppy_track_offset : 0x%.8X\n",state->regs->floppy_track_offset[i]);
		printf("drive_config : 0x%.8X\n",state->regs->drive_config[i]);
		printf("drv_index_len : 0x%.8X\n",state->regs->drv_index_len[i]);
		printf("drv_track_index_start : 0x%.8X\n",state->regs->drv_track_index_start[i]);
		printf("floppy_track_pos : 0x%.8X\n",state->regs->floppy_track_pos[i]);
		printf("\n");
	}

	printf("in_signal_polarity_reg : 0x%.8X\n",state->regs->in_signal_polarity_reg);
	printf("out_signal_polarity_reg : 0x%.8X\n",state->regs->out_signal_polarity_reg);
	printf("cur_track_base_address : 0x%.8X\n",state->regs->cur_track_base_address);
	printf("address_offset : 0x%.8X\n",state->regs->address_offset);
	printf("drv0_qdstopmotor_len : 0x%.8X\n",state->regs->drv0_qdstopmotor_len);
	printf("drv0_qdstopmotor_start : 0x%.8X\n",state->regs->drv0_qdstopmotor_start);
	printf("floppy_ctrl_control : 0x%.8X\n",state->regs->floppy_ctrl_control);
	printf("floppy_ctrl_steprate : 0x%.8X\n",state->regs->floppy_ctrl_steprate);
	printf("floppy_ctrl_headmove : 0x%.8X\n",state->regs->floppy_ctrl_headmove);
	printf("floppy_ctrl_curtrack : 0x%.8X\n",state->regs->floppy_ctrl_curtrack);
	printf("floppy_dump_base_address : 0x%.8X\n",state->regs->floppy_dump_base_address);
	printf("floppy_dump_buffer_size : 0x%.8X\n",state->regs->floppy_dump_buffer_size);
	printf("floppy_dump_cur_track_offset : 0x%.8X\n",state->regs->floppy_dump_cur_track_offset);
	printf("floppy_continuous_mode : 0x%.8X\n",state->regs->floppy_continuous_mode);
	printf("floppy_done : 0x%.8X\n",state->regs->floppy_done);

	printf("\n");
}

void set_extio(fpga_state * state, int io, int oe, int data)
{
	if(state)
	{
		pthread_mutex_lock( &state->io_fpga_mutex );

		if(oe)
		{
			if(data)
				state->regs->gpio_reg |=  ( (0x01 << 2) << (io&3) );
			else
				state->regs->gpio_reg &= ~( (0x01 << 2) << (io&3) );

			state->regs->gpio_oe_reg |= ( (0x01 << 2) << (io&3) );
		}
		else
		{
			state->regs->gpio_oe_reg &= ~( (0x01 << 2) << (io&3) );

			if(data)
				state->regs->gpio_reg |=  ( (0x01 << 2) << (io&3) );
			else
				state->regs->gpio_reg &= ~( (0x01 << 2) << (io&3) );
		}

		pthread_mutex_unlock( &state->io_fpga_mutex );
	}
}

void test_interface(fpga_state * state)
{
	uint32_t i,j;
	int err_cnt[32],good_cnt[32];

	#define HOST_OUTPUT_MASK   0x1C42E009   // 0001 1100 0100 0010 1110 0000 0000 1001
	#define FLOPPY_OUTPUT_MASK 0x03BD1FF6   // 0000 0011 1011 1101 0001 1111 1111 0110

	if(state)
	{
		state->regs->gpio_reg = 0x01 | ((0x1) << 6);

		state->regs->control_reg = 0x40000000;

		state->regs->floppy_port_io = 0xFFFFFFFF;
		state->regs->host_port_io = 0xFFFFFFFF;

		memset(err_cnt,0,sizeof(err_cnt));
		memset(good_cnt,0,sizeof(good_cnt));

		printf("Host -> Floppy test\n");
		for(j=0;j<4096;j++)
		{
			if(j&1)
				state->regs->gpio_reg = ((j>>8)&3) | ((0x1) << 6) ;
			else
				state->regs->gpio_reg = (((j>>8)&3) | 0x80) | ((0x1) << 6);

			for(i=0;i<32;i++)
			{
				if( (0x00000001<<i) & HOST_OUTPUT_MASK)
				{
					state->regs->host_port_io = ~(0x00000001<<i) ;
					usleep(10);
					if( ((~(0x00000001<<i)) & HOST_OUTPUT_MASK ) == ( state->regs->floppy_port_io & HOST_OUTPUT_MASK ) )
					{
						good_cnt[i]++;
						//printf("(%.2d) OK ! 0x%.8X 0x%.8X\n",i,state->regs->host_port_io,state->regs->floppy_port_io);
					}
					else
					{
						err_cnt[i]++;
						//printf("(%.2d) KO ! 0x%.8X 0x%.8X\n",i,state->regs->host_port_io,state->regs->floppy_port_io);
					}
				}
			}
		}

		for(i=0;i<32;i++)
		{
			if(good_cnt[i] || err_cnt[i])
			{
				if(err_cnt[i])
				{
					printf("(%.2d) KO ! (%d / %d)\n",i,good_cnt[i],err_cnt[i]);
				}
				else
				{
					printf("(%.2d) OK !\n",i);
				}
			}
		}

		state->regs->floppy_port_io = 0xFFFFFFFF;
		state->regs->host_port_io = 0xFFFFFFFF;

		memset(err_cnt,0,sizeof(err_cnt));
		memset(good_cnt,0,sizeof(good_cnt));

		printf("Floppy -> Host test\n");
		for(j=0;j<4096;j++)
		{
			if(j&1)
				state->regs->gpio_reg = ((j>>8)&3) | ((0x1) << 6);
			else
				state->regs->gpio_reg = (((j>>8)&3) | 0x80) | ((0x1) << 6);

			for(i=0;i<32;i++)
			{
				if( (0x00000001<<i) & FLOPPY_OUTPUT_MASK)
				{
					state->regs->floppy_port_io = ~(0x00000001<<i) ;
					usleep(10);
					if( ((~(0x00000001<<i)) & FLOPPY_OUTPUT_MASK ) == ( state->regs->host_port_io & FLOPPY_OUTPUT_MASK ) )
					{
						good_cnt[i]++;
						//printf("(%.2d) OK ! 0x%.8X 0x%.8X\n",i,state->regs->floppy_port_io,state->regs->host_port_io);
					}
					else
					{
						err_cnt[i]++;
						//printf("(%.2d) KO ! 0x%.8X 0x%.8X\n",i,state->regs->floppy_port_io,state->regs->host_port_io);
					}
				}
			}
		}

		for(i=0;i<32;i++)
		{
			if(good_cnt[i] || err_cnt[i])
			{
				if(err_cnt[i])
				{
					printf("(%.2d) KO ! (%d / %d)\n",i,good_cnt[i],err_cnt[i]);
				}
				else
				{
					printf("(%.2d) OK !\n",i);
				}
			}
		}

		state->regs->gpio_reg = 1 | ((0x1) << 6);

		state->regs->gpio_oe_reg = ((0xF) << 2);
		for(i=0;i<4;i++)
		{
			state->regs->gpio_oe_reg = ((0xF) << 2);

			state->regs->gpio_reg = ((0x1<<i) << 2);
			usleep(10);
			printf("(%.2d) (0x%.1X) 0x%.1X   ",i,(0x1<<i),(~state->regs->gpio_in_reg>>2)&0xF);

			state->regs->gpio_oe_reg = (((~0x1)&0xF) << 2);
			usleep(10);
			printf("(0x1|)0x%.1X ",(~state->regs->gpio_in_reg>>2)&0xF);

			state->regs->gpio_oe_reg = (((~0x2)&0xF) << 2);
			usleep(10);
			printf("(0x2|)0x%.1X ",(~state->regs->gpio_in_reg>>2)&0xF);

			state->regs->gpio_oe_reg = (((~0x4)&0xF) << 2);
			usleep(10);
			printf("(0x4|)0x%.1X ",(~state->regs->gpio_in_reg>>2)&0xF);

			state->regs->gpio_oe_reg = (((~0x8)&0xF) << 2);
			usleep(10);
			printf("(0x8|)0x%.1X ",(~state->regs->gpio_in_reg>>2)&0xF);

			state->regs->gpio_oe_reg = (((~0xF)&0xF) << 2);
			usleep(10);
			printf("   0x%.1X ",(~state->regs->gpio_in_reg>>2)&0xF);

			printf("\n");
		}

		printf("\n");
		state->regs->gpio_reg = ((0x1) << 6);
		usleep(10);
		printf("1 -> %d\n",(state->regs->gpio_in_reg>>6)&1);
		state->regs->gpio_reg = ((0x0) << 6);
		usleep(10);
		printf("0 -> %d\n",(state->regs->gpio_in_reg>>6)&1);

		for(i=0;i<100;i++)
		{
			printf("PB1:%d ",(state->regs->gpio_in_reg>>8)&1);
			printf("PB2:%d ",(state->regs->gpio_in_reg>>9)&1);
			printf("PB3:%d ",(state->regs->gpio_in_reg>>10)&1);
			printf("INT:%d\n",(state->regs->gpio_in_reg>>7)&1);
			usleep(1000*100);
		}

	}
}
