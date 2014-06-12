#!/bin/sh
##################################################################################
# Custom build tool for Realm Objective C binding.
#
# (C) Copyright 2011-2014 by realm.io.
##################################################################################
PATH=/usr/local/bin:/usr/bin:/bin

######################################
# Variables
######################################
REALM_CORE_VERSION=latest
COMMAND="$1"
XCMODE="$2"
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool

usage() {
cat <<EOF
Usage: sh $0 command [xcmode]

command:
  download-core: downloads core library (binary version)
  clean:         clean up/remove all generated files
  build:         builds iOS and OS X frameworks with debug configuration
  test:          tests iOS and OS X frameworks with release configuration
  test-debug:    tests iOS and OS X frameworks with release configuration
  docs:          builds docs in docs/output
  examples:      builds all examples in examples/
  verify:        cleans core/ and docs/output/, then runs docs, test-all and examples

xcmode (optional): xcodebuild (default), xcpretty or xctool
EOF
}

######################################
# Xcode Helpers
######################################

xc() {
        if [[ "$XCMODE" == "xcodebuild" ]]; then
                xcodebuild $1 || exit 1
        elif [[ "$XCMODE" == "xcpretty" ]]; then
                xcodebuild $1 | xcpretty || exit 1
        elif [[ "$XCMODE" == "xctool" ]]; then
                xctool $1 || exit 1
        fi
}

xcrealm() {
        xc "-project Realm.xcodeproj $1"
}


case "$COMMAND" in

######################################
# Clean
######################################
    "clean")
        xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator clean" || exit 1
        xcrealm "-scheme iOS -configuration Release -sdk iphonesimulator clean" || exit 1
        xcrealm "-scheme OSX -configuration Debug clean" || exit 1
        xcrealm "-scheme OSX -configuration Release clean" || exit 1
	exit 0
	;;

######################################
# Download Core Library
######################################
    "download-core")
        if ! [ -d core ]; then
            curl -s "http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip" -o "/tmp/core-${REALM_CORE_VERSION}.zip" || exit 1
            unzip "/tmp/core-${REALM_CORE_VERSION}.zip" || exit 1
            rm -f "/tmp/core-${REALM_CORE_VERSION}.zip" || exit 1
	else
	    echo "The core library has already been downloaded."
	    echo "Consider removing the folder 'core' and rerun."
        fi
	exit 0
	;;

######################################
# Building
######################################
    "build")
	sh build.sh ios "$XCMODE" || exit 1
	sh build.sh osx "$XCMODE" || exit 1
	exit 0
	;;

    "ios")
        xcrealm "-scheme iOS"
	exit 0
	;;

    "osx")
        xcrealm "-scheme OSX"
	exit 0
	;;

    "docs")
	sh scripts/build-docs.sh || exit 1
	exit 0;
	;;

######################################
# Testing
######################################
    "test")
	# FIXME: how to run on a device?
	#xcrealm "-scheme iOS -configuration Release -sdk iphoneos build test"
        xcrealm "-scheme OSX -configuration Release build test"
	exit 0
	;;

    "test-debug")
	xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator build test"
        xcrealm "-scheme OSX -configuration Debug build test"
	exit 0
	;;

    "test-all")
	sh build.sh test || exit 1
	sh build.sh test-debug || exit 1
	;;

    "test-ios")
        xcrealm "-scheme iOS -sdk iphonesimulator test"
	exit 0
	;;

    "test-osx")
        xcrealm "-scheme OSX test"
	exit 0
	;;

    "test-cover")
	echo "Not yet implemented"
	exit 0
	;;

    "verify")
        sh build.sh docs || exit 1
        sh build.sh test-all "$XCMODE" || exit 1
        sh build.sh examples "$XCMODE" || exit 1
	exit 0
	;;

######################################
# Docs
######################################
    "docs")
        sh scripts/build-docs.sh || exit 1
	;;

######################################
# Examples
######################################
    "examples")
        cd examples
        xc "-project RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample clean build"
        xc "-project RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample clean build"
	xc "-project RealmPerformanceExample/RealmPerformanceExample.xcodeproj -scheme RealmPerformanceExample clean build"
	exit 0
	;;

    *)
	usage
	exit 0
	;;
esac
