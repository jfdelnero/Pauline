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
	{"DRIVES_PORT_DS0",                    OUT_OC,   0x23,  0},
	{"DRIVES_PORT_MOTEA",                  OUT_OC,   0x23,  0},
	{"DRIVES_PORT_PIN10",                  OUT_OC,   0x23,  0},
	{"DRIVES_PORT_MOTON_TWISTED_RIBBON",   OUT_OC,   0x23,  0},
	{"DRIVES_PORT_MOTEB_TWISTED_RIBBON",   OUT_OC,   0x23,  0},
	{"DRIVES_PORT_PIN16_TWISTED_RIBBON",   OUT_OC,   0x23,  0},

	{"DRIVES_PORT_DS1",                    OUT_OC,   0x23,  1},
	{"DRIVES_PORT_DRVSB",                  OUT_OC,   0x23,  1},
	{"DRIVES_PORT_PIN12",                  OUT_OC,   0x23,  1},
	{"DRIVES_PORT_DS2_TWISTED_RIBBON",     OUT_OC,   0x23,  1},
	{"DRIVES_PORT_DRVSA_TWISTED_RIBBON",   OUT_OC,   0x23,  1},
	{"DRIVES_PORT_PIN14_TWISTED_RIBBON",   OUT_OC,   0x23,  1},

	{"DRIVES_PORT_DS2",                    OUT_OC,   0x23,  2},
	{"DRIVES_PORT_DRVSA",                  OUT_OC,   0x23,  2},
	{"DRIVES_PORT_PIN14",                  OUT_OC,   0x23,  2},
	{"DRIVES_PORT_DS1_TWISTED_RIBBON",     OUT_OC,   0x23,  2},
	{"DRIVES_PORT_DRVSB_TWISTED_RIBBON",   OUT_OC,   0x23,  2},
	{"DRIVES_PORT_PIN12_TWISTED_RIBBON",   OUT_OC,   0x23,  2},

	{"DRIVES_PORT_DS3",                    OUT_OC,   0x23,  3},
	{"DRIVES_PORT_PIN6",                   OUT_OC,   0x23,  3},

	{"DRIVES_PORT_MOTON",                  OUT_OC,   0x23,  4},
	{"DRIVES_PORT_MOTEB",                  OUT_OC,   0x23,  4},
	{"DRIVES_PORT_PIN16",                  OUT_OC,   0x23,  4},
	{"DRIVES_PORT_DS0_TWISTED_RIBBON",     OUT_OC,   0x23,  4},
	{"DRIVES_PORT_MOTEA_TWISTED_RIBBON",   OUT_OC,   0x23,  4},
	{"DRIVES_PORT_PIN10_TWISTED_RIBBON",   OUT_OC,   0x23,  4},


	{"DRIVES_PORT_SIDE1",                  OUT_OC,   0x23,  5},

	{"DRIVES_PORT_TRK00",                INPUT_ST,   0x23,  6},
	{"DRIVES_PORT_DATA",                 INPUT_ST,   0x23,  7},
	{"DRIVES_PORT_WPT",                  INPUT_ST,   0x23,  8},
	{"DRIVES_PORT_INDEX",                INPUT_ST,   0x23,  9},
	{"DRIVES_PORT_PIN02",                INPUT_ST,   0x23,  10},
	{"DRIVES_PORT_PIN34",                INPUT_ST,   0x23,  11},

	{"DRIVES_PORT_PIN02_OUT",              OUT_OC,   0x43,  0},
	{"DRIVES_PORT_MODESELECT",             OUT_OC,   0x43,  0},

	{"DRIVES_PORT_PIN04_OUT",              OUT_OC,   0x43,  1},

	{"DRIVES_PORT_X68000_OPTIONSEL0_OUT",  OUT_OC,   0x43,  2},
	{"DRIVES_PORT_PIN01_OUT",              OUT_OC,   0x43,  2},

	{"DRIVES_PORT_X68000_OPTIONSEL1_OUT",  OUT_OC,   0x43,  3},
	{"DRIVES_PORT_PIN03_OUT",              OUT_OC,   0x43,  3},

	{"DRIVES_PORT_X68000_OPTIONSEL2_OUT",  OUT_OC,   0x43,  4},
	{"DRIVES_PORT_PIN05_OUT",              OUT_OC,   0x43,  4},

	{"DRIVES_PORT_X68000_OPTIONSEL3_OUT",  OUT_OC,   0x43,  5},
	{"DRIVES_PORT_PIN07_OUT",              OUT_OC,   0x43,  5},

	{"DRIVES_PORT_X68000_BLINK_OUT",       OUT_OC,   0x43,  6},
	{"DRIVES_PORT_PIN13_OUT",              OUT_OC,   0x43,  6},

	{"DRIVES_PORT_X68000_LOCK_OUT",        OUT_OC,   0x43,  7},
	{"DRIVES_PORT_PIN11_OUT",              OUT_OC,   0x43,  7},

	{"DRIVES_PORT_X68000_EJECT_OUT",       OUT_OC,   0x43,  8},
	{"DRIVES_PORT_PIN09_OUT",              OUT_OC,   0x43,  8},

	{"LED_LED1_OUT",                       OUT_PP,   0x40,  0},
	{"LED_LED2_OUT",                       OUT_PP,   0x40,  1},

	{"EXPENSION_PORT_TRIS_IO0_PIN07_OUT",  OUT_PP,   0x40,  2},
	{"EXPENSION_PORT_TRIS_IO1_PIN08_OUT",  OUT_PP,   0x40,  3},
	{"EXPENSION_PORT_TRIS_IO2_PIN09_OUT",  OUT_PP,   0x40,  4},
	{"EXPENSION_PORT_TRIS_IO3_PIN10_OUT",  OUT_PP,   0x40,  5},
	{"EXPENSION_PORT_EXT_IO_OUT",          OUT_OC,   0x40,  6},

	{"EXPENSION_PORT_TRIS_IO0_PIN07_OE",   CTRL,     0x41,  2},
	{"EXPENSION_PORT_TRIS_IO1_PIN08_OE",   CTRL,     0x41,  3},
	{"EXPENSION_PORT_TRIS_IO2_PIN09_OE",   CTRL,     0x41,  4},
	{"EXPENSION_PORT_TRIS_IO3_PIN10_OE",   CTRL,     0x41,  5},

	{"EXPENSION_PORT_TRIS_IO0_PIN07_IN",  INPUT_ST,  0x42,  2},
	{"EXPENSION_PORT_TRIS_IO1_PIN08_IN",  INPUT_ST,  0x42,  3},
	{"EXPENSION_PORT_TRIS_IO2_PIN09_IN",  INPUT_ST,  0x42,  4},
	{"EXPENSION_PORT_TRIS_IO3_PIN10_IN",  INPUT_ST,  0x42,  5},
	{"EXPENSION_PORT_EXT_IO_IN",          INPUT_ST,  0x42,  6},
	{"EXPENSION_PORT_EXT_INT_IN",         INPUT_ST,  0x42,  7},
	{"PUSH_BUTTON_0_IN",                  INPUT,     0x42,  8},
	{"PUSH_BUTTON_1_IN",                  INPUT,     0x42,  9},
	{"PUSH_BUTTON_2_IN",                  INPUT,     0x42,  10},

	{ NULL,                               INPUT_ST,  0x00,  0},
};

void print_ios_list()
{
	int i;

	printf("\nIOs List :\n");

	i = 0;
	while(ios_definition[i].name)
	{
		switch(ios_definition[i].type)
		{
			case INPUT:
				printf("INPUT     : ");
			break;
			case INPUT_ST:
				printf("INPUT_ST  : ");
			break;
			case OUT_OC:
				printf("OUTPUT_OC : ");
			break;
			case OUT_PP:
				printf("OUTPUT_PP : ");
			break;
			case CTRL:
				printf("CONTROL   : ");
			break;

			default:
			break;
		}

		printf("%s\n",ios_definition[i].name);

		i++;
	}

	printf("\n");
}

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
