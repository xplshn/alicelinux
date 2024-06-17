#!/bin/sh

while [ "$1" ]; do
	#set -- ${1%/}
	unset curver port
	[ -f $1/abuild ] && port=${1%/}
	[ "$port" ] || { shift; continue; }
	pname=${1##*/}
	curver=$(grep ^version= $port/abuild | awk -F = '{print $2}')
	[ "$curver" ] || { shift; continue; }
	case $pname in
		python-*) pname=python:${pname#python-};;
		clang) pname=llvm;;
		dejavu-fonts-ttf) pame=fonts:dejavu;;
		lcms2) pname=lcms;;
	esac
	#echo $pname
	v=$(curl -SsZA a https://repology.org/badge/latest-versions/$pname.svg | grep middle | sed 's/.*middle">//;s/<.*//;s/,//' | tr ' ' '\n' | tail -n1)
	#if [ "$curver" = "$v" ]; then
		#echo "$1: $curver (OK)"
	#elif [ "$v" = "-" ]; then
		#echo "$1: $curver (404)"
	#else
		#echo "$1: $curver > $v"
	#fi
	if [ "$curver" != "$v" ]; then
		echo "$port $v ($curver)"
	fi
	#echo $1: ${v:-404}
	shift
done
