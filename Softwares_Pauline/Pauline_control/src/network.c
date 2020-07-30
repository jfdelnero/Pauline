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
#include <string.h>
#include <malloc.h>
#include <fcntl.h>
#include <sys/mman.h>

#include <stdint.h>
#include <stdarg.h>

#include "libhxcfe.h"

#include "script.h"

#include "fpga.h"
#include "dump_chunk.h"
#include "network.h"

#define SOCKET_ERROR        -1
#define QUEUE_SIZE          5

#include "bmp_file.h"
#include "screen.h"

#include "messages.h"

pthread_t     * threads_data;
thread_params * threadparams_data[MAXCONNECTION];

pthread_t     * threads_cmd;
thread_params * threadparams_cmd[MAXCONNECTION];

int cmd_socket_index;
int dat_socket_index;

int sendpacket(int hSocket,unsigned char * buffer,int size)
{
	int offset,rv;

	offset = 0;
	while(offset < size)
	{
		rv = send(hSocket, &buffer[offset], size - offset, 0);
		if(rv <= 0)
		{
			return -1;
		}
		offset += rv;
	}

	return size;
}

int senddatapacket(unsigned char * buffer,int size)
{
	thread_params * tp;

	if(threads_data)
	{
		tp = threadparams_data[dat_socket_index];
		if(tp)
		{
			return sendpacket(tp->hSocket,buffer,size);
		}
	}

	return -1;
}

void *connection_thread(void *threadid)
{
	thread_params * tp;
	int i;
	int iResult;
	char recvbuf[DEFAULT_BUFLEN];
	char fullline[MAX_LINE_SIZE];
	int line_index;
	int recvbuflen = DEFAULT_BUFLEN;
	//struct timeval tv;

	tp = (thread_params*)threadid;

	pthread_detach(pthread_self());

	//tv.tv_sec = 20;
	//tv.tv_usec = 0;
	//setsockopt(hSocket, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,sizeof(struct timeval));

	if(!tp->mode)
	{
		display_bmp("/data/pauline_splash_bitmaps/connected.bmp");

		line_index = 0;
		// Receive until the peer shuts down the connection
		do {

			iResult = recv(threadparams_cmd[tp->index]->hSocket, recvbuf, recvbuflen, 0);
			if (iResult > 0) {

				i = 0;
				do
				{
					while( recvbuf[i]!='\n' && i < iResult )
					{
						if(line_index<MAX_LINE_SIZE)
						{
							fullline[line_index] = recvbuf[i];
							line_index++;
						}
						i++;
					}

					if( recvbuf[i] == '\n' &&  i != iResult )
					{
						fullline[line_index] = 0;

						if( !strncmp( fullline, "kill_server", 11 ) )
						{
							printf("Exiting !\n");
							close(threadparams_cmd[tp->index]->hSocket);

							display_bmp("/data/pauline_splash_bitmaps/disconnected.bmp");

							pthread_exit(NULL);
						}
						else
						{
							execute_line(NULL,fullline);
							line_index = 0;
						}
						i++;
					}
				}while(i < iResult);
			}

		} while (iResult > 0);

		close(threadparams_cmd[tp->index]->hSocket);

		display_bmp("/data/pauline_splash_bitmaps/disconnected.bmp");

		printf("Connection closed !\n");
	}
	else
	{
		/*
		int sendsize;
		char testbuffer[512];
		int hSocket;

		hSocket = tp->hSocket;

		i = 0;
		do
		{
			sprintf(testbuffer,"Ligne %d - ABCDEFGHIJKLMNOPQRSTUVW\n",i);
			i++;
			sendsize = sendpacket(hSocket,(unsigned char*)testbuffer,strlen(testbuffer));
			sleep(1);
		}while(sendsize>0);
		*/
	}

	pthread_exit(NULL);
}

int Printf_socket(int MSGTYPE,char * chaine, ...)
{
	char temp[DEFAULT_BUFLEN];
	char textbuf[DEFAULT_BUFLEN];
	int iSendResult,i,j;

	if(MSGTYPE!=MSGTYPE_DEBUG)
	{
		va_list marker;
		va_start( marker, chaine );

		switch(MSGTYPE)
		{
			case MSGTYPE_NONE:
				textbuf[0] = 0;
			break;
			case MSGTYPE_INFO_0:
				sprintf(textbuf,"OK : ");
			break;
			case MSGTYPE_INFO_1:
				sprintf(textbuf,"OK : ");
			break;
			case MSGTYPE_WARNING:
				sprintf(textbuf,"WARNING : ");
			break;
			case MSGTYPE_ERROR:
				sprintf(textbuf,"ERROR : ");
			break;
			case MSGTYPE_DEBUG:
				sprintf(textbuf,"DEBUG : ");
			break;
		}

		vsprintf(temp,chaine,marker);
		//strcat(textbuf,"\n");

		j = strlen(textbuf);
		i = 0;
		while(temp[i])
		{

			if(temp[i]=='\n')
			{
				textbuf[j++] = '\r';
				textbuf[j++] = '\n';
			}
			else
				textbuf[j++] = temp[i];

			i++;
		}
		textbuf[j] = 0;

		// Echo the buffer back to the sender
		iSendResult = sendpacket(threadparams_cmd[cmd_socket_index]->hSocket,(unsigned char*)textbuf, strlen(textbuf));
		if (iSendResult < 0) {
			printf("send failed with error:\n");
//			closesocket(ClientSocket);
			return 1;
		}

		va_end( marker );
	}
	return 0;
}

int print_netif_ips(int x,int y)
{
	int i;
	struct ifaddrs *addrs, *tmp;

	getifaddrs(&addrs);
	tmp = addrs;

	i = 0;
	while (tmp)
	{
		if (tmp->ifa_addr && tmp->ifa_addr->sa_family == AF_INET)
		{
			struct sockaddr_in *pAddr = (struct sockaddr_in *)tmp->ifa_addr;
			//printf("%s: %s\n", tmp->ifa_name, inet_ntoa(pAddr->sin_addr));
			if(!strcmp(tmp->ifa_name,"eth0"))
			{
				printf_screen(x, (y - 13), PRINTSCREEN_BLACK_FG, "%s", "IP:");
				printf_screen(x, y + (i * 13), PRINTSCREEN_BLACK_FG, "%s", inet_ntoa(pAddr->sin_addr));
				i++;
			}
		}

		tmp = tmp->ifa_next;
	}

	freeifaddrs(addrs);

	return 0;
}

void *tcp_listener(void *threadid)
{
	int hSocket,hServerSocket;  /* handle to socket */
	struct sockaddr_in Address; /* Internet socket address stuct */
	struct sockaddr_in Address_con; /* Internet socket address stuct */
	int nAddressSize=sizeof(struct sockaddr_in);
	int nAddressSize_con=sizeof(struct sockaddr_in);
	int nHostPort;
	int rc,i;
	thread_params * tp;
	char hostname[512];
	char servname[512];
	int connection;
	int mode;

	struct sigaction new_actn, old_actn;

	pthread_detach(pthread_self());

	if(threadid)
		mode = 1;
	else
		mode = 0;

	new_actn.sa_handler = SIG_IGN;
	sigemptyset (&new_actn.sa_mask);
	new_actn.sa_flags = 0;
	sigaction (SIGPIPE, &new_actn, &old_actn);

	connection=0;

	if(mode)
	{
		threads_data = malloc(sizeof(pthread_t) * MAXCONNECTION);
		memset(threads_data,0,sizeof(pthread_t) * MAXCONNECTION);

		memset(&threadparams_data,0,sizeof(thread_params*) * MAXCONNECTION);
	}
	else
	{
		//setOutputFunc( NULL, Printf_socket );
		threads_cmd = malloc(sizeof(pthread_t) * MAXCONNECTION);
		memset(threads_cmd,0,sizeof(pthread_t) * MAXCONNECTION);

		memset(&threadparams_cmd,0,sizeof(thread_params*) * MAXCONNECTION);
	}

	nHostPort=600 + (mode & 1);

	printf("Starting server (mode %d)\n",mode&1);

	/* make a socket */
	hServerSocket = socket(AF_INET,SOCK_STREAM,0);

	if(hServerSocket == SOCKET_ERROR)
	{
		printf("Could not make a socket\n");
		pthread_exit(NULL);
	}

	/* fill address struct */
	Address.sin_addr.s_addr=INADDR_ANY;
	Address.sin_port=htons(nHostPort);
	Address.sin_family=AF_INET;

	printf("Binding to port %d\n",nHostPort);

	/* bind to a port */
	if(bind(hServerSocket,(struct sockaddr*)&Address,sizeof(Address)) == SOCKET_ERROR)
	{
		printf("Could not connect to host\r\n");
		pthread_exit(NULL);
	}

 /*  get port number */
	getsockname( hServerSocket, (struct sockaddr *) &Address,(socklen_t *)&nAddressSize);
	printf("opened socket as fd (%d) on port (%d) for stream i/o\r\n",hServerSocket, ntohs(Address.sin_port) );
	printf("Server\r\n\
			  sin_family        = %d\r\n\
			  sin_addr.s_addr   = %d\r\n\
			  sin_port          = %d\r\n"
			  , Address.sin_family
			  , Address.sin_addr.s_addr
			  , ntohs(Address.sin_port)
			);

	display_bmp("/data/pauline_splash_bitmaps/ready.bmp");

	printf("Making a listen queue of %d elements\r\n",QUEUE_SIZE);

	/* establish listen queue */
	if(listen(hServerSocket,QUEUE_SIZE) == SOCKET_ERROR)
	{
		printf("Could not listen\r\n");
		pthread_exit(NULL);
	}

	tp = malloc( sizeof(thread_params) *  MAXCONNECTION );
	memset(tp,0, sizeof(thread_params) *  MAXCONNECTION );

	for(;;)
	{
		printf("Waiting for a connection\r\n");
		/* get the connected socket */

		hSocket = accept(hServerSocket,(struct sockaddr*)&Address,(socklen_t *)&nAddressSize);

		getsockname( hSocket, (struct sockaddr *) &Address_con,(socklen_t *)&nAddressSize_con);

		printf("Got a connection\r\n");
		printf("Client\r\n\
			  sin_family        = %d\r\n\
			  sin_addr.s_addr   = %d.%d.%d.%d\r\n\
			  sin_port          = %d\r\n"
			  , Address.sin_family
			  , (Address.sin_addr.s_addr>>0)&0xFF,(Address.sin_addr.s_addr>>8)&0xFF,(Address.sin_addr.s_addr>>16)&0xFF,(Address.sin_addr.s_addr>>24)&0xFF
			  , ntohs(Address.sin_port)
			);


		connection = 0;
		for(i=0;i<MAXCONNECTION;i++)
		{
			if(mode)
			{
				if(!threadparams_data[i])
				{
					connection++;
				}
			}
			else
			{
				if(!threadparams_cmd[i])
				{
					connection++;
				}
			}
		}
		printf("%d Slot(s)\r\n",connection);

		if(mode)
		{
			connection=0;
			while((connection<MAXCONNECTION) && threadparams_data[connection])
			{
				connection++;
			}

		}
		else
		{
			connection=0;
			while((connection<MAXCONNECTION) && threadparams_cmd[connection])
			{
				connection++;
			}
		}

		if(connection<MAXCONNECTION)
		{
			memset(&tp[connection],0,sizeof(thread_params));

			if(mode)
			{
				threadparams_data[connection] = &tp[connection];
				threadparams_data[connection]->hSocket=hSocket;
				threadparams_data[connection]->tid=connection;
				threadparams_data[connection]->mode=1;
				threadparams_data[connection]->index = connection;
				dat_socket_index = connection;
			}
			else
			{
				threadparams_cmd[connection] = &tp[connection];
				threadparams_cmd[connection]->hSocket=hSocket;
				threadparams_cmd[connection]->tid=connection;
				threadparams_cmd[connection]->mode=0;
				threadparams_cmd[connection]->index = connection;
				cmd_socket_index = connection;
			}

			memset(hostname,0,sizeof(hostname));
			memset(servname,0,sizeof(servname));
			getnameinfo((struct sockaddr*)&Address, sizeof(Address), hostname, sizeof(hostname), servname, sizeof(servname), NI_NAMEREQD);

			if(mode)
			{
				snprintf(threadparams_data[connection]->clientip,32,"%d.%d.%d.%d:%d"
				  , (Address.sin_addr.s_addr>>0)&0xFF,(Address.sin_addr.s_addr>>8)&0xFF,(Address.sin_addr.s_addr>>16)&0xFF,(Address.sin_addr.s_addr>>24)&0xFF
				  , ntohs(Address.sin_port)
				);

				snprintf(threadparams_data[connection]->clientname,1024,"%d.%d.%d.%d:%d - %s - %s -"
				  , (Address.sin_addr.s_addr>>0)&0xFF,(Address.sin_addr.s_addr>>8)&0xFF,(Address.sin_addr.s_addr>>16)&0xFF,(Address.sin_addr.s_addr>>24)&0xFF
				  , ntohs(Address.sin_port)
				  , hostname
				  , servname
				);

				printf("Starting thread... (Index %d)\r\n",connection);
				rc = pthread_create(&threads_data[connection], NULL, connection_thread, (void *)&tp[connection]);
				if(rc)
				{
					printf("Error ! Can't Create the thread ! (Error %d)\r\n",rc);
				}
			}
			else
			{
				snprintf(threadparams_cmd[connection]->clientip,32,"%d.%d.%d.%d:%d"
				  , (Address.sin_addr.s_addr>>0)&0xFF,(Address.sin_addr.s_addr>>8)&0xFF,(Address.sin_addr.s_addr>>16)&0xFF,(Address.sin_addr.s_addr>>24)&0xFF
				  , ntohs(Address.sin_port)
				);

				snprintf(threadparams_cmd[connection]->clientname,1024,"%d.%d.%d.%d:%d - %s - %s -"
				  , (Address.sin_addr.s_addr>>0)&0xFF,(Address.sin_addr.s_addr>>8)&0xFF,(Address.sin_addr.s_addr>>16)&0xFF,(Address.sin_addr.s_addr>>24)&0xFF
				  , ntohs(Address.sin_port)
				  , hostname
				  , servname
				);

				printf("Starting thread... (Index %d)\r\n",connection);
				rc = pthread_create(&threads_cmd[connection], NULL, connection_thread, (void *)&tp[connection]);
				if(rc)
				{
					printf("Error ! Can't Create the thread ! (Error %d)\r\n",rc);
				}
			}
		}
		else
		{
			printf("Error ! Too many connections!\r\n");
			close(hSocket);
		}
	}

	pthread_exit(NULL);
}

void *server_script_thread(void *threadid)
{
	thread_params * tp;
	int i;
	int iResult;
	char recvbuf[MAX_MESSAGES_SIZE];
	char fullline[MAX_LINE_SIZE];
	int line_index;
	int recvbuflen = DEFAULT_BUFLEN;
	//struct timeval tv;
	script_ctx * ctx;

	tp = (thread_params*)threadid;

	pthread_detach(pthread_self());
	ctx = init_script();

	//tv.tv_sec = 20;
	//tv.tv_usec = 0;
	//setsockopt(hSocket, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,sizeof(struct timeval));

	line_index = 0;
	// Receive until the peer shuts down the connection
	do {

		iResult = msg_in_wait((char*)&recvbuf);
		if (iResult>0) {

			i = 0;
			do
			{
				while( recvbuf[i]!='\n' && recvbuf[i] && i < MAX_MESSAGES_SIZE)
				{
					if(line_index<MAX_LINE_SIZE)
					{
						fullline[line_index] = recvbuf[i];
						line_index++;
					}
					i++;
				}

				if( 1 ) //recvbuf[i] == '\n' )
				{
					fullline[line_index] = 0;

					if( !strncmp( fullline, "kill_server", 11 ) )
					{
						//printf("Exiting !\n");

						//display_bmp("/data/pauline_splash_bitmaps/disconnected.bmp");

						//pthread_exit(NULL);
					}
					else
					{
						execute_line(ctx,fullline);
						line_index = 0;
					}
					i++;
				}
			}while(recvbuf[i] && i < MAX_MESSAGES_SIZE);
		}

	} while (1);

	pthread_exit(NULL);
}
