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

#include "libhxcfe.h"

#include "script.h"

#include "fpga.h"
#include "dump_chunk.h"
#include "network.h"

#include "bmp_file.h"
#include "screen.h"

#include "messages.h"

pthread_t ws_thread[MAX_NB_CLIENTS];

void *websocket_txthread(void *threadid)
{
	int fd;
	char msg[MAX_MESSAGES_SIZE];

	pthread_detach(pthread_self());

	fd = (int) threadid;

	printf("websocket_txthread : handle %d, index %d\n",fd,handle_to_index(fd));

	while( msg_out_wait(handle_to_index(fd), (char*)&msg) > 0 )
	{
		ws_sendframe(fd, (char *)msg, false);
	}

	pthread_exit(NULL);
}

void onopen(int fd)
{
	char *cli;
	int index;
	cli = ws_getaddress(fd);

	index = add_client(fd);

	printf("Connection opened, client: %d | addr: %s, index : %d\n", fd, cli,index);

	if(index >= 0)
	{
		pthread_create(&ws_thread[index], NULL, websocket_txthread, (void*)fd);
	}

	free(cli);
}

void onclose(int fd)
{
	char *cli;
	int index;

	cli = ws_getaddress(fd);

	index = handle_to_index(fd);

	exitwait(index);

	remove_client(index);

	printf("Connection closed, client: %d | addr: %s\n", fd, cli);
	free(cli);
}

void onmessage(int fd, const unsigned char *msg)
{
	char *cli;

	cli = ws_getaddress(fd);

	if(cli)
	{
		printf("I receive a message: %s, from: %s/%d\n", msg, cli, fd);

		msg_push_in_msg(handle_to_index(fd), (char*)msg);
	}

	//msg_printf(" Hello ! :) ");

	free(cli);
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