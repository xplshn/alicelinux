#!/bin/sh

rm -f *.html docs/*.html

for i in *.md; do
	{
		title=${i%.md}
		case ${i%.md} in index) title=home; esac
		sed "s/@TITLE@/$title/g" header
		smu $i
		cat footer
	} > ${i%.md}.html
done

echo "Here lie the docs" > docs/docs.md
for i in docs/*.md; do
	i=${i#*/}
	case $i in docs.md) continue; esac
	echo "- [${i%.md}](./${i%.md}.html)" >> docs/docs.md
done

for i in docs/*.md; do
	i=${i#*/}
	{
		sed "s/@TITLE@/docs/g" header
		smu docs/$i
		cat footer
	} > docs/${i%.md}.html
done
rm -f docs/docs.md

exit 0
