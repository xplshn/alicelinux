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

echo 'Here lie the documentations for Alice Linux.' > docs/index.md
for i in docs/*.md; do
	case $i in docs/index.md) continue; esac
	title=$(head -n1 $i)
	i=${i#*/}
	echo "- [$title](./${i%.md}.html)" >> docs/index.md
done

for i in docs/*.md; do
	i=${i#*/}
	{
		sed "s/@TITLE@/docs/g" header
		smu docs/$i
		cat footer
	} > docs/${i%.md}.html
done

exit 0
