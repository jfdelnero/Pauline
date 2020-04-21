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

#pragma pack(1)

#define HXCSTREAM_HEADERSIGN 0x484B4843
#define HXCSTREAM_CHUNKBLOCK_METADATA_ID       0x00000000
#define HXCSTREAM_CHUNKBLOCK_PACKEDIOSTREAM_ID 0x00000001
#define HXCSTREAM_CHUNKBLOCK_PACKEDSTREAM_ID   0x00000002

typedef struct _chunk_header
{
	uint32_t header;       // CHKH -  0x43, 0x48, 0x4B, 0x48 - 484B4843
	uint32_t size;         // Header + data +CRC
	uint32_t packet_number;
}chunk_header;

typedef struct _chunkblock_header
{
	uint32_t type;
	uint32_t payload_size;
	// data
}chunkblock_header;

typedef struct _metadata_header
{
	uint32_t type;         // 0x00000000 - Metadata text buffer
	uint32_t payload_size;
	// data
}metadata_header;

typedef struct _packed_io_header
{
	uint32_t type;         // 0x00000001 - LZ4 packed 16 bits IO dump
	uint32_t payload_size;
	uint32_t packed_size;
	uint32_t unpacked_size;
	// packed_data
}packed_io_header;

typedef struct _packed_stream_header
{
	uint32_t type;         // 0x00000002 - LZ4 packed stream
	uint32_t payload_size;
	uint32_t packed_size;
	uint32_t unpacked_size;
	uint32_t number_of_pulses;
	// packed_data
}packed_stream_header;

// Data + CRC32

#pragma pack()

unsigned char * generate_chunk(fpga_state * state, uint16_t * data_in, uint32_t chunk_size, uint32_t * packed_size,int chunk_number,int samplerate,unsigned int * bitdelta);
