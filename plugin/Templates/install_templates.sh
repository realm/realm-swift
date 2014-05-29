#!/bin/sh
PATH=/bin:/usr/bin

# User File Templates

FILE_TEMPLATES_DIR="$HOME/Library/Developer/Xcode/Templates/File Templates/Realm"
mkdir -p "$FILE_TEMPLATES_DIR"

for dir in "file_templates/*/"
do
    cp -R ${dir%*/} "$FILE_TEMPLATES_DIR"
done

# Class Templates

XCODE_DIR=$(xcode-select -p)
OBJC_CLASS_TEMPLATES_DIR="$XCODE_DIR/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/Cocoa Touch/Objective-C class.xctemplate"
TEMPLATE_INFO_PLIST_PATH="$OBJC_CLASS_TEMPLATES_DIR/TemplateInfo.plist"

for dir in "class_templates/*/"
do
    cp -R ${dir%*/} "$OBJC_CLASS_TEMPLATES_DIR"

    PLIST_BUDDY=/usr/libexec/PlistBuddy
    class=$(basename $dir)

    echo "Installing '$class' class template"

    $PLIST_BUDDY -c "Print :Options:1:Values:" "$TEMPLATE_INFO_PLIST_PATH" | grep $class >/dev/null
    rc=$?
	if [[ $rc != 0 ]] ; then
    	$PLIST_BUDDY -c "Add :Options:1:Values: string '$class'" "$TEMPLATE_INFO_PLIST_PATH"
    fi
done

echo "Installed templates"
