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
# 
#  xcmode (optional): xcodebuild (default), xcpretty or xctool

######################################
# Variables
######################################

PATH=/usr/local/bin:/usr/bin:$PATH
COMMAND=$1
REALM_CORE_VERSION=latest
XCMODE=$2
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool

######################################
# Helpers
######################################

xc(){
	PROJECT=Realm.xcodeproj
	if [[ "$XCMODE" == "xcodebuild" ]]; then
		xcodebuild -project $PROJECT $1
	elif [[ "$XCMODE" == "xcpretty" ]]; then
		xcodebuild -project $PROJECT $1 | xcpretty
	elif [[ "$XCMODE" == "xctool" ]]; then
		xctool -project $PROJECT $1
	fi
}

######################################
# Download core
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
	xc "-scheme iOS"
fi

if [[ "$COMMAND" == "osx" ]]; then
	xc "-scheme OSX"
fi

######################################
# Testing
######################################

if [[ "$COMMAND" == "test-ios" ]]; then
	xc "-scheme iOS -sdk iphonesimulator test"
fi

if [[ "$COMMAND" == "test-osx" ]]; then
	xc "-scheme OSX test"
fi

if [[ "$COMMAND" == "test-all" ]]; then
	xc "-scheme iOS -configuration Debug -sdk iphonesimulator clean test"
	xc "-scheme iOS -configuration Release -sdk iphonesimulator clean test"
	xc "-scheme OSX -configuration Debug clean test"
	xc "-scheme OSX -configuration Release clean test"
fi

######################################
# Docs
######################################

if [[ "$COMMAND" == "docs" ]]; then
	sh scripts/build-docs.sh
fi
