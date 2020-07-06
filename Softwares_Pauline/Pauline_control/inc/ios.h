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

enum {
	INPUT = 0,
	INPUT_ST,
	OUT_OC,
	OUT_PP,
	CTRL
};

typedef struct io_def_
{
	char * name;
	int    type;
	int    reg_number;
	int    bit_number;
}io_def;

int  get_io_index(char * name);
int  get_io_reg(int index);
unsigned int get_io_bitmask(int index);
void get_io_address(int index, int * regs, unsigned int * bitmask);
void print_ios_list();
