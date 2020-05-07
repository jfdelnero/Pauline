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
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <ftw.h>
#include <dirent.h>
#include <errno.h>

#include "script.h"
#include "fpga.h"
#include "network.h"
#include "errors.h"

#include "bmp_file.h"
#include "screen.h"

extern char home_folder[512];
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

static int is_end_line(char c)
{
	if( c == 0 || c == '#' || c == '\r' || c == '\n' )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

static int is_space(char c)
{
	if( c == ' ' || c == '\t' )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

static int get_next_word(char * line, int offset)
{
	while( !is_end_line(line[offset]) && ( line[offset] == ' ' ) )
	{
		offset++;
	}

	return offset;
}

static int copy_param(char * dest, char * line, int offs)
{
	int i,insidequote;

	i = 0;
	insidequote = 0;
	while( !is_end_line(line[offs]) && ( insidequote || !is_space(line[offs]) ) )
	{
		if(line[offs] != '"')
		{
			if(dest)
				dest[i] = line[offs];

			i++;
		}
		else
		{
			if(insidequote)
				insidequote = 0;
			else
				insidequote = 1;
		}

		offs++;
	}

	if(dest)
		dest[i] = 0;

	return offs;
}

static int get_param_offset(char * line, int param)
{
	int param_cnt, offs;

	offs = 0;
	offs = get_next_word(line, offs);

	param_cnt = 0;
	do
	{
		offs = copy_param(NULL, line, offs);

		offs = get_next_word( line, offs );

		if(line[offs] == 0 || line[offs] == '#')
			return -1;

		param_cnt++;
	}while( param_cnt < param );

	return offs;
}

static int get_param(char * line, int param_offset,char * param)
{
	int offs;

	offs = get_param_offset(line, param_offset);

	if(offs>=0)
	{
		offs = copy_param(param, line, offs);

		return 1;
	}

	return -1;
}

int is_dir_present(char * path)
{
	DIR* dir = opendir(path);

	if (dir)
	{
		closedir(dir);
		return 1;
	}
	else
	{
		if (ENOENT == errno)
		{
			return 0;
		}
		else
		{
			return 0;
		}
	}
}

char global_search_name[512];
int global_max_index;

static int display_info(const char *fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf)
{
	int i,j,val;

	if(tflag == FTW_D)
	{
		i = strlen(fpath);
		while( (fpath[i] != '/') && i)
		{
			i--;
		}

		if(  fpath[i] == '/' )
			i++;

		if( !strncmp( &fpath[i],global_search_name,strlen(global_search_name)) )
		{
			if( strlen(&fpath[i]) - strlen(global_search_name) == 4 )
			{
				i += strlen(global_search_name);

				for(j=0;j<4;j++)
				{
					if(  !(fpath[i + j] >= '0' && fpath[i + j] <= '9') )
					{
						break;
					}
				}

				if( j == 4 )
				{
					val = atoi(&fpath[i]);

					if(val > global_max_index)
					{
						global_max_index = val;
					}
				}
			}
		}

	}

    return 0;
}

int prepare_folder(char * name, char * comment, int start_index, int mode, char * folder_pathoutput)
{
	char folder_path[1024];
	char dump_name[512];
	char tmp[512];
	struct stat st = {0};
	int ret;
	int max;
	int i;

	ret = -1;

	strcpy(dump_name,"untitled dump");
	if(name)
	{
		i = strlen(name);
		if(i)
		{
			strcpy(dump_name,name);
			while(i)
			{
				if(dump_name[i - 1] == ' ')
				{
					dump_name[i - 1] = '\0';
				}
				else
				{
					break;
				}

				i--;
			}
		}
	}

	if(comment)
	{
		i = strlen(comment);
		if(i)
		{
			while(i)
			{
				if(comment[i - 1] == ' ')
				{
					comment[i - 1] = '\0';
				}
				else
				{
					break;
				}

				i--;
			}
		}
	}

	switch(mode)
	{
		case 0:
			sprintf(folder_path,"%s/%s",home_folder,dump_name);

			if(!is_dir_present(folder_path))
			{
				ret = mkdir(folder_path, 0777);
			}

			if(strlen(comment))
			{
				sprintf(tmp,"/%s-%s",dump_name,comment);
			}
			else
			{
				sprintf(tmp,"/%s",dump_name);
			}

			strcat(folder_path,tmp);

			if(is_dir_present(folder_path))
			{
				sprintf(tmp,"rm -rf \"%s\"",folder_path);
				ret = system(tmp);
			}

			if (stat(folder_path, &st) == -1)
			{
				ret = mkdir(folder_path, 0777);
			}

			strcpy(folder_pathoutput,folder_path);

			// No file index
		break;
		case 1:
			// Manual - no auto increment (overwrite if present)
			sprintf(folder_path,"%s/%s",home_folder,dump_name);

			if(!is_dir_present(folder_path))
			{
				ret = mkdir(folder_path, 0777);
			}

			if(strlen(comment))
			{
				sprintf(tmp,"/%s-%s-%.4d",dump_name,comment,start_index);
			}
			else
			{
				sprintf(tmp,"/%s-%.4d",dump_name,start_index);
			}
			strcat(folder_path,tmp);

			if(is_dir_present(folder_path))
			{
				sprintf(tmp,"rm -rf \"%s\"",folder_path);
				ret = system(tmp);
			}

			if (stat(folder_path, &st) == -1)
			{
				ret = mkdir(folder_path, 0777);
			}

			strcpy(folder_pathoutput,folder_path);

		break;
		case 2:
			sprintf(folder_path,"%s/%s",home_folder,dump_name);

			if(!is_dir_present(folder_path))
			{
				ret = mkdir(folder_path, 0777);
				if(ret < 0)
					return -1;
			}

			// Find the last index (no overwrite!)
			global_max_index = 0;
			if(strlen(comment))
			{
				sprintf(global_search_name,"%s-%s-",dump_name,comment);
			}
			else
			{
				sprintf(global_search_name,"%s-",dump_name);
			}

			ftw(folder_path, display_info, 20 );

			max = global_max_index;

			if(max != 9999)
			{
				max++;

				if(max < start_index)
					max = start_index;

				if(strlen(comment))
				{
					sprintf(tmp,"/%s-%s-%.4d",dump_name,comment,max);
				}
				else
				{
					sprintf(tmp,"/%s-%.4d",dump_name,max);
				}
				strcat(folder_path,tmp);

				if(!is_dir_present(folder_path))
				{
					ret = mkdir(folder_path, 0777);
					strcpy(folder_pathoutput,folder_path);
					ret = 0;
				}
			}
		break;
	}

	return ret;
}

int readdisk(int drive, int dump_start_track,int dump_max_track,int dump_start_side,int dump_max_side,int high_res_mode,int doubestep,int ignore_index,int spy, char * name, char * comment, int start_index, int incmode )
{
	int i,j;
	char temp[512];
	char folder_path[512];
	DIR* dir;

	FILE *f;
	unsigned char * tmpptr;
	uint32_t  buffersize;
	int error;

	error = PAULINE_NO_ERROR;

	f = NULL;
	dump_running = 1;
	if(!spy)
	{
		script_printf(MSG_INFO_0,"Start disk reading...\nTrack(s): %d <-> %d, Side(s): %d <-> %d, Ignore index: %d, Time: %dms, %s\n",dump_start_track,dump_max_track,dump_start_side,dump_max_side,ignore_index,dump_time_per_track,high_res_mode?"50Mhz":"25Mhz");

		display_bmp("/data/pauline_splash_bitmaps/reading_floppy.bmp");

	//	floppy_ctrl_motor(fpga, drive, 1);
		floppy_ctrl_selectbyte(fpga, 0x1F);


		if( prepare_folder( name, comment, start_index, incmode, folder_path) < 0 )
		{
			display_bmp("/data/pauline_splash_bitmaps/error.bmp");

			script_printf(MSG_ERROR,"ERROR : Can't create the folder\n",temp);
			dump_running = 0;
			return -1;
		}

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

				display_bmp("/data/pauline_splash_bitmaps/error.bmp");

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

			sprintf(temp,"%s/track%.2d.%d.hxcstream",folder_path,i,j);
			f = fopen(temp,"wb");
			if(!f)
			{
				script_printf(MSG_ERROR,"ERROR : Can't create %s\n",temp);

				display_bmp("/data/pauline_splash_bitmaps/error.bmp");
			}
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
					if( fpga->regs->floppy_done & (0x01 << 5) )
					{
						error = PAULINE_NOINDEX_ERROR;
					}
					else
					{
						error = PAULINE_INTERNAL_ERROR;
					}

					i = dump_max_track + 1;
					j = dump_max_side + 1;
					fpga->last_dump_offset = fpga->regs->floppy_dump_buffer_size;
					script_printf(MSG_ERROR,"ERROR : get_next_available_stream_chunk failed !\n");
					display_bmp("/data/pauline_splash_bitmaps/error.bmp");
				}
			}

			if(f)
				fclose(f);

			if(strlen(temp) > 24)
			{
				temp[strlen(temp) - 36] = '.';
				temp[strlen(temp) - 35] = '.';
				temp[strlen(temp) - 34] = '.';
				script_printf(MSG_INFO_0,"%s done !\n",&temp[strlen(temp) - 36]);
			}
			else
			{
				script_printf(MSG_INFO_0,"%s done !\n",temp);
			}

			display_bmp("/data/pauline_splash_bitmaps/reading_floppy.bmp");
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

	if(error)
	{
		switch(error)
		{
			case PAULINE_INTERNAL_ERROR:
				display_bmp("/data/pauline_splash_bitmaps/internal_error.bmp");
				script_printf(MSG_INFO_0,"Internal error !\n");
			break;
			case PAULINE_NOINDEX_ERROR:
				display_bmp("/data/pauline_splash_bitmaps/no_index.bmp");
				script_printf(MSG_INFO_0,"No index signal ! Disk in drive ?\n");
			break;
		}
	}
	else
	{
		if(!stop_process)
		{
			script_printf(MSG_INFO_0,"Done...\n");
			display_bmp("/data/pauline_splash_bitmaps/done.bmp");
		}
		else
		{
			script_printf(MSG_INFO_0,"Stopped !!!\n");
			display_bmp("/data/pauline_splash_bitmaps/stopped.bmp");
		}
	}

	return 0;
}

void *diskdump_thread(void *threadid)
{
	char * cmdline;
	int p[16];
	char tmp[512];
	char name[512];
	char comment[512];

	char str_index_mode[512];
	int i,index_mode;

	cmdline= (char*) threadid;

	for(i=0;i<12;i++)
	{
		if(get_param(cmdline, i + 1,tmp)>=0)
		{
			p[i] = 	atoi(tmp);
		}
	}

	name[0] = 0;
	if(!(get_param(cmdline, 9 + 1,name)>=0))
	{
	}

	if(!strlen(name))
		strcpy(name,"untitled");

	comment[0] = 0;
	if(!(get_param(cmdline, 10 + 1,comment)>=0))
	{
	}

	if(!(get_param(cmdline, 12 + 1,str_index_mode)>=0))
	{
		str_index_mode[0] = 0;
		index_mode = 2;
	}
	else
	{
		index_mode = 2;

		if(!strcmp(str_index_mode,"AUTO_INDEX_NAME"))
		{
			index_mode = 2;
		}

		if(!strcmp(str_index_mode,"NONE_INDEX_NAME"))
		{
			index_mode = 0;
		}

		if(!strcmp(str_index_mode,"MANUAL_INDEX_NAME"))
		{
			index_mode = 1;
		}
	}

	readdisk(p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],name,comment,p[11],index_mode);

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
