#!/bin/sh

while [ "$1" ]; do
	unset curver port
	[ -f $1/abuild ] && port=${1%/}
	[ "$port" ] || { shift; continue; }
	pname=${1##*/}
	curver=$(grep ^version= $port/abuild | awk -F = '{print $2}')
	[ "$curver" ] || { shift; continue; }
	case $pname in
		python-*) pname=python:${pname#python-};;
		perl-*) pname=perl:${pname#perl-};;
	esac
		#clang) pname=llvm;;
		#dejavu-fonts-ttf) pame=fonts:dejavu;;
		#lcms2) pname=lcms;;
		#libconfig) pname=libconfig-hyperrealm;;
		#xf86-input-libinput) pname=xdrv:libinput;;
	#esac
	if [ -s $port/outdated ]; then
		pname=$(cat $port/outdated | tail -n1)
	fi
	v=$(curl -SsZA tmp https://repology.org/badge/latest-versions/$pname.svg | grep middle | sed 's/.*middle">//;s/<.*//;s/,//' | tr ' ' '\n' | tail -n1)
	[ "$v" ] || v=404
	if [ "$curver" != "$v" ]; then
		echo "$port $v ($curver)"
	fi
	shift
done
