#!/bin/sh

# Usage: sh build.sh [command] [xcmode]
# 
#  command (required):
#   download_core: downloads tightdb core
#   ios: builds iOS framework with debug configuration
#   osx: builds OSX framework with debug configuration
#   test-ios: builds and tests iOS framework with debug configuration
#   test-osx: builds and tests OSX framework with debug configuration
#   docs: builds docs in docs/output
#   examples: builds all examples in examples/
#   verify: cleans core/ and docs/output/, then runs docs, test-all and examples
# 
#  xcmode (optional): xcodebuild (default), xcpretty or xctool

######################################
# Variables
######################################

PATH=/usr/local/bin:/usr/bin:$PATH
REALM_CORE_VERSION=latest
COMMAND=$1
XCMODE=$2
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool

######################################
# Xcode Helpers
######################################

xc(){
	if [[ "$XCMODE" == "xcodebuild" ]]; then
		xcodebuild $1
	elif [[ "$XCMODE" == "xcpretty" ]]; then
		xcodebuild $1 | xcpretty
	elif [[ "$XCMODE" == "xctool" ]]; then
		xctool $1
	fi
}

xcrealm(){
	xc "-project Realm.xcodeproj $1"
}

######################################
# Download Core
######################################

if [[ "$COMMAND" == "download_core" ]]; then
	if ! [ -d core ]; then
	    curl -s http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip -o /tmp/core-${REALM_CORE_VERSION}.zip
	    unzip /tmp/core-${REALM_CORE_VERSION}.zip
	    rm -f /tmp/core-${REALM_CORE_VERSION}.zip
	fi
fi

######################################
# Building
######################################

if [[ "$COMMAND" == "ios" ]]; then
	xcrealm "-scheme iOS"
fi

if [[ "$COMMAND" == "osx" ]]; then
	xcrealm "-scheme OSX"
fi

######################################
# Testing
######################################

if [[ "$COMMAND" == "test-ios" ]]; then
	xcrealm "-scheme iOS -sdk iphonesimulator test"
fi

if [[ "$COMMAND" == "test-osx" ]]; then
	xcrealm "-scheme OSX test"
fi

if [[ "$COMMAND" == "test-all" ]]; then
	xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator clean test"
	xcrealm "-scheme iOS -configuration Release -sdk iphonesimulator clean test"
	xcrealm "-scheme OSX -configuration Debug clean test"
	xcrealm "-scheme OSX -configuration Release clean test"
fi

if [[ "$COMMAND" == "verify" ]]; then
	sh build.sh docs
	sh build.sh test-all $2
	sh build.sh examples $2
fi

######################################
# Docs
######################################

if [[ "$COMMAND" == "docs" ]]; then
	sh scripts/build-docs.sh
fi

######################################
# Examples
######################################

if [[ "$COMMAND" == "examples" ]]; then
	cd examples
	xc "-project RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample clean build"
	xc "-project RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample clean build"
	xc "-project RealmPerformanceExample/RealmPerformanceExample.xcodeproj -scheme RealmPerformanceExample clean build"
fi
