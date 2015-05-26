#!/bin/bash

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  bootstrap:                downloads product dependencies and runs 'pod install'/'carthage bootstrap' where appropriate

  test-all:                 tests all projects in this repo.

  test-ios-objc-static:     tests iOS Objective-C static example.
  test-ios-objc-dynamic:    tests iOS Objective-C dynamic example.
  test-ios-objc-cocoapods:  tests iOS Objective-C CocoaPods example.
  test-ios-objc-carthage:   tests iOS Objective-C Carthage example.
  test-ios-swift-dynamic:   tests iOS Swift dynamic example.
  test-ios-swift-cocoapods: tests iOS Swift CocoaPods example.

  test-osx-objc-dynamic:    tests OS X Objective-C dynamic example.
  test-osx-objc-cocoapods:  tests OS X Objective-C CocoaPods example.
  test-osx-objc-carthage:   tests OS X Objective-C Carthage example.
EOF
}

COMMAND="$1"

xctest() {
    XCODE_COMMAND="$@"
    xcodebuild $XCODE_COMMAND clean build test -sdk iphonesimulator || exit 1
}

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

        pod install --project-directory=ios/objc/CocoaPodsExample
        pod install --project-directory=ios/swift/CocoaPodsExample
        pod install --project-directory=osx/objc/CocoaPodsExample

        ################
        # Carthage
        ################

        # (
        #     cd ios/objc/CarthageExample
        #     carthage bootstrap
        # )
        # (
        #     cd osx/objc/CarthageExample
        #     carthage bootstrap
        # )
        exit 0
        ;;

    ######################################
    # Test
    ######################################

    "test-all")
        ./build.sh test-ios-objc-static || exit 1
        ./build.sh test-ios-objc-dynamic || exit 1
        ./build.sh test-ios-objc-cocoapods || exit 1
        # ./build.sh test-ios-objc-carthage || exit 1
        ./build.sh test-ios-swift-dynamic || exit 1
        ./build.sh test-ios-swift-cocoapods || exit 1

        ./build.sh test-osx-objc-dynamic || exit 1
        ./build.sh test-osx-objc-cocoapods || exit 1
        # ./build.sh test-osx-objc-carthage || exit 1
        exit 0
        ;;

    "test-ios-objc-static")
        xctest "-project" "ios/objc/StaticExample/StaticExample.xcodeproj" "-scheme" "StaticExample"
        exit 0
        ;;

    "test-ios-objc-dynamic")
        xctest "-project" "ios/objc/DynamicExample/DynamicExample.xcodeproj" "-scheme" "DynamicExample"
        exit 0
        ;;

    "test-ios-objc-cocoapods")
        xctest "-workspace" "ios/objc/CocoaPodsExample/CocoaPodsExample.xcworkspace" "-scheme" "CocoaPodsExample"
        exit 0
        ;;

    "test-ios-objc-carthage")
        xctest "-project" "ios/objc/CarthageExample/CarthageExample.xcodeproj" "-scheme" "CarthageExample"
        exit 0
        ;;

    "test-ios-swift-dynamic")
        xctest "-project" "ios/swift/DynamicExample/DynamicExample.xcodeproj" "-scheme" "DynamicExample"
        exit 0
        ;;

    "test-ios-swift-cocoapods")
        xctest "-workspace" "ios/swift/CocoaPodsExample/CocoaPodsExample.xcworkspace" "-scheme" "CocoaPodsExample"
        exit 0
        ;;

    "test-osx-objc-dynamic")
        xcodebuild -project osx/objc/DynamicExample/DynamicExample.xcodeproj -scheme DynamicExample clean build test || exit 1
        exit 0
        ;;

    "test-osx-objc-cocoapods")
        xcodebuild -workspace osx/objc/CocoaPodsExample/CocoaPodsExample.xcworkspace -scheme CocoaPodsExample clean build test || exit 1
        exit 0
        ;;

    "test-osx-objc-carthage")
        xcodebuild -project osx/objc/CarthageExample/CarthageExample.xcodeproj -scheme CarthageExample clean build test || exit 1
        exit 0
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
