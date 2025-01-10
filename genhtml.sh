#!/bin/sh

# Clean existing HTML files
rm -f ./*.html ./docs/*.html

# Convert root markdown files
for i in *.md; do
    [ -f "$i" ] || continue
    title=${i%.md}
    case ${i%.md} in 
        index) title=home ;;
    esac
    {
        sed "s/@TITLE@/$title/g" header
        pandoc -f markdown -t html "$i"
        cat footer
    } > "${i%.md}.html"
done

# Generate docs/index.md
echo 'Here lie the documentations for Alice Linux.' > docs/index.md

# Add links to other documentation files
for i in docs/*.md; do
    [ -f "$i" ] || continue
    case $i in 
        docs/index.md) continue ;;
    esac
    title=$(head -n1 "$i")
    i=${i#*/}
    echo "- [$title](./${i%.md}.html)" >> docs/index.md
done

# Convert documentation markdown files
for i in docs/*.md; do
    [ -f "$i" ] || continue
    i=${i#*/}
    {
        sed "s/@TITLE@/docs/g" header
        pandoc -f markdown -t html "docs/$i"
        cat footer
    } > "docs/${i%.md}.html"
done

exit 0
