#!/bin/sh

echo "---> Starting wireless (AP mode)..."

#modprobe rfkill
#modprobe cfg80211

iw dev wlan0 set power_save off

ifconfig wlan0 192.168.100.1 up

#wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
hostapd -d /etc/hostapd.conf &

