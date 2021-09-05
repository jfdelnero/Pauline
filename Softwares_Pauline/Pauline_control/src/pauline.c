/*
//
// Copyright (C) 2019-2021 Jean-François DEL NERO
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
#include <execinfo.h>

#include "libhxcfe.h"
#include "utils.h"
#include "fpga.h"
#include "stream_hfe.h"
#include "network.h"
#include "websocket.h"
#include "script.h"
#include "bmp_file.h"
#include "screen.h"
#include "ios.h"

#include "messages.h"

#include "version.h"

int verbose;
fpga_state * fpga;
char home_folder[512];

#define INOTIFY_RD_BUF_SIZE ( 32*1024 )

void sig_handler(int sig)
{
	void *array[16];
	size_t size;
	int ret;
	int flog;
	char tmpstr[256];

	// get void*'s for all entries on the stack
	size = backtrace(array, 16);

	// print out all the frames to stderr
	sprintf(tmpstr, "\n-----------------------\nError: signal %d:\n", sig);

	ret = write(stderr,tmpstr, strlen(tmpstr));
	backtrace_symbols_fd(array, size, STDERR_FILENO);

	flog = open(CRASH_LOGS_FILE, O_CREAT | O_WRONLY | O_APPEND, (S_IRUSR | S_IWUSR));
	if( flog > 0 )
	{
		ret = write(flog,tmpstr, strlen(tmpstr));
		backtrace_symbols_fd(array, size, flog);
		close(flog);
	}

	exit(1);
}

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
	printf("  -home_folder:[path]\t\t: Set the base folder\n");
	printf("  -initscript:[path]\t\t: Set the init script path\n");
	printf("  -reset\t\t\t: FPGA reset\n");
	printf("  -drive:[drive nb]\t\t: select the drive number\n");
	printf("  -load:[filename]\t\t: load the a image\n");
	printf("  -save:[filename]\t\t: Save the a image\n");
	printf("  -headrecal\t\t: recalibrate the head\n");
	printf("  -headstep:[tracknb][\t\t\t: move the head\n");
	printf("  -selsrc:[id]\t\t\t: drive simulation select source line\n");
	printf("  -motsrc:[id]\t\t\t: drive simulation motor source line\n");
	printf("  -pin02mode:[id]\t\t\t: drive simulation pin 2 status line mode\n");
	printf("  -pin34mode:[id]\t\t\t: drive simulation pin 34 status line mode\n");
	printf("  -enabledrive\t\t\t: drive enable\n");
	printf("  -disabledrive\t\t\t: drive disable\n");
	printf("  -finput:[filename]\t\t: Input file image \n");
	printf("  -foutput:[filename]\t\t: Output file image \n");
	printf("  -readdsk\t\t\t: Read a Disk\n");
	printf("  -writedsk\t\t\t: Write a Disk\n");
	printf("  -highres\t\t\t: High sampling rate (50Mhz/20ns instead of 25Mhz/40ns)\n");
	printf("  -start_track:[side number]\t: Disk dump : first track number (default 0)\n");
	printf("  -max_track:[side number]\t: Disk dump : last track number (default 79)\n");
	printf("  -start_side:[side number]\t: Disk dump : first side number (default 0)\n");
	printf("  -max_side:[side number]\t: Disk dump : last side number (default 1)\n");
	printf("  -track_rd_time:[time (ms)]\t: Disk dump : track dump duration (ms) (default 800ms)\n");
	printf("  -after_index_delay:[time (us)]: Disk dump : index to track dump delay (us) (default 100000us)\n");
	printf("  -autodetect\t\t\t: drives auto-detection\n");
	printf("  -testmaxtrack\t\t\t: drives max track auto-detection\n");
	printf("  -set:[io name]\n");
	printf("  -clear:[io name]\n");
	printf("  -get:[io name]\n");
	printf("  -ledsrc:[io name]\n");
	printf("  -ioslist\n");
	printf("  -ejectdisk\n");
	printf("  -setiohigh:[io number]\n");
	printf("  -setiolow:[io number]\n");
	printf("  -setiohz:[io number]\n");
	printf("  -sound:[frequency]\n");
	printf("  -test_interface\n");
	printf("\n");
	printf("Drive Simulation select lines ID (-selsrc & -motsrc ID):\n");
	printf("  0 : Always deasserted\n");
	printf("  1 : Always asserted\n");
	printf("  8 : SEL0/MOTEA  (Pin 10)\n");
	printf("  9 : SEL1/DRVSB  (Pin 12)\n");
	printf("  10: SEL2/DRVSA  (Pin 14)\n");
	printf("  11: SEL3        (Pin 6)\n");
	printf("  12: MTRON/MOTEB (Pin 16)\n");
	printf("  13: EXTERNAL IO (J5 - Pin 4)\n");

	printf("\n");
	printf("Drive Simulation status lines ID (-pin02mode & -pin34mode ID):\n");
	printf("  0 : Low state\n");
	printf("  1 : High state\n");
	printf("  2 : nReady\n");
	printf("  3 : Ready\n");
	printf("  4 : nDensity\n");
	printf("  5 : Density\n");
	printf("  6 : nDiskChange (mode 1 : Head step clear)\n");
	printf("  7 : DiskChange  (mode 1 : Head step clear)\n");
	printf("  8 : nDiskChange (mode 2 : Head step clear + timer/timeout clear)\n");
	printf("  9 : DiskChange  (mode 2 : Head step clear + timer/timeout clear)\n");
	printf("  10: nDiskChange (mode 3 : timer/timeout clear)\n");
	printf("  11: DiskChange  (mode 3 : timer/timeout clear)\n");
	printf("  12: nDiskChange (mode 4 : floppy_dc_reset input clear)\n");
	printf("  13: DiskChange  (mode 4 : floppy_dc_reset input clear)\n");
	printf("\n");

	// Signal input mux
	printf("Signal input mux (-led1src & -led2src ID):\n");
	printf("  0 : LED gpio register\n");
	printf("  1 : Drive 0 emulation enabled\n");
	printf("  2 : Drive 1 emulation enabled\n");
	printf("  3 : Drive 2 emulation enabled\n");
	printf("  4 : Drive 3 emulation enabled\n");
	printf("  5 : Motor emulation input enabled\n");
	printf("  6 : Floppy step output\n");
	printf("  7 : Floppy dir output\n");
	printf("  8 : Floppy side1 output\n");
	printf("  9 : Floppy index input\n");
	printf(" 10 : Floppy pin 2 input\n");
	printf(" 11 : Floppy pin 34 input\n");
	printf(" 12 : Floppy write protect input\n");
	printf(" 13 : Floppy data input\n");
	printf(" 14 : Floppy write gate output\n");
	printf(" 15 : Floppy write data output\n");
	printf(" 16 : Host pin 10 / sel 0 input\n");
	printf(" 17 : Host pin 12 / sel 1 input\n");
	printf(" 18 : Host pin 14 / sel 2 input\n");
	printf(" 19 : Host pin 16 / sel 3 input\n");
	printf(" 20 : Host pin 6  / mot on input\n");
	printf(" 21 : Host step input\n");
	printf(" 22 : Host dir input\n");
	printf(" 23 : Host side1 input\n");
	printf(" 24 : Host write gate input\n");
	printf(" 25 : Host write data input\n");
	printf(" 26 : IO input 0\n");
	printf(" 27 : IO input 1\n");
	printf(" 28 : IO input 2\n");
	printf(" 29 : IO input 3\n");
	printf(" 30 : IO input 4\n");
	printf(" 31 : IO input 5\n");

	printf("\n");
}

void *inotify_gotsig(int sig, siginfo_t *info, void *ucontext)
{
	return NULL;
}

void* inotify_thread(void* arg)
{
	fpga_state * ctx;
	int i,length;
	char inotify_buffer[INOTIFY_RD_BUF_SIZE] __attribute__ ((aligned(__alignof__(struct inotify_event))));
	const struct inotify_event *event;
	struct sigaction sa;

	ctx = (fpga_state *)arg;

	sa.sa_handler = NULL;
	sa.sa_sigaction =  (void *)inotify_gotsig;
	sa.sa_flags = SA_SIGINFO;
	sigemptyset(&sa.sa_mask);

	if (sigaction(SIGUSR1, &sa, NULL) < 0)
	{
		return (void *)-1;
	}

	for (;;)
	{
		memset(inotify_buffer,0,sizeof(inotify_buffer));
		length = read(ctx->inotify_fd, inotify_buffer, sizeof(inotify_buffer));

		if ( length >= 0 )
		{
			i = 0;
			while ( i < length && i < INOTIFY_RD_BUF_SIZE )
			{

				event = ( struct inotify_event * ) &inotify_buffer[ i ];

				// Sanity check to prevent possible buffer overrun/overflow.
				if ( event->len && (i + (( sizeof (struct inotify_event) ) + event->len) < sizeof(inotify_buffer)) )
				{
					if ( event->mask & IN_CREATE )
					{

					}

					if ( event->mask & IN_MODIFY )
					{
						hxcfe_execScriptFile( ctx->libhxcfe, DEFAULT_DRIVES_CFG_FILE );
						hxcfe_execScriptFile( ctx->libhxcfe, USER_DRIVES_CFG_FILE );
					}

					if ( event->mask & IN_DELETE )
					{

					}

				}

				i +=  (( sizeof (struct inotify_event) ) + event->len);
			}
		}
		else
		{
			return NULL;
		}
	}
}

int inotify_handler_addwatch( fpga_state * ctx, char * path )
{
	if( ctx->inotify_fd != -1 )
	{
		return inotify_add_watch( ctx->inotify_fd, path, /*IN_CREATE | IN_DELETE |*/ IN_MODIFY );
	}

	return -1;
}

int inotify_handler_rmwatch( fpga_state * ctx, int wd )
{
	if( ctx->inotify_fd != -1 && wd != -1 )
	{
		return inotify_rm_watch( ctx->inotify_fd, wd );
	}

	return -1;
}

int testmaxtrack[]={ 10, 20, 36, 40, 41, 42, 43, 44, 45, 46, 50, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, -1};

int main(int argc, char* argv[])
{
	char filename[512];
	char ofilename[512];
	char layoutformat[128];
	char temp[512];
	//int doublestep;
	int drive;

	int track,dir;
	int selsrc, motsrc;
	int pin02mode, pin34mode;
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
	pthread_t websocket_thread;
	pthread_t websocket_image_thread;
	pthread_t script_thread;

	fpga = NULL;

	signal(SIGSEGV, sig_handler);

	init_srv_msg();

	verbose = 0;
	drive = 0;
	//doublestep = -1;
	home_folder[0] = '\0';

	printf("HxC Floppy Emulator : Pauline floppy drive simulator / floppy drive dumper control software v"STR_FILE_VERSION2"\n");
	printf("Copyright (C) 2006-2021 Jean-Francois DEL NERO\n");
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

	// Default config value
	hxcfe_setEnvVar( libhxcfe, "PAULINE_UI_SOUND", "1" );
	hxcfe_setEnvVar( libhxcfe, "DRIVE_MOTOR_SPINUP_DELAY",     "1000" );
	hxcfe_setEnvVar( libhxcfe, "DRIVE_HEAD_LOAD_DELAY",        "250" );
	hxcfe_setEnvVar( libhxcfe, "DRIVE_HEAD_STEP_RATE",         "24000" );
	hxcfe_setEnvVar( libhxcfe, "DRIVE_HEAD_SETTLING_TIME",     "16000" );
	hxcfe_setEnvVar( libhxcfe, "DRIVE_STEP_SIGNAL_WIDTH",      "8" );
	hxcfe_setEnvVar( libhxcfe, "DRIVE_STEP_PHASES_WIDTH",      "14000" );
	hxcfe_setEnvVar( libhxcfe, "DRIVE_STEP_PHASES_STOP_WIDTH", "36000" );

	ret = hxcfe_execScriptFile( libhxcfe, DEFAULT_DRIVES_CFG_FILE );
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
		ret = hxcfe_execScriptFile( libhxcfe, USER_DRIVES_CFG_FILE );
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

	for(i=0;i<MAX_DRIVES;i++)
	{
		sprintf(temp,"DRIVE_%d_MAX_STEPS",i);
		fpga->drive_max_steps[i] = hxcfe_getEnvVarValue( fpga->libhxcfe, (char *)temp );

		get_drive_io(fpga, "DRIVE_%d_SELECT_LINE", i, &fpga->drive_sel_reg_number[i], &fpga->drive_sel_bit_mask[i]);
		get_drive_io(fpga, "DRIVE_%d_MOTOR_LINE", i, &fpga->drive_mot_reg_number[i], &fpga->drive_mot_bit_mask[i]);
		get_drive_io(fpga, "DRIVE_%d_HEADLOAD_LINE", i, &fpga->drive_headload_reg_number[i], &fpga->drive_headload_bit_mask[i]);
		get_drive_io(fpga, "DRIVE_%d_X68000_OPTION_SELECT_LINE", i, &fpga->drive_X68000_opt_sel_reg_number[i], &fpga->drive_X68000_opt_sel_bit_mask[i]);
	}

	if(isOption(argc,argv,"home_folder",(char*)&home_folder)>0)
	{
		printf("Home folder : %s\n",home_folder);
	}

	if(isOption(argc,argv,"server",0)>0)
	{
		printf("Start server...\n");

		reset_fpga(fpga);

		if(pthread_create(&listener_thread, NULL, tcp_listener, NULL))
		{
			printf("Error ! Can't Create the listener thread !\n");
		}

		if(pthread_create(&listener_thread, NULL, tcp_listener, (void*)0x1))
		{
			printf("Error ! Can't Create the listener thread !\n");
		}

		if(pthread_create(&websocket_thread, NULL, websocket_listener, NULL))
		{
			printf("Error ! Can't Create the websocket listener thread !\n");
		}

		if(pthread_create(&websocket_image_thread, NULL, websocket_image_listener, NULL))
		{
			printf("Error ! Can't Create the websocket image listener thread !\n");
		}

		if(pthread_create(&script_thread, NULL, server_script_thread, NULL))
		{
			printf("Error ! Can't Create the script thread !\n");
		}

		fpga->inotify_fd = inotify_init1(0x00);

		inotify_handler_addwatch(fpga, USER_DRIVES_CFG_FILE);

		sound(fpga,1500, 200);
		sound(fpga,2000, 200);
		sound(fpga,2500, 200);

		for(;;)
		{
			if( !count_client() )
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

	if(isOption(argc,argv,"sound",(char*)&temp)>0)
	{
		sound(fpga,atoi(temp),100);
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

	if(isOption(argc,argv,"pin02mode",(char*)&temp)>0)
	{
		pin02mode = atoi(temp);
		set_pin02_mode(fpga, drive, pin02mode);
		printf("Pin 2 Mode : %d\n", pin02mode);
	}

	if(isOption(argc,argv,"pin34mode",(char*)&temp)>0)
	{
		pin34mode = atoi(temp);
		set_pin34_mode(fpga, drive, pin34mode);
		printf("Pin 34 Mode : %d\n", pin34mode);
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

	/*
	if(isOption(argc,argv,"singlestep",0)>0)
	{
		doublestep = 0;
	}

	if(isOption(argc,argv,"doublestep",0)>0)
	{
		doublestep = 0xFF;
	}
	*/

/*
	if(isOption(argc,argv,"init",0)>0)
	{
		printf("FPGA Init...\n");
		fflush(stdout);
		fpga = init_fpga();
		if(!fpga)
			printf("FPGA Init failed !\n");
	}*/

	if(isOption(argc,argv,"headrecal",0)>0)
	{
		printf("Head recalibration\n");

		floppy_ctrl_select_drive(fpga, drive, 1);

		ret = floppy_head_recalibrate(fpga, drive);

		if(ret < 0)
			printf("Head calibration failed !\n");

		floppy_ctrl_select_drive(fpga, drive, 0);
	}

	if(isOption(argc,argv,"headstep",(char*)&temp)>0)
	{
		track = atoi(temp);
		printf("Head step : %d\n",track);

		if( track > fpga->drive_max_steps[drive] )
		{
			printf("Warning : Drive Max step : %d !\n",fpga->drive_max_steps[drive]);
			track = fpga->drive_max_steps[drive];
		}

		floppy_ctrl_select_drive(fpga, drive, 1);

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
		floppy_ctrl_move_head(fpga, dir, track, drive);

		floppy_ctrl_select_drive(fpga, drive, 0);

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

	if(isOption(argc,argv,"set",(char*)&temp)>0)
	{
		setio(fpga, (char*)temp, 1);
	}

	if(isOption(argc,argv,"clear",(char*)&temp)>0)
	{
		setio(fpga, (char*)temp, 0);
	}

	if(isOption(argc,argv,"led1src",(char*)&temp)>0)
	{
		set_led_src(fpga, 0, atoi(temp));
	}

	if(isOption(argc,argv,"led2src",(char*)&temp)>0)
	{
		set_led_src(fpga, 1, atoi(temp));
	}

	if(isOption(argc,argv,"get",(char*)&temp)>0)
	{
		ret = getio(fpga, (char*)temp);
		if(ret >= 0)
			printf("io %s state : %d\n", temp, ret);
		else
			printf("ERROR : can't get the io %s state ! \n", temp);
	}

	if(isOption(argc,argv,"ioslist",0)>0)
	{
		print_ios_list();
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

	if(isOption(argc,argv,"autodetect",0)>0)
	{
		printf("Drives auto-detection...\n");

		setio(fpga, (char*)"DRIVES_PORT_PIN10", 0);
		setio(fpga, (char*)"DRIVES_PORT_PIN12", 0);
		setio(fpga, (char*)"DRIVES_PORT_PIN14", 0);
		setio(fpga, (char*)"DRIVES_PORT_PIN6", 0);

		setio(fpga, (char*)"DRIVES_PORT_PIN16", 0);

		sleep(1);

		printf("Testing PIN10/DS0/MOTA... : ");
		fflush(stdout);
		setio(fpga, (char*)"DRIVES_PORT_PIN10", 1);
		usleep(1000);
		ret = floppy_head_recalibrate(fpga, -1);
		if(ret >= 0)
			printf("Drive on PIN10/DS0/MOTA Found !!!\n");
		else
			printf("No drive\n");

		setio(fpga, (char*)"DRIVES_PORT_PIN10", 0);

		sleep(1);

		printf("Testing PIN12/DS1/DRVSB... : ");
		fflush(stdout);
		setio(fpga, (char*)"DRIVES_PORT_PIN12", 1);
		usleep(1000);
		ret = floppy_head_recalibrate(fpga, -1);
		if(ret >= 0)
			printf("Drive on PIN12/DS1/DRVSB found !!!\n");
		else
			printf("No drive\n");

		setio(fpga, (char*)"DRIVES_PORT_PIN12", 0);

		sleep(1);

		printf("Testing PIN14/DS2/DRVSA... : ");
		fflush(stdout);
		setio(fpga, (char*)"DRIVES_PORT_PIN14", 1);
		usleep(1000);
		ret = floppy_head_recalibrate(fpga, -1);
		if(ret >= 0)
			printf("Drive on PIN14/DS2/DRVSA found !!!\n");
		else
			printf("No drive\n");

		setio(fpga, (char*)"DRIVES_PORT_PIN14", 0);

		sleep(1);

		printf("Testing PIN6/DS3... : ");
		fflush(stdout);
		setio(fpga, (char*)"DRIVES_PORT_PIN6", 1);
		usleep(1000);
		ret = floppy_head_recalibrate(fpga, -1);
		if(ret >= 0)
			printf("Drive on PIN6/DS3 found !!!\n");
		else
			printf("No drive\n");

		setio(fpga, (char*)"DRIVES_PORT_PIN6", 0);

		sleep(1);

		printf("Testing PIN16/MOTON/MOTEB... : ");
		fflush(stdout);
		setio(fpga, (char*)"DRIVES_PORT_PIN16", 1);
		usleep(1000);
		ret = floppy_head_recalibrate(fpga, -1);
		if(ret >= 0)
			printf("Drive on PIN16/MOTON/MOTEB found !!! (Shugart drive on twisted ribbon ?)\n");
		else
			printf("No drive\n");

		setio(fpga, (char*)"DRIVES_PORT_PIN16", 0);

		setio(fpga, (char*)"DRIVES_PORT_PIN10", 0);
		setio(fpga, (char*)"DRIVES_PORT_PIN12", 0);
		setio(fpga, (char*)"DRIVES_PORT_PIN14", 0);
		setio(fpga, (char*)"DRIVES_PORT_PIN6", 0);

		setio(fpga, (char*)"DRIVES_PORT_PIN16", 0);

	}

	if(isOption(argc,argv,"testmaxtrack",0)>0)
	{
		printf("Test Drive %d max track...\n",drive);

		floppy_ctrl_select_drive(fpga, drive, 1);

		i=0;
		while(testmaxtrack[i]>=0)
		{
			printf("Max track %d ... : ",testmaxtrack[i]);
			fflush(stdout);

			ret = floppy_head_maxtrack(fpga, testmaxtrack[i],drive);

			if( ret >= 0)
			{
				if(ret>0)
				{
					printf("Track seeking error (%d track(s))\n",ret);
					printf("Safe max track value found for this drive : %d\n",testmaxtrack[i] - ret);
					break;
				}
				else
				{
					printf("Ok !\n");
				}
			}
			else
			{
				printf("Unexpected error while seeking...\n");
				break;
			}

			i++;
		}

		floppy_ctrl_select_drive(fpga, drive, 0);
	}

	if(isOption(argc,argv,"readdsk",0)>0)
	{
		printf("Start disk reading...\nTrack(s): %d <-> %d, Side(s): %d <-> %d, Time: %dms, %s\n",dump_start_track,dump_max_track,dump_start_side,dump_max_side,dump_time_per_track,high_res_mode?"50Mhz":"25Mhz");

		floppy_ctrl_motor(fpga, drive, 1);

		for(i=0;i<1000;i++)
			usleep(1000);

		floppy_ctrl_select_drive(fpga, drive, 1);

		usleep(1000);

		ret = floppy_head_recalibrate(fpga, drive);
		if(ret < 0)
		{
			printf("Head position calibration failed ! (%d)\n",ret);

			floppy_ctrl_select_drive(fpga, drive, 0);
			floppy_ctrl_motor(fpga, drive, 0);
			hxcfe_deinit( libhxcfe );
			exit(-1);
		}

		if(dump_start_track)
			floppy_ctrl_move_head(fpga, 1, dump_start_track, drive);

		if( dump_max_track > fpga->drive_max_steps[drive] )
		{
			printf("Warning : Drive Max step : %d !\n",fpga->drive_max_steps[drive]);
			dump_max_track = fpga->drive_max_steps[drive];
		}

		// Head load...
		if(fpga->drive_headload_bit_mask[drive])
		{
			usleep(25*1000);

			floppy_ctrl_headload(fpga, drive, 1);

			for(i=0;i<250;i++)
				usleep(1000);
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
					tmpptr = NULL ; //get_next_available_stream_chunk(fpga,&buffersize);
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
				floppy_ctrl_move_head(fpga, 1, 1, drive);
		}

		if(fpga->drive_headload_bit_mask[drive])
		{
			floppy_ctrl_headload(fpga, drive, 0);

			for(i=0;i<250;i++)
				usleep(1000);
		}

		floppy_ctrl_select_drive(fpga, drive, 0);
		floppy_ctrl_motor(fpga, drive, 0);

		printf("Done...\n");
	}

	if(isOption(argc,argv,"regs",0)>0)
	{
		print_fpga_regs(fpga);
	}

	if(isOption(argc,argv,"ejectdisk",0)>0)
	{
		printf("Eject disk...\n");

		floppy_ctrl_x68000_eject(fpga, drive);
	}

	if( (isOption(argc,argv,"help",0)<=0) &&
		(isOption(argc,argv,"license",0)<=0) &&
		(isOption(argc,argv,"modulelist",0)<=0) &&
		(isOption(argc,argv,"interfacelist",0)<=0) &&
		(isOption(argc,argv,"headrecal",0)<=0) &&
		(isOption(argc,argv,"headstep",0)<=0) &&
		(isOption(argc,argv,"drive",0)<=0) &&
		(isOption(argc,argv,"load",0)<=0) &&
		(isOption(argc,argv,"save",0)<=0) &&
		(isOption(argc,argv,"infos",0)<=0 ) &&
		(isOption(argc,argv,"motsrc",0)<=0 ) &&
		(isOption(argc,argv,"selsrc",0)<=0 ) &&
		(isOption(argc,argv,"pin02mode",0)<=0 ) &&
		(isOption(argc,argv,"pin34mode",0)<=0 ) &&
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
		(isOption(argc,argv,"set",0)<=0 ) &&
		(isOption(argc,argv,"clear",0)<=0 ) &&
		(isOption(argc,argv,"get",0)<=0 ) &&
		(isOption(argc,argv,"ioslist",0)<=0 ) &&
		(isOption(argc,argv,"ejectdisk",0)<=0 ) &&
		(isOption(argc,argv,"initscript",0)<=0 ) &&
		(isOption(argc,argv,"autodetect",0)<=0 ) &&
		(isOption(argc,argv,"testmaxtrack",0)<=0 ) &&
		(isOption(argc,argv,"sound",0)<=0 ) &&
		(isOption(argc,argv,"led1src",0)<=0 ) &&
		(isOption(argc,argv,"led2src",0)<=0 ) &&
		(isOption(argc,argv,"reset",0)<=0 )
		)
	{
		printhelp(argv);
	}

	return 0;
}
