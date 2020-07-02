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

#include "libhxcfe.h"

#include "ios.h"

#include "fpga.h"
#include "dump_chunk.h"

io_def ios_definition[]=
{
	{"FLOPPY_DUMP_DS0",       OUT_OC,   0x23,  0},
	{"FLOPPY_DUMP_DS1",       OUT_OC,   0x23,  1},
	{"FLOPPY_DUMP_DS2",       OUT_OC,   0x23,  2},
	{"FLOPPY_DUMP_DS3",       OUT_OC,   0x23,  3},
	{"FLOPPY_DUMP_MOTON",     OUT_OC,   0x23,  4},
	{"FLOPPY_DUMP_SIDE1",     OUT_OC,   0x23,  5},

	{"FLOPPY_DUMP_TRK00",   INPUT_ST,   0x23,  6},
	{"FLOPPY_DUMP_DATA",    INPUT_ST,   0x23,  7},
	{"FLOPPY_DUMP_WPT",     INPUT_ST,   0x23,  8},
	{"FLOPPY_DUMP_INDEX",   INPUT_ST,   0x23,  9},
	{"FLOPPY_DUMP_PIN02",   INPUT_ST,   0x23,  10},
	{"FLOPPY_DUMP_PIN34",   INPUT_ST,   0x23,  11},

	{ NULL,                 INPUT_ST,   0x00,  0},
};


int get_io_index(char * name)
{
	int i;

	i = 0;
	while(ios_definition[i].name)
	{
		if(!strcmp(ios_definition[i].name,name))
		{
			return i;
		}
		i++;
	}

	return -1;
}

int get_io_reg(int index)
{
	if(index < 0)
		return 0;

	return ios_definition[index].reg_number;
}

unsigned int get_io_bitmask(int index)
{
	if(index < 0)
		return 0;

	return 0x00000001 << ios_definition[index].bit_number;
}

void get_io_address(int index, int * regs, unsigned int * bitmask)
{
	if(index < 0)
		return;

	*regs = ios_definition[index].reg_number;
	*bitmask = (0x01 << ios_definition[index].bit_number);

	return;
}
