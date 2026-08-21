#!/bin/sh

# Test and copy the pauline folders

if [ ! -d "/home/pauline/Disks_Captures" ] ; then
	mkdir "/home/pauline/Disks_Captures"
fi

if [ ! -d "/home/pauline/Drives_Simulation" ] ; then
	mkdir "/home/pauline/Drives_Simulation"
	cp -ar /data/Drives_Simulation/* /home/pauline/Drives_Simulation
fi

if [ ! -d "/home/pauline/Tools" ] ; then
	mkdir "/home/pauline/Tools"
	cp -ar /data/Tools/* /home/pauline/Tools
fi

if [ /data/Tools/pc_hxc_tool/HxCFloppyEmulator.exe -nt /home/pauline/Tools/pc_hxc_tool/HxCFloppyEmulator.exe ]
then
	cp -ar /data/Tools/* /home/pauline/Tools
fi

if [ ! -d "/home/pauline/Documentations" ] ; then
	mkdir "/home/pauline/Documentations"
	cp -ar /data/Documentations/* /home/pauline/Documentations
fi

if [ ! -d "/home/pauline/Settings" ] ; then
	mkdir "/home/pauline/Settings"
	cp -ar /data/Settings/* /home/pauline/Settings
	cp /data/Settings/drives.script /home/pauline/Settings/drives_script_base.txt
fi

if [ ! -f "/home/pauline/Settings/drives.script" ] ; then
	cp -ar /data/Settings/* /home/pauline/Settings
fi

if [ ! -f "/home/pauline/Settings/drives_script_base.txt" ] ; then
	cp -ar /data/Settings/drives.script /home/pauline/Settings/drives_script_base.txt
fi

if [ /data/Settings/drives.script -nt /home/pauline/Settings/drives_script_base.txt ]
then
	cp -ar /data/Settings/drives.script /home/pauline/Settings/drives_script_base.txt
fi

