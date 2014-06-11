######################################
# Variables
######################################

PATH=/usr/local/bin:/usr/bin:$PATH
COMMAND=$1
REALM_CORE_VERSION=latest
XCMODE=xcpretty # must be one of: xctool, xcpretty, xcodebuild

######################################
# Helpers
######################################

xc(){
	PROJECT=Realm.xcodeproj
	if [[ "$XCMODE" == "xctool" ]]; then
		xctool -project $PROJECT $1
	elif [[ "$XCMODE" == "xcpretty" ]]; then
		xcodebuild -project $PROJECT $1 | xcpretty
	elif [[ "$XCMODE" == "xcodebuild" ]]; then
		xcodebuild -project $PROJECT $1
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
