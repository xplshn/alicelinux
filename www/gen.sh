#!/bin/sh

if [ ! "$(basename "$PWD")" = "www" ] || [ ! -f "$PWD/config.toml" ]; then
    if [ -d "$PWD/www" ]; then
        echo "You must enter ./www"
        exit 1
    else
        echo "Where the fuck are we? You must enter https://github.com/xplshn/alicelinux/www, run me within of the ./www directory!"
        exit 1
    fi
fi

# Cleanup older files
for FILE in ./content/posts/*.md; do
    rm -f "./content/posts/$(basename "$FILE")"
done
for FILE in ../files/*; do
    rm -f "./static/assets/$(basename "$FILE")"
done

# Loop over markdown files in ./docs
for FILE in ../docs/*.md; do
	# Extract the filename
	FILENAME="$(basename "$FILE")"

	# Prepare the metadata header
	DATE="$(date +"%Y-%m-%dT%H:%M:%S%:z")"
	TITLE="$(basename "$FILE" .md)"
	AUTHOR="$(git log --follow --format="%an" -- "$FILE" | tail -n 1)"

	# Create the target markdown file with metadata
	{
		echo "+++"
		echo "date = '$DATE'"
		echo "draft = false"
		echo "title = '$TITLE'"
		echo "author = '$AUTHOR'"
		echo "+++"
		cat "$FILE"
	} >"./content/posts/$FILENAME"
done

for FILE in ../files/*; do
    cp "$FILE" "./static/assets/$(basename "$FILE")"
done

# Build with Hugo
hugo
