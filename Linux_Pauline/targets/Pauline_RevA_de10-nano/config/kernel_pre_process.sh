#!/bin/bash
#
# Cross compiler and Linux generation scripts
# (c)2014-2019 Jean-François DEL NERO
#
# DE10-Nano target kernel compilation
#

source ${TARGET_CONFIG}/config.sh || exit 1

sed -i -e "s/YYLTYPE\ yylloc/extern\ YYLTYPE\ \ yylloc/g" ./scripts/dtc/dtc-lexer.lex.c_shipped
cp ${TARGET_CONFIG}/patches/ssd1307fb.c ./drivers/video/fbdev/ || exit 1
