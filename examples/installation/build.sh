#!/bin/bash

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  bootstrap:                       downloads product dependencies and runs 'pod install'/'carthage bootstrap' where appropriate

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
  test-osx-swift-carthage:         tests OS X Swift Carthage example.
EOF
}

COMMAND="$1"

xctest() {
    XCODE_COMMAND="$@"
    xcodebuild $XCODE_COMMAND clean build test -sdk iphonesimulator || exit 1
}

source "$(dirname "$0")/../../scripts/swift-version.sh"

case "$COMMAND" in

    ######################################
    # Bootsrap
    ######################################

    "bootstrap")
        ################
        # Release zips
        ################

        # Download zips if there are none
        shopt -s nullglob
        set -- *.zip
        if [ "$#" -eq 0 ]; then
            for lang in swift objc; do
                rm -rf realm-$lang-latest
                curl -o realm-$lang-latest.zip -L https://static.realm.io/downloads/$lang/latest
                unzip realm-$lang-latest.zip
                mv realm-$lang-0.* realm-$lang-latest
            done
        fi

        ################
        # CoocaPods
        ################

        for path in $(find . -path "*/CocoaPods*Example/CocoaPods*Example"); do
            pod install --project-directory="$path/.."
        done

        ################
        # Carthage
        ################

        for path in $(find . -path "*/CarthageExample/CarthageExample"); do
            (cd "$path/.."; carthage bootstrap)
        done
        ;;

    ######################################
    # Test
    ######################################

    "test-all")
        ./build.sh test-ios-objc-static || exit 1
        ./build.sh test-ios-objc-dynamic || exit 1
        ./build.sh test-ios-objc-cocoapods || exit 1
        ./build.sh test-ios-objc-cocoapods-dynamic || exit 1
        ./build.sh test-ios-objc-carthage || exit 1

        ./build.sh test-osx-objc-dynamic || exit 1
        ./build.sh test-osx-objc-cocoapods || exit 1
        ./build.sh test-osx-objc-carthage || exit 1

        for swift_version in 1.2 2.0; do
            REALM_SWIFT_VERSION=swift_version ./build.sh test-ios-swift-dynamic || exit 1
            REALM_SWIFT_VERSION=swift_version ./build.sh test-ios-swift-cocoapods || exit 1
            REALM_SWIFT_VERSION=swift_version ./build.sh test-ios-swift-carthage || exit 1

            REALM_SWIFT_VERSION=swift_version ./build.sh test-osx-swift-dynamic || exit 1
            REALM_SWIFT_VERSION=swift_version ./build.sh test-osx-swift-carthage || exit 1
        done
        ;;

    "test-ios-objc-static")
        xctest "-project" "ios/objc/StaticExample/StaticExample.xcodeproj" "-scheme" "StaticExample"
        ;;

    "test-ios-objc-dynamic")
        xctest "-project" "ios/objc/DynamicExample/DynamicExample.xcodeproj" "-scheme" "DynamicExample"
        ;;

    "test-ios-objc-cocoapods")
        xctest "-workspace" "ios/objc/CocoaPodsExample/CocoaPodsExample.xcworkspace" "-scheme" "CocoaPodsExample"
        ;;

    "test-ios-objc-cocoapods-dynamic")
        xctest "-workspace" "ios/objc/CocoaPodsDynamicExample/CocoaPodsDynamicExample.xcworkspace" "-scheme" "CocoaPodsDynamicExample"
        ;;

    "test-ios-objc-carthage")
        xctest "-project" "ios/objc/CarthageExample/CarthageExample.xcodeproj" "-scheme" "CarthageExample"
        ;;

    "test-ios-swift-dynamic")
        xctest "-project" "ios/swift-$REALM_SWIFT_VERSION/DynamicExample/DynamicExample.xcodeproj" "-scheme" "DynamicExample"
        ;;

    "test-ios-swift-cocoapods")
        xctest "-workspace" "ios/swift-$REALM_SWIFT_VERSION/CocoaPodsExample/CocoaPodsExample.xcworkspace" "-scheme" "CocoaPodsExample"
        ;;

    "test-ios-swift-carthage")
        xctest "-project" "ios/swift-$REALM_SWIFT_VERSION/CarthageExample/CarthageExample.xcodeproj" "-scheme" "CarthageExample"
        ;;

    "test-osx-objc-dynamic")
        xcodebuild -project osx/objc/DynamicExample/DynamicExample.xcodeproj -scheme DynamicExample clean build test || exit 1
        ;;

    "test-osx-objc-cocoapods")
        xcodebuild -workspace osx/objc/CocoaPodsExample/CocoaPodsExample.xcworkspace -scheme CocoaPodsExample clean build test || exit 1
        ;;

    "test-osx-objc-carthage")
        xcodebuild -project osx/objc/CarthageExample/CarthageExample.xcodeproj -scheme CarthageExample clean build test || exit 1
        ;;

    "test-osx-swift-dynamic")
        xcodebuild -project osx/swift-$REALM_SWIFT_VERSION/DynamicExample/DynamicExample.xcodeproj -scheme DynamicExample clean build test || exit 1
        ;;

    "test-osx-swift-carthage")
        xcodebuild -project osx/swift-$REALM_SWIFT_VERSION/CarthageExample/CarthageExample.xcodeproj -scheme CarthageExample clean build test || exit 1
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
