#!/bin/sh -e

rm -rf public
mkdir -p public

rm -rf smu
git clone --depth=1 https://github.com/karlb/smu
make -C smu

# docs
mkdir -p public/docs
rm -f docs.md
for i in docs/*.md; do
	echo "generating html for $i..."
	i=${i#*/}
	{
		sed "s/@TITLE@/docs/g" header
		./smu/smu docs/$i
		cat footer
	} > public/docs/${i%.md}.html
	echo "- [$(head -n1 docs/$i)](./docs/${i%.md}.html)" >> docs.md
done

# top files
for i in *.md; do
	echo "generating html for $i..."
	{
		title=${i%.md}
		case ${i%.md} in index) title=home; esac
		sed "s/@TITLE@/$title/g" header
		./smu/smu $i
		cat footer
	} > public/${i%.md}.html
done

if [ -d assets ]; then
	cp -ra assets public/
fi

exit 0
