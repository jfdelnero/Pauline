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

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <time.h>

#include <stdint.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/inotify.h>
#include <signal.h>

#include "messages.h"
#include "script.h"

msg_ctx * msg_context = NULL;

void eventInit(wait_event_ctx * ctx)
{
	ctx->signalled = 0;
	ctx->cancelled = 0;

	pthread_mutex_init(&ctx->mutex, NULL);
	pthread_cond_init(&ctx->cond, NULL);
}

void eventDeinit(wait_event_ctx * ctx)
{
	pthread_mutex_destroy(&ctx->mutex);
	pthread_cond_destroy(&ctx->cond);
}

int waitEvent(wait_event_ctx * ctx)
{
	int ret;

	pthread_mutex_lock(&ctx->mutex);
	while (!ctx->signalled && !ctx->cancelled)
	{
		pthread_cond_wait(&ctx->cond, &ctx->mutex);
	}

	ctx->signalled = 0;

	if(ctx->cancelled)
		ret = 0;
	else
		ret = 1;

	pthread_mutex_unlock(&ctx->mutex);

	return ret;
}

void sendEvent(wait_event_ctx * ctx)
{
	pthread_mutex_lock(&ctx->mutex);
	ctx->signalled = 1;
	pthread_mutex_unlock(&ctx->mutex);
	pthread_cond_signal(&ctx->cond);
}

void cancelEvent(wait_event_ctx * ctx)
{
	pthread_mutex_lock(&ctx->mutex);
	ctx->cancelled = 1;
	pthread_mutex_unlock(&ctx->mutex);
	pthread_cond_signal(&ctx->cond);
}

void init_srv_msg()
{
	int i;

	msg_context = malloc(sizeof(msg_ctx));
	if(msg_context)
	{
		memset(msg_context,0,sizeof(msg_ctx));

		pthread_mutex_init(&msg_context->msg_ctx_mutex,NULL);
		pthread_mutex_init(&msg_context->new_in_message_mutex,NULL);

		eventInit(&msg_context->in_event);

		for(i=0;i<MAX_NB_CLIENTS;i++)
		{
			eventInit(&msg_context->clients_out_buffer[i].event);
		}
	}
}

int handle_to_index(uint32_t handle)
{
	int i;

	i = 0;

	if(!msg_context)
		return -1;

	i = 0;
	do
	{
		if(msg_context->clients_out_buffer[i].enabled && (msg_context->handle_to_index[i] == handle))
		{
			return i;
		}

		i++;
	}while(i<MAX_NB_CLIENTS);

	return -1;
}

int count_client()
{
	int i,cnt;

	cnt = 0;

	for(i=0;i<MAX_NB_CLIENTS;i++)
	{
		if(msg_context->clients_out_buffer[i].enabled)
		{
			cnt++;
		}
	}

	return cnt;
}

int add_client(uint32_t handle)
{
	int i;

	i = 0;

	if(!msg_context)
		return -1;

	pthread_mutex_lock(&msg_context->msg_ctx_mutex);

	while(msg_context->clients_out_buffer[i].enabled && i < MAX_NB_CLIENTS)
	{
		i++;
	}

	if(i<MAX_NB_CLIENTS)
	{
		msg_context->handle_to_index[i] = handle;

		msg_context->clients_out_buffer[i].out_index = 0;
		msg_context->clients_out_buffer[i].in_index = 0;

		memset(&msg_context->clients_out_buffer[i].messages,0,MAX_NB_MESSAGES*MAX_MESSAGES_SIZE);

		msg_context->clients_out_buffer[i].event.cancelled = 0;
		msg_context->clients_out_buffer[i].event.signalled = 0;

		msg_context->clients_out_buffer[i].enabled = 1;

		pthread_mutex_unlock(&msg_context->msg_ctx_mutex);

		return i;
	}

	pthread_mutex_unlock(&msg_context->msg_ctx_mutex);

	return -1;
}

void remove_client(int client_id)
{
	if(!msg_context || (client_id > (MAX_NB_CLIENTS - 1)))
		return;

	pthread_mutex_lock(&msg_context->msg_ctx_mutex);

	if(msg_context->clients_out_buffer[client_id].enabled)
	{
		msg_context->clients_out_buffer[client_id].out_index = 0;
		msg_context->clients_out_buffer[client_id].in_index = 0;

		memset(&msg_context->clients_out_buffer[client_id].messages,0,MAX_NB_MESSAGES*MAX_MESSAGES_SIZE);

		msg_context->clients_out_buffer[client_id].enabled = 0;
	}

	pthread_mutex_unlock(&msg_context->msg_ctx_mutex);

}

// stdout -> clients
void msg_print(char * msg)
{
	int i;

	if(!msg_context || !msg)
		return;

	for(i=0;i<MAX_NB_CLIENTS;i++)
	{
		if( msg_context->clients_out_buffer[i].enabled )
		{
			memset((char*)&msg_context->clients_out_buffer[i].messages[msg_context->clients_out_buffer[i].in_index & (MAX_NB_MESSAGES - 1)], 0, MAX_MESSAGES_SIZE);
			strncpy((char*)&msg_context->clients_out_buffer[i].messages[msg_context->clients_out_buffer[i].in_index & (MAX_NB_MESSAGES - 1)], msg, MAX_MESSAGES_SIZE - 1);
			msg_context->clients_out_buffer[i].in_index = (msg_context->clients_out_buffer[i].in_index + 1) & (MAX_NB_MESSAGES - 1);
			if(msg_context->clients_out_buffer[i].in_index == msg_context->clients_out_buffer[i].out_index)
			{
				msg_context->clients_out_buffer[i].out_index = (msg_context->clients_out_buffer[i].out_index + 1) & (MAX_NB_MESSAGES - 1);
			}

			sendEvent(&msg_context->clients_out_buffer[i].event);
		}
	}
}

int msg_printf(int MSGTYPE,char * chaine, ...)
{
	char temp[MAX_MESSAGES_SIZE];
	char textbuf[MAX_MESSAGES_SIZE];
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

		msg_print(textbuf);

		va_end( marker );
	}
	return 0;
}

void exitwait(int client_id)
{
	if(!msg_context)
		return;

	if(client_id < 0)
		return;

	msg_context->clients_out_buffer[client_id].in_index = 0;
	msg_context->clients_out_buffer[client_id].out_index = 0;
	cancelEvent(&msg_context->clients_out_buffer[client_id].event);

	/*msg_context->in_buffer.in_index = 0;
	msg_context->in_buffer.out_index = 0;
	sendEvent(&msg_context->in_event);*/
}

int msg_out_wait(int client_id, char * outbuf)
{
	char * ptr;

	if(!msg_context || (client_id > (MAX_NB_CLIENTS - 1)))
	{
		outbuf[0] = 0;
		return  -1;
	}

	while (msg_context->clients_out_buffer[client_id].out_index == msg_context->clients_out_buffer[client_id].in_index)
	{
		if( !waitEvent(&msg_context->clients_out_buffer[client_id].event) )
		{
			return 0;
		}
	}

	if(msg_context->clients_out_buffer[client_id].out_index != msg_context->clients_out_buffer[client_id].in_index)
	{
		ptr = (char*)&msg_context->clients_out_buffer[client_id].messages[msg_context->clients_out_buffer[client_id].out_index];
		strncpy(outbuf, ptr, MAX_MESSAGES_SIZE - 1);
		msg_context->clients_out_buffer[client_id].out_index = (msg_context->clients_out_buffer[client_id].out_index + 1) & (MAX_NB_MESSAGES - 1);

		return 1;
	}
	else
	{
		outbuf[0] = 0;
	}

	return 1;
}

// clients -> "stdin"
void msg_push_in_msg(int client_id, char * msg)
{
	if(!msg_context || (client_id > (MAX_NB_CLIENTS - 1)))
		return;

	if(msg_context->clients_out_buffer[client_id].enabled)
	{
		pthread_mutex_lock(&msg_context->new_in_message_mutex);

		memset((char*)&msg_context->in_buffer.messages[msg_context->in_buffer.in_index & (MAX_NB_MESSAGES - 1)],0,MAX_MESSAGES_SIZE);
		strncpy((char*)&msg_context->in_buffer.messages[msg_context->in_buffer.in_index & (MAX_NB_MESSAGES - 1)], msg, MAX_MESSAGES_SIZE - 1);
		msg_context->in_buffer.in_index = (msg_context->in_buffer.in_index + 1) & (MAX_NB_MESSAGES - 1);
		if(msg_context->in_buffer.in_index == msg_context->in_buffer.out_index)
		{
			msg_context->in_buffer.out_index = (msg_context->in_buffer.out_index + 1) & (MAX_NB_MESSAGES - 1);
		}

		pthread_mutex_unlock(&msg_context->new_in_message_mutex);

		sendEvent(&msg_context->in_event);
	}
}

int msg_in_wait(char * outbuf)
{
	char * ptr;

	if(!msg_context)
	{
		outbuf[0] = 0;
		return -1;
	}

	pthread_mutex_lock(&msg_context->new_in_message_mutex);

	if(msg_context->in_buffer.out_index == msg_context->in_buffer.in_index)
	{
		pthread_mutex_unlock(&msg_context->new_in_message_mutex);

		waitEvent(&msg_context->in_event);

		pthread_mutex_lock(&msg_context->new_in_message_mutex);

	}

	if(msg_context->in_buffer.out_index != msg_context->in_buffer.in_index)
	{
		ptr = (char*)&msg_context->in_buffer.messages[msg_context->in_buffer.out_index];
		strncpy(outbuf, ptr, MAX_MESSAGES_SIZE - 1);
		msg_context->in_buffer.out_index = (msg_context->in_buffer.out_index + 1) & (MAX_NB_MESSAGES - 1);

		pthread_mutex_unlock(&msg_context->new_in_message_mutex);

		return 1;
	}
	else
	{
		pthread_mutex_unlock(&msg_context->new_in_message_mutex);

		outbuf[0] = 0;

		return 0;
	}


}

void deinit_srv_msg()
{
	int i;

	if( msg_context )
	{
		for(i=0;i<MAX_NB_CLIENTS;i++)
		{
			remove_client(i);
		}

		free(msg_context);

		msg_context = NULL;
	}
}
