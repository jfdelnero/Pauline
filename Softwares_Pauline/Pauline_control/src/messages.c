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

msg_ctx * msg_context = NULL;

void eventInit(wait_event_ctx * ctx)
{
	ctx->signalled = 0;
	pthread_mutex_init(&ctx->mutex, NULL);
	pthread_cond_init(&ctx->cond, NULL);
}

void eventDeinit(wait_event_ctx * ctx)
{
	pthread_mutex_destroy(&ctx->mutex);
	pthread_cond_destroy(&ctx->cond);
}

void waitEvent(wait_event_ctx * ctx)
{
	pthread_mutex_lock(&ctx->mutex);
	while (!ctx->signalled)
	{
		pthread_cond_wait(&ctx->cond, &ctx->mutex);
	}
	ctx->signalled = 0;
	pthread_mutex_unlock(&ctx->mutex);
}

void sendEvent(wait_event_ctx * ctx)
{
	pthread_mutex_lock(&ctx->mutex);
	ctx->signalled = 1;
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

int add_client()
{
	int i;

	i = 0;

	if(!msg_context)
		return -1;

	pthread_mutex_lock(&msg_context->msg_ctx_mutex);

	while(!msg_context->clients_out_buffer[i].enabled && i < MAX_NB_CLIENTS)
	{
		i++;
	}

	if(i<MAX_NB_CLIENTS)
	{
		msg_context->clients_out_buffer[i].out_index = 0;
		msg_context->clients_out_buffer[i].in_index = 0;

		memset(&msg_context->clients_out_buffer[i].messages,0,MAX_NB_MESSAGES*MAX_MESSAGES_SIZE);

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
void msg_printf(char * msg)
{
	int i;

	if(!msg_context || !msg)
		return;

	for(i=0;i<MAX_NB_CLIENTS;i++)
	{
		if( msg_context->clients_out_buffer[i].enabled )
		{
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

void msg_out_wait(int client_id, char * outbuf)
{
	char * ptr;

	if(!msg_context || (client_id > (MAX_NB_CLIENTS - 1)))
	{
		outbuf[0] = 0;
		return;
	}

	waitEvent(&msg_context->clients_out_buffer[client_id].event);

	if(msg_context->clients_out_buffer[client_id].out_index != msg_context->clients_out_buffer[client_id].in_index)
	{
		ptr = (char*)&msg_context->clients_out_buffer[client_id].messages[msg_context->clients_out_buffer[client_id].out_index];
		strncpy(outbuf, ptr, MAX_MESSAGES_SIZE - 1);
		msg_context->clients_out_buffer[client_id].out_index = (msg_context->clients_out_buffer[client_id].out_index + 1) & (MAX_NB_MESSAGES - 1);
	}
	else
	{
		outbuf[0] = 0;
	}

	return;
}

// clients -> "stdin"
void msg_push_in_msg(int client_id, char * msg)
{
	if(!msg_context || (client_id > (MAX_NB_CLIENTS - 1)))
		return;

	if(msg_context->clients_out_buffer[client_id].enabled)
	{
		pthread_mutex_lock(&msg_context->new_in_message_mutex);

		strncpy((char*)&msg_context->in_buffer.messages[msg_context->in_buffer.in_index & (MAX_NB_MESSAGES - 1)], msg, MAX_MESSAGES_SIZE - 1);
		msg_context->in_buffer.in_index = (msg_context->in_buffer.in_index + 1) & (MAX_NB_MESSAGES - 1);
		if(msg_context->in_buffer.in_index == msg_context->in_buffer.out_index)
		{
			msg_context->in_buffer.out_index = (msg_context->in_buffer.out_index + 1) & (MAX_NB_MESSAGES - 1);
		}

		pthread_mutex_lock(&msg_context->new_in_message_mutex);
	}
}

void msg_in_wait(char * outbuf)
{
	char * ptr;

	if(!msg_context)
	{
		outbuf[0] = 0;
		return;
	}

	waitEvent(&msg_context->in_event);

	if(msg_context->in_buffer.out_index != msg_context->in_buffer.in_index)
	{
		ptr = (char*)&msg_context->in_buffer.messages[msg_context->in_buffer.out_index];
		strncpy(outbuf, ptr, MAX_MESSAGES_SIZE - 1);
		msg_context->in_buffer.out_index = (msg_context->in_buffer.out_index + 1) & (MAX_NB_MESSAGES - 1);
	}
	else
	{
		outbuf[0] = 0;
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
