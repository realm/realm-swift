#!/bin/bash

##################################################################################
# Custom build tool for Realm Objective-C binding.
#
# (C) Copyright 2011-2022 by realm.io.
##################################################################################

# Warning: pipefail is not a POSIX compatible option, but on macOS it works just fine.
#          macOS uses a POSIX complain version of bash as /bin/sh, but apparently it does
#          not strip away this feature. Also, this will fail if somebody forces the script
#          to be run with zsh.
set -o pipefail
set -e

readonly source_root="$(dirname "$0")"

: "${REALM_CORE_VERSION:=$(sed -n 's/^REALM_CORE_VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")}" # set to "current" to always use the current build

# You can override the xcmode used
: "${XCMODE:=xcodebuild}" # must be one of: xcodebuild (default), xcpretty, xctool

# Provide a fallback value for TMPDIR, relevant for Xcode Bots
: "${TMPDIR:=$(getconf DARWIN_USER_TEMP_DIR)}"

PATH=/usr/libexec:$PATH

if [ -n "${JENKINS_HOME}" ]; then
    XCPRETTY_PARAMS=(--no-utf --report junit --output build/reports/junit.xml)
    CODESIGN_PARAMS=(CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO)
fi

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  clean:                clean up/remove all generated files
  download-core:        downloads core library (binary version)
  build [platforms]:    builds xcframeworks for Realm and RealmSwift for given platforms (default all)
  build-static [plats]: builds static xcframework for Realm platforms (default all)
  analyze-osx:          analyzes macOS framework

  test:                 tests all iOS and macOS frameworks
  test-all:             tests all iOS and macOS frameworks in both Debug and Release configurations
  test-ios-static:      tests static iOS framework on 32-bit and 64-bit simulators
  test-ios-dynamic:     tests dynamic iOS framework on 32-bit and 64-bit simulators
  test-ios-swift:       tests RealmSwift iOS framework on 32-bit and 64-bit simulators
  test-ios-devices:     tests ObjC & Swift iOS frameworks on all attached iOS devices
  test-ios-devices-objc:  tests ObjC iOS framework on all attached iOS devices
  test-ios-devices-swift: tests Swift iOS framework on all attached iOS devices
  test-tvos:            tests tvOS framework
  test-tvos-swift:      tests RealmSwift tvOS framework
  test-tvos-devices:    tests ObjC & Swift tvOS frameworks on all attached tvOS devices
  test-osx:             tests macOS framework
  test-osx-swift:       tests RealmSwift macOS framework
  test-catalyst:        tests Mac Catalyst framework
  test-catalyst-swift:  tests RealmSwift Mac Catalyst framework
  test-swiftpm:         tests ObjC and Swift macOS frameworks via SwiftPM
  test-swiftui-ios:         tests SwiftUI framework UI tests
  test-swiftui-server-osx:  tests Server Sync in SwiftUI
  verify:               verifies docs, osx, osx-swift, ios-static, ios-dynamic, ios-swift, ios-device, swiftui-ios in both Debug and Release configurations, swiftlint, ios-xcode-spm
  verify-osx-object-server:  downloads the Realm Object Server and runs the Objective-C and Swift integration tests

  docs:                 builds docs in docs/output
  examples:             builds all examples
  examples-ios:         builds all static iOS examples
  examples-ios-swift:   builds all Swift iOS examples
  examples-osx:         builds all macOS examples

  get-version:          get the current version
  get-ioplatformuuid:   get io platform uuid
  set-version version:  set the version
  set-core-version version: set the version of core to use

  package platform:     build release package for the given platform
  package-release:      assemble per-platform release packages into a combined one
  package-docs:         build release package the docs
  package-examples:     build release package the examples
  package-test-examples: test a built examples release package
  test-package-release: locally build a complete release package for all platforms

  publish-tag branch:   create and push a git tag for the given branch
  publish-github:       create a Github release for the currently checked-out tag
  publish-docs:         publish a built docs release to the website
  publish-cocoapods tag: publish the requested tag to CocoaPods

argument:
  version: version in the x.y.z format
  platform: exactly one of "osx ios watchos tvos visionos"
  platforms: one or more of "osx ios watchos tvos visionos"

environment variables:
  XCMODE: xcodebuild (default), xcpretty or xctool
  CONFIGURATION: Debug, Release (default), or Static
  REALM_CORE_VERSION: version in x.y.z format or "current" to use local build
  REALM_EXTRA_BUILD_ARGUMENTS: additional arguments to pass to the build tool
  REALM_XCODE_VERSION: the version number of Xcode to use (e.g.: 13.3.1)
  REALM_XCODE_OLDEST_VERSION: the version number of oldest available Xcode to use (e.g.: 12.4)
  REALM_XCODE_LATEST_VERSION: the version number of latest available Xcode to use (e.g.: 13.3.1)
EOF
}

######################################
# Xcode Helpers
######################################

xcode_version_major() {
    echo "${REALM_XCODE_VERSION%%.*}"
}

xcode() {
    mkdir -p build/DerivedData
    CMD="xcodebuild -IDECustomDerivedDataLocation=build/DerivedData"
    echo "Building with command: $CMD $*"
    xcodebuild -IDECustomDerivedDataLocation=build/DerivedData "$@"
}

xc() {
    # Logs xcodebuild output in realtime
    : "${NSUnbufferedIO:=YES}"
    if [[ "$XCMODE" == "xcodebuild" ]]; then
        xcode "$@" "${REALM_EXTRA_BUILD_ARGUMENTS[@]}"
    elif [[ "$XCMODE" == "xcpretty" ]]; then
        mkdir -p build
        xcode "$@" "${REALM_EXTRA_BUILD_ARGUMENTS[@]}" | tee build/build.log | xcpretty -c "${XCPRETTY_PARAMS[@]}" || {
            echo "The raw xcodebuild output is available in build/build.log"
            exit 1
        }
    elif [[ "$XCMODE" == "xctool" ]]; then
        xctool "$@" "${REALM_EXTRA_BUILD_ARGUMENTS[@]}"
    fi
}

xctest() {
  local scheme="$1"
  xc -scheme "$scheme" "${@:2}" build-for-testing
  xc -scheme "$scheme" "${@:2}" test-without-building
}

build_combined() {
    local product="$1"
    local platform="$2"
    local config="$CONFIGURATION"

    local config_suffix simulator_suffix destination build_args
    case "$platform" in
        osx)
            destination='generic/platform=macOS'
            config_suffix=
            ;;
        ios)
            destination='generic/platform=iOS'
            config_suffix=-iphoneos
            simulator_suffix=iphonesimulator
            ;;
        watchos)
            destination='generic/platform=watchOS'
            config_suffix=-watchos
            simulator_suffix=watchsimulator
            ;;
        tvos)
            destination='generic/platform=tvOS'
            config_suffix=-appletvos
            simulator_suffix=appletvsimulator
            ;;
        visionos)
            destination='generic/platform=visionOS'
            config_suffix=-xros
            simulator_suffix=xrsimulator
            ;;
        catalyst)
            destination='generic/platform=macOS,variant=Mac Catalyst'
            config_suffix=-maccatalyst
            ;;
    esac

    build_args=(-scheme "$product" -configuration "$config" build REALM_HIDE_SYMBOLS=YES)

    # Derive build paths
    local build_products_path="build/DerivedData/Realm/Build/Products"
    local product_name="$product.framework"
    local os_path="$build_products_path/$config${config_suffix}/$product_name"
    local simulator_path="$build_products_path/$config-$simulator_suffix/$product_name"
    local out_path="build/$config/$platform"
    local xcframework_path="$out_path/$product.xcframework"

    # Build for each platform
    xc -destination "$destination" "${build_args[@]}"
    simulator_framework=()
    if [[ -n "$simulator_suffix" ]]; then
        xc -destination "$destination Simulator" "${build_args[@]}"
        simulator_framework+=(-framework "$simulator_path")
    fi

    # Create the xcframework
    rm -rf "$xcframework_path"
    xcodebuild -create-xcframework -allow-internal-distribution -output "$xcframework_path" \
        -framework "$os_path" "${simulator_framework[@]}"
}

clean_retrieve() {
  mkdir -p "$2"
  rm -rf "$2/$3"
  cp -R "$1" "$2"
}

plist_get() {
    /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2> /dev/null
}

######################################
# Device Test Helper
######################################

test_devices() {
    local serial_numbers=()
    local awk_script="
    /^ +Vendor ID: / { is_apple = 0; }
    /^ +Vendor ID: 0x05[aA][cC] / { is_apple = 1; }
    /^ +Serial Number: / {
        if (is_apple) {
            match(\$0, /^ +Serial Number: /);
            print substr(\$0, RLENGTH + 1);
        }
    }
    "
    local serial_numbers_text=$(/usr/sbin/system_profiler SPUSBDataType | /usr/bin/awk "$awk_script")
    while read -r number; do
        if [[ "$number" != "" ]]; then
            serial_numbers+=("$number")
        fi
    done <<< "$serial_numbers_text"
    if [[ ${#serial_numbers[@]} == 0 ]]; then
        echo "At least one iOS/tvOS device must be connected to this computer to run device tests"
        if [ -z "${JENKINS_HOME}" ]; then
            # Don't fail if running locally and there's no device
            exit 0
        fi
        exit 1
    fi
    local sdk="$1"
    local scheme="$2"
    local configuration="$3"
    local failed=0
    for device in "${serial_numbers[@]}"; do
        xc -scheme "$scheme" -configuration "$configuration" -destination "id=$device" -sdk "$sdk" test || failed=1
    done
    return $failed
}

######################################
# Docs
######################################

build_docs() {
    local language="$1"
    local version=$(sh build.sh get-version)

    local xcodebuild_arguments="--objc,Realm/Realm.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path),-I,$(pwd)"
    local module="Realm"
    local objc="--objc"

    if [[ "$language" == "swift" ]]; then
        xcodebuild_arguments="-scheme,RealmSwift"
        module="RealmSwift"
        objc=""
    fi

    jazzy \
      "${objc}" \
      --clean \
      --author Realm \
      --author_url https://docs.mongodb.com/realm-sdks \
      --github_url https://github.com/realm/realm-swift \
      --github-file-prefix "https://github.com/realm/realm-swift/tree/v${version}" \
      --module-version "${version}" \
      --xcodebuild-arguments "${xcodebuild_arguments}" \
      --module "${module}" \
      --root-url "https://docs.mongodb.com/realm-sdks/${language}/${version}/" \
      --output "docs/${language}_output" \
      --head "$(cat docs/custom_head.html)" \
      --exclude 'RealmSwift/Impl/*'
}

######################################
# Input Validation
######################################

if [ "$#" -eq 0 ] || [ "$#" -gt 3 ]; then
    usage
    exit 1
fi

######################################
# Variables
######################################

COMMAND="$1"

# Use Debug config if command ends with -debug, otherwise default to Release
case "$COMMAND" in
    *-debug)
        COMMAND="${COMMAND%-debug}"
        CONFIGURATION="Debug"
        ;;
    *-static)
        COMMAND="${COMMAND%-static}"
        CONFIGURATION="Static"
        ;;
esac
export CONFIGURATION=${CONFIGURATION:-Release}

# Pre-choose Xcode version for those operations that do not override it
REALM_XCODE_VERSION=${xcode_version:-$REALM_XCODE_VERSION}
source "${source_root}/scripts/swift-version.sh"
set_xcode_version

######################################
# Commands
######################################

case "$COMMAND" in

    ######################################
    # Clean
    ######################################
    "clean")
        find . -type d -name build -exec rm -r "{}" +
        exit 0
        ;;

    ######################################
    # Dependencies
    ######################################
    "download-core")
        sh scripts/download-core.sh
        exit 0
        ;;

    "setup-baas")
        ruby Realm/ObjectServerTests/setup_baas.rb
        exit 0
        ;;

    "prelaunch-simulator")
        if [ -z "$REALM_SKIP_PRELAUNCH" ]; then
            sh "${source_root}/scripts/reset-simulators.sh" "$1"
        fi
        ;;

    ######################################
    # Building
    ######################################
    "build")
        sh build.sh xcframework
        exit 0
        ;;

    "ios")
        build_combined Realm ios
        exit 0
        ;;

    "ios-swift")
        build_combined Realm ios
        build_combined RealmSwift ios
        exit 0
        ;;

    "watchos")
        build_combined Realm watchos
        exit 0
        ;;

    "watchos-swift")
        build_combined Realm watchos
        build_combined RealmSwift watchos
        exit 0
        ;;

    "tvos")
        build_combined Realm tvos
        exit 0
        ;;

    "tvos-swift")
        build_combined Realm tvos
        build_combined RealmSwift tvos
        exit 0
        ;;

    "osx")
        build_combined Realm osx
        exit 0
        ;;

    "osx-swift")
        build_combined Realm osx
        build_combined RealmSwift osx
        exit 0
        ;;

    "catalyst")
        build_combined Realm catalyst
        ;;

    "catalyst-swift")
        build_combined Realm catalyst
        build_combined RealmSwift catalyst
        ;;

    "visionos")
        build_combined Realm visionos
        ;;

    "visionos-swift")
        build_combined Realm visionos
        build_combined RealmSwift visionos
        ;;

    "xcframework")
        # Build all of the requested frameworks
        shift
        if (( $(xcode_version_major) < 15 )); then
            PLATFORMS="${*:-osx ios watchos tvos catalyst}"
        else
            PLATFORMS="${*:-osx ios watchos tvos catalyst visionos}"
        fi
        for platform in $PLATFORMS; do
            sh build.sh "$platform-swift"
        done

        # Assemble them into xcframeworks
        rm -rf "build/$CONFIGURATION/"*.xcframework
        find "build/$CONFIGURATION" -name 'Realm.framework' \
            | sed 's/.*/-framework &/' \
            | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "build/$CONFIGURATION/Realm.xcframework"
        find "build/$CONFIGURATION" -name 'RealmSwift.framework' \
            | sed 's/.*/-framework &/' \
            | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "build/$CONFIGURATION/RealmSwift.xcframework"

        # Because we have a module named Realm and a type named Realm we need to manually resolve the naming
        # collisions that are happening. These collisions create a red herring which tells the user the xcframework
        # was compiled with an older Swift version and is not compatible with the current compiler.
        find "build/$CONFIGURATION/RealmSwift.xcframework" -name "*.swiftinterface" \
            -exec sed -i '' 's/Realm\.//g' {} \; \
            -exec sed -i '' 's/import Private/import Realm.Private\nimport Realm.Swift/g' {} \; \
            -exec sed -i '' 's/RealmSwift.Configuration/RealmSwift.Realm.Configuration/g' {} \; \
            -exec sed -i '' 's/extension Configuration/extension Realm.Configuration/g' {} \; \
            -exec sed -i '' 's/RealmSwift.Error[[:>:]]/RealmSwift.Realm.Error/g' {} \; \
            -exec sed -i '' 's/extension Error/extension Realm.Error/g' {} \; \
            -exec sed -i '' 's/RealmSwift.AsyncOpenTask/RealmSwift.Realm.AsyncOpenTask/g' {} \; \
            -exec sed -i '' 's/RealmSwift.UpdatePolicy/RealmSwift.Realm.UpdatePolicy/g' {} \; \
            -exec sed -i '' 's/RealmSwift.Notification[[:>:]]/RealmSwift.Realm.Notification/g' {} \; \
            -exec sed -i '' 's/RealmSwift.OpenBehavior/RealmSwift.Realm.OpenBehavior/g' {} \; \
            -exec sed -i '' 's/τ_1_0/V/g' {} \; # Generics will use τ_1_0 which needs to be changed to the correct type name.

        exit 0
        ;;

    "verify-xcframework-evolution-mode")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        unset REALM_SWIFT_VERSION

        # Build with the oldest supported Xcode version
        REALM_XCODE_VERSION=$REALM_XCODE_OLDEST_VERSION sh build.sh xcframework osx

        # Try to import the built framework using the newest supported version
        cd examples/installation
        REALM_XCODE_VERSION=$REALM_XCODE_LATEST_VERSION ./build.rb osx xcframework

        exit 0
        ;;

    ######################################
    # Analysis
    ######################################

    "analyze-osx")
        xc -scheme Realm -configuration "$CONFIGURATION" analyze
        exit 0
        ;;

    ######################################
    # Testing
    ######################################
    "test")
        set +e # Run both sets of tests even if the first fails
        failed=0
        sh build.sh test-ios || failed=1
        sh build.sh test-ios-swift || failed=1
        sh build.sh test-ios-devices || failed=1
        sh build.sh test-tvos-devices || failed=1
        sh build.sh test-osx || failed=1
        sh build.sh test-osx-swift || failed=1
        sh build.sh test-catalyst || failed=1
        sh build.sh test-catalyst-swift || failed=1
        exit $failed
        ;;

    "test-all")
        set +e
        failed=0
        sh build.sh test || failed=1
        sh build.sh test-debug || failed=1
        exit $failed
        ;;

    "test-ios")
        xctest Realm -configuration "$CONFIGURATION" -sdk iphonesimulator -destination 'name=iPhone 8'
        exit 0
        ;;

    "test-ios-swift")
        xctest RealmSwift -configuration "$CONFIGURATION" -sdk iphonesimulator -destination 'name=iPhone 8'
        exit 0
        ;;

    "test-ios-devices")
        failed=0
        trap "failed=1" ERR
        sh build.sh test-ios-devices-objc
        sh build.sh test-ios-devices-swift
        exit $failed
        ;;

    "test-ios-devices-objc")
        test_devices iphoneos "Realm" "$CONFIGURATION"
        exit $?
        ;;

    "test-ios-devices-swift")
        test_devices iphoneos "RealmSwift" "$CONFIGURATION"
        exit $?
        ;;

    "test-tvos")
        destination="Apple TV"
        xctest Realm -configuration "$CONFIGURATION" -sdk appletvsimulator -destination "name=$destination"
        exit $?
        ;;

    "test-tvos-swift")
        destination="Apple TV"
        xctest RealmSwift -configuration "$CONFIGURATION" -sdk appletvsimulator -destination "name=$destination"
        exit $?
        ;;

    "test-tvos-devices")
        test_devices appletvos TestHost "$CONFIGURATION"
        ;;

    "test-osx")
        COVERAGE_PARAMS=()
        if [[ "$CONFIGURATION" == "Debug" ]]; then
            COVERAGE_PARAMS=(GCC_GENERATE_TEST_COVERAGE_FILES=YES GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES)
        fi
        xctest Realm -configuration "$CONFIGURATION" "${COVERAGE_PARAMS[@]}" -destination "platform=macOS,arch=$(uname -m)"
        exit 0
        ;;

    "test-osx-swift")
        xctest RealmSwift -configuration "$CONFIGURATION" -destination "platform=macOS,arch=$(uname -m)"
        exit 0
        ;;

    "test-osx-object-server")
        xctest 'Object Server Tests' -configuration "$CONFIGURATION" -sdk macosx -destination "platform=macOS,arch=$(uname -m)"
        exit 0
        ;;

    test-ios-xcode-spm)
        cd examples/installation
        ./build.rb ios spm
        exit 0
        ;;

    test-swiftpm*)
        SANITIZER=$(echo "$COMMAND" | cut -d - -f 3)
        # FIXME: throwing an exception from a property getter corrupts Swift's
        # runtime exclusivity checking state. Unfortunately, this is something
        # we do a lot in tests.
        SWIFT_TEST_FLAGS=(-Xcc -g0 -Xswiftc -enforce-exclusivity=none)
        if [ -n "$SANITIZER" ]; then
            SWIFT_TEST_FLAGS+=(--sanitize "$SANITIZER")
            export ASAN_OPTIONS='check_initialization_order=true:detect_stack_use_after_return=true'
        fi
        xcrun swift package resolve
        xcrun swift test --configuration "$(echo "$CONFIGURATION" | tr "[:upper:]" "[:lower:]")" "${SWIFT_TEST_FLAGS[@]}"
        exit 0
        ;;

    "test-swiftui-ios")
        xctest 'SwiftUITestHost' -configuration "$CONFIGURATION" -sdk iphonesimulator -destination 'name=iPhone 8'
        exit 0
        ;;

    "test-catalyst")
        xctest Realm -configuration "$CONFIGURATION" -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGN_IDENTITY=''
        exit 0
        ;;

    "test-catalyst-swift")
        xctest RealmSwift -configuration "$CONFIGURATION" -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGN_IDENTITY=''
        exit 0
        ;;

    "test-swiftui-server-osx")
        xctest 'SwiftUISyncTestHost' -configuration "$CONFIGURATION" -sdk macosx -destination 'platform=macOS'
        exit 0
        ;;

    ######################################
    # Full verification
    ######################################
    "verify")
        sh build.sh verify-cocoapods
        sh build.sh verify-docs
        sh build.sh verify-osx
        sh build.sh verify-osx-debug
        sh build.sh verify-osx-swift
        sh build.sh verify-osx-swift-debug
        sh build.sh verify-ios-static
        sh build.sh verify-ios-static-debug
        sh build.sh verify-ios-dynamic
        sh build.sh verify-ios-dynamic-debug
        sh build.sh verify-ios-swift
        sh build.sh verify-ios-swift-debug
        sh build.sh verify-ios-device-objc
        sh build.sh verify-ios-device-swift
        sh build.sh verify-watchos
        sh build.sh verify-tvos
        sh build.sh verify-tvos-debug
        sh build.sh verify-tvos-device
        sh build.sh verify-swiftlint
        sh build.sh verify-swiftpm
        sh build.sh verify-osx-object-server
        sh build.sh verify-catalyst
        sh build.sh verify-catalyst-swift
        sh build.sh verify-swiftui-ios
        sh build.sh verify-swiftui-server-osx
        ;;

    "verify-cocoapods")
        export REALM_TEST_BRANCH="$sha"
        if [[ -d .git ]]; then
          # Verify the current branch, unless one was already specified in the sha environment variable.
          if [[ -z $sha ]]; then
            export REALM_TEST_BRANCH=$(git rev-parse --abbrev-ref HEAD)
          fi

          if [[ $(git log -1 '@{push}..') != "" ]] || ! git diff-index --quiet HEAD; then
            echo "WARNING: verify-cocoapods will test the latest revision of $sha found on GitHub."
            echo "         Any unpushed local changes will not be tested."
            echo ""
            sleep 1
          fi
        fi

        cd examples/installation
        ./build.rb ios cocoapods static
        ./build.rb ios cocoapods dynamic
        ./build.rb osx cocoapods
        ./build.rb tvos cocoapods
        ./build.rb watchos cocoapods
        ./build.rb catalyst cocoapods
        ;;

    verify-cocoapods-ios-dynamic)
        cd examples/installation
        REALM_TEST_BRANCH="$sha" ./build.rb ios cocoapods
        ;;

    verify-cocoapods-*)
        PLATFORM=$(echo "$COMMAND" | cut -d - -f 3)
        cd examples/installation
        REALM_TEST_BRANCH="$sha" ./build.rb "$PLATFORM" cocoapods
        ;;

    "verify-osx-encryption")
        REALM_ENCRYPT_ALL=YES sh build.sh test-osx
        exit 0
        ;;

    "verify-osx")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/osx/objc/RealmExamples.xcworkspace" \
            sh build.sh test-osx
        sh build.sh examples-osx

        (
            cd examples/osx/objc/build/DerivedData/RealmExamples/Build/Products/$CONFIGURATION
            DYLD_FRAMEWORK_PATH=. ./JSONImport >/dev/null
        )
        exit 0
        ;;

    "verify-osx-swift-evolution")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        sh build.sh test-osx-swift
        exit 0
        ;;

    "verify-ios-static")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/ios/objc/RealmExamples.xcworkspace" \
            sh build.sh test-ios-static
        sh build.sh examples-ios
        ;;

    "verify-ios-swift")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/ios/swift/RealmExamples.xcworkspace" \
            sh build.sh test-ios-swift
        sh build.sh examples-ios-swift
        ;;

    "verify-ios-swift-evolution")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        sh build.sh test-ios-swift
        exit 0
        ;;

    "verify-docs")
        sh build.sh docs
        for lang in swift objc; do
            undocumented="docs/${lang}_output/undocumented.json"
            if ruby -rjson -e "j = JSON.parse(File.read('docs/${lang}_output/undocumented.json')); exit j['warnings'].length != 0"; then
              echo "Undocumented Realm $lang declarations:"
              cat "$undocumented"
              exit 1
            fi
        done
        exit 0
        ;;

    "verify-watchos")
        sh build.sh watchos-swift
        exit 0
        ;;

    "verify-tvos")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/tvos/objc/RealmExamples.xcworkspace" \
            sh build.sh test-tvos
        sh build.sh examples-tvos
        exit 0
        ;;

    "verify-tvos-swift")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/tvos/swift/RealmExamples.xcworkspace" \
            sh build.sh test-tvos-swift
        sh build.sh examples-tvos-swift
        exit 0
        ;;

    "verify-tvos-swift-evolution")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        sh build.sh test-tvos-swift
        exit 0
        ;;

    "verify-swiftlint")
        swiftlint lint --strict
        exit 0
        ;;

    verify-swiftpm*)
        sh build.sh "test-$(echo "$COMMAND" | cut -d - -f 2-)"
        exit 0
        ;;

    "verify-xcframework")
        sh build.sh xcframework osx
        exit 0
        ;;

    "verify-ios-xcode-spm")
        REALM_TEST_BRANCH="$sha" sh build.sh test-ios-xcode-spm
        exit 0
        ;;

    verify-*)
        sh build.sh "test-$(echo "$COMMAND" | cut -d - -f 2-)"
        exit 0
        ;;

    ######################################
    # Docs
    ######################################
    "docs")
        build_docs objc
        build_docs swift
        exit 0
        ;;

    ######################################
    # Examples
    ######################################
    "examples")
        sh build.sh clean
        sh build.sh prelaunch-simulator
        export REALM_SKIP_PRELAUNCH=1
        sh build.sh examples-ios
        sh build.sh examples-ios-swift
        sh build.sh examples-osx
        sh build.sh examples-tvos
        sh build.sh examples-tvos-swift
        exit 0
        ;;

    "examples-ios")
        workspace="examples/ios/objc/RealmExamples.xcworkspace"
        examples="Simple TableView Migration Backlink GroupedTableView Encryption Draw"
        versions="0 1 2 3 4 5"
        for example in $examples; do
            if [ "$example" = "Migration" ]; then
                # The migration example needs to be built for each schema version to ensure each compiles.
                for version in $versions; do
                    xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator build ARCHS=x86_64 "${CODESIGN_PARAMS[@]}" GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) SCHEMA_VERSION_$version"
                done
            else
                xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator build ARCHS=x86_64 "${CODESIGN_PARAMS[@]}"
            fi
        done
        if [ -n "${JENKINS_HOME}" ]; then
            xc -workspace "$workspace" -scheme Extension -configuration "$CONFIGURATION" -sdk iphonesimulator build ARCHS=x86_64 "${CODESIGN_PARAMS[@]}"
        fi

        exit 0
        ;;

    "examples-ios-swift")
        workspace="examples/ios/swift/RealmExamples.xcworkspace"
        if [[ ! -d "$workspace" ]]; then
            workspace="${workspace/swift/swift-$REALM_XCODE_VERSION}"
        fi

        examples="Simple TableView Migration Backlink GroupedTableView Encryption AppClip AppClipParent"
        versions="0 1 2 3 4 5"
        for example in $examples; do
            if [ "$example" = "Migration" ]; then
                # The migration example needs to be built for each schema version to ensure each compiles.
                for version in $versions; do
                    xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator build ARCHS=x86_64 "${CODESIGN_PARAMS[@]}" OTHER_SWIFT_FLAGS="\$(OTHER_SWIFT_FLAGS) -DSCHEMA_VERSION_$version"
                done
            else
                xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator build ARCHS=x86_64 "${CODESIGN_PARAMS[@]}"
            fi
        done

        exit 0
        ;;

    "examples-osx")
        xc -workspace examples/osx/objc/RealmExamples.xcworkspace \
           -scheme JSONImport -configuration "${CONFIGURATION}" \
           -destination "platform=macOS,arch=$(uname -m)" \
           build "${CODESIGN_PARAMS[@]}"
        ;;

    "examples-tvos")
        workspace="examples/tvos/objc/RealmExamples.xcworkspace"
        examples="DownloadCache PreloadedData"
        for example in $examples; do
            xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk appletvsimulator build ARCHS=x86_64 "${CODESIGN_PARAMS[@]}"
        done

        exit 0
        ;;

    "examples-tvos-swift")
        workspace="examples/tvos/swift/RealmExamples.xcworkspace"
        if [[ ! -d "$workspace" ]]; then
            workspace="${workspace/swift/swift-$REALM_XCODE_VERSION}"
        fi
        examples="DownloadCache PreloadedData"
        for example in $examples; do
            xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk appletvsimulator build ARCHS=x86_64 "${CODESIGN_PARAMS[@]}"
        done

        exit 0
        ;;

    ######################################
    # Versioning
    ######################################
    "get-version")
        plist_get 'Realm/Realm-Info.plist' 'CFBundleShortVersionString'
        exit 0
        ;;

    "get-ioplatformuuid")
        ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}'
        exit 0
        ;;

    "set-version")
        realm_version="$2"
        version_files="Realm/Realm-Info.plist"

        if [ -z "$realm_version" ]; then
            echo "You must specify a version."
            exit 1
        fi
        # The bundle version can contain only three groups of digits separated by periods,
        # so strip off any -beta.x tag from the end of the version string.
        bundle_version=$(echo "$realm_version" | cut -d - -f 1)
        for version_file in $version_files; do
            PlistBuddy -c "Set :CFBundleVersion $bundle_version" "$version_file"
            PlistBuddy -c "Set :CFBundleShortVersionString $realm_version" "$version_file"
        done
        sed -i '' "s/^VERSION=.*/VERSION=$realm_version/" dependencies.list
        sed -i '' "s/^let cocoaVersion =.*/let cocoaVersion = Version(\"$realm_version\")/" Package.swift
        sed -i '' "s/x.y.z Release notes (yyyy-MM-dd)/$realm_version Release notes ($(date '+%Y-%m-%d'))/" CHANGELOG.md

        exit 0
        ;;

    "set-core-version")
        new_version="$2"
        old_version="$(sed -n 's/^REALM_CORE_VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"

        sed -i '' "s/^REALM_CORE_VERSION=.*/REALM_CORE_VERSION=$new_version/" dependencies.list
        sed -i '' "s/^let coreVersion =.*/let coreVersion = Version(\"$new_version\")/" Package.swift
        sed -i '' "s/Upgraded realm-core from ? to ?/Upgraded realm-core from $old_version to $new_version/" CHANGELOG.md

        exit 0
        ;;

    ######################################
    # Continuous Integration
    ######################################

    "ci-pr")
        mkdir -p build/reports
        export REALM_DISABLE_ANALYTICS=1
        export REALM_DISABLE_UPDATE_CHECKER=1
        # FIXME: Re-enable once CI can properly unlock the keychain
        export REALM_DISABLE_METADATA_ENCRYPTION=1

        # Make sure there aren't any lingering server processes from previous jobs
        pkill -9 mongo stitch || true

        # strip off the ios|tvos version specifier, e.g. the last part of: `ios-device-objc-ios8`
        if [[ "$target" =~ ^((ios|tvos)-device(-(objc|swift))?)(-(ios|tvos)[[:digit:]]+)?$ ]]; then
            export target=${BASH_REMATCH[1]}
        fi

        if [ "$target" = "docs" ]; then
            sh build.sh verify-docs
        elif [ "$target" = "swiftlint" ]; then
            sh build.sh verify-swiftlint
        else
            export sha=$GITHUB_PR_SOURCE_BRANCH
            export REALM_EXTRA_BUILD_ARGUMENTS='GCC_GENERATE_DEBUGGING_SYMBOLS=NO -allowProvisioningUpdates'
            if [[ "$target" = *ios* ]] || [[ "$target" = *tvos* ]] || [[ "$target" = *watchos* ]]; then
                sh build.sh prelaunch-simulator "$target"
            fi
            export REALM_SKIP_PRELAUNCH=1

            if [[ "$target" = *"server"* ]] || [[ "$target" = "swiftpm"* ]]; then
                mkdir .baas
                mv build/stitch .baas
                source "$(brew --prefix nvm)/nvm.sh" --no-use
                nvm install 16.5.0
                sh build.sh setup-baas
            fi

            # Reset CoreSimulator.log
            mkdir -p ~/Library/Logs/CoreSimulator
            echo > ~/Library/Logs/CoreSimulator/CoreSimulator.log

            failed=0
            sh build.sh "verify-$target" 2>&1 | tee build/build.log | xcpretty -r junit -o build/reports/junit.xml || failed=1
            if [ "$failed" = "1" ] && grep -E 'DTXProxyChannel|DTXChannel|out of date and needs to be rebuilt|operation never finished bootstrapping|thread is already initializing this class' build/build.log ; then
                echo "Known Xcode error detected. Running job again."
                if grep -E 'out of date and needs to be rebuilt' build/build.log; then
                    rm -rf build/DerivedData
                fi
                failed=0
                sh build.sh "verify-$target" | tee build/build.log | xcpretty -r junit -o build/reports/junit.xml || failed=1
            elif [ "$failed" = "1" ] && tail ~/Library/Logs/CoreSimulator/CoreSimulator.log | grep -E "Operation not supported|Failed to lookup com.apple.coreservices.lsuseractivity.simulatorsupport"; then
                echo "Known Xcode error detected. Running job again."
                failed=0
                sh build.sh "verify-$target" | tee build/build.log | xcpretty -r junit -o build/reports/junit.xml || failed=1
            fi
            if [ "$failed" = "1" ]; then
                set +e
                printf "%s" "\n\n***\nbuild/build.log\n***\n\n" && cat build/build.log
                printf "%s" "\n\n***\nCoreSimulator.log\n***\n\n" && cat ~/Library/Logs/CoreSimulator/CoreSimulator.log
                exit 1
            fi
        fi

        if [ "$target" = "osx" ] && [ "$configuration" = "Debug" ]; then
          gcovr -r . -f ".*Realm.*" -e ".*Tests.*" -e ".*core.*" --xml > build/reports/coverage-report.xml
          WS=$(pwd | sed "s/\//\\\\\//g")
          sed -i ".bak" "s/<source>\./<source>${WS}/" build/reports/coverage-report.xml
        fi
        ;;

    ######################################
    # Release packaging
    ######################################

    "package-docs")
        sh scripts/reset-simulators.sh
        sh build.sh docs
        cd docs
        zip -r realm-docs.zip objc_output swift_output
        ;;

    "package-examples")
        ./scripts/package_examples.rb
        zip --symlinks -r realm-examples.zip examples -x "examples/installation/*"
        ;;

    "package-build-scripts")
        zip -r build-scripts.zip build.sh dependencies.list scripts examples/installation
        ;;

    "package-test-examples")
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        dir="realm-swift-${VERSION}"
        unzip "${dir}.zip"

        cp "$0" "${dir}"
        cp -r "${source_root}/scripts" "${dir}"
        cd "${dir}"
        sh build.sh examples-ios
        sh build.sh examples-tvos
        sh build.sh examples-osx
        sh build.sh examples-ios-swift
        sh build.sh examples-tvos-swift
        cd ..
        rm -rf "${dir}"
        ;;

    "package")
        PLATFORM="$2"
        sh build.sh "$PLATFORM-swift"
        if [[ "$PLATFORM" == ios ]]; then
            sh build.sh "$PLATFORM-static"
        else
            mkdir -p Static
        fi

        cd build
        zip --symlinks -r "realm-$PLATFORM-$REALM_XCODE_VERSION.zip" "Release/$PLATFORM" "Static/$PLATFORM"
        ;;

    "package-release")
        tempdir="$(mktemp -d "$TMPDIR/realm-release-package.XXXX")"
        extract_dir="$(mktemp -d "$TMPDIR/realm-release-package.XXXX")"
        version="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        package_dir="${tempdir}/realm-swift-${version}"

        mkdir -p "${package_dir}"

        xcode_versions=$(find . -name 'realm-*-1*.zip' -maxdepth 1 | sed 's@./realm-[a-z]*-\(.*\).zip@\1@' | sort -u --version-sort)
        for xcode_version in $xcode_versions; do
            rm -rf "${extract_dir}"
            mkdir -p "${extract_dir}"
            for platform in osx ios watchos tvos catalyst; do
                unzip "realm-$platform-$xcode_version.zip" -d "${extract_dir}/${platform}"
            done
            if (( "${xcode_version%%.*}" >= 15 )); then
                unzip "realm-visionos-$xcode_version.zip" -d "${extract_dir}/visionos"
            fi

            find "${extract_dir}" -name 'RealmSwift.framework' -path "*/Release/*" \
                | sed 's/.*/-framework &/' \
                | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "${package_dir}/${xcode_version}/RealmSwift.xcframework"
        done
        find "${extract_dir}" -name 'Realm.framework' -path "*/Release/*" \
            | sed 's/.*/-framework &/' \
            | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "${package_dir}/Realm.xcframework"
        find "${extract_dir}" -name 'Realm.framework' -path "*/Static/*" \
            | sed 's/.*/-framework &/' \
            | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "${package_dir}/static/Realm.xcframework"

        cp "${WORKSPACE}/LICENSE" "${package_dir}"

        (
            cd "${package_dir}"
            unzip "${WORKSPACE}/realm-examples.zip"
        )

        for lang in objc swift; do
            cat > "${package_dir}/${lang}-docs.webloc" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>URL</key>
    <string>https://www.mongodb.com/docs/realm-sdks/${lang}/${version}</string>
</dict>
</plist>
EOF
        done

        (
          cd "${tempdir}"
          zip --symlinks -r "realm-swift-${version}.zip" "realm-swift-${version}"
          mv "realm-swift-${version}.zip" "${WORKSPACE}"
        )
        ;;

    "test-package-release")
        # Generate a release package locally for testing purposes
        # Real releases should always be done via Jenkins
        if [ -z "${WORKSPACE}" ]; then
            echo 'WORKSPACE must be set to a directory to assemble the release in'
            exit 1
        fi
        if [ -d "${WORKSPACE}" ]; then
            echo 'WORKSPACE directory should not already exist'
            exit 1
        fi

        REALM_SOURCE="$(pwd)"
        mkdir -p "$WORKSPACE"
        WORKSPACE="$(cd "$WORKSPACE" && pwd)"
        export WORKSPACE
        cd "$WORKSPACE"
        git clone --recursive "$REALM_SOURCE" realm-swift
        cd realm-swift

        echo 'Packaging iOS'
        sh build.sh package ios
        cp "build/realm-ios-$REALM_XCODE_VERSION.zip" .

        echo 'Packaging macOS'
        sh build.sh package osx
        cp "build/realm-osx-$REALM_XCODE_VERSION.zip" .

        echo 'Packaging watchOS'
        sh build.sh package watchos
        cp "build/realm-watchos-$REALM_XCODE_VERSION.zip" .

        echo 'Packaging tvOS'
        sh build.sh package tvos
        cp "build/realm-tvos-$REALM_XCODE_VERSION.zip" .

        echo 'Packaging Catalyst'
        sh build.sh package catalyst
        cp "build/realm-catalyst-$REALM_XCODE_VERSION.zip" .

        if (( "$(xcode_version_major)" >= 15 )); then
            echo 'Packaging visionOS'
            sh build.sh package visionOS
            cp "build/realm-visionOS-$REALM_XCODE_VERSION.zip" .
        fi

        echo 'Packaging examples'
        sh build.sh package-examples

        echo 'Building final release packages'
        export WORKSPACE="${WORKSPACE}/realm-swift"
        sh build.sh package-release

        echo 'Testing packaged examples'
        sh build.sh package-test-examples
        ;;

    "publish-github")
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        ./scripts/github_release.rb "$VERSION" "$REALM_XCODE_VERSION"
        ;;

    "publish-docs")
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        PRERELEASE_REGEX='alpha|beta|rc|preview'
        if [[ $VERSION =~ $PRERELEASE_REGEX ]]; then
          exit 0
        fi
        rm -rf swift_output objc_output
        unzip realm-docs.zip
        s3cmd put --recursive --acl-public --access_key=${AWS_ACCESS_KEY_ID} --secret_key=${AWS_SECRET_ACCESS_KEY} swift_output/ s3://realm-sdks/docs/realm-sdks/swift/${VERSION}/
        s3cmd put --recursive --acl-public --access_key=${AWS_ACCESS_KEY_ID} --secret_key=${AWS_SECRET_ACCESS_KEY} swift_output/ s3://realm-sdks/docs/realm-sdks/swift/latest/

        s3cmd put --recursive --acl-public --access_key=${AWS_ACCESS_KEY_ID} --secret_key=${AWS_SECRET_ACCESS_KEY} objc_output/ s3://realm-sdks/docs/realm-sdks/objc/${VERSION}/
        s3cmd put --recursive --acl-public --access_key=${AWS_ACCESS_KEY_ID} --secret_key=${AWS_SECRET_ACCESS_KEY} objc_output/ s3://realm-sdks/docs/realm-sdks/objc/latest/

        # update static.realm.io/update/cocoa
        printf "%s" "${VERSION}" > cocoa
        s3cmd put cocoa s3://static.realm.io/update/
        rm cocoa
        ;;

    "publish-tag")
        git clone git@github.com:realm/realm-swift.git
        cd realm-swift
        git checkout "$2"
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' dependencies.list)"
        git tag -m "Release ${VERSION}" "v${VERSION}"
        git push origin "v${VERSION}"
        ;;

    "publish-cocoapods")
        git clone https://github.com/realm/realm-swift
        cd realm-swift
        git checkout "$2"
        ./scripts/reset-simulators.rb
        pod trunk push Realm.podspec --verbose --allow-warnings
        pod trunk push RealmSwift.podspec --verbose --allow-warnings --synchronous
        ;;

    "add-empty-changelog")
        empty_section=$(cat <<EOS
x.y.z Release notes (yyyy-MM-dd)
=============================================================
### Enhancements
* None.

### Fixed
* <How to hit and notice issue? what was the impact?> ([#????](https://github.com/realm/realm-swift/issues/????), since v?.?.?)
* None.

<!-- ### Breaking Changes - ONLY INCLUDE FOR NEW MAJOR version -->

### Compatibility
* Realm Studio: 14.0.1 or later.
* APIs are backwards compatible with all previous releases in the 10.x.y series.
* Carthage release for Swift is built with Xcode 14.3.1.
* CocoaPods: 1.10 or later.
* Xcode: 14.1-15 beta 4.

### Internal
* Upgraded realm-core from ? to ?

EOS)
        changelog=$(cat CHANGELOG.md)
        echo "$empty_section" > CHANGELOG.md
        echo >> CHANGELOG.md
        echo "$changelog" >> CHANGELOG.md
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
