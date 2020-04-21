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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <unistd.h>

#include "script.h"
#include "fpga.h"
#include "network.h"

extern fpga_state * fpga;
typedef int (* CMD_FUNC)(char * line);

PRINTF_FUNC script_printf;

typedef struct cmd_list_
{
	char * command;
	CMD_FUNC func;
}cmd_list;

#define ERROR_CMD_NOT_FOUND -10

volatile int dump_time_per_track;
volatile int index_to_dump_delay;

pthread_t     threads_dump;
char thread_dump_cmdline[512];

volatile int dump_running = 0;
volatile int stop_process = 0;

volatile int headpos=0;
void setOutputFunc( PRINTF_FUNC ext_printf )
{
	script_printf = ext_printf;

	return;
}

int get_param_offset(char * line, int param)
{
	int i,j;

	i = 0;
	j = 0;

	while( ( line[j] != 0 ) && ( line[j] == ' ' ) )
	{
		j++;
	}

	do
	{
		while( ( line[j] != 0 ) && ( line[j] != ' ' ) )
		{
			j++;
		}

		while( ( line[j] != 0 ) && ( line[j] == ' ' ) )
		{
			j++;
		}

		if(line[j] == 0)
			return -1;

		i++;
	}while(i<param);

	return j;
}

int readdisk(int drive, int dump_start_track,int dump_max_track,int dump_start_side,int dump_max_side,int high_res_mode,int doubestep,int ignore_index,int spy)
{
	int i,j;
	char temp[512];
	FILE *f;
	unsigned char * tmpptr;
	uint32_t  buffersize;

	f = NULL;
	dump_running = 1;
	if(!spy)
	{
		script_printf(MSG_INFO_0,"Start disk reading...\nTrack(s): %d <-> %d, Side(s): %d <-> %d, Ignore index: %d, Time: %dms, %s\n",dump_start_track,dump_max_track,dump_start_side,dump_max_side,ignore_index,dump_time_per_track,high_res_mode?"50Mhz":"25Mhz");

	//	floppy_ctrl_motor(fpga, drive, 1);
		floppy_ctrl_selectbyte(fpga, 0x1F);

		for(i=0;i<1000;i++)
			usleep(1000);

	//	floppy_ctrl_select_drive(fpga, drive, 1);

	//	usleep(1000);

		if(dump_start_track!=-1)
		{
			i = 0;
			while( !(fpga->regs->floppy_ctrl_control & (0x1<<6)) && i < 160 )
			{
				if(headpos)
					headpos--;

				floppy_ctrl_move_head(fpga, 0, 1);
				usleep(12000);
				i++;
			}

			if(i>=160)
			{
				script_printf(MSG_ERROR,"Head position calibration failed ! (%d)\n",i);

		//		floppy_ctrl_select_drive(fpga, drive, 0);
		//		floppy_ctrl_motor(fpga, drive, 0);
				floppy_ctrl_selectbyte(fpga, 0x00);

				dump_running = 0;

				return -1;
			}

			headpos = 0;

			if(dump_start_track)
			{
				for(i=0;i<dump_start_track;i++)
				{
					floppy_ctrl_move_head(fpga, 1, 1);
					headpos++;
				}
			}
		}
		else
		{
			script_printf(MSG_INFO_0,"Start spy mode reading...\nTime: %dms, %s\n",dump_time_per_track,high_res_mode?"50Mhz":"25Mhz");

			dump_start_track = fpga->regs->floppy_ctrl_curtrack & 0x3FF;
			dump_max_track = dump_start_track;
		}
	}
	else
	{
		dump_start_track = fpga->regs->floppy_ctrl_curtrack & 0x3FF;
		dump_max_track = dump_start_track;
	}

	for(i=dump_start_track;i<=dump_max_track;i++)
	{
		for(j=dump_start_side;j<=dump_max_side;j++)
		{
			if(stop_process)
				goto readstop;

			sprintf(temp,"/root/track%.2d.%d.hxcstream",i,j);
			f = fopen(temp,"wb");
			if(!f)
				script_printf(MSG_ERROR,"ERROR : Can't create %s\n",temp);

			floppy_ctrl_side(fpga, drive, j);

			if(high_res_mode)
				buffersize = (dump_time_per_track * (((50000000 / 16 /*16 bits shift*/ ) * 4 /*A word is 4 bytes*/) / 1000));
			else
				buffersize = (dump_time_per_track * (((25000000 / 16 /*16 bits shift*/ ) * 4 /*A word is 4 bytes*/) / 1000));

			buffersize += ((4 - (buffersize&3)) & 3);

			fpga->last_dump_offset = 0;
			fpga->bitdelta = 0;
			fpga->chunk_number = 0;

			start_dump(fpga, buffersize, high_res_mode , index_to_dump_delay,ignore_index);

			while( fpga->last_dump_offset < fpga->regs->floppy_dump_buffer_size)
			{
				tmpptr = get_next_available_stream_chunk(fpga,&buffersize);
				if(tmpptr)
				{
					if(f)
						fwrite(tmpptr,buffersize,1,f);

					senddatapacket(tmpptr,buffersize);

					free(tmpptr);
				}
				else
				{
					i = dump_max_track + 1;
					j = dump_max_side + 1;
					fpga->last_dump_offset = fpga->regs->floppy_dump_buffer_size;
					script_printf(MSG_ERROR,"ERROR : get_next_available_stream_chunk failed !\n");
				}
			}

			if(f)
				fclose(f);

			script_printf(MSG_INFO_0,"%s done !\n",temp);
		}

		if(i<dump_max_track && !spy)
		{
			if(doubestep)
			{
				floppy_ctrl_move_head(fpga, 1, 2);
				headpos++;
			}
			else
			{
				floppy_ctrl_move_head(fpga, 1, 1);
				headpos++;
			}
		}
	}

readstop:
	free_dump_buffer(fpga);

	dump_running = 0;

	if(!spy)
	{
		floppy_ctrl_selectbyte(fpga, 0x00);
		//floppy_ctrl_select_drive(fpga, drive, 0);
		//floppy_ctrl_motor(fpga, drive, 0);
	}

	script_printf(MSG_INFO_0,"Done...\n");

	return 0;
}

int get_param(char * line, int param_index,char * param)
{
	int i,j;

	i = get_param_offset(line, param_index);
	j = 0;

	if(i>=0)
	{
		while( ( line[i] != 0 ) && ( line[i] != ' ' ) && ( line[i] != '\r' ) && ( line[i] != '\n' ) )
		{
			param[j] = line[i];
			j++;
			i++;
		}

		param[j] = 0;

		return 1;
	}

	return -1;

}

void *diskdump_thread(void *threadid)
{
	char * cmdline;
	int p[16];
	char tmp[512];
	int i;

	cmdline= (char*) threadid;

	for(i=0;i<9;i++)
	{
		if(get_param(cmdline, i + 1,tmp)>=0)
		{
			p[i] = 	atoi(tmp);
		}
	}

	readdisk(p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8]);

	return 0;
}

int cmd_dump(char * line)
{
	int p1,p2,p3,p4,p5,p6,p7,p8,p9,rc;
	char tmpstr[DEFAULT_BUFLEN];

	p1 = get_param(line, 1,tmpstr);
	p2 = get_param(line, 2,tmpstr);
	p3 = get_param(line, 3,tmpstr);
	p4 = get_param(line, 4,tmpstr);
	p5 = get_param(line, 5,tmpstr);
	p6 = get_param(line, 6,tmpstr);
	p7 = get_param(line, 7,tmpstr);
	p8 = get_param(line, 8,tmpstr);
	p9 = get_param(line, 9,tmpstr);

	if(p1>=0 && p2>=0 && p3>=0 && p4>=0 && p5>=0 && p6>=0 && p7>=0 && p8>=0 && p9>=0)
	{
		if(!dump_running)
		{
			strcpy(thread_dump_cmdline,line);

			rc = pthread_create(&threads_dump, NULL, diskdump_thread, (void *)&thread_dump_cmdline);
			if(rc)
			{
				script_printf(MSG_ERROR,"Error ! Can't Create the thread ! (Error %d)\r\n",rc);
			}
		}
		else
		{
			script_printf(MSG_ERROR,"Error ! Dump already running !\r\n");
		}

		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;

}

int cmd_stop(char * line)
{
	script_printf(MSG_INFO_0,"Stopping current dump...\n");

	stop_process = 1;

	while(dump_running)
	{
		sleep(1);
	}

	stop_process = 0;

	script_printf(MSG_INFO_0,"Current dump stopped !\n");

	return 1;
}

int cmd_print(char * line)
{
	int i;

	i = get_param_offset(line, 1);
	if(i>=0)
		script_printf(MSG_NONE,"%s\n",&line[i]);

	return 1;
}

int cmd_set_pin_mode(char * line)
{
	int i,j,k;
	char dev_index[DEFAULT_BUFLEN];
	char pinname[DEFAULT_BUFLEN];
	char mode[DEFAULT_BUFLEN];

	i = get_param(line, 1,dev_index);
	j = get_param(line, 2,pinname);
	k = get_param(line, 3,mode);

	if(i>=0 && j>=0 && k>=0)
	{
		script_printf(MSG_INFO_0,"Pin %s mode set to %d\n",pinname,atoi(mode));

		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;
}

int cmd_headstep(char * line)
{
	int i,j,track,dir;
	char trackstr[DEFAULT_BUFLEN];
	char drivestr[DEFAULT_BUFLEN];

	i = get_param(line, 1,drivestr);
	j = get_param(line, 2,trackstr);

	if(i>=0 && j>=0)
	{
		track = atoi(trackstr);
		script_printf(MSG_INFO_0,"Head step : %d\n",track);

		floppy_ctrl_select_drive(fpga, atoi(drivestr), 1);
		floppy_ctrl_selectbyte(fpga, 0x1F);

		usleep(1000);

		if(track < 0)
		{
			track = -track;
			headpos -= track;
			if(headpos<0)
				headpos=0;
			dir = 0;
		}
		else
		{
			headpos += track;

			dir = 1;
		}

		floppy_ctrl_move_head(fpga, dir, track);

		if((fpga->regs->floppy_ctrl_control & (0x1<<6)))
		{
			headpos = 0;
		}

		//floppy_ctrl_selectbyte(fpga, 0x00);
		//floppy_ctrl_select_drive(fpga, atoi(drivestr), 0);

		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;
}

int cmd_movehead(char * line)
{
	int i,j,track,cur_track,dir;
	char trackstr[DEFAULT_BUFLEN];
	char drivestr[DEFAULT_BUFLEN];

	i = get_param(line, 1,drivestr);
	j = get_param(line, 2,trackstr);

	if(i>=0 && j>=0)
	{
		track = atoi(trackstr);
		cur_track = (fpga->regs->floppy_ctrl_curtrack & 0x3FF);
		script_printf(MSG_INFO_0,"Head move : %d (cur pos: %d)\n",track);

		floppy_ctrl_select_drive(fpga, atoi(drivestr), 1);
		floppy_ctrl_selectbyte(fpga, 0x1F);

		usleep(12000);


		if( headpos < track )
		{
			track = (track - headpos);
			dir = 1;
		}
		else
		{
			track = headpos - track;
			dir = 0;
		}

		for(i=0;i<track;i++)
		{
			floppy_ctrl_move_head(fpga, dir, 1);
			usleep(12000);
			if(!dir)
			{
				if(headpos)
					headpos--;
			}
			else
			{
				headpos++;
			}

			if((fpga->regs->floppy_ctrl_control & (0x1<<6)))
			{
				headpos = 0;
			}
		}

		usleep(12000);

		//floppy_ctrl_select_drive(fpga, atoi(drivestr), 0);
		//floppy_ctrl_selectbyte(fpga, 0x00);

/*
		if(track>0)
		{
			floppy_ctrl_selectbyte(fpga, 0x1F);

			usleep(12000);

			floppy_ctrl_move_head(fpga, dir, track);

			usleep(12000);

			//floppy_ctrl_select_drive(fpga, atoi(drivestr), 0);
			floppy_ctrl_selectbyte(fpga, 0x00);
		}
*/
		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;
}

int cmd_reset(char * line)
{
	script_printf(MSG_INFO_0,"FPGA reset \n");
	reset_fpga(fpga);
	return 0;
}

int cmd_recalibrate(char * line)
{
	int i;
	int ret;
	char drivestr[DEFAULT_BUFLEN];

	i = get_param(line, 1,drivestr);
	if(i>=0)
	{
		floppy_ctrl_select_drive(fpga, atoi(drivestr), 1);
		floppy_ctrl_selectbyte(fpga, 0x1F);

		usleep(1000);

		ret = floppy_head_recalibrate(fpga);
		if(ret < 0)
		{
			script_printf(MSG_ERROR,"Head position calibration failed ! (%d)\n",ret);

			floppy_ctrl_select_drive(fpga, atoi(drivestr), 0);
			return 0;
		}

		headpos = 0;

		//floppy_ctrl_selectbyte(fpga, 0x00);
		//floppy_ctrl_select_drive(fpga, atoi(drivestr), 0);
	}

	return 1;
}

int cmd_set_motor_src(char * line)
{
	int i,j,drive,motsrc;
	char temp[DEFAULT_BUFLEN];
	char temp2[DEFAULT_BUFLEN];

	i = get_param(line, 1,temp);
	j = get_param(line, 2,temp);

	if(i>=0 && j>=0)
	{
		drive = atoi(temp);
		motsrc = atoi(temp2);

		script_printf(MSG_INFO_0,"Drive %d Motor source : %d\n",drive,motsrc);

		set_motor_src(fpga, drive, motsrc);

		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;
}

int cmd_set_select_src(char * line)
{
	int i,j,drive,selsrc;
	char temp[DEFAULT_BUFLEN];
	char temp2[DEFAULT_BUFLEN];

	i = get_param(line, 1,temp);
	j = get_param(line, 2,temp);

	if(i>=0 && j>=0)
	{
		drive = atoi(temp);
		selsrc = atoi(temp2);

		script_printf(MSG_INFO_0,"Drive %d select source : %d\n",drive,selsrc);

		set_select_src(fpga, drive, selsrc);

		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;
}

int cmd_set_dump_time_per_track(char * line)
{
	int i;
	char temp[DEFAULT_BUFLEN];

	i = get_param(line, 1,temp);

	if(i>=0)
	{
		dump_time_per_track = atoi(temp);

		if( !dump_time_per_track )
			dump_time_per_track = 800;

		if(dump_time_per_track > 60000)
			dump_time_per_track = 60000;

		script_printf(MSG_INFO_0,"dump_time_per_track : %d\n",dump_time_per_track);

		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;
}

int cmd_set_index_to_dump_time(char * line)
{
	int i;
	char temp[DEFAULT_BUFLEN];

	i = get_param(line, 1,temp);

	if(i>=0)
	{
		index_to_dump_delay = atoi(temp);

		script_printf(MSG_INFO_0,"index_to_dump_delay : %d\n",index_to_dump_delay);

		return 1;
	}

	script_printf(MSG_ERROR,"Bad/Missing parameter(s) ! : %s\n",line);

	return 0;
}

int cmd_help(char * line);

int cmd_version(char * line)
{
	script_printf(MSG_INFO_0,"HxC Streamer version : %s, Date : "__DATE__" "__TIME__"\n","1.0.0.0");
	return 1;
}

cmd_list cmdlist[] =
{
	{"print",					cmd_print},
	{"help",					cmd_help},
	{"?",						cmd_help},
	{"version",					cmd_version},

	{"jtag_set_pin_dir",		cmd_set_pin_mode},
	{"headstep",				cmd_headstep},
	{"motsrc",					cmd_set_motor_src},
	{"selsrc",					cmd_set_select_src},
	{"dump_time",				cmd_set_dump_time_per_track},
	{"index_to_dump",			cmd_set_index_to_dump_time},
	{"reset",					cmd_reset},
	{"recalibrate",				cmd_recalibrate},
	{"dump",					cmd_dump},
	{"stop",					cmd_stop},
	{"movehead",				cmd_movehead},

	{0 , 0}
};


int extract_cmd(char * line, char * command)
{
	int i;

	i = 0;
	while( ( line[i] != 0 ) && ( line[i] == ' ' ) )
	{
		i++;
	}

	if( line[i] != 0 )
	{
		while( ( line[i] != 0 ) && ( line[i] != ' ' ) && ( line[i] != '\r' ) && ( line[i] != '\n' ))
		{
			command[i] = line[i];
			i++;
		}

		command[i] = 0;

		return 1;
	}

	return 0;
}

int exec_cmd(char * command,char * line)
{
	int i;

	i = 0;
	while(cmdlist[i].func)
	{
		if( !strcmp(cmdlist[i].command,command) )
		{
			cmdlist[i].func(line);
			return 1;
		}

		i++;
	}

	return ERROR_CMD_NOT_FOUND;
}

int cmd_help(char * line)
{
	int i;

	script_printf(MSG_INFO_0,"Supported Commands :\n\n");

	i = 0;
	while(cmdlist[i].func)
	{
		script_printf(MSG_NONE,"%s\n",cmdlist[i].command);
		i++;
	}

	return 1;
}

int execute_line(char * line)
{
	char command[DEFAULT_BUFLEN];

	if( extract_cmd(line, command) )
	{
		if(strlen(command))
		{
			if(exec_cmd(command,line) == ERROR_CMD_NOT_FOUND )
			{
				script_printf(MSG_ERROR,"Command not found ! : %s\n",line);
				return 0;
			}
		}
		return 1;
	}

	return 0;
}

int execute_script(char * filename)
{
	FILE * f;
	char script_line[MAX_LINE_SIZE];

	f = fopen(filename,"r");
	if(f)
	{
		do
		{
			if(fgets(script_line,sizeof(script_line)-1,f))
			{
				execute_line(script_line);
			}
		}while(!feof(f));
		fclose(f);
	}
	return 0;
}
