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

#define MAX_LINE_SIZE 2048
#define DEFAULT_BUFLEN 512

typedef int (* PRINTF_FUNC)(int MSGTYPE, char * string, ... );

typedef struct _script_ctx
{
	PRINTF_FUNC script_printf;
	pthread_mutex_t script_mutex;
} script_ctx;

script_ctx * pauline_init_script();
int pauline_execute_script( script_ctx * ctx, char * filename );
int pauline_execute_line( script_ctx * ctx, char * line );
void pauline_setOutputFunc( script_ctx * ctx, PRINTF_FUNC ext_printf );
script_ctx * pauline_deinit_script(script_ctx * ctx);


// Output Message level
#define MSGTYPE_NONE                         0
#define MSGTYPE_INFO_0                       1
#define MSGTYPE_INFO_1                       2
#define MSGTYPE_WARNING                      3
#define MSGTYPE_ERROR                        4
#define MSGTYPE_DEBUG                        5

#define USER_DRIVES_CFG_FILE "/home/pauline/Settings/drives.script"
#define DEFAULT_DRIVES_CFG_FILE "/data/Settings/drives.script"
#define CRASH_LOGS_FILE "/home/pauline/pauline_logs.txt"
