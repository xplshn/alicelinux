#!/bin/sh

[ -f $1/info ] || {
	echo "port $1 not exist"
	exit 1
}

cd $1

cp info info.bak
#[ -f .md5sum ] && mv .md5sum .md5sum.bak
#[ -f .footprint ] && mv .footprint .footprint.bak

sed "s/^version=.*/version=$2/" -i info
sed "s/^release=.*/release=1/" -i info

#fakeroot pkgmk -uf
#fakeroot pkgmk -um
#[ -f .footprint.bak ] && diff -Naur --color=always .footprint.bak .footprint
doas apkg -u || {
	mv -f info.bak info
	exit 1
}
doas rm -v *.bak

exit 0
