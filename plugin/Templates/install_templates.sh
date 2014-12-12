#!/bin/sh
PATH=/bin:/usr/bin:/usr/libexec

# Class Templates

XCODE_DIR=$(xcode-select -p)
IOS_CLASS_TEMPLATES_DIR="$XCODE_DIR/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/Cocoa Touch/Objective-C class.xctemplate"
OSX_CLASS_TEMPLATES_DIR="$XCODE_DIR/Library/Xcode/Templates/File Templates/Cocoa/Objective-C class.xctemplate"

LOCAL_CLASS_TEMPLATES_DIR="class_templates/*/"

for dir in ${LOCAL_CLASS_TEMPLATES_DIR%*/}
do
  for classTemplatesDir in "$IOS_CLASS_TEMPLATES_DIR" "$OSX_CLASS_TEMPLATES_DIR"
  do
    mkdir -p "$classTemplatesDir"
    cp -R "$dir" "$classTemplatesDir"

    class=$(basename $dir)
    class=${class/Swift/}
    class=${class/Objective-C/}

    echo "Installing '$class' class template in '$classTemplatesDir'"

    INFO_PLIST_PATH="$classTemplatesDir/TemplateInfo.plist"
    PlistBuddy -c "Print :Options:1:Values:" "$INFO_PLIST_PATH" | grep $class >/dev/null
    rc=$?
    if [[ $rc != 0 ]] ; then
      PlistBuddy -c "Add :Options:1:Values: string '$class'" "$INFO_PLIST_PATH"
    fi
  done
done

echo "Installed templates"
