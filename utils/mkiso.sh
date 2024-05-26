#!/bin/sh -e

msg() { echo "-> $@"; }
cleanup() { rm -rf $WORKDIR; }

prepare_rootfs() {
	[ -d $ROOTFS ] && return
	basepkg="baselayout autils binutils bison busybox
		bzip2 ca-certificates curl file flex gcc
		git gmp initscripts linux-headers m4 make
		mpc mpfr musl openssl patch spm xz zlib"
	requiredpkg="linux grub syslinux"
	extrapkg="pfetch sway swaybg swayidle swaylock wmenu mpv
		foot firefox fff ranger dejavu-fonts-ttf wpa_supplicant dhcpcd 
		linux-firmware imv lm-sensors opendoas zstd rsync squashfs-tools"
	mkdir -p $ROOTFS/var/lib/spm/db
	APKG_NOPROMPT=1 APKG_ROOT=$ROOTFS apkg -I $basepkg $requiredpkg $extrapkg
}

squashfs_rootfs() {
	[ -f $ISODIR/boot/rootfs.sfs ] && return
	mkdir -p $ISODIR/boot

	msg "squashing rootfs..."
	mksquashfs \
		$ROOTFS \
		$ISODIR/boot/rootfs.sfs \
		-b 1048576 \
		-comp xz \
		-wildcards \
		-e tmp/* -e root/* -e sys/* -e dev/* -e proc/* -e run/*
}

add_kmod() {
	[ -f $INITRAMFSDIR/$KERNEL_MODULES_DIR/$1 ] && continue
	mkdir -p $INITRAMFSDIR/$KERNEL_MODULES_DIR/${1%/*}
	cp $ROOTFS/$KERNEL_MODULES_DIR/$1 $INITRAMFSDIR/$KERNEL_MODULES_DIR/${1%/*}
	for d in $(grep $1: $ROOTFS/$KERNEL_MODULES_DIR/modules.dep | tr ' ' '\n' | tail -n+2); do
		add_kmod $d
	done
}

make_initramfs() {
	[ -f $ISODIR/boot/initrd ] && return
	mkdir -p $INITRAMFSDIR/bin
	cp $MKISOD/init $INITRAMFSDIR
	chmod +x $INITRAMFSDIR/init
	cp /bin/busybox $INITRAMFSDIR/bin

	KERNEL_VER=$(file $ROOTFS/boot/vmlinuz-linux | awk '{print $9}')
	KERNEL_MODULES_DIR=lib/modules/$KERNEL_VER
	
	msg "copying kernel modules..."
	( cd $ROOTFS/$KERNEL_MODULES_DIR
	for rk in $required_kmods; do
		[ -d kernel/$rk ] || continue
		for f in $(find kernel/$rk -type f); do
			add_kmod $f
		done
	done
	)

	for i in order builtin builtin.modinfo; do
		cp $ROOTFS/$KERNEL_MODULES_DIR/modules.$i $INITRAMFSDIR/lib/modules/$KERNEL_VER/
	done
	depmod -b $INITRAMFSDIR $KERNEL_VER

	msg "generating live initrd..."
	( cd $INITRAMFSDIR ; find . | cpio -o -H newc | gzip -9 ) > $ISODIR/boot/initrd
}

prepare_grub() {
	[ -f $ISODIR/boot/efiboot.img ] && return
	msg "preparing grub boot files..."
	mkdir -p $ISODIR/boot/grub/x86_64-efi $ISODIR/boot/grub/fonts
	echo "set prefix=/boot/grub" > $ISODIR/boot/grub-early.cfg
	cp -a $ROOTFS/usr/lib/grub/x86_64-efi/*.mod $ISODIR/boot/grub/x86_64-efi
	cp -a $ROOTFS/usr/lib/grub/x86_64-efi/*.lst $ISODIR/boot/grub/x86_64-efi
	cp $ROOTFS/usr/share/grub/unicode.pf2 $ISODIR/boot/grub/fonts/unicode.pf2

	# UEFI
	rm -f $ISODIR/boot/efiboot.img
	mkdir -p $ISODIR/efi/boot
	grub-mkimage -c $ISODIR/boot/grub-early.cfg -o $ISODIR/efi/boot/bootx64.efi -O x86_64-efi -p "" iso9660 normal search search_fs_file
	modprobe loop
	dd if=/dev/zero of=$ISODIR/boot/efiboot.img count=4096
	mkdosfs -n LIVE-UEFI $ISODIR/boot/efiboot.img
	mkdir -p $ISODIR/boot/efiboot
	mount -o loop $ISODIR/boot/efiboot.img $ISODIR/boot/efiboot
	mkdir -p $ISODIR/boot/efiboot/EFI/boot
	cp $ISODIR/efi/boot/bootx64.efi $ISODIR/boot/efiboot/EFI/boot
	umount $ISODIR/boot/efiboot
	rm -fr $ISODIR/boot/efiboot
}

prepare_syslinux() {
	[ -f $ISODIR/isolinux/isolinux.bin ] && return
	msg "preparing syslinux boot files..."
	mkdir -p $ISODIR/isolinux
	cp $ROOTFS/usr/share/syslinux/ldlinux.c32 $ISODIR/isolinux
	cp $ROOTFS/usr/share/syslinux/isolinux.bin $ISODIR/isolinux
}

make_iso() {
	cp $ROOTFS/boot/vmlinuz-linux $ISODIR/boot/vmlinuz
	[ -f $MKISOD/live_script.sh ] && cp $MKISOD/live_script.sh $ISODIR/boot
	touch $ISODIR/boot/livemedia
	
	if [ -d $MKISOD/isoinclude ]; then
		echo "include rootfs files..."
		(
			cd MKISOD/isoinclude
			chown -R 0:0 *
			tar -czf $ISODIR/boot/rootfs.gz *
		)
	fi
	
	cat << EOF > $ISODIR/isolinux/isolinux.cfg
#UI /isolinux/menu.c32
DEFAULT silent
TIMEOUT 0

LABEL silent
LINUX /boot/vmlinuz
APPEND initrd=/boot/initrd
EOF
	
	cat << EOF > $ISODIR/boot/grub/grub.cfg
set default=0
set timeout=3
set timeout_style=hidden

menuentry 'Alice Linux' {
    linux /boot/vmlinuz
    initrd /boot/initrd
}
EOF

	msg "generating iso..."
	rm -f $OUTPUT
	xorriso -as mkisofs \
	-isohybrid-mbr $ROOTFS/usr/share/syslinux/isohdpfx.bin \
	-c isolinux/boot.cat \
	-b isolinux/isolinux.bin \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-eltorito-alt-boot \
	-e boot/efiboot.img \
	-no-emul-boot \
	-isohybrid-gpt-basdat \
	-volid ALICE \
	-o $OUTPUT $ISODIR
	
	sha256sum $OUTPUT > $ISOSUM
}

WORKDIR=$PWD/iso
ROOTFS=$WORKDIR/rootfs
ISODIR=$WORKDIR/liveiso
INITRAMFSDIR=$WORKDIR/initramfs
MKISOD=$PWD/mkiso.d
OUTPUT=$PWD/alicelinux-$(date +%Y%m%d).iso
ISOSUM=$OUTPUT.sha256sum

required_kmods="crypto
        fs lib
        drivers/block
        drivers/md
        drivers/ata
        drivers/firewire
        drivers/input/keyboard
        drivers/input/mouse
        drivers/scsi
        drivers/message
        drivers/pcmcia
        drivers/virtio
        drivers/usb/host
        drivers/usb/storage
        drivers/hid
        drivers/cdrom"

cleanup
prepare_rootfs
squashfs_rootfs
make_initramfs
prepare_grub
prepare_syslinux
make_iso
cleanup

msg "making iso done"

exit 0
