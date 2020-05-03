#!/bin/bash
#
# Cross compiler and Linux generation scripts
# (c)2014-2020 Jean-François DEL NERO
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
# Generate Pauline tools
#

cd ${PAULINE_BASE}/Softwares_Pauline/Pauline_control
make clean
make mrproper
make CC=${TGT_MACH}-gcc  || exit 1
cp ${PAULINE_BASE}/Softwares_Pauline/Pauline_control/pauline ${TARGET_HOME}/output_objects || exit 1


#
# Generate OLED splash screen
#

cd ${PAULINE_BASE}/Softwares_Pauline/ssd1306-1.8.2/tools
make clean
make CC=${TGT_MACH}-gcc CXX=${TGT_MACH}-gcc -C ../examples -f Makefile.linux PROJECT=demos/sh1106_pauline_splash || exit 1
cp   ${PAULINE_BASE}/Softwares_Pauline/ssd1306-1.8.2/bld/demos/sh1106_pauline_splash.out  ${TARGET_HOME}/output_objects/oled_splash || exit 1

#
# Generate the dts and build the dtb
#

echo --- Generate the dts and build the dtb ---

cd ${FPGA_GHRD_FOLDER} || exit 1
sopc2dts --input soc_system.sopcinfo --output ${TARGET_HOME}/output_objects/soc_system.dts --type dts --board software/spl_bsp/soc_system_board_info.xml --board software/spl_bsp/hps_common_board_info.xml --bridge-removal all --clocks  || exit 1
cat ${TARGET_CONFIG}/patches/sh1106_128x64_oled.dts >> ${TARGET_HOME}/output_objects/soc_system.dts || exit 1
dtc -I dts -O dtb -o ${TARGET_HOME}/output_objects/soc_system.dtb ${TARGET_HOME}/output_objects/soc_system.dts  || exit 1

#
# Generate bsp files
#
echo --- Generate bsp files ---

cd ${FPGA_GHRD_FOLDER}

rm -rf ${FPGA_GHRD_FOLDER}/software/spl_bsp/generated
rm -rf ${FPGA_GHRD_FOLDER}/software/spl_bsp/u-boot-socfpga

${ALTERA_TOOLS_ROOT}/embedded/host_tools/altera/preloadergen/bsp-create-settings --type spl --bsp-dir "${FPGA_GHRD_FOLDER}/software/spl_bsp" --preloader-settings-dir "hps_isw_handoff/soc_system_hps_0" --settings "${FPGA_GHRD_FOLDER}/software/spl_bsp/settings.bsp"

cd ${FPGA_GHRD_FOLDER}/software/spl_bsp

#
# build the preloader
#

echo --- build the preloader ---

cd ${FPGA_GHRD_FOLDER}/software/spl_bsp || exit 1
cp Makefile_old Makefile

rm -rf uboot-socfpga
tar -xvJf old-uboot-socfpga-2013-01-01.tar.xz

cp -rfv ${FPGA_GHRD_FOLDER}/software/spl_bsp/generated/* ${FPGA_GHRD_FOLDER}/software/spl_bsp/uboot-socfpga/board/altera/socfpga

make clean  || exit 1
make  || exit 1

cp ${FPGA_GHRD_FOLDER}/software/spl_bsp/preloader-mkpimage.bin ${TARGET_HOME}/output_objects/  || exit 1

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

cp ${FPGA_GHRD_FOLDER}/software/spl_bsp/preloader-mkpimage.bin ${TARGET_HOME}/output_objects/  || exit 1

# copy u-boot and the kernel to the output folder.

cp ${TARGET_SOURCES}/u-boot-socfpga-rel_socfpga_v2013.01.01_19.03.02_pr/u-boot.img ${TARGET_HOME}/output_objects/  || exit 1
cp ${TARGET_SOURCES}/linux-kernel/arch/arm/boot/zImage ${TARGET_HOME}/output_objects/  || exit 1

# convert the fpga sof file to rbf.

${ALTERA_TOOLS_ROOT}/quartus/bin/quartus_cpf -c -o bitstream_compression=on ${FPGA_GHRD_FOLDER}/output_files/FPGA_Pauline_Rev_A.sof ${TARGET_HOME}/output_objects/soc_system.rbf || exit 1
${ALTERA_TOOLS_ROOT}/quartus/bin/quartus_cpf -c -o bitstream_compression=off ${FPGA_GHRD_FOLDER}/output_files/FPGA_Pauline_Rev_A.sof ${TARGET_HOME}/output_objects/soc_system_unpacked.rbf || exit 1

############################################################################################
# Create SD Card image

dd if=/dev/zero of=${TARGET_HOME}/output_objects/pauline_sdcard.img iflag=fullblock bs=1M count=512 && sync
sudo losetup loop0 --sector-size 512  ${TARGET_HOME}/output_objects/pauline_sdcard.img || exit 1
sudo sfdisk -f /dev/loop0 < ${TARGET_CONFIG}/sfdisk_pauline.txt || exit 1
sudo losetup -d /dev/loop0

############################################################################################

#sudo losetup --show --sector-size 512 -f -P ${TARGET_HOME}/output_objects/pauline_sdcard.img
#sudo dd if=${TARGET_HOME}/output_objects/preloader-mkpimage.bin of=/dev/loop0p3 bs=64k seek=0  && sync
#sudo dd if=${TARGET_HOME}/output_objects/u-boot.img of=/dev/loop0p3 bs=64k seek=4              && sync
#sudo losetup -d /dev/loop0

#1040384
dd if=${TARGET_HOME}/output_objects/preloader-mkpimage.bin of=${TARGET_HOME}/output_objects/pauline_sdcard.img bs=512 seek=1040384  conv=notrunc && sync
dd if=${TARGET_HOME}/output_objects/u-boot.img of=${TARGET_HOME}/output_objects/pauline_sdcard.img bs=512 seek=1040896 conv=notrunc && sync

fdisk -l ${TARGET_HOME}/output_objects/pauline_sdcard.img

############################################################################################

sudo losetup --show --sector-size 512 -f -P ${TARGET_HOME}/output_objects/pauline_sdcard.img
sudo mkfs.vfat /dev/loop0p1
sudo mkfs.ext2 /dev/loop0p2
sudo losetup -d /dev/loop0

############################################################################################
echo "Copy boot files to the file image ..."
mkdir ${TARGET_HOME}/output_objects/tmp_mount_point

sudo losetup --show --sector-size 512 -f -P ${TARGET_HOME}/output_objects/pauline_sdcard.img
sudo mount /dev/loop0p1 ${TARGET_HOME}/output_objects/tmp_mount_point
sudo cp ${TARGET_HOME}/output_objects/u-boot.scr        ${TARGET_HOME}/output_objects/tmp_mount_point  && sync
sudo cp ${TARGET_HOME}/output_objects/soc_system.rbf    ${TARGET_HOME}/output_objects/tmp_mount_point  && sync
sudo cp ${TARGET_HOME}/output_objects/soc_system.dtb    ${TARGET_HOME}/output_objects/tmp_mount_point  && sync
sudo cp ${TARGET_HOME}/output_objects/soc_system.dts    ${TARGET_HOME}/output_objects/tmp_mount_point  && sync
sudo cp ${TARGET_HOME}/output_objects/zImage            ${TARGET_HOME}/output_objects/tmp_mount_point  && sync
sudo umount ${TARGET_HOME}/output_objects/tmp_mount_point
sudo losetup -d /dev/loop0

############################################################################################
echo "Copy rootfs to the file image ..."

sudo losetup --show --sector-size 512 -f -P ${TARGET_HOME}/output_objects/pauline_sdcard.img
sudo mount /dev/loop0p2 ${TARGET_HOME}/output_objects/tmp_mount_point

sudo cp -av ${TARGET_ROOTFS_MIRROR}/* ${TARGET_HOME}/output_objects/tmp_mount_point/.

sudo cp -av ${TARGET_HOME}/output_objects/pauline  ${TARGET_HOME}/output_objects/tmp_mount_point/usr/sbin || exit 1
sudo cp -av ${TARGET_HOME}/output_objects/oled_splash ${TARGET_HOME}/output_objects/tmp_mount_point/usr/sbin || exit 1

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

sudo umount ${TARGET_HOME}/output_objects/tmp_mount_point
sudo losetup -d /dev/loop0

############################################################################################

#sudo dd if=${TARGET_HOME}/output_objects/preloader-mkpimage.bin of=/dev/sdd3 bs=64k seek=0
#sudo dd if=${TARGET_HOME}/output_objects/u-boot.img of=/dev/sdd3 bs=64k seek=4
