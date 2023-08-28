#!/bin/bash
#
# Cross compiler and Linux generation scripts
# (c)2014-2019 Jean-François DEL NERO
#
# DE10-Nano uboot
#

source ${TARGET_CONFIG}/config.sh || exit 1

cp ./tools/mkimage ${TARGET_CROSS_TOOLS}/bin || exit 1
cp ./u-boot.img ${TARGET_HOME}/output_objects/ || exit 1

