#!/bin/sh

cwd=$PWD

[ -f $1/abuild ] || {
	echo "port $1 not exist"
	exit 1
}

[ "$(grep ^version= $1/abuild | cut -d = -f2)" = "$2" ] && {
	echo "port $1 is up-to-dated ($2)"
	exit 0
}

cd $1

cp abuild abuild.bak
mv .checksum .checksum.bak
mv .files .files.bak

sed "s/^version=.*/version=$2/" -i abuild
sed "s/^release=.*/release=1/" -i abuild

doas apkg -u || {
	mv -f abuild.bak abuild
	mv -f .checksum.bak .checksum
	mv -f .files.bak .files
	exit 1
}

[ -f $cwd/outdate.list ] && {
	sed "\|\/${1##*/} .*|d" -i $cwd/outdate.list
}

doas rm -fv .*.bak *.bak

exit 0
