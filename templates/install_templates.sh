#!/bin/sh

FILE_TEMPLATES_DIR="$HOME/Library/Developer/Xcode/Templates/File Templates/Realm"
mkdir -p "$FILE_TEMPLATES_DIR"

for dir in ./*/
do
    cp -R "${dir%*/}" "$FILE_TEMPLATES_DIR"
done
echo "Installed templates"
