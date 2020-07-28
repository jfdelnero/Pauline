#define MAX_NB_CLIENTS 64
#define MAX_NB_MESSAGES 64
#define MAX_MESSAGES_SIZE 512

typedef struct _wait_event_ctx
{
	int signalled;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
}wait_event_ctx;

typedef struct _msg_buffer
{
	int enabled;

	int in_index;
	int out_index;

	char messages[MAX_NB_MESSAGES][MAX_MESSAGES_SIZE];

	pthread_mutex_t new_message_mutex;

	wait_event_ctx event;

}msg_buffer;

typedef struct _msg_ctx
{
	msg_buffer clients_out_buffer[MAX_NB_CLIENTS];

	int in_buffer_mutex;
	msg_buffer in_buffer;
	pthread_mutex_t new_in_message_mutex;

	pthread_mutex_t msg_ctx_mutex;

	wait_event_ctx in_event;

}msg_ctx;

void init_srv_msg();

int  add_client();
void remove_client(int client_id);

// stdout -> clients
void msg_printf(char * msg);
void msg_out_wait(int client_id, char * outbuf);

// clients -> "stdin"
void msg_push_in_msg(int client_id, char * msg);
void msg_in_wait(char * outbuf);


void deinit_srv_msg();
