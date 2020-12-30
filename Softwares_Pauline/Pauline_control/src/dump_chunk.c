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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdarg.h>
#include <time.h>
#include <stdint.h>

#include "libhxcfe.h"

#include "streamhfe_format.h"
#include "fpga.h"
#include "dump_chunk.h"
#include "std_crc32.h"

#include "lz4.h"

#include "version.h"

unsigned char * fast_convert_chunk(fpga_state * state, uint16_t *chunk_ptr, uint32_t track_size, unsigned int * tracksize,unsigned int * outbuffersize, unsigned int * number_of_pulses, unsigned int * prev_bitdelta)
{
	unsigned int j;
	unsigned int final_track_len;
	unsigned char  * data_track, *start_data_track;
	unsigned int bits_delta,nb_pulses;
	uint16_t *tmp_ptr, tmp_data;
	uint16_t lutval;

	tmp_ptr = chunk_ptr;

	final_track_len = (track_size/2);

	if(final_track_len & 0xF)
		final_track_len = (final_track_len & ~0xF) + 0x10;

	data_track = malloc(final_track_len);
	start_data_track = data_track;

	if( data_track )
	{
		nb_pulses = 0;
		bits_delta = *prev_bitdelta;

		j = 0;
		do
		{
			tmp_data = *tmp_ptr;
			tmp_ptr += 2;

			if(!tmp_data)
			{
				bits_delta += 16;
			}
			else
			{
				lutval = state->conv_lut[tmp_data];
				if(lutval)
				{
					bits_delta += (lutval>>8);

					if( bits_delta < 0x00000080)
					{
						*data_track++ = bits_delta;
					}
					else
					{
						if( bits_delta < 0x00004000)
						{
							*data_track++ = 0x80 | (bits_delta>>8);
							*data_track++ = (bits_delta&0xFF);
						}
						else
						{
							if( bits_delta < 0x00200000)
							{
								*data_track++ = 0xC0 | (bits_delta>>16);
								*data_track++ = ((bits_delta>>8)&0xFF);
								*data_track++ = (bits_delta&0xFF);
							}
							else
							{
								if( bits_delta < 0x10000000)
								{
									*data_track++ = 0xE0 | (bits_delta>>24);
									*data_track++ = ((bits_delta>>16)&0xFF);
									*data_track++ = ((bits_delta>>8)&0xFF);
									*data_track++ = (bits_delta&0xFF);
								}
								else
								{
									*data_track++ = 0xE0 | 0x0F;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
								}
							}
						}
					}

					bits_delta = (lutval&0xFF);
					nb_pulses++;
				}
				else
				{
					if( bits_delta < 0x00000080)
					{
						*data_track++ = bits_delta;
					}
					else
					{
						if( bits_delta < 0x00004000)
						{
							*data_track++ = 0x80 | (bits_delta>>8);
							*data_track++ = (bits_delta&0xFF);
						}
						else
						{
							if( bits_delta < 0x00200000)
							{
								*data_track++ = 0xC0 | (bits_delta>>16);
								*data_track++ = ((bits_delta>>8)&0xFF);
								*data_track++ = (bits_delta&0xFF);
							}
							else
							{
								if( bits_delta < 0x10000000)
								{
									*data_track++ = 0xE0 | (bits_delta>>24);
									*data_track++ = ((bits_delta>>16)&0xFF);
									*data_track++ = ((bits_delta>>8)&0xFF);
									*data_track++ = (bits_delta&0xFF);
								}
								else
								{
									*data_track++ = 0xE0 | 0x0F;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
								}
							}
						}
					}

					bits_delta = 0;
					nb_pulses++;
				}
			}

			j += 2;

		}while(j<final_track_len);

		*prev_bitdelta = bits_delta;
		*tracksize = (final_track_len * 8);
		*outbuffersize = (unsigned int)(data_track - start_data_track);
		*number_of_pulses = nb_pulses;
	}

	return start_data_track;
}

int metadata_catprintf(char * metabuffer,int metamaxsize,char * chaine, ...)
{
	char temp[512];
	char textbuf[512];
	int i,j;
	int ret;

	ret = 0;

	va_list marker;
	va_start( marker, chaine );

	textbuf[0] = 0;

	vsprintf(temp,chaine,marker);

	j = 0;
	i = 0;
	while(temp[i])
	{
		if(temp[i]!='\r')
			textbuf[j++] = temp[i];
		i++;
	}

	textbuf[j] = 0;

	if(strlen(metabuffer) + strlen(textbuf) < metamaxsize )
	{
		strcat(metabuffer,textbuf);
	}
	else
	{
		ret = 1;
	}

	va_end( marker );

	return ret;
}

unsigned char * generate_chunk(fpga_state * state, uint16_t * data_in, uint32_t chunk_size, uint32_t * packed_size,int chunk_number,unsigned int * bitdelta, dump_state * dstate)
{
	unsigned int i,packedsize,iopackedsize;
	unsigned char * full_block;

	unsigned int stream_track_size;
	unsigned int track_size,number_of_pulses;

	uint16_t * io_buffer;
	uint16_t * tmp_ptr;
	uint32_t * long_ptr;
	unsigned char * convertedchunk;
	unsigned int total_size;
	int temp_size,prev_bitdelta;
	char * meta_data_buffer;
	chunk_header * cheader;
	metadata_header * pmetadata_header;
	packed_stream_header * pstream_header;
	packed_io_header * pio_header;
	time_t t;
	struct tm tm;
	#define METADATA_MAXSIZE (8*1024)

	io_buffer = NULL;
	full_block = NULL;
	convertedchunk = NULL;

	if(!state)
		return 0;

	track_size = 0;
	packedsize = 0;
	number_of_pulses = 0;

	prev_bitdelta = *bitdelta;
	convertedchunk = fast_convert_chunk(state, data_in, chunk_size, &track_size, &stream_track_size, &number_of_pulses, bitdelta);
	if(!convertedchunk)
		goto error;

	temp_size  = LZ4_compressBound(stream_track_size) + LZ4_compressBound(chunk_size/2) + 8*1024 + 1024;
	full_block = malloc(temp_size);
	if(!full_block)
		goto error;

	cheader = (chunk_header*)&full_block[0];
	pmetadata_header = (metadata_header*)&full_block[sizeof(chunk_header)];
	meta_data_buffer = (char*)pmetadata_header + sizeof(metadata_header);

	memset(meta_data_buffer,0,METADATA_MAXSIZE);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"format_version v1.0\n");
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"software_version v"STR_FILE_VERSION2" "STR_DATE"\n");
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"software_buildtime "__DATE__" "__TIME__"\n");
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"chunk_number %d\n",chunk_number);

	t = time(NULL);
	tm = *localtime(&t);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"current_time %d-%02d-%02d %02d:%02d:%02d\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"sample_rate_hz %d\n",dstate->sample_rate_hz);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"floppy_drive %d \"%s\"\n",dstate->drive_number,dstate->drive_description);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"drive_reference \"%s\"\n",dstate->dump_driveref);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"dump_name \"%s\"\n",dstate->dump_name);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"dump_comment \"%s\"\n",dstate->dump_comment);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"dump_comment2 \"%s\"\n",dstate->dump_comment2);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"operator \"%s\"\n",dstate->dump_operator);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"start_track %d\n",dstate->start_track);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"max_track %d\n",dstate->max_track);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"double_step %d\n",dstate->doublestep);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"start_side %d\n",dstate->start_side);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"max_side %d\n",dstate->max_side);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"index_synced %d\n",dstate->index_synced);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"index_to_dump_delay %d\n",dstate->index_to_dump_delay);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"time_per_track %d\n",dstate->time_per_track);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"current_track %d\n",dstate->current_track);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"current_side %d\n",dstate->current_side);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"number_of_data_pulses %d\n",number_of_pulses);
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"number_of_data_samples %d\n", (prev_bitdelta + ((chunk_size/4)*16)) - *bitdelta );
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"number_of_ios_samples %d\n", (chunk_size/4) );
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"memory_dump_offset 0x%.8X\n", state->last_dump_offset );
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"io_channel 0 floppy_i_index\n" );
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"io_channel 1 floppy_i_pin02\n" );
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"io_channel 2 floppy_i_pin34\n" );
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"io_channel 5 floppy_i_wpt\n" );
	metadata_catprintf(meta_data_buffer,METADATA_MAXSIZE,"io_channel 9 ext_io_i\n" );

	pmetadata_header->type = HXCSTREAM_CHUNKBLOCK_METADATA_ID;
	pmetadata_header->payload_size = strlen(meta_data_buffer) + 1;
	pmetadata_header->payload_size += (4 - (pmetadata_header->payload_size & 3)) & 3;

	pstream_header = (packed_stream_header*)(((void*)pmetadata_header) + sizeof(chunkblock_header) + pmetadata_header->payload_size);

	packedsize = LZ4_compress_default((const char*)convertedchunk, (char*)(void*)pstream_header +  sizeof(packed_stream_header), stream_track_size, temp_size - ((void*)pstream_header - (void*)cheader) );
	free(convertedchunk);
	convertedchunk = NULL;

	pstream_header->type = HXCSTREAM_CHUNKBLOCK_PACKEDSTREAM_ID;
	pstream_header->payload_size = (sizeof(uint32_t)*3) + packedsize + ((4 - (packedsize & 3)) & 3);
	pstream_header->packed_size = packedsize;
	pstream_header->unpacked_size = stream_track_size;
	pstream_header->number_of_pulses = number_of_pulses;

	pio_header = (packed_io_header*)(((void*)pstream_header) + sizeof(chunkblock_header) + pstream_header->payload_size);

	io_buffer = malloc(chunk_size / 2);
	if(!io_buffer)
		goto error;

	tmp_ptr = data_in + 1;
	for(i=0;i<chunk_size / 4;i++)
	{
		io_buffer[i] = tmp_ptr[i*2];
	}

	iopackedsize = LZ4_compress_default((const char*)io_buffer, (char*)pio_header+ sizeof(packed_io_header), chunk_size/2, temp_size - ((void*)pio_header - (void*)cheader));

	free(io_buffer);
	io_buffer = NULL;

	pio_header->type = HXCSTREAM_CHUNKBLOCK_PACKEDIOSTREAM_ID;
	pio_header->payload_size = (sizeof(uint32_t)*2) + iopackedsize;
	pio_header->payload_size += (4 - (pio_header->payload_size & 3)) & 3;
	pio_header->packed_size = iopackedsize;
	pio_header->unpacked_size = chunk_size/2;

	///////
	total_size = 	sizeof(chunk_header) + \
					sizeof(chunkblock_header) + pmetadata_header->payload_size + \
					sizeof(chunkblock_header) + pstream_header->payload_size + \
					sizeof(chunkblock_header) + pio_header->payload_size + \
					sizeof(uint32_t);

	cheader->header = 0x484B4843;
	cheader->size = total_size;
	cheader->packet_number = chunk_number;

	long_ptr = (uint32_t *)&full_block[total_size - 4];

	*long_ptr = std_crc32(0xFFFFFFFF, (void*)full_block, total_size - 4);
	*packed_size = total_size;

	return full_block;

////////////////////////////////////////

error:
	if(io_buffer)
		free(io_buffer);

	if(convertedchunk)
		free(convertedchunk);

	if(full_block)
		free(full_block);

	return NULL;
}
