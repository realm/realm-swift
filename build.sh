#!/bin/bash

##################################################################################
# Custom build tool for Realm Objective C binding.
#
# (C) Copyright 2011-2014 by realm.io.
##################################################################################

# Warning: pipefail is not a POSIX compatible option, but on OS X it works just fine.
#          OS X uses a POSIX complain version of bash as /bin/sh, but apparently it does
#          not strip away this feature. Also, this will fail if somebody forces the script
#          to be run with zsh.
set -o pipefail

error() {
    echo "The script ended with an error at line $1"
    exit 1
}

trap 'error ${LINENO}' ERR

# You can override the version of the core library
# Otherwise, use the default value
if [ -z "$REALM_CORE_VERSION" ]; then
    REALM_CORE_VERSION=0.80.3
fi

PATH=/usr/local/bin:/usr/bin:/bin:/usr/libexec:$PATH

if ! [ -z "${JENKINS_HOME}" ]; then
    XCPRETTY_PARAMS="--no-utf --report junit --output build/reports/junit.xml"
    CODESIGN_PARAMS="CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO"
fi

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  download-core:           downloads core library (binary version)
  clean [xcmode]:          clean up/remove all generated files
  build [xcmode]:          builds iOS and OS X frameworks with release configuration
  build-debug [xcmode]:    builds iOS and OS X frameworks with debug configuration
  ios [xcmode]:            builds iOS framework with release configuration
  ios-debug [xcmode]:      builds iOS framework with debug configuration
  osx [xcmode]:            builds OS X framework with release configuration
  osx-debug [xcmode]:      builds OS X framework with debug configuration
  test-ios [xcmode]:       tests iOS framework with release configuration
  test-osx [xcmode]:       tests OSX framework with release configuration
  test [xcmode]:           tests iOS and OS X frameworks with release configuration
  test-debug [xcmode]:     tests iOS and OS X frameworks with debug configuration
  test-all [xcmode]:       tests iOS and OS X frameworks with debug and release configurations, on Xcode 5 and Xcode 6
  examples [xcmode]:       builds all examples in examples/ in release configuration
  examples-debug [xcmode]: builds all examples in examples/ in debug configuration
  verify [xcmode]:         cleans, removes docs/output/, then runs docs, test-all and examples
  docs:                    builds docs in docs/output
  get-version:             get the current version
  set-version version:     set the version

argument:
  xcmode:  xcodebuild (default), xcpretty or xctool
  version: version in the x.y.z format
EOF
}

######################################
# Xcode Helpers
######################################

if [ -z "$XCODE_VERSION" ]; then
    XCODE_VERSION=5
fi

xcode5() {
    ln -s /Applications/Xcode.app/Contents/Developer/usr/bin build/bin
    PATH=./build/bin:$PATH xcodebuild -IDECustomDerivedDataLocation=build/DerivedData $@
}

xcode6() {
    ln -s /Applications/Xcode6-Beta3.app/Contents/Developer/usr/bin build/bin
    PATH=./build/bin:$PATH xcodebuild -IDECustomDerivedDataLocation=build/DerivedData $@
}

xcode() {
    rm -rf build/bin
    mkdir -p build/DerivedData
    case "$XCODE_VERSION" in
        5)
            xcode5 $@
            ;;
        6)
            xcode6 $@
            ;;
        *)
            echo "Unsupported version of xcode specified"
            exit 1
    esac
}

xc() {
    echo "Building target \"$1\" with xcode${XCODE_VERSION}"
    if [[ "$XCMODE" == "xcodebuild" ]]; then
        xcode $1
    elif [[ "$XCMODE" == "xcpretty" ]]; then
        mkdir -p build
        xcode $1 | tee build/build.log | xcpretty -c ${XCPRETTY_PARAMS}
        if [ "$?" -ne 0 ]; then
            echo "The raw xcodebuild output is available in build/build.log"
            exit 1
        fi
    elif [[ "$XCMODE" == "xctool" ]]; then
        xctool $1
    fi
}

xcrealm() {
    PROJECT=Realm.xcodeproj
    if [[ "$XCODE_VERSION" == "6" ]]; then
        PROJECT=Realm-Xcode6.xcodeproj
    fi
    xc "-project $PROJECT $1"
}

######################################
# Input Validation
######################################

if [ "$#" -eq 0 -o "$#" -gt 2 ]; then
    usage
    exit 1
fi

######################################
# Variables
######################################

# Xcode sets this variable - set to current directory if running standalone
if [ -z "$SRCROOT" ]; then
    SRCROOT="$(pwd)"
fi

download_core() {
    echo "Downloading dependency: core ${REALM_CORE_VERSION}"
    curl -L -s "http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip" -o "/tmp/core-${REALM_CORE_VERSION}.zip"
    (
        cd /tmp
        unzip "/tmp/core-${REALM_CORE_VERSION}.zip" || exit 1
        mv core core-${REALM_CORE_VERSION}
        rm -f "/tmp/core-${REALM_CORE_VERSION}.zip" || exit 1
    )
    mv /tmp/core-${REALM_CORE_VERSION} .
    ln -s core-${REALM_CORE_VERSION} core
}

COMMAND="$1"
XCMODE="$2"
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool

case "$COMMAND" in

    ######################################
    # Clean
    ######################################
    "clean")
        xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator clean"
        xcrealm "-scheme iOS -configuration Release -sdk iphonesimulator clean"
        xcrealm "-scheme OSX -configuration Debug clean"
        xcrealm "-scheme OSX -configuration Release clean"
        exit 0
        ;;

    ######################################
    # Download Core Library
    ######################################
    "download-core")
        if ! [ -L core ]; then
            echo "core is not a symlink. Deleting..."
            rm -rf core
            download_core
        elif ! $(head -n 1 core/release_notes.txt | grep ${REALM_CORE_VERSION} >/dev/null); then
            download_core
        else
            echo "The core library seems to be up to date."
            echo "To force an update remove the folder 'core' and rerun."
        fi
        exit 0
        ;;

    ######################################
    # Building
    ######################################
    "build")
        sh build.sh ios "$XCMODE"
        sh build.sh osx "$XCMODE"
        exit 0
        ;;

    "build-debug")
        sh build.sh ios-debug "$XCMODE"
        sh build.sh osx-debug "$XCMODE"
        exit 0
        ;;

    "ios")
        xcrealm "-scheme iOS -configuration Release"
        exit 0
        ;;

    "osx")
        xcrealm "-scheme OSX -configuration Release"
        exit 0
        ;;

    "ios-debug")
        xcrealm "-scheme iOS -configuration Debug"
        exit 0
        ;;

    "osx-debug")
        xcrealm "-scheme OSX -configuration Debug"
        exit 0
        ;;

    "docs")
        sh scripts/build-docs.sh
        exit 0
        ;;

    ######################################
    # Testing
    ######################################
    "test")
        sh build.sh test-ios "$XCMODE"
        sh build.sh test-osx "$XCMODE"
        exit 0
        ;;

    "test-debug")
        sh build.sh test-osx-debug "$XCMODE"
        sh build.sh test-ios-debug "$XCMODE"
        exit 0
        ;;

    "test-all")
        sh build.sh test "$XCMODE"
        sh build.sh test-debug "$XCMODE"
        XCODE_VERSION=6 sh build.sh test "$XCMODE"
        XCODE_VERSION=6 sh build.sh test-debug "$XCMODE"
        ;;

    "test-ios")
        xcrealm "-scheme iOS -configuration Release -sdk iphonesimulator test"
        exit 0
        ;;

    "test-osx")
        xcrealm "-scheme OSX -configuration Release test"
        exit 0
        ;;

    "test-ios-debug")
        xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator test"
        exit 0
        ;;

    "test-osx-debug")
        xcrealm "-scheme OSX -configuration Debug test"
        exit 0
        ;;

    "test-cover")
        echo "Not yet implemented"
        exit 0
        ;;

    "verify")
        sh build.sh docs
        sh build.sh test-all "$XCMODE"
        sh build.sh examples "$XCMODE"
        exit 0
        ;;

    ######################################
    # Docs
    ######################################
    "docs")
        sh scripts/build-docs.sh
        exit 0
        ;;

    ######################################
    # Examples
    ######################################
    "examples")
        cd examples
        if [[ "$XCVERSION" == "6" ]]; then
            xc "-project swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample.xcodeproj -scheme RealmSwiftSimpleExample -configuration Release clean build ${CODESIGN_PARAMS}"
        	xc "-project swift/RealmSwiftTableViewExample/RealmSwiftTableViewExample.xcodeproj -scheme RealmSwiftTableViewExample -configuration Release clean build ${CODESIGN_PARAMS}"
        fi
        xc "-project objc/RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample -configuration Release clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample -configuration Release clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmMigrationExample/RealmMigrationExample.xcodeproj -scheme RealmMigrationExample -configuration Release clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmRestExample/RealmRestExample.xcodeproj -scheme RealmRestExample -configuration Release clean build ${CODESIGN_PARAMS}"

        # Not all examples can be built using Xcode 6
        if [[ "$XCVERSION" != "6" ]]; then
            xc "-project objc/RealmJSONImportExample/RealmJSONImportExample.xcodeproj -scheme RealmJSONImportExample -configuration Release clean build ${CODESIGN_PARAMS}"
        fi
        exit 0
        ;;

    "examples-debug")
        cd examples
        if [[ "$XCVERSION" == "6" ]]; then
            xc "-project swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample.xcodeproj -scheme RealmSwiftSimpleExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        	xc "-project swift/RealmSwiftTableViewExample/RealmSwiftTableViewExample.xcodeproj -scheme RealmSwiftTableViewExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        fi
        xc "-project objc/RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmMigrationExample/RealmMigrationExample.xcodeproj -scheme RealmMigrationExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmRestExample/RealmRestExample.xcodeproj -scheme RealmRestExample -configuration Debug clean build ${CODESIGN_PARAMS}"

        # Not all examples can be built using Xcode 6
        if [[ "$XCVERSION" != "6" ]]; then
            xc "-project objc/RealmJSONImportExample/RealmJSONImportExample.xcodeproj -scheme RealmJSONImportExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        fi 
        exit 0
        ;;

    ######################################
    # Versioning
    ######################################
    "get-version")
        version_file="Realm/Realm-Info.plist"
        echo "$(PlistBuddy -c "Print :CFBundleVersion" "$version_file")"
        exit 0
        ;;

    "set-version")
        realm_version="$2"
        version_file="Realm/Realm-Info.plist"

        if [ -z "$realm_version" ]; then
            echo "You must specify a version."
            exit 1
        fi 
        PlistBuddy -c "Set :CFBundleVersion $realm_version" "$version_file"
        PlistBuddy -c "Set :CFBundleShortVersionString $realm_version" "$version_file"
        exit 0
        ;;

    *)
        usage
        exit 1
        ;;
esac
