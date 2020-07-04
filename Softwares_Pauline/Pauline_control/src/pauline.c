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

#include "libhxcfe.h"
#include "utils.h"
#include "fpga.h"
#include "stream_hfe.h"
#include "network.h"
#include "script.h"
#include "bmp_file.h"
#include "screen.h"

int verbose;
fpga_state * fpga;
char home_folder[512];

typedef struct gpio_description_
{
	char * name;
	uint32_t oe_register;
	uint32_t oe_bit;
	uint32_t oe_polarity;

	uint32_t out_register;
	uint32_t out_bit;
	uint32_t out_polarity;

	uint32_t input_register;
	uint32_t input_bit;
	uint32_t input_polarity;
}gpio_description;

gpio_description gpio_list[]=
{
	{"extio_0", 0xFFFFFFFF,0,0,     0x00000001,2,1,    0x00000001,2,1 }
};

int isOption(int argc, char* argv[],char * paramtosearch,char * argtoparam)
{
	int param=1;
	int i,j;

	char option[512];

	memset(option,0,512);
	while(param<=argc)
	{
		if(argv[param])
		{
			if(argv[param][0]=='-')
			{
				memset(option,0,512);

				j=0;
				i=1;
				while( argv[param][i] && argv[param][i]!=':')
				{
					option[j]=argv[param][i];
					i++;
					j++;
				}

				if( !strcmp(option,paramtosearch) )
				{
					if(argtoparam)
					{
						if(argv[param][i]==':')
						{
							i++;
							j=0;
							while( argv[param][i] )
							{
								argtoparam[j]=argv[param][i];
								i++;
								j++;
							}
							argtoparam[j]=0;
							return 1;
						}
						else
						{
							return -1;
						}
					}
					else
					{
						return 1;
					}
				}
			}
		}
		param++;
	}

	return 0;
}

void printhelp(char* argv[])
{
	printf("Options:\n");
	printf("  -help \t\t\t: This help\n");
	printf("  -license\t\t\t: Print the license\n");
	printf("  -verbose\t\t\t: Verbose mode\n");
	printf("  -home_folder:[path]\t\t\t: Set the base folder\n");
	printf("  -initscript:[path]\t\t\t: Set the init script path\n");
	printf("  -reset\t\t\t: FPGA reset\n");
	printf("  -drive:[drive nb]\t\t: select the drive number\n");
	printf("  -load:[filename]\t\t: load the a image\n");
	printf("  -save:[filename]\t\t: Save the a image\n");
	printf("  -headstep:[tracknb]\t\t: move the head\n");
	printf("  -selsrc:[id]\t\t\t: select source line\n");
	printf("  -motsrc:[id]\t\t\t: motor source line\n");
	printf("  -enabledrive\t\t\t: drive enable\n");
	printf("  -disabledrive\t\t\t: drive disable\n");
	printf("  -finput:[filename]\t\t: Input file image \n");
	printf("  -foutput:[filename]\t\t: Output file image \n");
	printf("  -readdsk\t\t\t: Read a Disk\n");
	printf("  -readdsk\t\t\t: Write a Disk\n");
	printf("  -highres\t\t\t: High sampling rate (50Mhz/20ns instead of 25Mhz/40ns)\n");
	printf("  -start_track:[side number]\t: Disk dump : first track number (default 0)\n");
	printf("  -max_track:[side number]\t: Disk dump : last track number (default 79)\n");
	printf("  -start_side:[side number]\t: Disk dump : first side number (default 0)\n");
	printf("  -max_side:[side number]\t: Disk dump : last side number (default 1)\n");
	printf("  -track_rd_time:[time (ms)]\t: Disk dump : track dump duration (ms) (default 800ms)\n");
	printf("  -after_index_delay:[time (us)]\t: Disk dump : index to track dump delay (us) (default 100000us)\n");
	printf("  -setiohigh:io number\n");
	printf("  -setiolow:io number\n");
	printf("  -setiohz:io number\n");
	printf("  -test_interface\n");
	printf("\n");
}

int main(int argc, char* argv[])
{
	char filename[512];
	char ofilename[512];
	char layoutformat[128];
	char temp[512];
	int doublestep,drive;

	int track,dir;
	int selsrc, motsrc;
	unsigned char * tmpptr;
	uint32_t  buffersize;
	FILE *f;
	int i,j;

	int dump_max_track;
	int dump_start_track;

	int dump_max_side;
	int dump_start_side;

	int dump_time_per_track;
	int high_res_mode;
	int ret,index_to_dump_delay;
	HXCFE* libhxcfe;

	pthread_t listener_thread;

	fpga = NULL;

	verbose = 0;
	drive = 0;
	doublestep = -1;
	home_folder[0] = '\0';

	printf("HxC Floppy Emulator : Pauline floppy drive simulator / floppy drive dumper control software v1.0.0.0\n");
	printf("Copyright (C) 2006-2020 Jean-Francois DEL NERO\n");
	printf("This program comes with ABSOLUTELY NO WARRANTY\n");
	printf("This is free software, and you are welcome to redistribute it\n");
	printf("under certain conditions;\n\n");

	libhxcfe = hxcfe_init();

	// License print...
	if(isOption(argc,argv,"license",0)>0)
	{
	}

	// Verbose option...
	if(isOption(argc,argv,"verbose",0)>0)
	{
		printf("verbose mode\n");
		verbose=1;
	}

	// help option...
	if(isOption(argc,argv,"help",0)>0)
	{
		printhelp(argv);
	}

	ret = hxcfe_execScriptFile( libhxcfe, "/data/Settings/drives.script" );
	if( ret < 0)
	{
		printf("Error while reading the default init script !\n");

		hxcfe_deinit( libhxcfe );
		exit(-1);
	}

	if(isOption(argc,argv,"initscript",(char*)&filename)>0)
	{
		ret = hxcfe_execScriptFile( libhxcfe, filename );
	}
	else
	{
		ret = hxcfe_execScriptFile( libhxcfe, "/home/pauline/Settings/drives.script" );
	}

	if( ret < 0)
	{
		printf("Error while reading the user init script !\n");
	}

	if(isOption(argc,argv,"servertst",0)>0)
	{
		printf("Start server...\n");
		if(pthread_create(&listener_thread, NULL, tcp_listener, NULL))
		{
			printf("Error ! Can't Create the listener thread !\n");
		}

		if(pthread_create(&listener_thread, NULL, tcp_listener, (void*)0x1))
		{
			printf("Error ! Can't Create the listener thread !\n");
		}

		for(;;)
			sleep(1);
	}

	fpga = init_fpga();
	if(!fpga)
	{
		printf("FPGA Init failed !\n");
		hxcfe_deinit( libhxcfe );
		exit(-1);
	}

	fpga->libhxcfe = libhxcfe;

	for(i=0;i<4;i++)
	{
		sprintf(temp,"DRIVE_%d_MAX_STEPS",i);
		fpga->drive_max_steps[i] = hxcfe_getEnvVarValue( fpga->libhxcfe, (char *)temp );

		get_drive_io(fpga, "DRIVE_%d_SELECT_LINE", i, &fpga->drive_sel_reg_number[i], &fpga->drive_sel_bit_mask[i]);
		get_drive_io(fpga, "DRIVE_%d_MOTOR_LINE", i, &fpga->drive_mot_reg_number[i], &fpga->drive_mot_bit_mask[i]);
	}

	if(isOption(argc,argv,"home_folder",(char*)&home_folder)>0)
	{
		printf("Home folder : %s\n",home_folder);
	}

	if(isOption(argc,argv,"server",0)>0)
	{
		printf("Start server...\n");
		if(pthread_create(&listener_thread, NULL, tcp_listener, NULL))
		{
			printf("Error ! Can't Create the listener thread !\n");
		}

		if(pthread_create(&listener_thread, NULL, tcp_listener, (void*)0x1))
		{
			printf("Error ! Can't Create the listener thread !\n");
		}

		for(;;)
		{
			if(threadparams_cmd[0] == NULL)
			{
				display_bmp("/data/pauline_splash_bitmaps/ready.bmp");
				print_netif_ips(0,64 - 13);
				screen_printtime(0,0,PRINTSCREEN_TRANSPARENT | PRINTSCREEN_BLACK_FG);
			}
			sleep(1);
		}
	}

	memset(filename,0,sizeof(filename));

	// Input file name option
	if(isOption(argc,argv,"finput",(char*)&filename)>0)
	{
		printf("Input file : %s\n",filename);
	}

	// Output file name option
	memset(ofilename,0,512);
	isOption(argc,argv,"foutput",(char*)&ofilename);

	// Module list option
	if(isOption(argc,argv,"modulelist",0)>0)
	{
	}

	// Interface mode list option
	if(isOption(argc,argv,"interfacelist",0)>0)
	{
	}

	if(isOption(argc,argv,"drive",(char*)&temp)>0)
	{
		drive = atoi(temp);
	}

	if(isOption(argc,argv,"reset",0)>0)
	{
		printf("FPGA Reset...\n");
		fflush(stdout);
		reset_fpga(fpga);
	}

	if(isOption(argc,argv,"selsrc",(char*)&temp)>0)
	{
		selsrc = atoi(temp);
		set_select_src(fpga, drive, selsrc);

		printf("Select source : %d\n", selsrc);
	}

	if(isOption(argc,argv,"motsrc",(char*)&temp)>0)
	{
		motsrc = atoi(temp);
		set_motor_src(fpga, drive, motsrc);
		printf("Motor source : %d\n", motsrc);
	}

	// Interface mode option
	if(isOption(argc,argv,"ifmode",(char*)&temp)>0)
	{
	}

	// Convert a file ?
	if(isOption(argc,argv,"conv",0)>0)
	{
		if(isOption(argc,argv,"uselayout",(char*)&layoutformat)>0)
		{
		}
		else
		{
		}
	}

	if(isOption(argc,argv,"singlestep",0)>0)
	{
		doublestep = 0;
	}

	if(isOption(argc,argv,"doublestep",0)>0)
	{
		doublestep = 0xFF;
	}

/*
	if(isOption(argc,argv,"init",0)>0)
	{
		printf("FPGA Init...\n");
		fflush(stdout);
		fpga = init_fpga();
		if(!fpga)
			printf("FPGA Init failed !\n");
	}*/


	if(isOption(argc,argv,"headstep",(char*)&temp)>0)
	{
		track = atoi(temp);
		printf("Head step : %d\n",track);
		if(track < 0)
		{
			track = -track;
			dir = 0;
		}
		else
		{
			dir = 1;
		}

		fflush(stdout);
		floppy_ctrl_move_head(fpga, dir, track);
	}

	if(isOption(argc,argv,"save",(char*)&ofilename)>0)
	{
		printf("Stream HFE save : %s, drive : %d\n",ofilename,drive);
		fflush(stdout);

		save_stream_hfe(fpga, drive, ofilename);
	}


	if(isOption(argc,argv,"load",(char*)&filename)>0)
	{
		printf("Stream HFE Load : %s, drive : %d\n",filename,drive);
		fflush(stdout);

		load_stream_hfe(fpga, drive, filename, 0,0);
	}

	if(isOption(argc,argv,"getiostate",(char*)&temp)>0)
	{

	}

	if(isOption(argc,argv,"setiohigh",(char*)&temp)>0)
	{
		set_extio(fpga, atoi(temp), 1, 1);
	}

	if(isOption(argc,argv,"setiolow",(char*)&temp)>0)
	{
		set_extio(fpga, atoi(temp), 1, 0);
	}

	if(isOption(argc,argv,"setiohz",(char*)&temp)>0)
	{
		set_extio(fpga, atoi(temp), 0, 0);
	}

	if(isOption(argc,argv,"enabledrive",0)>0)
	{
		enable_drive(fpga, drive,1);

		printf("Drive enabled : %d\n", drive);
	}

	if(isOption(argc,argv,"disabledrive",0)>0)
	{
		enable_drive(fpga, drive,0);

		printf("Drive disabled : %d\n", drive);
	}

	high_res_mode = 0;
	if(isOption(argc,argv,"highres",0)>0)
	{
		high_res_mode = 1;
	}

	dump_time_per_track = 800; // 800ms
	if(isOption(argc,argv,"track_rd_time",(char*)&temp)>0)
	{
		dump_time_per_track = atoi(temp);

		if( !dump_time_per_track )
			dump_time_per_track = 800;

		if(dump_time_per_track > 60000)
			dump_time_per_track = 60000;
	}

	index_to_dump_delay = 100*1000; // 100ms
	if(isOption(argc,argv,"after_index_delay",(char*)&temp)>0)
	{
		index_to_dump_delay = atoi(temp);
	}

	dump_start_track = 0;
	if(isOption(argc,argv,"start_track",(char*)&temp)>0)
	{
		dump_start_track = atoi(temp);
	}

	dump_max_track = 79;
	if(isOption(argc,argv,"max_track",(char*)&temp)>0)
	{
		dump_max_track = atoi(temp);
	}

	if(dump_start_track > dump_max_track )
		dump_max_track = dump_start_track;

	dump_start_side = 0;
	if(isOption(argc,argv,"start_side",(char*)&temp)>0)
	{
		dump_start_side = atoi(temp);
	}

	dump_max_side = 1;
	if(isOption(argc,argv,"max_side",(char*)&temp)>0)
	{
		dump_max_side = atoi(temp);
	}

	if(dump_start_side > dump_max_track )
		dump_max_side = dump_start_side;

	if(isOption(argc,argv,"test_interface",0)>0)
	{
		test_interface(fpga);
	}

	if(isOption(argc,argv,"readdsk",0)>0)
	{
		printf("Start disk reading...\nTrack(s): %d <-> %d, Side(s): %d <-> %d, Time: %dms, %s\n",dump_start_track,dump_max_track,dump_start_side,dump_max_side,dump_time_per_track,high_res_mode?"50Mhz":"25Mhz");

		floppy_ctrl_motor(fpga, drive, 1);

		for(i=0;i<1000;i++)
			usleep(1000);

		floppy_ctrl_select_drive(fpga, drive, 1);

		usleep(1000);

		ret = floppy_head_recalibrate(fpga);
		if(ret < 0)
		{
			printf("Head position calibration failed ! (%d)\n",ret);

			floppy_ctrl_select_drive(fpga, drive, 0);
			floppy_ctrl_motor(fpga, drive, 0);
			hxcfe_deinit( libhxcfe );
			exit(-1);
		}

		if(dump_start_track)
			floppy_ctrl_move_head(fpga, 1, dump_start_track);

		if( dump_max_track > fpga->drive_max_steps[drive] )
		{
			printf("Warning : Drive Max step : %d !\n",fpga->drive_max_steps[drive]);
			dump_max_track = fpga->drive_max_steps[drive];
		}

		for(i=dump_start_track;i<=dump_max_track;i++)
		{
			for(j=dump_start_side;j<=dump_max_side;j++)
			{
				sprintf(temp,"track%.2d.%d.hxcstream",i,j);
				f = fopen(temp,"wb");
				if(!f)
					printf("ERROR : Can't create %s\n",temp);

				floppy_ctrl_side(fpga, drive, j);

				if(high_res_mode)
					buffersize = (dump_time_per_track * (((50000000 / 16 /*16 bits shift*/ ) * 4 /*A word is 4 bytes*/) / 1000));
				else
					buffersize = (dump_time_per_track * (((25000000 / 16 /*16 bits shift*/ ) * 4 /*A word is 4 bytes*/) / 1000));

				buffersize += ((4 - (buffersize&3)) & 3);

				fpga->last_dump_offset = 0;
				fpga->bitdelta = 0;
				fpga->chunk_number = 0;

				start_dump(fpga, buffersize, high_res_mode , index_to_dump_delay,0);

				while( fpga->last_dump_offset < fpga->regs->floppy_dump_buffer_size)
				{
					tmpptr = get_next_available_stream_chunk(fpga,&buffersize);
					if(tmpptr)
					{
						fwrite(tmpptr,buffersize,1,f);
						free(tmpptr);
					}
					else
					{
						i = dump_max_track + 1;
						j = dump_max_side + 1;
						fpga->last_dump_offset = fpga->regs->floppy_dump_buffer_size;
						printf("ERROR : get_next_available_stream_chunk failed !\n");
					}
				}

				if(f)
					fclose(f);

				printf("%s done !\n",temp);
			}

			if(i<=dump_max_track)
				floppy_ctrl_move_head(fpga, 1, 1);
		}

		floppy_ctrl_select_drive(fpga, drive, 0);
		floppy_ctrl_motor(fpga, drive, 0);

		printf("Done...\n");
	}

	if(isOption(argc,argv,"regs",0)>0)
	{
		print_fpga_regs(fpga);
	}

	if( (isOption(argc,argv,"help",0)<=0) &&
		(isOption(argc,argv,"license",0)<=0) &&
		(isOption(argc,argv,"modulelist",0)<=0) &&
		(isOption(argc,argv,"interfacelist",0)<=0) &&
		(isOption(argc,argv,"headstep",0)<=0) &&
		(isOption(argc,argv,"drive",0)<=0) &&
		(isOption(argc,argv,"load",0)<=0) &&
		(isOption(argc,argv,"save",0)<=0) &&
		(isOption(argc,argv,"infos",0)<=0 ) &&
		(isOption(argc,argv,"motsrc",0)<=0 ) &&
		(isOption(argc,argv,"selsrc",0)<=0 ) &&
		(isOption(argc,argv,"enabledrive",0)<=0 ) &&
		(isOption(argc,argv,"disabledrive",0)<=0 ) &&
		(isOption(argc,argv,"test",0)<=0 ) &&
		(isOption(argc,argv,"readdsk",0)<=0 ) &&
		(isOption(argc,argv,"writedsk",0)<=0 ) &&
		(isOption(argc,argv,"regs",0)<=0 ) &&
		(isOption(argc,argv,"home_folder",0)<=0 ) &&
		(isOption(argc,argv,"server",0)<=0 ) &&
		(isOption(argc,argv,"test_interface",0)<=0 ) &&
		(isOption(argc,argv,"setiolow",0)<=0 ) &&
		(isOption(argc,argv,"setiohigh",0)<=0 ) &&
		(isOption(argc,argv,"setiohz",0)<=0 ) &&
		(isOption(argc,argv,"initscript",0)<=0 ) &&
		(isOption(argc,argv,"reset",0)<=0 )

		)
	{
		printhelp(argv);
	}

	return 0;
}
