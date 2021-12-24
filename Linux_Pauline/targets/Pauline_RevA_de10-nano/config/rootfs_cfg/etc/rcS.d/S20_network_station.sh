#!/bin/sh

echo "---> Starting Network (station mode)..."

ifconfig lo 127.0.0.1 up

#ifconfig eth0 192.168.0.104 up

udhcpc &

#modprobe g_ether dev_addr=12:34:56:78:9a:bc host_addr=12:34:56:78:9a:bd
#ifconfig usb0 192.168.168.1 netmask 255.255.255.0
#dhcpd

