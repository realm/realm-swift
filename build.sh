######################################
# Variables
######################################

PATH=/usr/local/bin:/usr/bin:$PATH
COMMAND="$1"
REALM_CORE_VERSION='0.20.0'
USE_XCTOOL=false

######################################
# Helpers
######################################

xc(){
	if [[ $USE_XCTOOL ]]; then
		xctool -project Realm.xcodeproj $1
	elif [[ condition ]]; then
		xcodebuild -project Realm.xcodeproj $1
	fi
}

######################################
# Download core
######################################

if [[ "$COMMAND" == "download_core" ]]; then
	if ! [ -d core ]; then
	    curl -s http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip -o /tmp/core-${REALM_CORE_VERSION}.zip
	    rm -rf core
	    unzip /tmp/core-${REALM_CORE_VERSION}.zip
	    rm -f /tmp/core-${REALM_CORE_VERSION}.zip
	    mv realm-core core
	fi
fi

######################################
# Building
######################################

if [[ "$COMMAND" == "ios" ]]; then
	xc "-scheme Realm-iOS"
fi

if [[ "$COMMAND" == "osx" ]]; then
	xc "-scheme Realm-OSX"
fi

######################################
# Testing
######################################

if [[ "$COMMAND" == "ios-tests" ]]; then
	xc "-scheme Realm-iOS test"
fi

if [[ "$COMMAND" == "osx-tests" ]]; then
	xc "-scheme Realm-OSX test"
fi

######################################
# Docs
######################################

if [[ "$COMMAND" == "docs" ]]; then
	sh scripts/build-docs.sh
fi
