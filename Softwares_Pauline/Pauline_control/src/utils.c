/*
//
// Copyright (C) 2019-2023 Jean-François DEL NERO
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

void get_filename(char * path,char * filename)
{
	int i,done;

	i=strlen(path);
	done=0;
	while(i && !done)
	{
		i--;

		if(path[i]=='/')
		{
			done=1;
			i++;
		}
	}

	sprintf(filename,"%s",&path[i]);

	i=0;
	while(filename[i])
	{
		if(filename[i]=='.')
		{
			filename[i]='_';
		}

		i++;
	}

	return;
}

void delay_us(unsigned int us)
{
	#define USLEEP_MAX (1000000 - 1)
	unsigned int chunk;

	while(us > 0)
	{
		chunk = (us > USLEEP_MAX) ? USLEEP_MAX : us;
		usleep(chunk);
		us -= chunk;
	}
}


int us_to_fpga_clk(int us)
{
	return ((us* FPGA_CLOCK)/1000000);
}

int ms_to_fpga_clk(int ms)
{
	return ((ms* FPGA_CLOCK)/1000);
}
