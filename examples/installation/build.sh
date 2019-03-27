#!/bin/bash

set -o pipefail
set -e

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  test-all:                        tests all projects in this repo.

  test-ios-objc-static:            tests iOS Objective-C static example.
  test-ios-objc-dynamic:           tests iOS Objective-C dynamic example.
  test-ios-objc-cocoapods:         tests iOS Objective-C CocoaPods example.
  test-ios-objc-cocoapods-dynamic: tests iOS Objective-C CocoaPods Dynamic example.
  test-ios-objc-carthage:          tests iOS Objective-C Carthage example.
  test-ios-swift-dynamic:          tests iOS Swift dynamic example.
  test-ios-swift-cocoapods:        tests iOS Swift CocoaPods example.
  test-ios-swift-carthage:         tests iOS Objective-C Carthage example.

  test-osx-objc-dynamic:           tests OS X Objective-C dynamic example.
  test-osx-objc-cocoapods:         tests OS X Objective-C CocoaPods example.
  test-osx-objc-carthage:          tests OS X Objective-C Carthage example.
  test-osx-swift-dynamic:          tests OS X Swift dynamic example.
  test-osx-swift-cocoapods:        tests OS X Swift CocoaPods example.
  test-osx-swift-carthage:         tests OS X Swift Carthage example.

  test-watchos-objc-dynamic:       tests watchOS Objective-C dynamic example.
  test-watchos-objc-cocoapods:     tests watchOS Objective-C CocoaPods example.
  test-watchos-objc-carthage:      tests watchOS Objective-C Carthage example.
  test-watchos-swift-dynamic:      tests watchOS Swift dynamic example.
  test-watchos-swift-cocoapods:    tests watchOS Swift CocoaPods example.
  test-watchos-swift-carthage:     tests watchOS Swift Carthage example.
EOF
}

COMMAND="$1"

# https://github.com/CocoaPods/CocoaPods/issues/7708
export EXPANDED_CODE_SIGN_IDENTITY=''

download_zip_if_needed() {
    LANG="$1"
    DIRECTORY=realm-$LANG-latest
    if [ ! -d $DIRECTORY ]; then
        curl -o $DIRECTORY.zip -L https://static.realm.io/downloads/$LANG/latest
        unzip $DIRECTORY.zip
        rm $DIRECTORY.zip
        mv realm-$LANG-* $DIRECTORY
    fi
}

xctest() {
    PLATFORM="$1"
    LANG="$2"
    NAME="$3"
    DIRECTORY="$PLATFORM/$LANG/$NAME"
    if [[ ! -d "$DIRECTORY" ]]; then
        DIRECTORY="${DIRECTORY/swift/swift-$REALM_SWIFT_VERSION}"
    fi
    PROJECT="$DIRECTORY/$NAME.xcodeproj"
    WORKSPACE="$DIRECTORY/$NAME.xcworkspace"
    if [[ $PLATFORM == ios ]]; then
        sh "$(dirname "$0")/../../scripts/reset-simulators.sh"
    fi
    if [[ $NAME == CocoaPods* ]]; then
        pod install --project-directory="$DIRECTORY"
    elif [[ $NAME == Carthage* ]]; then
        (
            cd "$DIRECTORY"
            if [ -n "$REALM_BUILD_USING_LATEST_RELEASE" ]; then
                echo "github \"realm/realm-cocoa\"" > Cartfile
            else
                echo "github \"realm/realm-cocoa\" \"${sha:-master}\"" > Cartfile
            fi
            if [[ $PLATFORM == ios ]]; then
                carthage update --platform iOS
            elif [[ $PLATFORM == osx ]]; then
                carthage update --platform Mac
            elif [[ $PLATFORM == watchos ]]; then
                carthage update --platform watchOS
            fi
        )
    elif [[ $LANG == swift* ]]; then
        download_zip_if_needed swift
    else
        download_zip_if_needed $LANG
    fi
    DESTINATION=""
    if [[ $PLATFORM == ios ]]; then
        simulator_id="$(xcrun simctl list devices | grep -v unavailable | grep -m 1 -o '[0-9A-F\-]\{36\}')"
        xcrun simctl boot $simulator_id
        DESTINATION="-destination id=$simulator_id"
    elif [[ $PLATFORM == watchos ]]; then
        if xcrun simctl list devicetypes | grep -q 'iPhone Xs'; then
            DESTINATION="-destination id=$(xcrun simctl list devices | grep -v unavailable | grep 'iPhone Xs' | grep -m 1 -o '[0-9A-F\-]\{36\}')"
        fi
    fi
    CMD="-project $PROJECT"
    if [ -d $WORKSPACE ]; then
        CMD="-workspace $WORKSPACE"
    fi
    ACTION=""
    if [[ $PLATFORM == watchos ]]; then
        ACTION="build"
    else
        ACTION="build test"
    fi
    if [[ $PLATFORM == ios ]]; then
        xcodebuild $CMD -scheme $NAME clean $ACTION $DESTINATION CODE_SIGN_IDENTITY=
    else
        xcodebuild $CMD -scheme $NAME clean $ACTION $DESTINATION CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO
    fi
}

source "$(dirname "$0")/../../scripts/swift-version.sh"
set_xcode_and_swift_versions # exports REALM_SWIFT_VERSION, REALM_XCODE_VERSION, and DEVELOPER_DIR variables if not already set

case "$COMMAND" in
    "test-all")
        for target in ios-swift-dynamic ios-swift-cocoapods osx-swift-dynamic ios-swift-carthage osx-swift-carthage; do
            ./build.sh test-$target || exit 1
        done
        ;;

    "test-ios-objc-static")
        xctest ios objc StaticExample
        ;;

    "test-ios-objc-dynamic")
        xctest ios objc DynamicExample
        ;;

    "test-ios-objc-cocoapods")
        xctest ios objc CocoaPodsExample
        ;;

    "test-ios-objc-cocoapods-dynamic")
        xctest ios objc CocoaPodsDynamicExample
        ;;

    "test-ios-objc-carthage")
        xctest ios objc CarthageExample
        ;;

    "test-ios-swift-dynamic")
        xctest ios swift DynamicExample
        ;;

    "test-ios-swift-cocoapods")
        xctest ios swift CocoaPodsExample
        ;;

    "test-ios-swift-carthage")
        xctest ios swift CarthageExample
        ;;

    "test-osx-objc-dynamic")
        xctest osx objc DynamicExample
        ;;

    "test-osx-objc-cocoapods")
        xctest osx objc CocoaPodsExample
        ;;

    "test-osx-objc-carthage")
        xctest osx objc CarthageExample
        ;;

    "test-osx-swift-dynamic")
        xctest osx swift DynamicExample
        ;;

    "test-osx-swift-cocoapods")
        xctest osx swift CocoaPodsExample
        ;;

    "test-osx-swift-carthage")
        xctest osx swift CarthageExample
        ;;

    "test-watchos-objc-dynamic")
        xctest watchos objc DynamicExample
        ;;

    "test-watchos-objc-cocoapods")
        xctest watchos objc CocoaPodsExample
        ;;

    "test-watchos-objc-carthage")
        xctest watchos objc CarthageExample
        ;;

    "test-watchos-swift-dynamic")
        xctest watchos swift DynamicExample
        ;;

    "test-watchos-swift-cocoapods")
        xctest watchos swift CocoaPodsExample
        ;;

    "test-watchos-swift-carthage")
        xctest watchos swift CarthageExample
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
