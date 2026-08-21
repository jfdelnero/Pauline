#!/bin/sh

if [ ! -d "/home/pauline/patch_etc" ] ; then
	mkdir "/home/pauline/patch_etc"
fi

if [ -d "/home/pauline/patch_etc" ] ; then
	cp -a /home/pauline/patch_etc/* /etc/
	chmod +x /etc/rcS.d/*.sh
	chmod +x /etc/init.d/*
fi

