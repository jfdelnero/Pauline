#!/bin/sh
#
# References:
#   http://answers.microsoft.com/en-us/windows/forum/windows_10-networking/
#       windows-10-vs-remote-ndis-ethernet-usbgadget-not/cb30520a-753c-4219-b908-ad3d45590447
#

modprobe libcomposite
mount -t configfs none /sys/kernel/config

set -e

g=/sys/kernel/config/usb_gadget/device

# Device name can be retrieved from /sys/class/udc/
device="ffb40000.usb"

usb_ver="0x0200" # USB 2.0
dev_ver="0x0100"
dev_class="0xef"
dev_subclass="0x02"
dev_protocol="0x01"
vid="0x1d50"
pid="0x60c8"
mfg="HxC2001"
prod="Pauline"
serial="0123456789"
attr="0x80" # Bus powered
pwr="500" # mA
cfg1="RNDIS"
cfg2="CDC"
mac="01:23:45:67:89:ab"
# Change the first number for each MAC address - the second digit of 2 indicates
# that these are "locally assigned (b2=1), unicast (b1=0)" addresses. This is
# so that they don't conflict with any existing vendors. Care should be taken
# not to change these two bits.
dev_mac="02$(echo ${mac} | cut -b 3-)"
host_mac="12$(echo ${mac} | cut -b 3-)"
ms_vendor_code="0xcd" # Microsoft
ms_qw_sign="MSFT100" # also Microsoft (if you couldn't tell)
ms_compat_id="RNDIS" # matches Windows RNDIS Drivers
ms_subcompat_id="5162001" # matches Windows RNDIS 6.0 Driver

# Create a new gadget

mkdir -p ${g}
echo "${dev_ver}" > ${g}/bcdDevice
echo "${usb_ver}" > ${g}/bcdUSB
echo "${dev_class}" > ${g}/bDeviceClass
echo "${dev_subclass}" > ${g}/bDeviceSubClass
echo "${dev_protocol}" > ${g}/bDeviceProtocol
echo "${vid}" > ${g}/idVendor
echo "${pid}" > ${g}/idProduct
mkdir ${g}/strings/0x409
echo "${mfg}" > ${g}/strings/0x409/manufacturer
echo "${prod}" > ${g}/strings/0x409/product
echo "${serial}" > ${g}/strings/0x409/serialnumber

# Create 2 configurations. The first will be RNDIS, which is required by
# Windows to be first. The second will be CDC. Linux and Mac are smart
# enough to ignore RNDIS and load the CDC configuration.

# config 1 is for RNDIS

mkdir ${g}/configs/c.1
echo "${attr}" > ${g}/configs/c.1/bmAttributes
echo "${pwr}" > ${g}/configs/c.1/MaxPower
mkdir ${g}/configs/c.1/strings/0x409
echo "${cfg1}" > ${g}/configs/c.1/strings/0x409/configuration

# On Windows 7 and later, the RNDIS 5.1 driver would be used by default,
# but it does not work very well. The RNDIS 6.0 driver works better. In
# order to get this driver to load automatically, we have to use a
# Microsoft-specific extension of USB.

echo "1" > ${g}/os_desc/use
echo "${ms_vendor_code}" > ${g}/os_desc/b_vendor_code
echo "${ms_qw_sign}" > ${g}/os_desc/qw_sign

# Create the RNDIS function, including the Microsoft-specific bits

mkdir ${g}/functions/rndis.usb0
echo "${dev_mac}" > ${g}/functions/rndis.usb0/dev_addr
echo "${host_mac}" > ${g}/functions/rndis.usb0/host_addr
echo "${ms_compat_id}" > ${g}/functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo "${ms_subcompat_id}" > ${g}/functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

# config 2 is for CDC
# Note : Windows doesn't support dual configuration composite devices !
# ECM Disabled for the moment...
#mkdir ${g}/configs/c.2
#echo "${attr}" > ${g}/configs/c.2/bmAttributes
#echo "${pwr}" > ${g}/configs/c.2/MaxPower
#mkdir ${g}/configs/c.2/strings/0x409
#echo "${cfg2}" > ${g}/configs/c.2/strings/0x409/configuration

# Create the CDC ECM function

mkdir ${g}/functions/ecm.usb0
echo "${dev_mac}" > ${g}/functions/ecm.usb0/dev_addr
echo "${host_mac}" > ${g}/functions/ecm.usb0/host_addr

# Create the CDC ACM functions (common for both configurations)

#mkdir ${g}/functions/acm.GS0
#mkdir ${g}/functions/acm.GS1

# MTP function

mkdir ${g}/functions/ffs.mtp

# Link everything up and bind the USB device

ln -s ${g}/configs/c.1          ${g}/os_desc

ln -s ${g}/functions/rndis.usb0 ${g}/configs/c.1
ln -s ${g}/functions/ecm.usb0   ${g}/configs/c.1
#ln -s ${g}/functions/acm.GS0    ${g}/configs/c.1
#ln -s ${g}/functions/acm.GS1    ${g}/configs/c.1
ln -s ${g}/functions/ffs.mtp    ${g}/configs/c.1

#ln -s ${g}/functions/ecm.usb0   ${g}/configs/c.2
#ln -s ${g}/functions/acm.GS0    ${g}/configs/c.2
#ln -s ${g}/functions/acm.GS1    ${g}/configs/c.2
#ln -s ${g}/functions/ffs.mtp    ${g}/configs/c.2

mkdir /dev/ffs-mtp
mount -t functionfs mtp /dev/ffs-mtp

# Start the umtprd service
umtprd &

sleep 1

echo "${device}" > ${g}/UDC

echo 1 > /proc/sys/net/ipv4/ip_forward

ifconfig usb0 192.168.168.1
ifconfig usb1 192.168.169.1

dhcpd

