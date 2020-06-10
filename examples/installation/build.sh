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
  test-ios-objc-xcframework:       tests iOS Objective-C xcframework example.
  test-ios-objc-cocoapods:         tests iOS Objective-C CocoaPods example.
  test-ios-objc-cocoapods-dynamic: tests iOS Objective-C CocoaPods Dynamic example.
  test-ios-objc-carthage:          tests iOS Objective-C Carthage example.
  test-ios-swift-dynamic:          tests iOS Swift dynamic example.
  test-ios-swift-xcframework:      tests iOS Swift xcframework example.
  test-ios-swift-cocoapods:        tests iOS Swift CocoaPods example.
  test-ios-swift-carthage:         tests iOS Swift Carthage example.
  test-ios-spm:                    tests iOS Swift Package Manager example.

  test-osx-objc-dynamic:           tests macOS Objective-C dynamic example.
  test-osx-objc-xcframework:       tests macOS Objective-C xcframework example.
  test-osx-objc-cocoapods:         tests macOS Objective-C CocoaPods example.
  test-osx-objc-carthage:          tests macOS Objective-C Carthage example.
  test-osx-swift-dynamic:          tests macOS Swift dynamic example.
  test-osx-swift-xcframework:      tests macOS Swift xcframework example.
  test-osx-swift-cocoapods:        tests macOS Swift CocoaPods example.
  test-osx-swift-carthage:         tests macOS Swift Carthage example.
  test-osx-spm:                    tests macOS Swift Package Manager example.

  test-watchos-objc-dynamic:       tests watchOS Objective-C dynamic example.
  test-watchos-objc-xcframework:   tests watchOS Objective-C xcframework example.
  test-watchos-objc-cocoapods:     tests watchOS Objective-C CocoaPods example.
  test-watchos-objc-carthage:      tests watchOS Objective-C Carthage example.
  test-watchos-swift-dynamic:      tests watchOS Swift dynamic example.
  test-watchos-swift-xcframework:  tests watchOS Swift xcframework example.
  test-watchos-swift-cocoapods:    tests watchOS Swift CocoaPods example.
  test-watchos-swift-carthage:     tests watchOS Swift Carthage example.
  test-watchos-spm:                tests watchOS Swift Package Manager example.

  test-tvos-spm:                   tests tvOS Swift Package Manager example.
EOF
}

COMMAND="$1"

# https://github.com/CocoaPods/CocoaPods/issues/7708
export EXPANDED_CODE_SIGN_IDENTITY=''

download_zip_if_needed() {
    LANG="$1"
    local DIRECTORY=realm-$LANG-latest
    if [ ! -d "$DIRECTORY" ]; then
        curl -o "$DIRECTORY".zip -L https://static.realm.io/downloads/"$LANG"/latest
        unzip "$DIRECTORY".zip
        rm "$DIRECTORY".zip
        mv realm-"$LANG"-* "$DIRECTORY"
    fi
}

xcode_version_major() {
    echo "${REALM_XCODE_VERSION%%.*}"
}

xctest() {
    local PLATFORM="$1"
    local LANG="$2"
    local NAME="$3"
    local DIRECTORY="$PLATFORM/$LANG/$NAME"
    if [[ ! -d "$DIRECTORY" ]]; then
        DIRECTORY="${DIRECTORY/swift/swift-$REALM_SWIFT_VERSION}"
    fi
    if [[ $PLATFORM != osx ]]; then
        if [[ $NAME == Carthage* ]]; then
            # Building for Carthage requires that a simulator exist but not any
            # particular one, and having more than one makes xcodebuild
            # significantly slower and some of Carthage's operations time out.
            sh "$(dirname "$0")/../../scripts/reset-simulators.sh" -firstOnly
        else
            # The other installation methods depend on some specific simulators
            # existing so just create all of them to be safe.
            sh "$(dirname "$0")/../../scripts/reset-simulators.sh"
        fi
    fi
    if [[ $NAME == CocoaPods* ]]; then
        pod install --project-directory="$DIRECTORY"
    elif [[ $NAME == Carthage* ]]; then
        (
            cd "$DIRECTORY"
            if [ -n "${REALM_BUILD_USING_LATEST_RELEASE:-}" ]; then
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
    elif [[ $NAME == SwiftPackageManager* ]]; then
        if [ -n "$sha" ]; then
            sed -i '' 's@branch = "master"@branch = "'"$sha"'"@' "$DIRECTORY/$NAME.xcodeproj/project.pbxproj"
        fi
    elif [[ $LANG == swift* ]]; then
        download_zip_if_needed swift
    else
        download_zip_if_needed "$LANG"
    fi
    local destination=()
    if [[ $PLATFORM == ios ]]; then
        simulator_id="$(xcrun simctl list devices | grep -v unavailable | grep -m 1 -o '[0-9A-F\-]\{36\}')"
        xcrun simctl boot "$simulator_id"
        destination=(-destination "id=$simulator_id")
    elif [[ $PLATFORM == watchos ]]; then
        destination=(-sdk watchsimulator)
    fi

    local project=(-project "$DIRECTORY/$NAME.xcodeproj")
    local workspace="$DIRECTORY/$NAME.xcworkspace"
    if [ -d "$workspace" ]; then
        project=(-workspace "$workspace")
    fi
    local code_signing_flags=('CODE_SIGN_IDENTITY=' 'CODE_SIGNING_REQUIRED=NO' 'AD_HOC_CODE_SIGNING_ALLOWED=YES')
    local scheme=(-scheme "$NAME")

    # Ensure that dynamic framework tests try to use the correct version of the prebuilt libraries.
    sed -i '' 's@/swift-[0-9.]*@/swift-'"${REALM_XCODE_VERSION}"'@' "$DIRECTORY/$NAME.xcodeproj/project.pbxproj"

    xcodebuild "${project[@]}" "${scheme[@]}" clean build "${destination[@]}" "${code_signing_flags[@]}"
    if [[ $PLATFORM != watchos ]]; then
        xcodebuild "${project[@]}" "${scheme[@]}" test "${destination[@]}" "${code_signing_flags[@]}"
    fi

    if [[ $PLATFORM != osx ]]; then
        [[ $PLATFORM == 'ios' ]] && SDK=iphoneos || SDK=$PLATFORM
        if [ -d "$workspace" ]; then
            [[ $LANG == 'swift' ]] && scheme=(-scheme RealmSwift) || scheme=(-scheme Realm)
        else
            scheme=()
        fi
        xcodebuild "${project[@]}" "${scheme[@]}" -sdk "$SDK" build "${code_signing_flags[@]}"
    fi
}

swiftpm() {
    PLATFORM="$1"
    cd SwiftPMExample
    xcrun swift build
}

# shellcheck source=../../scripts/swift-version.sh
source "$(dirname "$0")/../../scripts/swift-version.sh"
set_xcode_and_swift_versions # exports REALM_SWIFT_VERSION, REALM_XCODE_VERSION, and DEVELOPER_DIR variables if not already set

PLATFORM=$(echo "$COMMAND" | cut -d - -f 2)
LANGUAGE=$(echo "$COMMAND" | cut -d - -f 3)

case "$COMMAND" in
    "test-all")
        for target in ios-swift-dynamic ios-swift-cocoapods osx-swift-dynamic ios-swift-carthage osx-swift-carthage; do
            ./build.sh test-$target || exit 1
        done
        if (( $(xcode_version_major) >= 11 )); then
            for target in ios osx watchos tvos; do
                ./build.sh test-$target-spm || exit 1
            done
        fi
        ;;

    test-*-*-cocoapods)
        xctest "$PLATFORM" "$LANGUAGE" CocoaPodsExample
        ;;

    test-*-*-cocoapods-dynamic)
        xctest "$PLATFORM" "$LANGUAGE" CocoaPodsDynamicExample
        ;;

    test-*-*-static)
        xctest "$PLATFORM" "$LANGUAGE" StaticExample
        ;;

    test-*-*-dynamic)
        xctest "$PLATFORM" "$LANGUAGE" DynamicExample
        ;;

    test-*-*-xcframework)
        xctest "$PLATFORM" "$LANGUAGE" XCFrameworkExample
        ;;

    test-*-*-carthage)
        xctest "$PLATFORM" "$LANGUAGE" CarthageExample
        ;;

    test-ios-spm)
        xctest "$PLATFORM" swift SwiftPackageManagerExample
        ;;

    test-*-spm)
        swiftpm "$PLATFORM"
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
