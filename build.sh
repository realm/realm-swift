#!/bin/sh

##################################################################################
# Custom build tool for Realm Objective-C binding.
#
# (C) Copyright 2011-2015 by realm.io.
##################################################################################

# Warning: pipefail is not a POSIX compatible option, but on OS X it works just fine.
#          OS X uses a POSIX complain version of bash as /bin/sh, but apparently it does
#          not strip away this feature. Also, this will fail if somebody forces the script
#          to be run with zsh.
set -o pipefail
set -e

# You can override the version of the core library
: ${REALM_CORE_VERSION:=0.100.4} # set to "current" to always use the current build

# You can override the xcmode used
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool

# Provide a fallback value for TMPDIR, relevant for Xcode Bots
: ${TMPDIR:=$(getconf DARWIN_USER_TEMP_DIR)}

PATH=/usr/libexec:$PATH

if ! [ -z "${JENKINS_HOME}" ]; then
    XCPRETTY_PARAMS="--no-utf --report junit --output build/reports/junit.xml"
    CODESIGN_PARAMS="CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO"
fi

export REALM_SKIP_DEBUGGER_CHECKS=YES

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  clean:                clean up/remove all generated files
  download-core:        downloads core library (binary version)
  set-core-bitcode-symlink: set core symlink to bitcode version for Xcode 7+ or non-bitcode version otherwise
  build:                builds all iOS  and OS X frameworks
  ios-static:           builds fat iOS static framework
  ios-dynamic:          builds iOS dynamic frameworks
  ios-swift:            builds RealmSwift frameworks for iOS
  watchos:              builds watchOS framwork
  watchos-swift:        builds RealmSwift framework for watchOS
  tvos:                 builds tvOS framework
  tvos-swift:           builds RealmSwift framework for tvOS
  osx:                  builds OS X framework
  osx-swift:            builds RealmSwift framework for OS X
  test:                 tests all iOS and OS X frameworks
  test-all:             tests all iOS and OS X frameworks in both Debug and Release configurations
  test-ios-static:      tests static iOS framework on 32-bit and 64-bit simulators
  test-ios-dynamic:     tests dynamic iOS framework on 32-bit and 64-bit simulators
  test-ios-swift:       tests RealmSwift iOS framework on 32-bit and 64-bit simulators
  test-ios-devices:     tests ObjC & Swift iOS frameworks on all attached iOS devices
  test-ios-devices-objc:  tests ObjC iOS framework on all attached iOS devices
  test-ios-devices-swift: tests Swift iOS framework on all attached iOS devices
  test-tvos:            tests tvOS framework
  test-tvos-swift:      tests RealmSwift tvOS framework
  test-tvos-devices:    tests ObjC & Swift tvOS frameworks on all attached tvOS devices
  test-osx:             tests OS X framework
  test-osx-swift:       tests RealmSwift OS X framework
  verify:               verifies docs, osx, osx-swift, ios-static, ios-dynamic, ios-swift, ios-device in both Debug and Release configurations, swiftlint
  docs:                 builds docs in docs/output
  examples:             builds all examples
  examples-ios:         builds all static iOS examples
  examples-ios-swift:   builds all Swift iOS examples
  examples-osx:         builds all OS X examples
  get-version:          get the current version
  set-version version:  set the version
  cocoapods-setup:      download realm-core and create a stub RLMPlatform.h file to enable building via CocoaPods


argument:
  version: version in the x.y.z format

environment variables:
  XCMODE: xcodebuild (default), xcpretty or xctool
  CONFIGURATION: Debug or Release (default)
  REALM_CORE_VERSION: version in x.y.z format or "current" to use local build
  REALM_EXTRA_BUILD_ARGUMENTS: additional arguments to pass to the build tool
EOF
}

######################################
# Xcode Helpers
######################################

xcode() {
    mkdir -p build/DerivedData
    CMD="xcodebuild -IDECustomDerivedDataLocation=build/DerivedData $@ $REALM_EXTRA_BUILD_ARGUMENTS"
    echo "Building with command:" $CMD
    eval "$CMD"
}

xc() {
    # Logs xcodebuild output in realtime
    : ${NSUnbufferedIO:=YES}
    if [[ "$XCMODE" == "xcodebuild" ]]; then
        xcode "$@"
    elif [[ "$XCMODE" == "xcpretty" ]]; then
        mkdir -p build
        xcode "$@" | tee build/build.log | xcpretty -c ${XCPRETTY_PARAMS} || {
            echo "The raw xcodebuild output is available in build/build.log"
            exit 1
        }
    elif [[ "$XCMODE" == "xctool" ]]; then
        xctool "$@"
    fi
}

copy_bcsymbolmap() {
    find "$1" -name '*.bcsymbolmap' -type f -exec cp {} "$2" \;
}

build_combined() {
    local scheme="$1"
    local module_name="$2"
    local os="$3"
    local simulator="$4"
    local scope_suffix="$5"
    local version_suffix="$6"
    local config="$CONFIGURATION"

    local destination=""
    local os_name=""
    if [[ "$os" == "iphoneos" ]]; then
        os_name="ios"
        destination="iPhone 6"
    elif [[ "$os" == "watchos"  ]]; then
        os_name="$os"
        destination="Apple Watch - 42mm"
    elif [[ "$os" == "appletvos"  ]]; then
        os_name="tvos"
        destination="Apple TV 1080p"
    fi

    # Derive build paths
    local build_products_path="build/DerivedData/Realm/Build/Products"
    local product_name="$module_name.framework"
    local binary_path="$module_name"
    local os_path="$build_products_path/$config-$os$scope_suffix/$product_name"
    local simulator_path="$build_products_path/$config-$simulator$scope_suffix/$product_name"
    local out_path="build/$os_name$scope_suffix$version_suffix"

    # Build for each platform
    xc "-scheme '$scheme' -configuration $config -sdk $os"
    xc "-scheme '$scheme' -configuration $config -sdk $simulator -destination 'name=$destination' ONLY_ACTIVE_ARCH=NO"

    # Combine .swiftmodule
    if [ -d $simulator_path/Modules/$module_name.swiftmodule ]; then
      cp $simulator_path/Modules/$module_name.swiftmodule/* $os_path/Modules/$module_name.swiftmodule/
    fi

    # Copy *.bcsymbolmap to .framework for submitting app with bitcode
    copy_bcsymbolmap "$build_products_path/$config-$os$scope_suffix" "$os_path"

    # Retrieve build products
    clean_retrieve $os_path $out_path $product_name

    # Combine ar archives
    LIPO_OUTPUT="$out_path/$product_name/$module_name"
    xcrun lipo -create "$simulator_path/$binary_path" "$os_path/$binary_path" -output "$LIPO_OUTPUT"

    if [[ $REALM_SWIFT_VERSION != '1.2' && "$destination" != "" && "$config" == "Release" ]]; then
        sh build.sh binary-has-bitcode "$LIPO_OUTPUT"
    fi
}

xc_work_around_rdar_23055637() {
    # xcodebuild times out waiting for the iOS simulator to launch if it takes > 120 seconds for the tests to
    # build (<http://openradar.appspot.com/23055637>). Work around this by having the test phases intentionally
    # exit after they finish building the first time, then run the tests for real.
    ( REALM_EXIT_AFTER_BUILDING_TESTS=YES xc "$1" ) || true
    # Xcode 7.2.1 fails to run tests in the iOS simulator for unknown reasons. Resetting the simulator here works
    # around this issue.
    sh build.sh prelaunch-simulator
    xc "$1"
}

clean_retrieve() {
  mkdir -p "$2"
  rm -rf "$2/$3"
  cp -R "$1" "$2"
}

move_to_clean_dir() {
    rm -rf "$2"
    mkdir -p "$2"
    mv "$1" "$2"
}

shutdown_simulators() {
    # Shut down simulators until there's no booted ones left
    # Only do one at a time because devices sometimes show up multiple times
    while xcrun simctl list | grep -q Booted; do
      xcrun simctl list | grep Booted | sed 's/.* (\(.*\)) (Booted)/\1/' | head -n 1 | xargs xcrun simctl shutdown
    done
}

######################################
# Device Test Helper
######################################

test_devices() {
    serial_numbers_str=$(system_profiler SPUSBDataType | grep "Serial Number: ")
    serial_numbers=()
    while read -r line; do
        number=${line:15} # Serial number starts at position 15
        if [[ ${#number} == 40 ]]; then
            serial_numbers+=("$number")
        fi
    done <<< "$serial_numbers_str"
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
        xc "-scheme '$scheme' -configuration $configuration -destination 'id=$device' -sdk $sdk test" || failed=1
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
        : ${REALM_SWIFT_VERSION:=2.2}
        sh build.sh set-swift-version
        xcodebuild_arguments="-scheme,RealmSwift"
        module="RealmSwift"
        objc=""
    fi

    touch Realm/RLMPlatform.h # jazzy will fail if it can't find all public header files
    jazzy \
      ${objc} \
      --swift-version 2.2 \
      --clean \
      --author Realm \
      --author_url https://realm.io \
      --github_url https://github.com/realm/realm-cocoa \
      --github-file-prefix https://github.com/realm/realm-cocoa/tree/v${version} \
      --module-version ${version} \
      --xcodebuild-arguments ${xcodebuild_arguments} \
      --module ${module} \
      --root-url https://realm.io/docs/${language}/${version}/api/ \
      --output docs/${language}_output \
      --head "$(cat docs/custom_head.html)"

    rm Realm/RLMPlatform.h
}

######################################
# Input Validation
######################################

if [ "$#" -eq 0 -o "$#" -gt 3 ]; then
    usage
    exit 1
fi

######################################
# Variables
######################################

download_core() {
    echo "Downloading dependency: core ${REALM_CORE_VERSION}"
    TMP_DIR="$TMPDIR/core_bin"
    mkdir -p "${TMP_DIR}"
    CORE_TMP_TAR="${TMP_DIR}/core-${REALM_CORE_VERSION}.tar.bz2.tmp"
    CORE_TAR="${TMP_DIR}/core-${REALM_CORE_VERSION}.tar.bz2"
    if [ ! -f "${CORE_TAR}" ]; then
        local CORE_URL="https://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.tar.bz2"
        set +e # temporarily disable immediate exit
        local ERROR # sweeps the exit code unless declared separately
        ERROR=$(curl --fail --silent --show-error --location "$CORE_URL" --output "${CORE_TMP_TAR}" 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "Downloading core failed:\n${ERROR}"
            exit 1
        fi
        set -e # re-enable flag
        mv "${CORE_TMP_TAR}" "${CORE_TAR}"
    fi

    (
        cd "${TMP_DIR}"
        rm -rf core
        tar xjf "${CORE_TAR}"
        mv core core-${REALM_CORE_VERSION}
    )

    rm -rf core-${REALM_CORE_VERSION} core
    mv ${TMP_DIR}/core-${REALM_CORE_VERSION} .
    ln -s core-${REALM_CORE_VERSION} core
}

COMMAND="$1"

# Use Debug config if command ends with -debug, otherwise default to Release
case "$COMMAND" in
    *-debug)
        COMMAND="${COMMAND%-debug}"
        CONFIGURATION="Debug"
        ;;
    *) CONFIGURATION=${CONFIGURATION:-Release}
esac
export CONFIGURATION

source "$(dirname "$0")/scripts/swift-version.sh"

case "$COMMAND" in

    ######################################
    # Clean
    ######################################
    "clean")
        find . -type d -name build -exec rm -r "{}" +\;
        exit 0
        ;;

    ######################################
    # Core
    ######################################
    "download-core")
        if [ "$REALM_CORE_VERSION" = "current" ]; then
            echo "Using version of core already in core/ directory"
            exit 0
        fi
        if [ -d core -a -d ../realm-core -a ! -L core ]; then
          # Allow newer versions than expected for local builds as testing
          # with unreleased versions is one of the reasons to use a local build
          if ! $(grep -i "${REALM_CORE_VERSION} Release notes" core/release_notes.txt >/dev/null); then
              echo "Local build of core is out of date."
              exit 1
          else
              echo "The core library seems to be up to date."
          fi
        elif ! [ -L core ]; then
            echo "core is not a symlink. Deleting..."
            rm -rf core
            download_core
        # With a prebuilt version we only want to check the first non-empty
        # line so that checking out an older commit will download the
        # appropriate version of core if the already-present version is too new
        elif ! $(grep -m 1 . core/release_notes.txt | grep -i "${REALM_CORE_VERSION} RELEASE NOTES" >/dev/null); then
            download_core
        else
            echo "The core library seems to be up to date."
        fi
        exit 0
        ;;

    "set-core-bitcode-symlink")
        cd core
        rm -f librealm-ios.a librealm-ios-dbg.a
        if [ $REALM_SWIFT_VERSION = '1.2' ]; then
            echo "Using core without bitcode"
            ln -s librealm-ios-no-bitcode.a librealm-ios.a
            ln -s librealm-ios-no-bitcode-dbg.a librealm-ios-dbg.a
        else
            echo "Using core with bitcode"
            ln -s librealm-ios-bitcode.a librealm-ios.a
            ln -s librealm-ios-bitcode-dbg.a librealm-ios-dbg.a
        fi
        ;;

    ######################################
    # Object Store
    ######################################
    "push-object-store-changes")
        commit="$2"
        path="$3"
        if [ -z "$commit" -o -z "$path" ]; then
            echo "usage: sh build.sh push-object-store-changes [base commit] [path to objectore repo]"
            exit 1
        fi

        # List all commits since $commit which touched the objecstore, generate
        # patches for each of them, and then apply those patches to the
        # objectstore repo
        git rev-list --reverse $commit..HEAD -- Realm/ObjectStore \
            | xargs -I@ git format-patch --stdout @^! Realm/ObjectStore \
            | git -C $path am -p 3 --directory src
        ;;

    "pull-object-store-changes")
        commit="$2"
        path="$3"
        if [ -z "$commit" -o -z "$path" ]; then
            echo "usage: sh build.sh pull-object-store-changes [base commit] [path to objectore repo]"
            exit 1
        fi

        git -C $path format-patch --stdout $commit..HEAD src | git am -p 2 --directory Realm/ObjectStore --exclude='*CMake*' --reject
        ;;

    ######################################
    # Swift versioning
    ######################################
    "set-swift-version")
        version="$2"
        if [[ -z "$version" ]]; then
            version="$REALM_SWIFT_VERSION"
        fi

        # Update the symlinks to point to the correct verion of the source, and
        # then tell git to ignore the fact that we just changed a tracked file so
        # that the new symlink doesn't accidentally get committed
        rm -rf RealmSwift
        ln -s "RealmSwift-swift$version" RealmSwift
        git update-index --assume-unchanged RealmSwift || true

        # Only write SwiftVersion.swift if RealmSwift supports the given version of Swift.
        if [[ -e "RealmSwift-swift$version" ]]; then
            SWIFT_VERSION_FILE="RealmSwift/SwiftVersion.swift"
            CONTENTS="let swiftLanguageVersion = \"$version\""
            if [ ! -f "$SWIFT_VERSION_FILE" ] || ! grep -q "$CONTENTS" "$SWIFT_VERSION_FILE"; then
                echo "$CONTENTS" > "$SWIFT_VERSION_FILE"
            fi
        fi

        cd Realm/Tests
        rm -rf Swift
        ln -s "Swift$version" Swift
        git update-index --assume-unchanged Swift || true
        exit 0
        ;;

    "prelaunch-simulator")
        sh $(dirname $0)/scripts/reset-simulators.sh
        ;;

    ######################################
    # Building
    ######################################
    "build")
        sh build.sh ios-static
        sh build.sh ios-dynamic
        sh build.sh ios-swift
        sh build.sh watchos
        sh build.sh watchos-swift
        sh build.sh tvos
        sh build.sh tvos-swift
        sh build.sh osx
        sh build.sh osx-swift
        exit 0
        ;;

    "ios-static")
        build_combined 'Realm iOS static' Realm iphoneos iphonesimulator "-static"
        exit 0
        ;;

    "ios-dynamic")
        build_combined Realm Realm iphoneos iphonesimulator
        exit 0
        ;;

    "ios-swift")
        sh build.sh ios-dynamic
        build_combined RealmSwift RealmSwift iphoneos iphonesimulator '' "/swift-$REALM_SWIFT_VERSION"
        cp -R build/ios/Realm.framework build/ios/swift-$REALM_SWIFT_VERSION
        exit 0
        ;;

    "watchos")
        build_combined Realm Realm watchos watchsimulator
        exit 0
        ;;

    "watchos-swift")
        sh build.sh watchos
        build_combined RealmSwift RealmSwift watchos watchsimulator
        exit 0
        ;;

    "tvos")
        build_combined Realm Realm appletvos appletvsimulator
        exit 0
        ;;

    "tvos-swift")
        sh build.sh tvos
        build_combined RealmSwift RealmSwift appletvos appletvsimulator
        exit 0
        ;;

    "osx")
        xc "-scheme Realm -configuration $CONFIGURATION"
        rm -rf build/osx
        mkdir build/osx
        cp -R build/DerivedData/Realm/Build/Products/$CONFIGURATION/Realm.framework build/osx
        exit 0
        ;;

    "osx-swift")
        sh build.sh osx
        xc "-scheme 'RealmSwift' -configuration $CONFIGURATION build"
        destination="build/osx/swift-$REALM_SWIFT_VERSION"
        clean_retrieve "build/DerivedData/Realm/Build/Products/$CONFIGURATION/RealmSwift.framework" "$destination" "RealmSwift.framework"
        cp -R build/osx/Realm.framework "$destination"
        exit 0
        ;;

    ######################################
    # Testing
    ######################################
    "test")
        set +e # Run both sets of tests even if the first fails
        failed=0
        sh build.sh test-ios-static || failed=1
        sh build.sh test-ios-dynamic || failed=1
        sh build.sh test-ios-swift || failed=1
        sh build.sh test-ios-devices || failed=1
        sh build.sh test-tvos-devices || failed=1
        sh build.sh test-osx || failed=1
        sh build.sh test-osx-swift || failed=1
        exit $failed
        ;;

    "test-all")
        set +e
        failed=0
        sh build.sh test || failed=1
        sh build.sh test-debug || failed=1
        exit $failed
        ;;

    "test-ios-static")
        xc_work_around_rdar_23055637 "-scheme 'Realm iOS static' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' test"
        shutdown_simulators
        xc_work_around_rdar_23055637 "-scheme 'Realm iOS static' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s' test"
        exit 0
        ;;

    "test-ios7-static")
        xc_work_around_rdar_23055637 "-scheme 'Realm iOS static' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 5S,OS=7.1' test"
        shutdown_simulators
        xc_work_around_rdar_23055637 "-scheme 'Realm iOS static' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s,OS=7.1' test"
        exit 0
        ;;

    "test-ios-dynamic")
        xc_work_around_rdar_23055637 "-scheme Realm -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' test"
        shutdown_simulators
        xc_work_around_rdar_23055637 "-scheme Realm -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s' test"
        exit 0
        ;;

    "test-ios-swift")
        xc_work_around_rdar_23055637 "-scheme RealmSwift -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' build test"
        shutdown_simulators
        xc_work_around_rdar_23055637 "-scheme RealmSwift -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s' build test"
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
        test_devices iphoneos "Realm iOS static" "$CONFIGURATION"
        exit $?
        ;;

    "test-ios-devices-swift")
        test_devices iphoneos "RealmSwift" "$CONFIGURATION"
        exit $?
        ;;

    "test-tvos")
        xc_work_around_rdar_23055637 "-scheme Realm -configuration $CONFIGURATION -sdk appletvsimulator -destination 'name=Apple TV 1080p' test"
        exit $?
        ;;

    "test-tvos-swift")
        xc_work_around_rdar_23055637 "-scheme RealmSwift -configuration $CONFIGURATION -sdk appletvsimulator -destination 'name=Apple TV 1080p' test"
        exit $?
        ;;

    "test-tvos-devices")
        test_devices appletvos TestHost "$CONFIGURATION"
        ;;

    "test-osx")
        COVERAGE_PARAMS=""
        if [[ "$CONFIGURATION" == "Debug" ]]; then
            COVERAGE_PARAMS="GCC_GENERATE_TEST_COVERAGE_FILES=YES GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES"
        fi
        xc "-scheme Realm -configuration $CONFIGURATION test $COVERAGE_PARAMS"
        exit 0
        ;;

    "test-osx-swift")
        xc "-scheme RealmSwift -configuration $CONFIGURATION test"
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
        sh build.sh verify-ios7-static
        sh build.sh verify-ios7-static-debug
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
        ;;

    "verify-cocoapods")
        pod setup
        pod spec lint Realm.podspec
        # allow warnings in the Swift podspec because there's no way to
        # prevent the typealias->associatedtype deprecation warning without
        # also breaking backwards compatibility with previous Swift 2.x versions
        pod spec lint RealmSwift.podspec --allow-warnings
        cd examples/installation
        sh build.sh test-ios-objc-cocoapods || exit 1
        sh build.sh test-ios-swift-cocoapods || exit 1
        ;;

    "verify-osx-encryption")
        REALM_ENCRYPT_ALL=YES sh build.sh test-osx || exit 1
        exit 0
        ;;

    "verify-osx")
        sh build.sh test-osx
        sh build.sh examples-osx

        (
            cd examples/osx/objc/build/DerivedData/RealmExamples/Build/Products/$CONFIGURATION
            DYLD_FRAMEWORK_PATH=. ./JSONImport >/dev/null
        ) || exit 1
        exit 0
        ;;

    "verify-osx-swift")
        sh build.sh test-osx-swift
        exit 0
        ;;

    "verify-ios-static")
        sh build.sh test-ios-static
        sh build.sh examples-ios
        ;;

    "verify-ios7-static")
        sh build.sh test-ios7-static
        ;;

    "verify-ios-dynamic")
        sh build.sh test-ios-dynamic
        ;;

    "verify-ios-swift")
        sh build.sh test-ios-swift
        sh build.sh examples-ios-swift
        ;;

    "verify-ios-device-objc")
        sh build.sh test-ios-devices-objc
        exit 0
        ;;

    "verify-ios-device-swift")
        sh build.sh test-ios-devices-swift
        exit 0
        ;;

    "verify-docs")
        sh build.sh docs
        for lang in swift objc; do
            undocumented="docs/${lang}_output/undocumented.txt"
            if [ -s "$undocumented" ]; then
              echo "Undocumented Realm $lang declarations:"
              cat "$undocumented"
              exit 1
            fi
        done
        exit 0
        ;;

    "verify-watchos")
        if [ $REALM_SWIFT_VERSION != '1.2' ]; then
            sh build.sh watchos-swift
        fi
        exit 0
        ;;

    "verify-tvos")
        if [ $REALM_SWIFT_VERSION != '1.2' ]; then
            sh build.sh test-tvos
            sh build.sh test-tvos-swift
            sh build.sh examples-tvos
            sh build.sh examples-tvos-swift
        fi
        exit 0
        ;;

    "verify-tvos-device")
        sh build.sh test-tvos-devices
        exit 0
        ;;

    "verify-swiftlint")
        swiftlint lint --strict
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
        sh build.sh examples-ios
        sh build.sh examples-ios-swift
        sh build.sh examples-osx
        sh build.sh examples-tvos
        sh build.sh examples-tvos-swift
        exit 0
        ;;

    "examples-ios")
        sh build.sh prelaunch-simulator
        if [[ -d "examples/ios/objc" ]]; then
            workspace="examples/ios/objc/RealmExamples.xcworkspace"
        elif [[ "$REALM_SWIFT_VERSION" = 1.2 ]]; then
            workspace="examples/ios/xcode-6/objc/RealmExamples.xcworkspace"
        else
            workspace="examples/ios/xcode-7/objc/RealmExamples.xcworkspace"
        fi
        pod install --project-directory="$workspace/.." --no-repo-update
        xc "-workspace $workspace -scheme Simple -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme TableView -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme Migration -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme Backlink -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme GroupedTableView -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme RACTableView -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme Encryption -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"

        if [ ! -z "${JENKINS_HOME}" ]; then
            xc "-workspace $workspace -scheme Extension -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        fi

        exit 0
        ;;

    "examples-ios-swift")
        sh build.sh prelaunch-simulator
        workspace="examples/ios/swift-$REALM_SWIFT_VERSION/RealmExamples.xcworkspace"
        pod install --project-directory="$workspace/.." --no-repo-update
        xc "-workspace $workspace -scheme Simple -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme TableView -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme Migration -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme Encryption -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme Backlink -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme GroupedTableView -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme ReactKitTableView -configuration $CONFIGURATION -destination 'name=iPhone 6' build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    "examples-osx")
        xc "-workspace examples/osx/objc/RealmExamples.xcworkspace -scheme JSONImport -configuration ${CONFIGURATION} build ${CODESIGN_PARAMS}"
        ;;

    "examples-tvos")
        workspace="examples/tvos/objc/RealmExamples.xcworkspace"
        xc "-workspace $workspace -scheme DownloadCache -configuration $CONFIGURATION -destination 'name=Apple TV 1080p' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme PreloadedData -configuration $CONFIGURATION -destination 'name=Apple TV 1080p' build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    "examples-tvos-swift")
        workspace="examples/tvos/swift/RealmExamples.xcworkspace"
        xc "-workspace $workspace -scheme DownloadCache -configuration $CONFIGURATION -destination 'name=Apple TV 1080p' build ${CODESIGN_PARAMS}"
        xc "-workspace $workspace -scheme PreloadedData -configuration $CONFIGURATION -destination 'name=Apple TV 1080p' build ${CODESIGN_PARAMS}"
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
        version_files="Realm/Realm-Info.plist"

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
    # Bitcode Detection
    ######################################

    "binary-has-bitcode")
        BINARY="$2"
        # Although grep has a '-q' flag to prevent logging to stdout, grep
        # behaves differently when used, so redirect stdout to /dev/null.
        if otool -l "$BINARY" | grep "segname __LLVM" > /dev/null 2>&1; then
            exit 0
        fi
        # Work around rdar://21826157 by checking for bitcode in thin binaries

        # Get architectures for binary
        archs="$(lipo -info "$BINARY" | rev | cut -d ':' -f1 | rev)"

        archs_array=( $archs )
        if [[ ${#archs_array[@]} < 2 ]]; then
            exit 1 # Early exit if not a fat binary
        fi

        TEMPDIR=$(mktemp -d $TMPDIR/realm-bitcode-check.XXXX)

        for arch in $archs; do
            lipo -thin "$arch" "$BINARY" -output "$TEMPDIR/$arch"
            if otool -l "$TEMPDIR/$arch" | grep -q "segname __LLVM"; then
                exit 0
            fi
        done
        exit 1
        ;;

    ######################################
    # CocoaPods
    ######################################
    "cocoapods-setup")
        if [[ "$2" != "swift" ]]; then
            sh build.sh download-core
            if [[ "$REALM_SWIFT_VERSION" = "1.2" ]]; then
                echo 'Installing for Xcode 6.'
                mv core/librealm-ios-no-bitcode.a core/librealm-ios.a
              else
                echo 'Installing for Xcode 7+.'
                mv core/librealm-ios-bitcode.a core/librealm-ios.a
            fi
        fi

        # CocoaPods won't automatically preserve files referenced via symlinks
        for symlink in $(find . -not -path "./.git/*" -type l); do
          if [[ -L "$symlink" ]]; then
            link="$(dirname "$symlink")/$(readlink "$symlink")"
            rm "$symlink"
            cp -RH "$link" "$symlink"
          fi
        done

        if [[ "$2" != "swift" ]]; then
          rm -rf include
          mkdir -p include
          mv core/include include/core

          mkdir -p include/impl/apple
          mkdir -p include/util
          cp Realm/*.hpp include
          cp Realm/ObjectStore/*.hpp include
          cp Realm/ObjectStore/impl/*.hpp include/impl
          cp Realm/ObjectStore/impl/apple/*.hpp include/impl/apple
          cp Realm/ObjectStore/util/*.hpp include/util

          touch Realm/RLMPlatform.h
          if [ -n "$COCOAPODS_VERSION" ]; then
            # This variable is set for the prepare_command available
            # from the 1.0 prereleases, which requires a different
            # header layout within the header_mappings_dir.
            cp Realm/*.h include
          else
            # For CocoaPods < 1.0, we need to scope the headers within
            # the header_mappings_dir by another subdirectory to avoid
            # Clang from complaining about non-modular headers.
            mkdir -p include/Realm
            cp Realm/*.h include/Realm
          fi
        else
          echo "let swiftLanguageVersion = \"$(get_swift_version)\"" > RealmSwift/SwiftVersion.swift
        fi
        ;;

    ######################################
    # Continuous Integration
    ######################################

    "ci-pr")
        mkdir -p build/reports

        if [ "$target" = "docs" ]; then
            sh build.sh set-swift-version
            sh build.sh verify-docs
        elif [ "$target" = "swiftlint" ]; then
            sh build.sh verify-swiftlint
        else
            export sha=$ghprbSourceBranch
            export REALM_SWIFT_VERSION=$swift_version
            export CONFIGURATION=$configuration
            export REALM_EXTRA_BUILD_ARGUMENTS='GCC_GENERATE_DEBUGGING_SYMBOLS=NO REALM_PREFIX_HEADER=Realm/RLMPrefix.h'
            sh build.sh prelaunch-simulator
            # Verify that no Realm files still exist
            ! find ~/Library/Developer/CoreSimulator/Devices/ -name '*.realm' | grep -q .

            sh build.sh verify-$target | tee build/build.log | xcpretty -r junit -o build/reports/junit.xml || \
                (echo "\n\n***\nbuild/build.log\n***\n\n" && cat build/build.log && exit 1)
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

    "package-examples")
        cd tightdb_objc
        ./scripts/package_examples.rb
        zip --symlinks -r realm-examples.zip examples -x "examples/installation/*"
        ;;

    "package-test-examples")
        if ! VERSION=$(echo realm-objc-*.zip | grep -o '\d*\.\d*\.\d*-[a-z]*'); then
            VERSION=$(echo realm-objc-*.zip | grep -o '\d*\.\d*\.\d*')
        fi
        OBJC="realm-objc-${VERSION}"
        SWIFT="realm-swift-${VERSION}"
        unzip ${OBJC}.zip

        cp $0 ${OBJC}
        cp -r $(dirname $0)/scripts ${OBJC}
        cd ${OBJC}
        REALM_SWIFT_VERSION=1.2 sh build.sh examples-ios
        REALM_SWIFT_VERSION=2.2 sh build.sh examples-ios
        sh build.sh examples-osx
        cd ..
        rm -rf ${OBJC}

        unzip ${SWIFT}.zip

        cp $0 ${SWIFT}
        cp -r $(dirname $0)/scripts ${SWIFT}
        cd ${SWIFT}
        REALM_SWIFT_VERSION=2.2 sh build.sh examples-ios-swift
        cd ..
        rm -rf ${SWIFT}
        ;;

    "package-ios-static")
        cd tightdb_objc

        REALM_SWIFT_VERSION=1.2 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=1.2 sh build.sh test-ios-static
        REALM_SWIFT_VERSION=1.2 sh build.sh ios-static
        move_to_clean_dir build/ios-static/Realm.framework xcode-6
        rm -rf build

        REALM_SWIFT_VERSION=2.2 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=2.2 sh build.sh test-ios-static
        REALM_SWIFT_VERSION=2.2 sh build.sh ios-static
        move_to_clean_dir build/ios-static/Realm.framework xcode-7

        zip --symlinks -r build/ios-static/realm-framework-ios.zip xcode-6 xcode-7
        ;;

    "package-ios-dynamic")
        cd tightdb_objc
        REALM_SWIFT_VERSION=1.2 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=1.2 sh build.sh ios-dynamic
        move_to_clean_dir build/ios/Realm.framework xcode-6
        rm -rf build

        REALM_SWIFT_VERSION=2.2 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=2.2 sh build.sh ios-dynamic
        move_to_clean_dir build/ios/Realm.framework xcode-7

        zip --symlinks -r build/ios/realm-dynamic-framework-ios.zip xcode-6 xcode-7
        ;;

    "package-osx")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.2 sh build.sh test-osx

        cd build/DerivedData/Realm/Build/Products/Release
        zip --symlinks -r realm-framework-osx.zip Realm.framework
        ;;

    "package-ios-swift")
        cd tightdb_objc
        for version in 2.2; do
            rm -rf build/ios/Realm.framework
            REALM_SWIFT_VERSION=$version sh build.sh prelaunch-simulator
            REALM_SWIFT_VERSION=$version sh build.sh ios-swift
        done

        cd build/ios
        zip --symlinks -r realm-swift-framework-ios.zip swift-2.2
        ;;

    "package-osx-swift")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.2 sh build.sh osx-swift

        cd build/osx
        zip --symlinks -r realm-swift-framework-osx.zip swift-2.2
        ;;

    "package-watchos")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.2 sh build.sh watchos

        cd build/watchos
        zip --symlinks -r realm-framework-watchos.zip Realm.framework
        ;;

    "package-watchos-swift")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.2 sh build.sh watchos-swift

        cd build/watchos
        zip --symlinks -r realm-swift-framework-watchos.zip RealmSwift.framework Realm.framework
        ;;

    "package-tvos")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.2 sh build.sh tvos

        cd build/tvos
        zip --symlinks -r realm-framework-tvos.zip Realm.framework
        ;;

    "package-tvos-swift")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.2 sh build.sh tvos-swift

        cd build/tvos
        zip --symlinks -r realm-swift-framework-tvos.zip RealmSwift.framework Realm.framework
        ;;

    "package-release")
        LANG="$2"
        TEMPDIR=$(mktemp -d $TMPDIR/realm-release-package-${LANG}.XXXX)

        cd tightdb_objc
        VERSION=$(sh build.sh get-version)
        cd ..

        FOLDER=${TEMPDIR}/realm-${LANG}-${VERSION}

        mkdir -p ${FOLDER}/osx ${FOLDER}/ios ${FOLDER}/watchos ${FOLDER}/tvos

        if [[ "${LANG}" == "objc" ]]; then
            mkdir -p ${FOLDER}/ios/static
            mkdir -p ${FOLDER}/ios/dynamic
            mkdir -p ${FOLDER}/Swift

            (
                cd ${FOLDER}/osx
                unzip ${WORKSPACE}/realm-framework-osx.zip
            )

            (
                cd ${FOLDER}/ios/static
                unzip ${WORKSPACE}/realm-framework-ios.zip
            )

            (
                cd ${FOLDER}/ios/dynamic
                unzip ${WORKSPACE}/realm-dynamic-framework-ios.zip
            )

            (
                cd ${FOLDER}/watchos
                unzip ${WORKSPACE}/realm-framework-watchos.zip
            )

            (
                cd ${FOLDER}/tvos
                unzip ${WORKSPACE}/realm-framework-tvos.zip
            )
        else
            (
                cd ${FOLDER}/osx
                unzip ${WORKSPACE}/realm-swift-framework-osx.zip
            )

            (
                cd ${FOLDER}/ios
                unzip ${WORKSPACE}/realm-swift-framework-ios.zip
            )

            (
                cd ${FOLDER}/watchos
                unzip ${WORKSPACE}/realm-swift-framework-watchos.zip
            )

            (
                cd ${FOLDER}/tvos
                unzip ${WORKSPACE}/realm-swift-framework-tvos.zip
            )
        fi

        (
            cd ${WORKSPACE}/tightdb_objc
            cp -R plugin ${FOLDER}
            cp LICENSE ${FOLDER}/LICENSE.txt
            if [[ "${LANG}" == "objc" ]]; then
                cp Realm/Swift/RLMSupport.swift ${FOLDER}/Swift/
            fi
        )

        (
            cd ${FOLDER}
            unzip ${WORKSPACE}/realm-examples.zip
            cd examples
            if [[ "${LANG}" == "objc" ]]; then
                rm -rf ios/swift-2.2
            else
                rm -rf ios/objc ios/rubymotion osx
            fi
        )

        cat > ${FOLDER}/docs.webloc <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>URL</key>
    <string>https://realm.io/docs/${LANG}/${VERSION}</string>
</dict>
</plist>
EOF

        (
          cd ${TEMPDIR}
          zip --symlinks -r realm-${LANG}-${VERSION}.zip realm-${LANG}-${VERSION}
          mv realm-${LANG}-${VERSION}.zip ${WORKSPACE}
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
        cd $WORKSPACE
        git clone $REALM_SOURCE tightdb_objc

        echo 'Packaging iOS static'
        sh tightdb_objc/build.sh package-ios-static
        cp tightdb_objc/build/ios-static/realm-framework-ios.zip .

        echo 'Packaging iOS dynamic'
        sh tightdb_objc/build.sh package-ios-dynamic
        cp tightdb_objc/build/ios/realm-dynamic-framework-ios.zip .

        echo 'Packaging OS X'
        sh tightdb_objc/build.sh package-osx
        cp tightdb_objc/build/DerivedData/Realm/Build/Products/Release/realm-framework-osx.zip .

        echo 'Packaging examples'
        (
            cd tightdb_objc/examples
            git clean -xfd
        )
        sh tightdb_objc/build.sh package-examples
        cp tightdb_objc/realm-examples.zip .

        echo 'Packaging iOS Swift'
        sh tightdb_objc/build.sh package-ios-swift
        cp tightdb_objc/build/ios/realm-swift-framework-ios.zip .

        echo 'Packaging OS X Swift'
        sh tightdb_objc/build.sh package-osx-swift
        cp tightdb_objc/build/osx/realm-swift-framework-osx.zip .

        echo 'Packaging watchOS'
        sh tightdb_objc/build.sh package-watchos
        sh tightdb_objc/build.sh package-watchos-swift
        cp tightdb_objc/build/watchos/realm-swift-framework-watchos.zip .
        cp tightdb_objc/build/watchos/realm-framework-watchos.zip .

        echo 'Packaging tvOS'
        sh tightdb_objc/build.sh package-tvos
        sh tightdb_objc/build.sh package-tvos-swift
        cp tightdb_objc/build/tvos/realm-swift-framework-tvos.zip .
        cp tightdb_objc/build/tvos/realm-framework-tvos.zip .

        echo 'Building final release packages'
        sh tightdb_objc/build.sh package-release objc
        sh tightdb_objc/build.sh package-release swift

        echo 'Testing packaged examples'
        sh tightdb_objc/build.sh package-test-examples

        ;;

    "github-release")
        if [ -z "${GITHUB_ACCESS_TOKEN}" ]; then
            echo 'GITHUB_ACCESS_TOKEN must be set to create GitHub releases'
            exit 1
        fi
        ./scripts/github_release.rb
        ;;

    "add-empty-changelog")
        empty_section=$(cat <<EOS
x.x.x Release notes (yyyy-MM-dd)
=============================================================

### API breaking changes

* None.

### Enhancements

* None.

### Bugfixes

* None.
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
