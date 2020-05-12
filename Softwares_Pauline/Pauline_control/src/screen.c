/*
//
// Copyright (C) 2019-2020 Jean-François DEL NERO
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
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdarg.h>

#include "types.h"
#include "bmp_file.h"

#include "screen.h"

#include "font_x_b_8x13.h"

#define SCREEN_TTY "/dev/tty1"

#define SCREEN_FB "/dev/fb0"

#define FB_XSIZE 128
#define FB_YSIZE 64


int fbcon_cursor (int blank)
{
	int fd,ret;

	ret = -1;

	fd = open( SCREEN_TTY, O_RDWR);
	if(fd)
	{
		ret = write(fd, "\033[?25", 5);
		ret = write(fd, blank ? "h" : "l", 1);

		close(fd);
	}
	
	return ret;
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

void print_char_screen(unsigned char * buffer,int xpos, int ypos, unsigned char c)
{
	int char_offset;
	int x,y;
	int bit_offset;
	unsigned char * char_ptr;

	char_offset = c * font_x_b_8x13.char_size;
 
	if( char_offset < font_x_b_8x13.buffer_size )
	{
		bit_offset = 0;
		char_ptr = (unsigned char*)&font_x_b_8x13.font_data[char_offset];
		for(y=0;y<font_x_b_8x13.char_y_size;y++)
		{
			for(x=0;x<font_x_b_8x13.char_x_size;x++)
			{
				if( char_ptr[bit_offset>>3] & (0x80>>(bit_offset&7)) )
				{
					set_fb_pixstate(buffer, xpos + x, ypos + y,1);
				}
				else
				{
					set_fb_pixstate(buffer, xpos + x, ypos + y,0);
				}
				bit_offset++;
			}			 
		}
	}
}

void printf_screen(int xpos, int ypos, char * string, ...)
{
	int i;
	char fullline[512];
	unsigned char * buffer;
	int fd,ret;

	va_list marker;

	buffer = malloc((FB_XSIZE*FB_YSIZE)/8);
	if(!buffer)
		return;

	fd = open( SCREEN_FB, O_RDWR);
	if(fd)
	{
		ret = read(fd, buffer, (FB_XSIZE*FB_YSIZE)/8);

		va_start( marker, string );

		vsnprintf(fullline,sizeof(fullline),string,marker);

		va_end( marker );

		if(xpos == -1)
		{
			xpos = (strlen(fullline)*font_x_b_8x13.char_x_size);
			if(xpos > FB_XSIZE)
				xpos = 0;
			else
				xpos = (FB_XSIZE - xpos) / 2;
		}

		if(ypos == -1)
		{
			ypos = (font_x_b_8x13.char_y_size);
			if(ypos > FB_YSIZE)
				ypos = 0;
			else
				ypos = (FB_YSIZE - ypos) / 2;
		}

		i = 0;
		while(fullline[i])
		{
			print_char_screen(buffer,xpos, ypos, fullline[i]);
			xpos += font_x_b_8x13.char_x_size;
			i++;
		}

		lseek(fd, 0, SEEK_SET);

		ret = write(fd, buffer, (FB_XSIZE*FB_YSIZE)/8);

		close(fd);
	}

	free(buffer);
}

/*
void fbcon_blank (int blank)
{
ioctl(fb.fd, FBIOBLANK, blank ? VESA_POWERDOWN: VESA_NO_BLANKING);
return;
}*/

void splash_screen(	bitmap_data * screen )
{
	unsigned char * buffer;
	int x,y,fd;
	int ret;

	if(!screen)
		return;

	buffer = malloc((FB_XSIZE*FB_YSIZE)/8);
	if(buffer)
	{

		for(y=0;y<FB_YSIZE;y++)
		{
			for(x=0;x<FB_XSIZE;x++)
			{
				set_fb_pixstate(buffer,x, y, getpixstate(screen, x, y));
			}
		}

		fd = open( SCREEN_FB, O_RDWR);
		if(fd)
		{
			ret = write(fd, buffer, (FB_XSIZE*FB_YSIZE)/8);
			close(fd);
		}

		free(buffer);
	}
}

bitmap_data * load_screen(char * file)
{
	bitmap_data * screen;

	screen = malloc(sizeof(bitmap_data));
	if(screen)
	{
		memset( screen,0,sizeof(bitmap_data));
		if(bmp_load(file,screen))
		{
			free(screen);
			screen = NULL;
		}
	}

	return screen;
}

void free_screen(bitmap_data * screen)
{
	if(!screen)
		return;

	if(screen->data)
		free(screen->data);

	free(screen);
}

void display_bmp(char * file)
{
	bitmap_data * screen;

	screen = load_screen(file);

	splash_screen( screen );
	
	free_screen( screen );
}

/*
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
					close(fd);
				}

				if(bmp.data)
					free(bmp.data);
			}
			free(buffer);
		}
	}

	return 0;
}
*/
