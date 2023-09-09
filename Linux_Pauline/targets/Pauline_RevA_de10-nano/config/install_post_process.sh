#!/bin/bash
#
# Cross compiler and Linux generation scripts
# (c)2014-2021 Jean-François DEL NERO
#
# DE10-Nano target post install process
#

source ${TARGET_CONFIG}/config.sh || exit 1

# setup the altera env
export _SOCEDS_ROOT=${ALTERA_TOOLS_ROOT}/embedded
export SOCEDS_DEST_ROOT="${_SOCEDS_ROOT}"
source ${_SOCEDS_ROOT}/env.sh || exit 1

mkdir ${TARGET_HOME}/output_objects

#
# Build the cross compiled hxc tool
#

if [ ! -d ${TARGET_HOME}/output_objects/target_hxc_tool ]
then
(
	cd ${PAULINE_BASE}/Softwares_Pauline/HxCFloppyEmulator/build
	make mrproper
	make CC=${TGT_MACH}-gcc HxCFloppyEmulator_cmdline || exit 1

	mkdir ${TARGET_HOME}/output_objects/target_hxc_tool

	${BASE_DIR}/scripts/fix_bin_paths hxcfe ${TARGET_ROOTFS}
	${BASE_DIR}/scripts/fix_bin_paths libusbhxcfe.so ${TARGET_ROOTFS}
	${BASE_DIR}/scripts/fix_bin_paths libhxcfe.so ${TARGET_ROOTFS}

	cp   hxcfe  ${TARGET_HOME}/output_objects/target_hxc_tool/hxcfe || exit 1
	cp   libusbhxcfe.so  ${TARGET_HOME}/output_objects/target_hxc_tool/libusbhxcfe.so || exit 1
	cp   libhxcfe.so  ${TARGET_HOME}/output_objects/target_hxc_tool/libhxcfe.so || exit 1

	cp   libusbhxcfe.so  ${TARGET_HOME}/output_objects/target_hxc_tool/libusbhxcfe.so || exit 1
	cp   libhxcfe.so  ${TARGET_HOME}/output_objects/target_hxc_tool/libhxcfe.so || exit 1

	cp   libusbhxcfe.so  ${TARGET_ROOTFS}/lib/ || exit 1
	cp   libhxcfe.so  ${TARGET_ROOTFS}/lib/ || exit 1
	cp   ${PAULINE_BASE}/Softwares_Pauline/HxCFloppyEmulator/libhxcfe/sources/libhxcfe.h  ${TARGET_ROOTFS}/include/ || exit 1

	cp   libusbhxcfe.so  ${TARGET_ROOTFS_MIRROR}/lib/ || exit 1
	cp   libhxcfe.so  ${TARGET_ROOTFS_MIRROR}/lib/ || exit 1

) || exit 1
fi

#
# Generate Pauline tools
#

cd ${PAULINE_BASE}/Softwares_Pauline/wsServer
make clean
make mrproper
make CC=${TGT_MACH}-gcc all || exit 1

cd ${PAULINE_BASE}/Softwares_Pauline/Pauline_control
make clean
make mrproper
make CC=${TGT_MACH}-gcc  || exit 1

${BASE_DIR}/scripts/fix_bin_paths ${PAULINE_BASE}/Softwares_Pauline/Pauline_control/pauline ${TARGET_ROOTFS}

cp ${PAULINE_BASE}/Softwares_Pauline/Pauline_control/pauline ${TARGET_HOME}/output_objects || exit 1


#
# Generate OLED splash screen
#

cd ${PAULINE_BASE}/Softwares_Pauline/splash_screen
make clean
make CC=${TGT_MACH}-gcc || exit 1
cp   ${PAULINE_BASE}/Softwares_Pauline/splash_screen/splash_screen  ${TARGET_HOME}/output_objects/splash_screen || exit 1

#
# Build the pc hxc tool
#

if [ ! -d ${TARGET_HOME}/output_objects/pc_hxc_tool ]
then
(
	cd ${PAULINE_BASE}/Softwares_Pauline/HxCFloppyEmulator/build
	make mrproper
	make TARGET=mingw32 || exit 1

	mkdir ${TARGET_HOME}/output_objects/pc_hxc_tool
	cp   HxCFloppyEmulator.exe  ${TARGET_HOME}/output_objects/pc_hxc_tool/HxCFloppyEmulator.exe || exit 1
	cp   hxcfe.exe  ${TARGET_HOME}/output_objects/pc_hxc_tool/hxcfe.exe || exit 1
	cp   libusbhxcfe.dll  ${TARGET_HOME}/output_objects/pc_hxc_tool/libusbhxcfe.dll || exit 1
	cp   libhxcfe.dll  ${TARGET_HOME}/output_objects/pc_hxc_tool/libhxcfe.dll || exit 1
) || exit 1
fi

#
# Generate the dts and build the dtb
#

#echo --- Generate the dts and build the dtb ---

#cd ${FPGA_GHRD_FOLDER} || exit 1
#sopc2dts --input soc_system.sopcinfo --output ${TARGET_HOME}/output_objects/soc_system.dts --type dts --board software/spl_bsp/soc_system_board_info.xml --board #software/spl_bsp/hps_common_board_info.xml --bridge-removal all --clocks  || exit 1
#cat ${TARGET_CONFIG}/patches/sh1106_128x64_oled.dts >> ${TARGET_HOME}/output_objects/soc_system.dts || exit 1
#dtc -I dts -O dtb -o ${TARGET_HOME}/output_objects/soc_system.dtb ${TARGET_HOME}/output_objects/soc_system.dts  || exit 1

#
# Generate bsp files
#
echo --- Generate bsp files ---

cd ${FPGA_GHRD_FOLDER}

rm -rf ${FPGA_GHRD_FOLDER}/software/spl_bsp/generated
rm -rf ${FPGA_GHRD_FOLDER}/software/spl_bsp/u-boot-socfpga
rm -rf ${FPGA_GHRD_FOLDER}/software/spl_bsp/settings.bsp
rm -rf ${FPGA_GHRD_FOLDER}/software/spl_bsp/*.ds
rm -rf ${FPGA_GHRD_FOLDER}/software/spl_bsp/*.bin

${ALTERA_TOOLS_ROOT}/embedded/host_tools/altera/preloadergen/bsp-create-settings --type spl --bsp-dir "${FPGA_GHRD_FOLDER}/software/spl_bsp" --preloader-settings-dir "hps_isw_handoff/soc_system_hps_0" --settings "${FPGA_GHRD_FOLDER}/software/spl_bsp/settings.bsp"

cd ${FPGA_GHRD_FOLDER}/software/spl_bsp

#
# build the preloader
#

if [ ! -f ${TARGET_HOME}/output_objects/preloader-mkpimage.bin ]
then
(
	echo --- build the preloader ---

	cd ${FPGA_GHRD_FOLDER}/software/spl_bsp
	cp Makefile_old Makefile

	rm -rf uboot-socfpga

	tar -xvJf old-uboot-socfpga-2013-01-01.tar.xz   || exit 1

	cp  old-uboot-socfpga-2013-01-01.tar.xz uboot-socfpga.tar.gz

	cp -rfv ${FPGA_GHRD_FOLDER}/software/spl_bsp/generated/* ${FPGA_GHRD_FOLDER}/software/spl_bsp/uboot-socfpga/board/altera/socfpga || exit 1

	cp ${FPGA_GHRD_FOLDER}/software/spl_bsp/uboot-socfpga/include/linux/compiler-gcc6.h ${FPGA_GHRD_FOLDER}/software/spl_bsp/uboot-socfpga/include/linux/compiler-gcc10.h
	cp ${FPGA_GHRD_FOLDER}/software/spl_bsp/uboot-socfpga/include/linux/compiler-gcc6.h ${FPGA_GHRD_FOLDER}/software/spl_bsp/uboot-socfpga/include/linux/compiler-gcc12.h

	make clean CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-        || exit 1
	echo stamp > uboot-socfpga/.untar
	make  CROSS_COMPILE=armv7a-hardfloat-linux-gnueabi-  TGZ=${FPGA_GHRD_FOLDER}/software/spl_bsp/uboot-socfpga.tar.gz || exit 1

	rm uboot-socfpga.tar.gz

	cp ${FPGA_GHRD_FOLDER}/software/spl_bsp/preloader-mkpimage.bin ${TARGET_HOME}/output_objects/  || exit 1

) || exit 1
fi

#############################################################################"

##git clone https://github.com/altera-opensource/u-boot-socfpga
##cd u-boot-socfpga
##git checkout -b test -t origin/socfpga_v2019.04

#git clone https://github.com/altera-opensource/u-boot-socfpga  || exit 1
#cd u-boot-socfpga || exit 1
#git checkout -b test -t origin/socfpga_v2019.04  || exit 1

#tar -xvzf ${FPGA_GHRD_FOLDER}/software/spl_bsp/u-boot-socfpga-2019-04.tar.gz

#cd ${FPGA_GHRD_FOLDER}/software/spl_bsp/u-boot-socfpga
#${FPGA_GHRD_FOLDER}/software/spl_bsp/u-boot-socfpga/arch/arm/mach-socfpga/qts-filter.sh cyclone5 ${FPGA_GHRD_FOLDER} ${FPGA_GHRD_FOLDER}/software/spl_bsp/ ${FPGA_GHRD_FOLDER}/software/spl_bsp/u-boot-socfpga/board/terasic/de10-nano/qts/

#cd ${FPGA_GHRD_FOLDER}/software/spl_bsp/u-boot-socfpga
#make socfpga_de10_nano_defconfig || exit 1
#make || exit 1

#############################################################################"

# Make the u-boot script image

mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script Name" -d ${TARGET_CONFIG}/boot.script ${TARGET_HOME}/output_objects/u-boot.scr

# convert the fpga sof file to rbf.

${ALTERA_TOOLS_ROOT}/quartus/bin/quartus_cpf -c -o bitstream_compression=on ${FPGA_GHRD_FOLDER}/output_files/FPGA_Pauline_Rev_A.sof ${TARGET_HOME}/output_objects/soc_system.rbf || exit 1
${ALTERA_TOOLS_ROOT}/quartus/bin/quartus_cpf -c -o bitstream_compression=off ${FPGA_GHRD_FOLDER}/output_files/FPGA_Pauline_Rev_A.sof ${TARGET_HOME}/output_objects/soc_system_unpacked.rbf || exit 1

#exit 0

############################################################################################
# Create the update ramdisk image

#export TARGET_UPDATE_RD_ROOTFS=${TARGET_HOME}/update_ramdisk

#rm -Rf ${TARGET_UPDATE_RD_ROOTFS}

#mkdir  ${TARGET_UPDATE_RD_ROOTFS}
#cd     ${TARGET_UPDATE_RD_ROOTFS}

#cp -av ${TARGET_ROOTFS_MIRROR}/* .

#rm -rf boot home/www include libexec media opt share usr/armv7a-hardfloat-linux-gnueabi usr/lib usr/bin usr/local usr/share www etc/fonts etc/libnl etc/lighttpd etc/netword etc/share etc/ssh etc/ssl etc/umtprd bin/smbclient bin/smbd bin/mu-mh lib/audit lib/cmake lib/engines lib/gconv lib/libffi-3.2 lib/libnl lib/mailutils lib/*.a lib/*.o lib/modules  usr/include usr/libexec var/db

#find . | cpio --dereference -H newc -o | gzip -9 > ${TARGET_HOME}/output_objects/update_rd.img

############################################################################################
# Create SD Card image

dd if=/dev/zero of=${TARGET_HOME}/output_objects/pauline_sdcard.img iflag=fullblock bs=1M count=1024 && sync
sudo losetup loop6 --sector-size 512  ${TARGET_HOME}/output_objects/pauline_sdcard.img || exit 1
sudo sfdisk -f /dev/loop6 < ${TARGET_CONFIG}/sfdisk_pauline.txt || exit 1
sudo losetup -d /dev/loop6

############################################################################################

#sudo losetup --show --sector-size 512 -f -P ${TARGET_HOME}/output_objects/pauline_sdcard.img
#sudo dd if=${TARGET_HOME}/output_objects/preloader-mkpimage.bin of=/dev/loop6p3 bs=64k seek=0  && sync
#sudo dd if=${TARGET_HOME}/output_objects/u-boot.img of=/dev/loop6p3 bs=64k seek=4              && sync
#sudo losetup -d /dev/loop6

#1040384
dd if=${TARGET_HOME}/output_objects/preloader-mkpimage.bin of=${TARGET_HOME}/output_objects/pauline_sdcard.img bs=512 seek=2088960  conv=notrunc || exit 1 && sync
dd if=${TARGET_HOME}/output_objects/u-boot.img of=${TARGET_HOME}/output_objects/pauline_sdcard.img bs=512 seek=2089472 conv=notrunc || exit 1 && sync

fdisk -l ${TARGET_HOME}/output_objects/pauline_sdcard.img || exit 1

############################################################################################

sleep 1
sudo losetup loop6 --show --sector-size 512 -P ${TARGET_HOME}/output_objects/pauline_sdcard.img || exit 1
sleep 1

sudo mkfs.vfat /dev/loop6p1 || exit 1
sudo mkfs.ext2 /dev/loop6p2 || exit 1
sudo losetup -d /dev/loop6

############################################################################################
echo "Copy boot files to the file image ..."
mkdir ${TARGET_HOME}/output_objects/tmp_mount_point

sleep 1
sudo losetup loop6 --show --sector-size 512 -P ${TARGET_HOME}/output_objects/pauline_sdcard.img
sleep 1

sudo mount /dev/loop6p1 ${TARGET_HOME}/output_objects/tmp_mount_point || exit 1
sudo cp ${TARGET_HOME}/output_objects/u-boot.scr        ${TARGET_HOME}/output_objects/tmp_mount_point || exit 1 && sync
sudo cp ${TARGET_HOME}/output_objects/soc_system.rbf    ${TARGET_HOME}/output_objects/tmp_mount_point || exit 1 && sync
sudo cp ${TARGET_HOME}/output_objects/soc_system.dtb    ${TARGET_HOME}/output_objects/tmp_mount_point || exit 1 && sync
sudo cp ${TARGET_HOME}/output_objects/zImage            ${TARGET_HOME}/output_objects/tmp_mount_point || exit 1 && sync
sudo umount ${TARGET_HOME}/output_objects/tmp_mount_point
sudo losetup -d /dev/loop6

############################################################################################
echo "Copy rootfs to the file image ..."

sleep 1
sudo losetup loop6 --show --sector-size 512 -P ${TARGET_HOME}/output_objects/pauline_sdcard.img
sleep 1
sudo mount /dev/loop6p2 ${TARGET_HOME}/output_objects/tmp_mount_point

sudo cp -av ${TARGET_ROOTFS_MIRROR}/* ${TARGET_HOME}/output_objects/tmp_mount_point/.

sudo cp -av ${TARGET_HOME}/output_objects/pauline  ${TARGET_HOME}/output_objects/tmp_mount_point/usr/sbin || exit 1
sudo cp -av ${TARGET_HOME}/output_objects/splash_screen ${TARGET_HOME}/output_objects/tmp_mount_point/usr/sbin || exit 1

sudo cp -av ${TARGET_HOME}/output_objects/target_hxc_tool/hxcfe ${TARGET_HOME}/output_objects/tmp_mount_point/usr/sbin || exit 1
sudo cp -av ${TARGET_HOME}/output_objects/target_hxc_tool/*.so ${TARGET_HOME}/output_objects/tmp_mount_point/lib || exit 1

#
# Prepare data folder.
#

sudo mkdir  ${TARGET_HOME}/output_objects/tmp_mount_point/data
sudo cp -ar ${PAULINE_BASE}/Softwares_Pauline/splash_screen/pauline_splash_bitmaps ${TARGET_HOME}/output_objects/tmp_mount_point/data/ || exit 1

sudo mkdir  ${TARGET_HOME}/output_objects/tmp_mount_point/data/Documentations
sudo mkdir  ${TARGET_HOME}/output_objects/tmp_mount_point/data/Tools
sudo mkdir  ${TARGET_HOME}/output_objects/tmp_mount_point/data/Settings
sudo cp -ar ${PAULINE_BASE}/Softwares_Pauline/splash_screen/pauline_splash_bitmaps ${TARGET_HOME}/output_objects/tmp_mount_point/data/ || exit 1
sudo cp -ar ${PAULINE_BASE}/Softwares_Pauline/Pauline_control/settings/* ${TARGET_HOME}/output_objects/tmp_mount_point/data/Settings || exit 1
sudo cp -ar ${TARGET_HOME}/output_objects/pc_hxc_tool ${TARGET_HOME}/output_objects/tmp_mount_point/data/Tools/

###

sudo mkdir  ${TARGET_HOME}/output_objects/tmp_mount_point/home/pauline
sudo chown 1000 ${TARGET_HOME}/output_objects/tmp_mount_point/home/pauline
sudo chgrp 1000 ${TARGET_HOME}/output_objects/tmp_mount_point/home/pauline
sudo chmod o+wr ${TARGET_HOME}/output_objects/tmp_mount_point/home/pauline

sudo chown 1001 ${TARGET_HOME}/output_objects/tmp_mount_point/ramdisk
sudo chgrp 1001 ${TARGET_HOME}/output_objects/tmp_mount_point/ramdisk
sudo chmod o+wr ${TARGET_HOME}/output_objects/tmp_mount_point/ramdisk

sudo chown -R root ${TARGET_HOME}/output_objects/tmp_mount_point/*
sudo chgrp -R root ${TARGET_HOME}/output_objects/tmp_mount_point/*

sudo chmod ugo-w   ${TARGET_HOME}/output_objects/tmp_mount_point/home
sudo chmod +x      ${TARGET_HOME}/output_objects/tmp_mount_point/etc/*.sh
sudo chmod +x      ${TARGET_HOME}/output_objects/tmp_mount_point/etc/rcS.d/*.sh
sudo chmod go-w    ${TARGET_HOME}/output_objects/tmp_mount_point/etc/*.sh
sudo chmod go-w    ${TARGET_HOME}/output_objects/tmp_mount_point/etc/rcS.d/*.sh
sudo chmod go-w    ${TARGET_HOME}/output_objects/tmp_mount_point/etc/*
sudo chmod ugo-rwx ${TARGET_HOME}/output_objects/tmp_mount_point/etc/passwd
sudo chmod u+rw    ${TARGET_HOME}/output_objects/tmp_mount_point/etc/passwd
sudo chmod go+r    ${TARGET_HOME}/output_objects/tmp_mount_point/etc/passwd

cd ${TARGET_HOME}/output_objects/tmp_mount_point
${SCRIPTS_HOME}/fix_fs_perm.sh
cd ${PAULINE_BASE}

sudo umount ${TARGET_HOME}/output_objects/tmp_mount_point
sudo losetup -d /dev/loop6

############################################################################################

#sudo dd if=${TARGET_HOME}/output_objects/preloader-mkpimage.bin of=/dev/sdd3 bs=64k seek=0
#sudo dd if=${TARGET_HOME}/output_objects/u-boot.img of=/dev/sdd3 bs=64k seek=4
