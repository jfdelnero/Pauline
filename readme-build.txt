------------------------------------------------------------------------------
-----------H----H--X----X-----CCCCC-----22222----0000-----0000-----11---------
----------H----H----X-X-----C--------------2---0----0---0----0---1-1----------
---------HHHHHH-----X------C----------22222---0----0---0----0-----1-----------
--------H----H----X--X----C----------2-------0----0---0----0-----1------------
-------H----H---X-----X---CCCCC-----22222----0000-----0000----11111-----------
------------------------------------------------------------------------------
------ Contact: hxc2001 at hxc2001.com ----------- https://hxc2001.com -------
------ (c) 2019-2023 Jean-François DEL NERO ----------------------------------
-============================================================================-
- Pauline
- Floppy disks archiving, creation and drives simulator system.
-
- HxC2001 (https://hxc2001.com)
- La Ludothèque Française (https://www.laludotheque.fr/)
- NPO Game Preservation Society (https://www.gamepres.org)
- Association MO5.COM (https://mo5.com)
-============================================================================-

                --- Pauline SD Card image build instructions ---

    Required and Recommended Prerequisites :

    - A Linux machine or a virtual machine with at least 20 GB of free disk
      space available and having an internet connection.
        ( Linux Mint https://www.linuxmint.com/ or any similar distribution )

    - build-essential installed
        ( sudo apt-get update ; sudo apt-get install build-essential )

    - Altera/Intel Quartus Prime Lite Edition installed (Lite edition v19.1 minimum)
        ( https://fpgasoftware.intel.com/?edition=lite )

    - Altera/Intel SoC FPGA Embedded Development Suite (Standard edition v19.1 minimum)
        ( https://fpgasoftware.intel.com/soceds/19.1/?edition=standard&download_manager=direct&platform=linux )

    - ALTERA_BASEDIR path environment variable pointing to the Quartus installation
        ( example : ALTERA_BASEDIR=/home/user_home/intelFPGA_lite/19.1)

    - ALTERA_DE10_GHRD_BASEDIR path environment variable pointing to the Pauline FPGA project
        ( example : ALTERA_DE10_GHRD_BASEDIR=/your_path_to/Pauline/FPGA_Pauline/Rev_A/)

    - The whole Pauline repository is present on the machine.
        ( git clone --recursive  https://github.com/jfdelnero/Pauline.git )
        ( To install the git tool : sudo apt-get install git )

-============================================================================-
-                       FPGA core bitstream generation                       -
-============================================================================-

In this part we are building the FPGA SoC bitstream.

    1.1) Start Quartus

    1.2) Open the Pauline project
        - Menu "File"
        - "Open project"
        - Select FPGA_Pauline_Rev_A.qpf in the Pauline/FPGA_Pauline/Rev_A/ folder.

    1.3) Start Plateform Designer
        - Menu "Tools"
        - "Plateform Designer"
        - Select soc_system.qsys in the Pauline/FPGA_Pauline/Rev_A/ folder.

    1.4) Generate the SoC VHDL
        - Press "Generate HDL" button in Plateform Designer main window.
        - Press "Generate" button in the Plateform Designer "Generation" window.
        - Once done press "Close" and "Finish" buttons to close Plateform Designer.

    1.5) Start the FPGA synthesis
        - Menu "Processing"
        - "Start Compilation"
        (Synthesis time on a Core i5-4300M : ~ 15 Minutes)
        - Done ! You have now the Pauline FPGA bitstream :) You can close Quartus.

-============================================================================-
-                        Pauline Linux BSP generation                        -
-============================================================================-

In this part all the stuffs related to the Linux core running on the board will be built :
Cross Compiler, System librairies, Linux kernel, Compiler, tools...

    2.1) Open a terminal console window

    2.2) Move to the Pauline Linux folder
        - Type this command  : cd "/your_path_to/Pauline/Linux_Pauline"
        (Change the example with your path)

    2.3) Enable the Pauline build environment
        - Type this command  : ./set_env Pauline_RevA_de10-nano

    2.4) Start the system-building process
        - Type this command : sysbuild.sh

        This will download all the needed sources and build the whole system.
        Build time on a Core i5-4300M + SSD machine : ~1h10m.

        Once done you should have the message "System build done".

    2.5) Prepare the SDCard image
        - Type this command : init_sd.sh

        This will launch some last things (bootloader and specific Pauline tools)
        and build the SDCard image. the root passsword is asked during the process.

        Once done the SD card image pauline_sdcard.img can be found
        in the /your_path_to/Pauline/Linux_Pauline/output_objects folder.

        You can write it to the SD Card:

        sudo dd if=pauline_sdcard.img of=/dev/your_sd_card_reader status=progress bs=4M ; sync

        (Or use any other software under Windows (https://rufus.ie/,...))


    (c) HxC2001 / Jean-François DEL NERO
