#!/bin/bash
#
# Cross compiler and Linux generation scripts
# (c)2014-2021 Jean-François DEL NERO
#
# DE10-Nano target setup
#

TMP_ALTERA_BASEDIR=${ALTERA_BASEDIR:-"UNDEF"}
TMP_ALTERA_BASEDIR="${TMP_ALTERA_BASEDIR##*/}"
if [ "$TMP_ALTERA_BASEDIR" == "UNDEF" ]
then
(
    echo ALTERA_BASEDIR is not specified !
    exit 1
) || exit 1
fi

export KERNEL_ARCH=arm
export TGT_MACH=armv7a-hardfloat-linux-gnueabi
export SSL_ARCH=linux-armv4
export GCC_ADD_CONF=""

export KERNEL_IMAGE_TYPE="zImage"

export DEBUG_SUPPORT="1"
export NETWORK_SUPPORT="1"
export WIRELESS_SUPPORT="1"
export TARGET_BUILD_SUPPORT="1"
export LIBGFX_SUPPORT="1"

export NETWORK_STATION_MODE="1"
#export NETWORK_ROUTER_MODE="1"

source ${BASE_DIR}/targets/common/config/config.sh || exit 1

# Altera tools installation path

# Quartus II Folder (../intelFPGA_lite/XX.X/)
export ALTERA_TOOLS_ROOT=${ALTERA_BASEDIR}

export ALTERA_DE10_GHRD_BASEDIR=${BASE_DIR}/../FPGA_Pauline/Rev_A/

# GHRD (Golden Hardware Reference Design) DE10-nano project folder (DE10_NANO_SoC_GHRD folder)
export FPGA_GHRD_FOLDER=${ALTERA_DE10_GHRD_BASEDIR}

# Pauline project base folder
export PAULINE_BASE=${BASE_DIR}/../

# Kernel

KERNEL_DTBS="YES"
SRC_PACKAGE_KERNEL="https://github.com/altera-opensource/linux-socfpga/archive/refs/tags/rel_socfpga-6.1.20-lts_23.09.01_pr.tar.gz"

SRC_PACKAGE_PERL=
SRC_PACKAGE_PERLCROSS=

#uboot
export UBOOT_DEFCONF=socfpga_de10_nano_defconfig

SRC_PACKAGE_UBOOT="https://github.com/altera-opensource/u-boot-socfpga/archive/refs/tags/rel_socfpga_v2023.01_23.09.01_pr.tar.gz"

SRC_PACKAGE_FTRACE="http://ftp.debian.org/debian/pool/main/t/trace-cmd/trace-cmd_2.9.1.orig.tar.gz"
#SRC_PACKAGE_VALGRIND=

# misc
SRC_PACKAGE_FSWEBCAM="@COMMON@""https://www.sanslogic.co.uk/fswebcam/files/fswebcam-20140113.tar.gz"
