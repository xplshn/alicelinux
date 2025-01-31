#!/bin/sh

fetchversion() {
	curl -SsZA tmp https://repology.org/badge/latest-versions/$1.svg \
	| sed 's/, /,/g' \
	| tr ' ' '\n' \
	| grep -Eo 'central">.*<' \
	| sed 's/<.*//;s/.*>//' \
	| tr ',' '\n' \
	| tail -n1
}

while [ "$1" ]; do
	unset curver port
	[ -f $1/abuild ] && port=${1%/}
	[ "$port" ] || { shift; continue; }
	name=${1#*/}; name=${name%/}
	curver=$(grep ^version= $port/abuild | awk -F = '{print $2}')
	[ "$curver" ] || { shift; continue; }
	case $name in
		python-*) name=python:${name#python-};;
		perl-*) name=perl:${name#perl-};;
	esac
	# clear newver function
	unset -f newver
	if [ -s $port/outdated ]; then
		. $port/outdated
	fi
	printf " checking $1\033[0K\r"
	newver=$(fetchversion $name)
	if [ "$(command -v newver)" ]; then
		newver
	fi
	touch outdate.error outdate.list
	sed "\|^$port .*|d" -i outdate.error
	sed "\|^$port .*|d" -i outdate.list
	if [ ! "$newver" ] || [ "$newver" = '-' ]; then
		echo "$port $curver" >> outdate.error
	elif [ "$curver" != "$newver" ]; then
		echo "$port $newver ($curver)"
		echo "$port $newver ($curver)" >> outdate.list
	fi
	shift
done
printf "\033[0K"
