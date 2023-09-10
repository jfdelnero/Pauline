/*
//
// Copyright (C) 2019-2023 Jean-François DEL NERO
//
// This file is part of the Pauline splash screen software
//
// Pauline splash screen software may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// Pauline splash screen software is free software; you can redistribute it
// and/or modify  it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Pauline splash screen software is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//   See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pauline splash screen software; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "types.h"
#include "bmp_file.h"

#define SCREEN_TTY "/dev/tty1"

#define SCREEN_FB "/dev/fb0"

#define FB_XSIZE 128
#define FB_YSIZE 64


void fbcon_cursor (int blank)
{
	int fd,ret;

	fd = open( SCREEN_TTY, O_RDWR);
	if(fd)
	{
		ret = write(fd, "\033[?25", 5);
		if(ret < 0)
			goto error;

		ret = write(fd, blank ? "h" : "l", 1);
		if(ret < 0)
			goto error;

		close(fd);
	}
	else
		goto error;

	return;

error:
	if(fd)
		close(fd);

	fprintf(stderr,"ERROR : Can't write to the screen tty !\n");

	return;
}

int getpixstate(bitmap_data * bdata, int xpos, int ypos)
{
	if( (xpos < bdata->xsize) && (ypos < bdata->ysize) )
	{
			if( bdata->data[( bdata->xsize * ypos ) + xpos] )
			{
					return 1;
			}
	}

	return 0;
}

void set_fb_pixstate(unsigned char * buffer,int xpos, int ypos,int state)
{
	int buffer_offset;

	if( (xpos < FB_XSIZE) && (ypos < FB_YSIZE) )
	{
		buffer_offset = ((ypos * FB_XSIZE) + xpos) / 8;

		if(state)
		{
			buffer[buffer_offset] |= (0x01 << (xpos&7));
		}
		else
		{
			buffer[buffer_offset] &= ~(0x01 << (xpos&7));
		}
	}
}

/*
void fbcon_blank (int blank)
{
ioctl(fb.fd, FBIOBLANK, blank ? VESA_POWERDOWN: VESA_NO_BLANKING);
return;
}*/

int main(int argc, char *argv[])
{
	bitmap_data bmp;
	unsigned char * buffer;
	int x,y,fd;
	int ret;

	if(argc > 1)
	{
		buffer = malloc((FB_XSIZE*FB_YSIZE)/8);
		if(buffer)
		{
			fbcon_cursor (0);

			if(!bmp_load(argv[1],&bmp))
			{
				for(y=0;y<FB_YSIZE;y++)
				{
					for(x=0;x<FB_XSIZE;x++)
					{
						set_fb_pixstate(buffer,x, y, getpixstate(&bmp, x, y));
					}
				}

				fd = open( SCREEN_FB, O_RDWR);
				if(fd)
				{
					ret = write(fd, buffer, (FB_XSIZE*FB_YSIZE)/8);
					if(ret < 0)
						fprintf(stderr,"ERROR : Error while writing to the frame buffer !\n");

					close(fd);
				}
				else
					fprintf(stderr,"ERROR : Can't write to the frame buffer !\n");

				if(bmp.data)
					free(bmp.data);
			}
			free(buffer);
		}
	}

	return 0;
}

