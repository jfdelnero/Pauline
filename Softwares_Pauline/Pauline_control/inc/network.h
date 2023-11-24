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

#define MAXCONNECTION 128

typedef struct thread_params_
{
	int hSocket;
	int mode;
	int index;
	int tid;
	char clientname[2048];
	char clientip[32];
	int connection_id;
}thread_params;

extern thread_params * threadparams_data[MAXCONNECTION];
extern thread_params * threadparams_cmd[MAXCONNECTION];

typedef struct listener_thread_params_
{
	int port;
	int mode;
}listener_thread_params;

void *ConnectionThread(void *threadid);

void *tcp_listener(void *threadid);
int senddatapacket(unsigned char * buffer,int size);
int print_netif_ips(int x,int y);

void *server_script_thread(void *threadid);
void *network_txthread(void *threadid);

