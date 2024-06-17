#!/bin/sh

[ -f $1/abuild ] || {
	echo "port $1 not exist"
	exit 1
}

cd $1

cp abuild abuild.bak

sed "s/^version=.*/version=$2/" -i abuild
sed "s/^release=.*/release=1/" -i abuild

doas apkg -u || {
	mv -f abuild.bak abuild
	exit 1
}
doas rm -v *.bak

exit 0
