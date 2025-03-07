#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

echo "Alice booting..."

mountpoint -q /proc    || mount -t proc proc /proc -o nosuid,noexec,nodev
mountpoint -q /sys     || mount -t sysfs sys /sys -o nosuid,noexec,nodev
mountpoint -q /run     || mount -t tmpfs run /run -o mode=0755,nosuid,nodev
mountpoint -q /dev     || mount -t devtmpfs dev /dev -o mode=0755,nosuid
mkdir -p /run/lock /dev/pts /dev/shm /run/runit
mountpoint -q /dev/pts || mount /dev/pts >/dev/null 2>&1 || mount -t devpts devpts /dev/pts -o mode=0620,gid=5,nosuid,noexec
mountpoint -q /dev/shm || mount /dev/shm >/dev/null 2>&1 || mount -t tmpfs shm /dev/shm -o mode=1777,nosuid,nodev

if [ "$(command -v udevd)" ]; then
	udevd --daemon
	udevadm trigger --action=add    --type=subsystems
	udevadm trigger --action=add    --type=devices
	udevadm settle
else
	# In the case the user may preffer mdevd as opposed to busybox mdev
	if [ ! -d "/var/service/mdevd" ]; then
		echo "/sbin/mdev" > /proc/sys/kernel/hotplug
		mdev -s
	fi
	find /sys -name 'modalias' -type f -exec cat '{}' + | sort -u | xargs modprobe -b -a 2>/dev/null
	ln -s /proc/self/fd /dev/fd
	ln -s fd/0          /dev/stdin
	ln -s fd/1          /dev/stdout
	ln -s fd/2          /dev/stderr
fi

swapon -a
ip link set lo up
mount -o remount,ro /

for arg in $(cat /proc/cmdline); do
    case $arg in
         fastboot) FASTBOOT=1;;
        forcefsck) FORCEFSCK="-f";;
    esac
done

if [ ! "$FASTBOOT" ]; then
	fsck $FORCEFSCK -ATat noopts=_netdev
	if [ "$?" -gt 1 ]; then
		echo "*******************************************"
		echo "**        Filesystem check failed        **"
		echo "** You been dropped to maintenance shell **"
		echo "*******************************************"
		sulogin -p
	fi
fi

mount -o remount,rw /
mount -a

if [ ! -f /etc/hostname ]; then
	echo alice > /etc/hostname
fi
hostname -F /etc/hostname

find /var/run -name "*.pid" -delete
find /tmp -xdev -mindepth 1 ! -name lost+found -delete

if [ -f "/etc/sysctl.conf" ]; then
	sysctl -q -p
fi

hwclock -s -u

if [ -f "/var/lib/random-seed" ]; then
	cat /var/lib/random-seed >/dev/urandom
	rm -f /var/lib/random-seed
fi

if [ -d /sys/firmware/efi/efivars ]; then
	mount -t efivarfs none /sys/firmware/efi/efivars
fi

dmesg >/var/log/dmesg.log

if [ -x /etc/rc.boot.local ]; then
        /etc/rc.boot.local
fi

IFS=. read -r boottime _ < /proc/uptime
echo "booted in ${boottime}s..."
