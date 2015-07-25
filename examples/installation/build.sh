#!/bin/bash

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  bootstrap:                       downloads product dependencies and runs 'pod install'/'carthage bootstrap' where appropriate

  test-all:                        tests all projects in this repo.
  test-xcode6:                     tests all Xcode 6 projects in this repo.
  test-xcode7:                     tests all Xcode 7 projects in this repo.

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

prelaunch_simulator() {
    killall "iOS Simulator" 2>/dev/null || true
    killall Simulator 2>/dev/null || true
    pkill CoreSimulator 2>/dev/null || true
    # Erase all available simulators
    (
        IFS=$'\n' # make newlines the only separator
        for LINE in $(xcrun simctl list); do
            if [[ $LINE =~ unavailable ]]; then
                # skip unavailable simulators
                continue
            fi
            if [[ $LINE =~ ([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}) ]]; then
                xcrun simctl erase "${BASH_REMATCH[1]}" 2>/dev/null || true
            fi
        done
    )
    sleep 5
    if [[ -a "${DEVELOPER_DIR}/Applications/iOS Simulator.app" ]]; then
        open "${DEVELOPER_DIR}/Applications/iOS Simulator.app"
    elif [[ -a "${DEVELOPER_DIR}/Applications/Simulator.app" ]]; then
        open "${DEVELOPER_DIR}/Applications/Simulator.app"
    fi
    sleep 5
}

xctest_ios() {
    prelaunch_simulator
    XCODE_COMMAND="$@"
    xcodebuild $XCODE_COMMAND clean build test -sdk iphonesimulator || exit 1
}

xctest_osx() {
    XCODE_COMMAND="$@"
    xcodebuild $XCODE_COMMAND clean build test -sdk macosx || exit 1
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
        ./build.sh test-xcode6 || exit 1
        ./build.sh test-xcode7 || exit 1
        ;;

    "test-xcode6")
        export REALM_SWIFT_VERSION=1.2

        ./build.sh test-ios-objc-static || exit 1
        ./build.sh test-ios-objc-dynamic || exit 1
        ./build.sh test-ios-objc-cocoapods || exit 1
        ./build.sh test-ios-objc-cocoapods-dynamic || exit 1
        ./build.sh test-ios-objc-carthage || exit 1

        ./build.sh test-osx-objc-dynamic || exit 1
        ./build.sh test-osx-objc-cocoapods || exit 1
        ./build.sh test-osx-objc-carthage || exit 1

        ./build.sh test-ios-swift-dynamic || exit 1
        ./build.sh test-ios-swift-cocoapods || exit 1

        ./build.sh test-osx-swift-dynamic || exit 1

        ./build.sh test-ios-swift-carthage || exit 1
        ./build.sh test-osx-swift-carthage || exit 1
        ;;

    "test-xcode7")
        export REALM_SWIFT_VERSION=2.0

        ./build.sh test-ios-swift-dynamic || exit 1
        ./build.sh test-ios-swift-cocoapods || exit 1
        ./build.sh test-osx-swift-dynamic || exit 1
        ;;

    "test-ios-objc-static")
        xctest_ios "-project" "ios/objc/StaticExample/StaticExample.xcodeproj" "-scheme" "StaticExample"
        ;;

    "test-ios-objc-dynamic")
        xctest_ios "-project" "ios/objc/DynamicExample/DynamicExample.xcodeproj" "-scheme" "DynamicExample"
        ;;

    "test-ios-objc-cocoapods")
        xctest_ios "-workspace" "ios/objc/CocoaPodsExample/CocoaPodsExample.xcworkspace" "-scheme" "CocoaPodsExample"
        ;;

    "test-ios-objc-cocoapods-dynamic")
        xctest_ios "-workspace" "ios/objc/CocoaPodsDynamicExample/CocoaPodsDynamicExample.xcworkspace" "-scheme" "CocoaPodsDynamicExample"
        ;;

    "test-ios-objc-carthage")
        xctest_ios "-project" "ios/objc/CarthageExample/CarthageExample.xcodeproj" "-scheme" "CarthageExample"
        ;;

    "test-ios-swift-dynamic")
        xctest_ios "-project" "ios/swift-$REALM_SWIFT_VERSION/DynamicExample/DynamicExample.xcodeproj" "-scheme" "DynamicExample"
        ;;

    "test-ios-swift-cocoapods")
        xctest_ios "-workspace" "ios/swift-$REALM_SWIFT_VERSION/CocoaPodsExample/CocoaPodsExample.xcworkspace" "-scheme" "CocoaPodsExample"
        ;;

    "test-ios-swift-carthage")
        xctest_ios "-project" "ios/swift-$REALM_SWIFT_VERSION/CarthageExample/CarthageExample.xcodeproj" "-scheme" "CarthageExample"
        ;;

    "test-osx-objc-dynamic")
        xctest_osx -project osx/objc/DynamicExample/DynamicExample.xcodeproj -scheme DynamicExample
        ;;

    "test-osx-objc-cocoapods")
        xctest_osx -workspace osx/objc/CocoaPodsExample/CocoaPodsExample.xcworkspace -scheme CocoaPodsExample
        ;;

    "test-osx-objc-carthage")
        xctest_osx -project osx/objc/CarthageExample/CarthageExample.xcodeproj -scheme CarthageExample
        ;;

    "test-osx-swift-dynamic")
        xctest_osx -project osx/swift-$REALM_SWIFT_VERSION/DynamicExample/DynamicExample.xcodeproj -scheme DynamicExample
        ;;

    "test-osx-swift-carthage")
        xctest_osx -project osx/swift-$REALM_SWIFT_VERSION/CarthageExample/CarthageExample.xcodeproj -scheme CarthageExample
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
