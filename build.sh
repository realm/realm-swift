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
set -e

# You can override the version of the core library
# Otherwise, use the default value
if [ -z "$REALM_CORE_VERSION" ]; then
    REALM_CORE_VERSION=0.81.0
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
  browser [xcmode]:        builds the RealmBrowser OSX app
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
    ln -s /Applications/Xcode6-Beta5.app/Contents/Developer/usr/bin build/bin
    PATH=./build/bin:$PATH xcodebuild -IDECustomDerivedDataLocation=build/DerivedData $@
}

xcode() {
    if [ -L build/bin ]; then
        unlink build/bin
    fi
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
        xcode $1 | tee build/build.log | xcpretty -c ${XCPRETTY_PARAMS} || {
            echo "The raw xcodebuild output is available in build/build.log"
            exit 1
        }
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
    TMP_DIR="$(mktemp -dt "$0")"
    curl -L -s "http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip" -o "${TMP_DIR}/core-${REALM_CORE_VERSION}.zip"
    (
        cd "${TMP_DIR}"
        unzip "core-${REALM_CORE_VERSION}.zip"
        mv core core-${REALM_CORE_VERSION}
        rm -f "core-${REALM_CORE_VERSION}.zip"
    )
    rm -rf core-${REALM_CORE_VERSION} core
    mv ${TMP_DIR}/core-${REALM_CORE_VERSION} .
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
        if [ "$REALM_CORE_VERSION" = "current" ]; then
            echo "Using version of core already in core/ directory"
            exit 0
        fi
        if [ -d core -a -d ../tightdb ]; then
          # Allow newer versions than expected for local builds as testing
          # with unreleased versions is one of the reasons to use a local build
          if ! $(grep "${REALM_CORE_VERSION} Release notes" core/release_notes.txt >/dev/null); then
              echo "Local build of core is out of date."
              exit 1
          else
              echo "The core library seems to be up to date."
          fi
        elif ! [ -L core ]; then
            echo "core is not a symlink. Deleting..."
            rm -rf core
            download_core
        elif ! $(head -n 1 core/release_notes.txt | grep ${REALM_CORE_VERSION} >/dev/null); then
            download_core
        else
            echo "The core library seems to be up to date."
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
        if [[ "$XCODE_VERSION" == "6" ]]; then
            # Build Universal Simulator/Device framework
            xcrealm "-scheme iOS -configuration Release -sdk iphonesimulator"
            xcrealm "-scheme iOS -configuration Release -sdk iphoneos"
            cd build/DerivedData/Realm-Xcode6/Build/Products
            mkdir -p Release-iphone
            cp -R Release-iphoneos/Realm.framework Release-iphone
            lipo -create -output Realm Release-iphoneos/Realm.framework/Realm Release-iphonesimulator/Realm.framework/Realm
            mv Realm Release-iphone/Realm.framework
        else
            xcrealm "-scheme iOS -configuration Release"
        fi
        exit 0
        ;;

    "osx")
        xcrealm "-scheme OSX -configuration Release"
        exit 0
        ;;

    "ios-debug")
        if [[ "$XCODE_VERSION" == "6" ]]; then
            # Build Universal Simulator/Device framework
            xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator"
            xcrealm "-scheme iOS -configuration Debug -sdk iphoneos"
            cd build/DerivedData/Realm-Xcode6/Build/Products
            mkdir -p Debug-iphone
            cp -R Debug-iphoneos/Realm.framework Debug-iphone
            lipo -create -output Realm Debug-iphoneos/Realm.framework/Realm Debug-iphonesimulator/Realm.framework/Realm
            mv Realm Debug-iphone/Realm.framework
        else
            xcrealm "-scheme iOS -configuration Debug"
        fi
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
        set +e # Run both sets of tests even if the first fails
        sh build.sh test-ios "$XCMODE"
        sh build.sh test-osx "$XCMODE"
        exit 0
        ;;

    "test-debug")
        set +e
        sh build.sh test-osx-debug "$XCMODE"
        sh build.sh test-ios-debug "$XCMODE"
        exit 0
        ;;

    "test-all")
        set +e
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
        if [[ "$XCODE_VERSION" == "6" ]]; then
            xc "-project swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample.xcodeproj -scheme RealmSwiftSimpleExample -configuration Release clean build ${CODESIGN_PARAMS}"
            xc "-project swift/RealmSwiftTableViewExample/RealmSwiftTableViewExample.xcodeproj -scheme RealmSwiftTableViewExample -configuration Release clean build ${CODESIGN_PARAMS}"
        fi
        xc "-project objc/RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample -configuration Release clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample -configuration Release clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmMigrationExample/RealmMigrationExample.xcodeproj -scheme RealmMigrationExample -configuration Release clean build ${CODESIGN_PARAMS}"
        #xc "-project objc/RealmRestExample/RealmRestExample.xcodeproj -scheme RealmRestExample -configuration Release clean build ${CODESIGN_PARAMS}"

        # Not all examples can be built using Xcode 6
        if [[ "$XCODE_VERSION" != "6" ]]; then
            xc "-project objc/RealmJSONImportExample/RealmJSONImportExample.xcodeproj -scheme RealmJSONImportExample -configuration Release clean build ${CODESIGN_PARAMS}"
        fi
        exit 0
        ;;

    "examples-debug")
        cd examples
        if [[ "$XCODE_VERSION" == "6" ]]; then
            xc "-project swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample.xcodeproj -scheme RealmSwiftSimpleExample -configuration Debug clean build ${CODESIGN_PARAMS}"
            xc "-project swift/RealmSwiftTableViewExample/RealmSwiftTableViewExample.xcodeproj -scheme RealmSwiftTableViewExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        fi
        xc "-project objc/RealmSimpleExample/RealmSimpleExample.xcodeproj -scheme RealmSimpleExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmTableViewExample/RealmTableViewExample.xcodeproj -scheme RealmTableViewExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        xc "-project objc/RealmMigrationExample/RealmMigrationExample.xcodeproj -scheme RealmMigrationExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        #xc "-project objc/RealmRestExample/RealmRestExample.xcodeproj -scheme RealmRestExample -configuration Debug clean build ${CODESIGN_PARAMS}"

        # Not all examples can be built using Xcode 6
        if [[ "$XCODE_VERSION" != "6" ]]; then
            xc "-project objc/RealmJSONImportExample/RealmJSONImportExample.xcodeproj -scheme RealmJSONImportExample -configuration Debug clean build ${CODESIGN_PARAMS}"
        fi 
        exit 0
        ;;

    ######################################
    # Browser
    ######################################
    "browser")
        if [[ "$XCODE_VERSION" != "6" ]]; then
            xc "-project tools/RealmBrowser/RealmBrowser.xcodeproj -scheme RealmBrowser -configuration Release clean build ${CODESIGN_PARAMS}"
        else
            echo "Realm Browser can only be built with Xcode 5."
            exit 1
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
        version_files="Realm/Realm-Info.plist tools/RealmBrowser/RealmBrowser/RealmBrowser-Info.plist"

        if [ -z "$realm_version" ]; then
            echo "You must specify a version."
            exit 1
        fi
        for version_file in $version_files; do
            PlistBuddy -c "Set :CFBundleVersion $realm_version" "$version_file"
            PlistBuddy -c "Set :CFBundleShortVersionString $realm_version" "$version_file"
        done
        exit 0
        ;;

    ######################################
    # CocoaPods
    ######################################
    "cocoapods-setup")
        sh build.sh download-core

        # CocoaPods seems to not like symlinks
        mv core tmp
        mv $(readlink tmp) core
        rm tmp

        mkdir include-ios
        cp -R core/include/* include-ios
        mkdir include-ios/Realm
        cp Realm/*.{h,hpp} include-ios/Realm
        cp Realm/ios/*.h include-ios/Realm

        mkdir include-osx
        cp -R core/include/* include-osx
        mkdir include-osx/Realm
        cp Realm/*.{h,hpp} include-osx/Realm
        cp Realm/osx/*.h include-osx/Realm
        ;;

    *)
        usage
        exit 1
        ;;
esac
