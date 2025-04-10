#!/bin/sh

for i in $(awk '{print $1}' outdate.list); do
	[ -d $i ] || continue
	nv=$(grep ^"$i " outdate.list | awk '{print $2}')
	ov=$(grep ^"$i " outdate.list | awk '{print $3}')
	read -p "Update $i $ov to $nv " aaa
	case $aaa in
		n|N|no|NO|No|nO) continue;;
		*) ./pkgup.sh $i $nv;;
	esac
done
