#!/bin/sh

# makeVM diskGB ramGB nameFQDN

if [ $# -ne 3 ] ; then
	echo "Usage: ganeti-coreos.sh <disk> <ram> <name>"
	exit 3
fi

if [ "`whoami`" != "root" ] ; then
	echo "Please run this as root"
	exit 2
fi
	 

gnt-os list | grep noop > /dev/null 

if [ $? -ne 0 ] ; then
	echo "Missing noop OS definition, correct by running the following"
	echo "deb http://repo.noc.grnet.gr/ wheezy main"
	echo "wget -O - http://repo.noc.grnet.gr/grnet.gpg.key | apt-key add -"
	echo "apt-get update"
	echo "apt-get install ganeti-os-noop"
	exit 1
fi


DISK=$1
RAM=$2
NAME=$3

if [ ! -f /iso/configdrive-$NAME.iso ] ; then
	echo "configdrive-$NAME.iso is missing, please create one for this instance"
	echo "https://coreos.com/os/docs/latest/cloud-config.html"
fi
	

gnt-instance add \
     -t plain \
     -o noop \
     -s ${DISK}G \
     -n $NODE \
     -B maxmem=${RAM}G,minmem=$((${RAM}/2))G \
     -H kvm:cdrom_image_path=/iso/configdrive-$NAME.iso \
     --no-install \
     --no-start \
     --no-ip-check \
     --no-name-check \
     ${NAME}


if [ ! -f coreos_production_qemu_image.img ] ; then
	echo "Downloading current stable image from core-os.net"
#	wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2
	cp src/coreos_production_qemu_image.img.bz2 .
	if [ -f coreos_production_qemu_image.img.bz2.sig ] ; then
		rm -f coreos_production_qemu_image.img.bz2.sig
	fi
	wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2.sig > /dev/null 2>&1
	gpg --list-keys | grep "CoreOS Buildbot" > /dev/null 2>&1
	if [ $? -ne 0 ] ; then
		curl https://coreos.com/security/image-signing-key/CoreOS_Image_Signing_Key.asc 2>/dev/null | gpg --import >/dev/null 2>&1	
	fi
	gpg --verify coreos_production_qemu_image.img.bz2.sig > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
		echo "Signature verified"
		bzip2 -v -d coreos_production_qemu_image.img.bz2
	else
		echo "The signature did not match, aborting!"
	fi
fi
	
echo "Converting Production Image to Disk"
DISKTGT=`gnt-instance activate-disks $NAME | awk -F: '{print $3}'`
qemu-img convert coreos_production_qemu_image.img $DISKTGT

gnt-instance start $NAME
