#!/bin/sh

[ "$1" ] || exit 1

#if [ ! -f REPO ]; then
	#echo "you not inside repo's directory"
	#exit 1
#fi

url=$1

name=$(echo $1 | rev | cut -d / -f1 | cut -d - -f2- | rev | tr '[:upper:]' '[:lower:]')
version=$(echo $1 | rev | cut -d / -f1 | cut -d - -f1 | rev | sed 's/\.tar.*//' | sed 's/^v//')

case $url in
	*.pythonhosted.*) name="python-$name";;
	*/pypi.org/*) name="python-$name";;
	*.metacpan.*|*.cpan.*) name="perl-$name";;
	*/refs/tags/*)                 # github tags tarball
			gh=${1%/archive*}      # project url
			name=${gh##*/}         # project name
			verstar=${1##*/}       # version with tar suffix
			vers=${verstar%.tar.*} # version without tar suffix
			version=${vers#v}      # final version without 'v' prefix
			url=$gh/archive/$vers/$name-$verstar;;
	*) name=$name;;
esac

if [ "$2" ]; then
	name=$2
fi

[ -d $name ] && {
	grep ^version= $name/info
	echo "port for $name exist"
	exit 1
}
url=$(echo $url | sed "s,$name,\${name},g;s,$version,\${version},g" )

case $version in
	*.*.*) v=${version%.*}
		url=$(echo $url | sed "s,$v,\${version%\.\*},g" )
esac

mkdir -p $name

echo "name=$name
version=$version
release=1
source=\"$url\"" > $name/info

cat $name/info
