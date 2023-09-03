#!/bin/sh

# Init the various file systems.
# The main idea here is to use tmpfs where the write support is needed.

echo "---> Init file systems..."

mount -o remount,ro /dev/root /

mount -t proc none  /proc
mount -t sysfs none /sys

mount -t tmpfs -o size=256m tmpfs /root
chmod go-rwx /root

mount -t tmpfs -o size=64m  tmpfs /tmp

mount -t tmpfs -o size=64m  tmpfs /var
chmod og-w /var

# Populate /var
mkdir /var/log
mkdir /var/db
touch /var/db/dhcpd.leases
mkdir /var/ftp
mkdir /var/empty
mkdir /var/run
mkdir /var/run/wpa_supplicant
mkdir /var/run/hostapd
mkdir /var/log/lastlog
mkdir /var/tmp
mkdir /var/local
mkdir /var/lib
mkdir /var/cache
mkdir /var/lock
mkdir /var/spool
mkdir /var/spool/cron
mkdir /var/spool/cron/crontabs
mkdir /var/state
mkdir /var/mail
mkdir /var/cache/samba/
mkdir /var/lock/samba
mkdir /var/log/samba
mkdir /var/lib/samba/
mkdir /var/lib/samba/private/

chgrp samba /var/log/samba
chown smbuser /var/log/samba
chgrp samba /var/cache/samba
chown smbuser /var/cache/samba
chgrp samba /var/lock/samba
chown smbuser /var/lock/samba
chgrp samba /var/lib/samba
chown smbuser /var/lib/samba
chgrp samba /var/lib/samba/private
chown smbuser /var/lib/samba/private

#######################################
# /dev
#######################################

# Done by devtmpfs...
#mount -t tmpfs -o size=64m  tmpfs /mnt
#cp -aR /dev/* /mnt
#mount --move /mnt /dev

# video / drm device
if [ ! -f "/dev/dri/card0" ]
then
	mkdir       /dev/dri
	mknod       /dev/dri/card0 c 226 0
	mknod       /dev/dri/controlD64 c 226 64
	mknod       /dev/dri/renderD128 c 226 128
fi
chgrp video /dev/dri/card0
chgrp video /dev/dri/controlD64
chgrp video /dev/dri/renderD128
chmod g+wr  /dev/dri/card0
chmod g+wr  /dev/dri/controlD64
chmod g+wr  /dev/dri/renderD128

mkdir /dev/pts
mount devpts /dev/pts -t devpts
chmod go+rw  /dev/null
chmod go+r   /dev/random
chmod go+r   /dev/urandom
chmod ugo+rw /dev/tty

#######################################

#######
# /home
mount -t tmpfs -o size=64m  tmpfs /mnt
cp -aR /home/* /mnt
mount --move /mnt /home
chmod og-w /home

#######
# /run
mount -t tmpfs -o size=64m  tmpfs /mnt
cp -aR /run/* /mnt 2> /dev/null
mount --move /mnt /run
chmod og-w /run

#######
# /etc
mount -t tmpfs -o size=64m  tmpfs /mnt
cp -aR /etc/* /mnt
mount --move /mnt /etc
chmod og-w /etc

mount -t tmpfs -o size=500m none /ramdisk
chown ramdisk /ramdisk
chgrp ramdisk /ramdisk
chmod og-rwx /ramdisk

#######################################
# Test the data partition presence
#######################################
SIZELEN=`sfdisk /dev/mmcblk0p4 -F -s 2>/dev/null | wc -m`
if [ $SIZELEN == 0 ]; then
   /usr/sbin/splash_screen /data/pauline_splash_bitmaps/prep_data_disk.bmp
   echo "Partition 4 not defined... Add it"


   # Add a partition (vfat) - (2097152 sectors -> keep/reserved the first 1GB for the system partitions)
   echo 'start=2097152,type=c' | sfdisk /dev/mmcblk0 -f -N 4

   # And restart the system...
   /usr/sbin/splash_screen /data/pauline_splash_bitmaps/rebooting.bmp
   reboot -f
fi

#
# Data partition mount / initialization
#
mount -o fmask=0000,dmask=0000 /dev/mmcblk0p4 /home/pauline
ret=$?

if [ $ret -ne 0 ]; then

   # TODO !!! Ask the user before doing this !!!

   MNTLEN=`grep mmcblk0p4 /proc/mounts | wc -m`
   if [ $MNTLEN == 0 ]; then
      /usr/sbin/splash_screen /data/pauline_splash_bitmaps/formatting_data_disk.bmp
      echo "Formating the data partition !"
      mkfs.vfat /dev/mmcblk0p4
      sync

      mount -o fmask=0000,dmask=0000 /dev/mmcblk0p4 /home/pauline

      /usr/sbin/splash_screen /data/pauline_splash_bitmaps/starting.bmp
   fi
fi

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

#######################################
# Cache :
# Push to the disk the dirty data after 1 second !
#######################################

echo 100 > /proc/sys/vm/dirty_expire_centisecs
echo 100 > /proc/sys/vm/dirty_writeback_centisecs

mount -t tmpfs -o size=64m  tmpfs /ramdisk
cp -aR /ramdisk/* /mnt
mount --move /mnt /ramdisk

mount -a
