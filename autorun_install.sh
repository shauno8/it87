#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only

# invoke insmod with all arguments we got
# and use a pathname, as insmod doesn't look in . by default

TARGET_PATH=/lib/modules/$(uname -r)/kernel/drivers/hwmon

if [ "$TARGET_PATH" = "" ]; then
echo
echo "Check old driver and unload it."
fi

check=`lsmod | grep it87`
if [ "$check" != "" ]; then
        echo "rmmod it87"
        /sbin/rmmod it87
fi

echo "Build the module and install"
echo "-------------------------------" >> log.txt
date 1>>log.txt
make $@ all 1>>log.txt || exit 1
module=`ls *.ko`
module=${module%.ko}
echo
echo "module is $module"
echo

if [ "$module" = "" ]; then
	echo "No driver exists!!!"
	exit 1
elif [ "$module" = "it87" ]; then
	if test -e $TARGET_PATH/it87.ko ; then
		echo "Backup it87.ko"
		if test -e $TARGET_PATH/it87.bak ; then
			i=0
			while test -e $TARGET_PATH/it87.bak$i
			do
				i=$(($i+1))
			done
			echo "rename it87.ko to it87.bak$i"
			mv $TARGET_PATH/it87.ko $TARGET_PATH/it87.bak$i
		else
			echo "rename it87.ko to it87.bak"
			mv $TARGET_PATH/it87.ko $TARGET_PATH/it87.bak
			cp it87.ko $TARGET_PATH/
		fi
	fi
fi

echo "DEPMOD $(uname -r)"
depmod `uname -r`
echo "load module IT8613E $module"
modprobe $module

is_update_initramfs=n
distrib_list="ubuntu debian"

if [ -r /etc/debian_version ]; then
	is_update_initramfs=y
elif [ -r /etc/lsb-release ]; then
	for distrib in $distrib_list
	do
		/bin/grep -i "$distrib" /etc/lsb-release 2>&1 /dev/null && \
			is_update_initramfs=y && break
	done
fi

if [ "$is_update_initramfs" = "y" ]; then
	if which update-initramfs >/dev/null ; then
		echo "Updating initramfs. Please wait."
		update-initramfs -u -k $(uname -r)
	else
		echo "update-initramfs: command not found"
		exit 1
	fi
fi

echo options it87 ignore_resource_conflict=1 force_id=0x8613 > /etc/modprobe.d/it87.conf

echo it87 >> /etc/modules

echo "Completed."
exit 0
