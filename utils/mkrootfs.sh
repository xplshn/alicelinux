#!/bin/sh -e

[ "$(id -u)" = 0 ] || {
	echo "making rootfs required root access"
	false
}

HERE=$(pwd)
OUTNAME=alicelinux-rootfs-$(date +%Y%m%d)
TARBALL=$HERE/$OUTNAME.tar.xz
PKGLIST=$TARBALL.pkglist
SHASUM=$TARBALL.sha256sum
ROOTFS=/tmp/alicerootfs
basepkg="baselayout autils b3sum bison busybox bzip2
	ca-certificates curl file git initscripts
	libressl linux-headers llvm m4 make musl
	patch spm xz zlib-ng zstd"

rm -rf $ROOTFS
mkdir -p $ROOTFS/var/lib/spm/db
APKG_ROOT=$ROOTFS apkg -i $basepkg
apkg-chroot $ROOTFS revdep -v

rm -f $TARBALL

echo "compressing rootfs..."
(cd $ROOTFS; tar -cJpf $TARBALL *)

for i in $ROOTFS/var/lib/spm/db/*; do
	n=${i##*/}
	v=$(head -n1 $i); v=${v%-*}
	echo "$n $v" >> $PKGLIST
done

sha256sum ${TARBALL##*/} > $SHASUM

rm -rf $ROOTFS

echo "alice rootfs created."
