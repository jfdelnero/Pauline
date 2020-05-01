#!/bin/sh

export PATH=$PATH:/usr/local/samba/sbin/:/usr/local/samba/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/samba/lib

mount -t tmpfs -o size=64m  tmpfs /mnt
cp -aR /usr/local/samba/private/* /mnt
mount --move /mnt /usr/local/samba/private

mount -t tmpfs -o size=64m  tmpfs /mnt
cp -aR /usr/local/samba/var/* /mnt
mount --move /mnt /usr/local/samba/var

smbd

