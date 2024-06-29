#!/bin/sh
#
# script to generate package database

deps() {
	[ -f $1/depends ] || return
	grep -Ev ^'(#|$)' $1/depends | tr '\n' '_' | sed 's/_$//' | sed 's/_/<br>/g'
}

PKGDBFILE=$(dirname $(dirname $(realpath $0)))/docs/packagedb.md

echo "## List available packages in repositories" > $PKGDBFILE
echo "Use \`Ctrl + F\` to find packages" >> $PKGDBFILE
echo >> $PKGDBFILE
echo "|REPO|NAME|VERSION|DEPENDENCIES|" >> $PKGDBFILE
echo "|:-:|-|:-:|-|" >> $PKGDBFILE

for i in */*/abuild; do
	i=${i%/abuild}
	repo=${i%/*}
	name=${i#*/}
	version=$(grep ^version= $i/abuild | awk -F = '{print $2}')-$(grep ^release= $i/abuild | awk -F = '{print $2}')
	echo "|$repo|$name|$version|$(deps $i)" >> $PKGDBFILE
done
