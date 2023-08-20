#!/bin/bash
#
# Cross compiler and Linux generation scripts
# (c)2014-2019 Jean-François DEL NERO
#
# DE10-Nano uboot patches
#

source ${TARGET_CONFIG}/config.sh || exit 1

cp ${TARGET_CONFIG}/patches/socfpga_cyclone5.h include/configs/
cp include/linux/compiler-gcc6.h include/linux/compiler-gcc10.h
cp include/linux/compiler-gcc6.h include/linux/compiler-gcc12.h

cp include/fdt.h lib/libfdt/
cp include/libfdt.h lib/libfdt/
cp include/libfdt_env.h lib/libfdt/

cp include/sha1.h lib/

