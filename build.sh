#!/bin/sh

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

XCVERSION=$(xcodebuild -version | head -1 | cut -f2 -d" " | cut -f1 -d.)

xc() {
    if [[ "$XCMODE" == "xcodebuild" ]]; then
        xcodebuild $1 || exit 1
    elif [[ "$XCMODE" == "xcpretty" ]]; then
        xcodebuild $1 | tee build.log | xcpretty -c ${XCPRETTY_PARAMS}
        if [ "$?" -ne 0 ]; then
            echo "The raw xcodebuild output is available in build.log"
            exit 1
        fi
    elif [[ "$XCMODE" == "xctool" ]]; then
        xctool $1 || exit 1
    fi
}

xcrealm() {
    PROJECT=Realm.xcodeproj
    if [[ "$XCVERSION" == "6" ]]; then
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

# You can override the version of the core library
# Otherwise, use the default value
if [ -z "$REALM_CORE_VERSION" ]; then
    REALM_CORE_VERSION=latest
fi

COMMAND="$1"
XCMODE="$2"
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool


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
            curl -L -s "http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip" -o "/tmp/core-${REALM_CORE_VERSION}.zip" || exit 1
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

    "build-debug")
        sh build.sh ios-debug "$XCMODE" || exit 1
        sh build.sh osx-debug "$XCMODE" || exit 1
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
        sh scripts/build-docs.sh || exit 1
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
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer || exit 1
        sh build.sh test "$XCMODE" || exit 1
        sh build.sh test-debug "$XCMODE" || exit 1
        sudo xcode-select -s /Applications/Xcode6-Beta2.app/Contents/Developer || exit 1
        fail=0
        (
            sh build.sh test "$XCMODE" || exit 1
            sh build.sh test-debug "$XCMODE" || exit 1
        ) || fail=1
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer || exit 1
        exit $fail
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
        exit 0
        ;;

    ######################################
    # Examples
    ######################################
    "examples")
        cd examples
        if [[ "$XCVERSION" == "6" ]]; then
        	xc "-project swift/RealmSwiftTableViewExample/RealmSwiftTableViewExample.xcodeproj -scheme RealmSwiftTableViewExample -configuration Release clean build ${CODESIGN_PARAMS}"
        	xc "-project swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample.xcodeproj -scheme RealmSwiftSimpleExample -configuration Release clean build ${CODESIGN_PARAMS}"
        fi
        xc "-project objc/RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample -configuration Release clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample -configuration Release clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmPerformanceExample/RealmPerformanceExample.xcodeproj -scheme RealmPerformanceExample -configuration Release clean build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    "examples-debug")
        cd examples
        if [[ "$XCVERSION" == "6" ]]; then
        	xc "-project swift/RealmSwiftTableViewExample/RealmSwiftTableViewExample.xcodeproj -scheme RealmSwiftTableViewExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        fi
        xc "-project objc/RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmPerformanceExample/RealmPerformanceExample.xcodeproj -scheme RealmPerformanceExample -configuration Debug clean build ${CODESIGN_PARAMS}"
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
        realm_version="$1"
        version_file="Realm/Realm-Info.plist"

        PlistBuddy -c "Set :CFBundleVersion $realm_version" "$version_file"
        PlistBuddy -c "Set :CFBundleShortVersionString $realm_version" "$version_file"
        exit 0
        ;;

    *)
        usage
        exit 1
        ;;
esac
