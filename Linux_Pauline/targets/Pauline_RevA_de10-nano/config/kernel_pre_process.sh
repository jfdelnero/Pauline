#!/bin/bash
#
# Cross compiler and Linux generation scripts
# (c)2014-2019 Jean-François DEL NERO
#
# DE10-Nano target kernel compilation
#

source ${TARGET_CONFIG}/config.sh || exit 1

cp ${TARGET_CONFIG}/patches/ssd1307fb.c ./drivers/video/fbdev/ || exit 1

cat ${TARGET_CONFIG}/patches/socfpga_cyclone5_bridges.dts >> ./arch/arm/boot/dts/socfpga_cyclone5_de0_nano_soc.dts
cat ${TARGET_CONFIG}/patches/sh1106_128x64_oled.dts       >> ./arch/arm/boot/dts/socfpga_cyclone5_de0_nano_soc.dts
