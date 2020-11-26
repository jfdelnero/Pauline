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

#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <linux/if_link.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <pthread.h>
#include <signal.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <malloc.h>
#include <fcntl.h>
#include <sys/mman.h>

#include <stdint.h>
#include <stdarg.h>

#include <ws.h>

#include <png.h>

#include "libhxcfe.h"

#include "script.h"

#include "fpga.h"
#include "dump_chunk.h"
#include "network.h"

#include "bmp_file.h"
#include "screen.h"

#include "messages.h"

#define MAX_CHUNK_BLOCKS_PER_PICTURE 16

extern fpga_state * fpga;
int    img_connection = 0;
pthread_t ws_thread[MAX_NB_CLIENTS];

pthread_t Image_thread;
void * ImageGeneratorThreadProc(void* context);

extern script_ctx * script_context;

extern FILE * tmp_file;

char file_to_analyse[512];
char last_file_to_analyse[512];

volatile int preview_image_flags = TD_FLAG_HICONTRAST;
volatile int preview_image_xtime = 600000;
volatile int preview_image_xoffset = 0;
volatile int preview_image_ytime = 16;

static void hxc_msleep (unsigned int ms) {
	int microsecs;
	struct timeval tv;
	microsecs = ms * 1000;
	tv.tv_sec  = microsecs / 1000000;
	tv.tv_usec = microsecs % 1000000;
	select (0, NULL, NULL, NULL, &tv);
}

void *websocket_txthread(void *threadid)
{
	int fd;
	char msg[MAX_MESSAGES_SIZE];

	pthread_detach(pthread_self());

	fd = (int) threadid;

	printf("websocket_txthread : handle %d, index %d\n",fd,handle_to_index(fd));

	while( msg_out_wait(handle_to_index(fd), (char*)&msg) > 0 )
	{
		ws_sendframe(fd, (char *)msg, -1, false);
	}

	pthread_exit(NULL);
}

void onopen(int fd)
{
	char *cli;
	int index;

	cli = ws_getaddress(fd);
	if(cli)
	{
		index = add_client(fd);

		display_bmp("/data/pauline_splash_bitmaps/connected.bmp");

		printf("Connection opened, client: %d | addr: %s, index : %d\n", fd, cli,index);

		if(index >= 0)
		{
			pthread_create(&ws_thread[index], NULL, websocket_txthread, (void*)fd);
		}

		free(cli);
	}
}

void onclose(int fd)
{
	char *cli;
	int index;

	cli = ws_getaddress(fd);

	if( cli )
	{
		index = handle_to_index(fd);

		exitwait(index);

		remove_client(index);

		printf("Connection closed, client: %d | addr: %s\n", fd, cli);
		free(cli);
	}
}

void onmessage(int fd, const unsigned char *msg)
{
	char *cli;

	cli = ws_getaddress(fd);

	if(cli)
	{
		//printf("I receive a message: %s, from: %s/%d\n", msg, cli, fd);

		msg_push_in_msg(handle_to_index(fd), (char*)msg);

		free(cli);
	}

	//msg_printf(" Hello ! :) ");
}


void *websocket_listener(void *threadid)
{
	struct ws_events evs;

	pthread_detach(pthread_self());

	evs.onopen    = &onopen;
	evs.onclose   = &onclose;
	evs.onmessage = &onmessage;
	ws_socket(&evs, 8080);

	pthread_exit(NULL);
}


void onopen_img(int fd)
{
	img_connection++;
}

void onclose_img(int fd)
{
	if(img_connection>0)
		img_connection--;
}

void onmessage_img(int fd, const unsigned char *msg)
{
	FILE *f;
	int size;
	unsigned char * ptr;

	f = fopen("/tmp/analysis.png","rb");
	if(f)
	{
		fseek(f,0,SEEK_END);
		size = ftell(f);
		fseek(f,0,SEEK_SET);

		if(size>0)
		{
			ptr= malloc(size);
			if(ptr)
			{
				fread(ptr,size,1,f);

				ws_sendframe(fd, (char *)ptr, size, false);

				free(ptr);
			}
		}

		fclose(f);
	}
}

void *websocket_image_listener(void *threadid)
{
	struct ws_events evs;

	pthread_detach(pthread_self());

	memset(file_to_analyse,0,sizeof(file_to_analyse));
	memset(last_file_to_analyse,0,sizeof(last_file_to_analyse));

	pthread_create(&Image_thread, NULL, ImageGeneratorThreadProc, (void*)NULL);

	evs.onopen    = &onopen_img;
	evs.onclose   = &onclose_img;
	evs.onmessage = &onmessage_img;
	ws_socket(&evs, 8081);

	pthread_exit(NULL);
}

void write_png_file(char* file_name, unsigned char * image, int width, int height)
{
	int i;
	png_byte color_type;
	png_byte bit_depth;
	png_structp png_ptr;
	png_infop info_ptr;
	png_bytep * row_pointers;
	uint32_t * lptr;
	uint32_t pixel;

	png_ptr = NULL;
	info_ptr = NULL;
	row_pointers = NULL;
	lptr = NULL;

	row_pointers = (png_bytep *)malloc(height*sizeof(png_bytep));
	if(!row_pointers)
		goto error;

	for(i=0;i<height;i++)
	{
		row_pointers[i] = (png_bytep)(image + (width*4*i));
	}

	lptr = (uint32_t *)image;
	for(i=0;i<height*width;i++)
	{
		pixel = *lptr;

		if( pixel != 0xFFFFFF )
		{
			*lptr = (pixel | 0xFF000000);
		}

		lptr++;
	}

	/* create file */
	FILE *fp = fopen(file_name, "wb");
	if (!fp)
		goto error;

	/* initialize stuff */
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

	if (!png_ptr)
		goto error;

	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr)
		goto error;

	if (setjmp(png_jmpbuf(png_ptr)))
		goto error;

	png_init_io(png_ptr, fp);

	/* write header */
	if (setjmp(png_jmpbuf(png_ptr)))
		goto error;

	color_type = PNG_COLOR_TYPE_RGB_ALPHA;
	bit_depth  = 8;

	png_set_IHDR(png_ptr, info_ptr, width, height,
				 bit_depth, color_type, PNG_INTERLACE_NONE,
				 PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

	png_write_info(png_ptr, info_ptr);

	/* write bytes */
	if (setjmp(png_jmpbuf(png_ptr)))
		goto error;

	png_write_image(png_ptr, row_pointers);

	/* end write */
	if (setjmp(png_jmpbuf(png_ptr)))
		goto error;

	png_write_end(png_ptr, NULL);

	/* cleanup heap allocation */
	/* for (y=0; y<height; y++)
			free(row_pointers[y]);
	*/

	png_destroy_write_struct(&png_ptr, &info_ptr);

	free(row_pointers);

	fclose(fp);

	return;

error:

	if(png_ptr && info_ptr)
	{
		png_destroy_write_struct(&png_ptr, &info_ptr);
	}

	free(row_pointers);

	fclose(fp);
	return;
}

void * ImageGeneratorThreadProc(void* context)
{
	HXCFE_TD * td;
	unsigned char * ptr1;
	unsigned char * buffer;
	unsigned char * full_track_buffer;
	int file_offset,tmp_file_offset,current_file_size;
	unsigned long * offset_table;
	int offset_table_index;
	FILE * f;
	chunk_header * ch;
	int ret;
	HXCFE_FXSA * fxsa;
	HXCFE_TRKSTREAM* trkstream;
	HXCFE_TD * td_stream;
	int xsize,ysize;

	#define OFFSET_TABLE_SIZE (128*1024)

	buffer = NULL;
	offset_table = NULL;
	full_track_buffer = NULL;

	xsize = 800;
	ysize = 480;

	buffer = (unsigned char*) malloc(1024*1024);
	if(!buffer)
		goto error;

	offset_table = (unsigned long *)malloc(OFFSET_TABLE_SIZE);
	if(!offset_table)
		goto error;

	memset(offset_table, 0, OFFSET_TABLE_SIZE);

	full_track_buffer = (unsigned char*) malloc(1024*1024);
	if(!full_track_buffer)
		goto error;

	memset(full_track_buffer,0,1024*1024);

	td_stream = hxcfe_td_init(fpga->libhxcfe,xsize,ysize);

	ret = 0;

	ch = (chunk_header *)buffer;

	offset_table_index = 0;

	file_offset = 0;

	while( ret >= 0 )
	{
		if(img_connection)
		{
			file_offset = 0;
			offset_table_index = 0;
			memset(offset_table,0,OFFSET_TABLE_SIZE);

			pthread_mutex_lock(&script_context->script_mutex);
			while(!file_to_analyse[0])
			{
				pthread_mutex_unlock(&script_context->script_mutex);
				hxc_msleep(20);
				pthread_mutex_lock(&script_context->script_mutex);
			};

			f = fopen(file_to_analyse,"rb");
			if(f)
			{
				file_to_analyse[0] = 0;
				pthread_mutex_unlock(&script_context->script_mutex);

				do
				{
					fseek(f,0,SEEK_END);
					current_file_size = ftell(f);
					fseek(f,file_offset,SEEK_SET);

					ret = fread(buffer,sizeof(chunk_header), 1, f);
					if(ret == 1)
					{
						if( (int)(file_offset + ch->size) <= current_file_size )
						{
							ret = fread(&buffer[sizeof(chunk_header)],ch->size - sizeof(chunk_header), 1, f);

							if(ret == 1)
							{
								fxsa = hxcfe_initFxStream(fpga->libhxcfe);

								if(fxsa)
								{
									trkstream = hxcfe_FxStream_ImportHxCStreamBuffer(fxsa,buffer,ch->size);

									if(trkstream)
									{
										if(ch->packet_number == 0)
										{
											offset_table_index=0;
										}

										offset_table[offset_table_index] = file_offset;

										offset_table_index++;

										hxcfe_FxStream_FreeStream( fxsa, trkstream );

										if(offset_table_index > MAX_CHUNK_BLOCKS_PER_PICTURE)
											tmp_file_offset = offset_table[offset_table_index - MAX_CHUNK_BLOCKS_PER_PICTURE];
										else
											tmp_file_offset = offset_table[0];

										tmp_file_offset = 0;
										file_offset = 0;

										ch->size = current_file_size;

										fseek(f,tmp_file_offset,SEEK_SET);

										if( fread(full_track_buffer,(file_offset - tmp_file_offset) + ch->size,1, f) == 1)
										{
											trkstream = hxcfe_FxStream_ImportHxCStreamBuffer(fxsa,full_track_buffer,(file_offset - tmp_file_offset) + ch->size);

											file_offset += ch->size;

											td = td_stream;

											hxcfe_td_activate_analyzer(td,ISOIBM_MFM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_ISOIBM_MFM_ENCODING"));
											hxcfe_td_activate_analyzer(td,ISOIBM_FM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_ISOIBM_FM_ENCODING"));
											hxcfe_td_activate_analyzer(td,AMIGA_MFM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_AMIGA_MFM_ENCODING"));
											hxcfe_td_activate_analyzer(td,EMU_FM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_EMU_FM_ENCODING"));
											hxcfe_td_activate_analyzer(td,MEMBRAIN_MFM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_MEMBRAIN_MFM_ENCODING"));
											hxcfe_td_activate_analyzer(td,TYCOM_FM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_TYCOM_FM_ENCODING"));
											hxcfe_td_activate_analyzer(td,APPLEII_GCR1_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_APPLEII_GCR1_ENCODING"));
											hxcfe_td_activate_analyzer(td,APPLEII_GCR2_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_APPLEII_GCR2_ENCODING"));
											hxcfe_td_activate_analyzer(td,APPLEMAC_GCR_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_APPLEMAC_GCR_ENCODING"));
											hxcfe_td_activate_analyzer(td,ARBURGDAT_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_ARBURGDAT_ENCODING"));
											hxcfe_td_activate_analyzer(td,ARBURGSYS_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_ARBURGSYS_ENCODING"));
											hxcfe_td_activate_analyzer(td,AED6200P_MFM_ENCODING,0);
											hxcfe_td_activate_analyzer(td,NORTHSTAR_HS_MFM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_NORTHSTAR_HS_MFM_ENCODING"));
											hxcfe_td_activate_analyzer(td,HEATHKIT_HS_FM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_HEATHKIT_HS_FM_ENCODING"));
											hxcfe_td_activate_analyzer(td,DEC_RX02_M2FM_ENCODING,hxcfe_getEnvVarValue( fpga->libhxcfe, "BMPEXPORT_ENABLE_DEC_RX02_M2FM_ENCODING"));

											hxcfe_td_setparams(td,preview_image_xtime,(int)preview_image_ytime,preview_image_xoffset,preview_image_flags);

											if(trkstream)
											{
												hxcfe_td_draw_trkstream( td, trkstream );
												hxcfe_td_draw_rules( td );

												ptr1 = (unsigned char*)hxcfe_td_getframebuffer(td);

												/*
												bitmap_data bmp;

												bmp.xsize = xsize;
												bmp.ysize = ysize;
												bmp.data = (uint32_t*)ptr1;

												bmp16b_write("/tmp/analysis.bmp",&bmp);
												*/

												write_png_file("/tmp/analysis.png", ptr1, xsize, ysize);

												hxcfe_FxStream_FreeStream( fxsa, trkstream );
											}
										}
									}
									else
									{
										hxc_msleep(10);
									}

									hxcfe_deinitFxStream( fxsa );

								}
								else
								{
									hxc_msleep(10);
								}
							}
							else
							{
								hxc_msleep(10);
							}
						}
						else
						{
							fseek(f,file_offset,SEEK_SET);
							hxc_msleep(10);
						}
					}
					else
					{
						hxc_msleep(50);
					}

					fseek(f,file_offset,SEEK_SET);

				}while(0);

				fclose(f);
			}
		}
		else
		{
			pthread_mutex_unlock(&script_context->script_mutex);
			hxc_msleep(200);
		}
	}


	if(buffer)
		free(buffer);

	if(offset_table)
		free(offset_table);

	if(full_track_buffer)
		free(full_track_buffer);

	hxcfe_td_deinit( td_stream );

	return NULL;

error:

	if(buffer)
		free(buffer);

	if(offset_table)
		free(offset_table);

	if(full_track_buffer)
		free(full_track_buffer);

	return NULL;
}
