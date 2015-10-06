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
: ${REALM_CORE_VERSION:=0.92.4} # set to "current" to always use the current build

# You can override the xcmode used
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool

PATH=/usr/local/bin:/usr/bin:/bin:/usr/libexec:$PATH

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
  osx:                  builds OS X framework
  osx-swift:            builds RealmSwift framework for OS X
  test:                 tests all iOS and OS X frameworks
  test-all:             tests all iOS and OS X frameworks in both Debug and Release configurations
  test-ios-static:      tests static iOS framework on 32-bit and 64-bit simulators
  test-ios-dynamic:     tests dynamic iOS framework on 32-bit and 64-bit simulators
  test-ios-swift:       tests RealmSwift iOS framework on 32-bit and 64-bit simulators
  test-ios-devices:     tests dynamic and Swift iOS frameworks on all attached iOS devices
  test-osx:             tests OS X framework
  test-osx-swift:       tests RealmSwift OS X framework
  verify:               verifies docs, osx, osx-swift, ios-static, ios-dynamic, ios-swift, ios-device in both Debug and Release configurations
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

xcrealm() {
    PROJECT=Realm.xcodeproj
    xc "-project $PROJECT $@"
}

xcrealmswift() {
    PROJECT=RealmSwift.xcodeproj
    xc "-project $PROJECT $@"
}

build_ios_combined() {
    local scheme="$1"
    local module_name="$2"
    local scope_suffix="$3"
    local version_suffix="$4"
    local config="$CONFIGURATION"

    # Derive build paths
    local build_products_path="build/DerivedData/$module_name/Build/Products"
    local product_name="$module_name.framework"
    local binary_path="$module_name"
    local iphoneos_path="$build_products_path/$config-iphoneos$scope_suffix/$product_name"
    local iphonesimulator_path="$build_products_path/$config-iphonesimulator$scope_suffix/$product_name"
    local out_path="build/ios$scope_suffix$version_suffix"

    # Build for each platform
    cmd=$(echo "xc$module_name" | tr '[:upper:]' '[:lower:]') # lowercase the module name to generate command (xcrealm or xcrealmswift)
    $cmd "-scheme '$scheme' -configuration $config -sdk iphoneos"
    $cmd "-scheme '$scheme' -configuration $config -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO"

    # Combine .swiftmodule
    if [ -d $iphonesimulator_path/Modules/$module_name.swiftmodule ]; then
      cp $iphonesimulator_path/Modules/$module_name.swiftmodule/* $iphoneos_path/Modules/$module_name.swiftmodule/
    fi

    # Retrieve build products
    clean_retrieve $iphoneos_path $out_path $product_name

    # Combine ar archives
    xcrun lipo -create "$iphonesimulator_path/$binary_path" "$iphoneos_path/$binary_path" -output "$out_path/$product_name/$module_name"
}

build_watchos_combined() {
    local scheme="$1"
    local module_name="$2"
    local scope_suffix="$3"
    local config="$CONFIGURATION"

    # Derive build paths
    local build_products_path="build/DerivedData/$module_name/Build/Products"
    local product_name="$module_name.framework"
    local binary_path="$module_name"
    local watchos_path="$build_products_path/$config-watchos$scope_suffix/$product_name"
    local watchsimulator_path="$build_products_path/$config-watchsimulator$scope_suffix/$product_name"
    local out_path="build/watchos$scope_suffix"

    # Build for each platform
    cmd=$(echo "xc$module_name" | tr '[:upper:]' '[:lower:]') # lowercase the module name to generate command (xcrealm or xcrealmswift)
    $cmd "-scheme '$scheme' -configuration $config -sdk watchos"
    $cmd "-scheme '$scheme' -configuration $config -sdk watchsimulator ONLY_ACTIVE_ARCH=NO"

    # Combine .swiftmodule
    if [ -d $watchsimulator_path/Modules/$module_name.swiftmodule ]; then
      cp $watchsimulator_path/Modules/$module_name.swiftmodule/* $watchos_path/Modules/$module_name.swiftmodule/
    fi

    # Retrieve build products
    clean_retrieve $watchos_path $out_path $product_name

    # Combine ar archives
    xcrun lipo -create "$watchsimulator_path/$binary_path" "$watchos_path/$binary_path" -output "$out_path/$product_name/$module_name"
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

test_ios_devices() {
    serial_numbers_str=$(system_profiler SPUSBDataType | grep "Serial Number: ")
    serial_numbers=()
    while read -r line; do
        number=${line:15} # Serial number starts at position 15
        if [[ ${#number} == 40 ]]; then
            serial_numbers+=("$number")
        fi
    done <<< "$serial_numbers_str"
    if [[ ${#serial_numbers[@]} == 0 ]]; then
        echo "At least one iOS device must be connected to this computer to run device tests"
        if [ -z "${JENKINS_HOME}" ]; then
            # Don't fail if running locally and there's no device
            exit 0
        fi
        exit 1
    fi
    cmd="$1"
    scheme="$2"
    configuration="$3"
    failed=0
    for device in "${serial_numbers[@]}"; do
        $cmd "-scheme '$2' -configuration $configuration -destination 'id=$device' test" || failed=1
    done
    return $failed
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

download_core() {
    echo "Downloading dependency: core ${REALM_CORE_VERSION}"
    TMP_DIR="$TMPDIR/core_bin"
    mkdir -p "${TMP_DIR}"
    CORE_TMP_TAR="${TMP_DIR}/core-${REALM_CORE_VERSION}.tar.bz2.tmp"
    CORE_TAR="${TMP_DIR}/core-${REALM_CORE_VERSION}.tar.bz2"
    if [ ! -f "${CORE_TAR}" ]; then
        curl -f -L -s "https://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.tar.bz2" -o "${CORE_TMP_TAR}" ||
          (echo "Downloading core failed. Please try again once you have an Internet connection." && exit 1)
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
        sh build.sh osx
        sh build.sh osx-swift
        exit 0
        ;;

    "ios-static")
        build_ios_combined iOS Realm
        exit 0
        ;;

    "ios-dynamic")
        build_ios_combined "iOS Dynamic" Realm "-dynamic"
        exit 0
        ;;

    "ios-swift")
        build_ios_combined RealmSwift RealmSwift '' "/swift-$REALM_SWIFT_VERSION"
        cp -R build/ios-dynamic/Realm.framework build/ios/swift-$REALM_SWIFT_VERSION
        exit 0
        ;;

    "watchos")
        build_watchos_combined "watchOS" Realm
        exit 0
        ;;

    "watchos-swift")
        build_watchos_combined RealmSwift RealmSwift
        exit 0
        ;;

    "osx")
        xcrealm "-scheme OSX -configuration $CONFIGURATION"
        rm -rf build/osx
        mkdir build/osx
        cp -R build/DerivedData/Realm/Build/Products/$CONFIGURATION/Realm.framework build/osx
        exit 0
        ;;

    "osx-swift")
        xcrealmswift "-scheme 'RealmSwift' -configuration $CONFIGURATION build"
        destination="build/osx/swift-$REALM_SWIFT_VERSION"
        clean_retrieve "build/DerivedData/RealmSwift/Build/Products/$CONFIGURATION/RealmSwift.framework" "$destination" "RealmSwift.framework"
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
        xcrealm "-scheme iOS -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' test"
        shutdown_simulators
        xcrealm "-scheme iOS -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s' test"
        exit 0
        ;;

    "test-ios7-static")
        xcrealm "-scheme iOS -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 5S,OS=7.1' test"
        shutdown_simulators
        xcrealm "-scheme iOS -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s,OS=7.1' test"
        exit 0
        ;;

    "test-ios-dynamic")
        xcrealm "-scheme 'iOS Dynamic' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' test"
        shutdown_simulators
        xcrealm "-scheme 'iOS Dynamic' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s' test"
        exit 0
        ;;

    "test-ios-swift")
        xcrealmswift "-scheme RealmSwift -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' test"
        shutdown_simulators
        xcrealmswift "-scheme RealmSwift -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4s' test"
        exit 0
        ;;

    "test-ios-devices")
        failed=0
        test_ios_devices xcrealm "iOS Device Tests" "$CONFIGURATION" || failed=1
        # test_ios_devices xcrealmswift "RealmSwift" "$CONFIGURATION" || failed=1 # FIXME: Re-enable once fixed
        exit $failed
        ;;

    "test-osx")
        COVERAGE_PARAMS=""
        if [[ "$CONFIGURATION" == "Debug" ]]; then
            COVERAGE_PARAMS="GCC_GENERATE_TEST_COVERAGE_FILES=YES GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES"
        fi
        xcrealm "-scheme OSX -configuration $CONFIGURATION test $COVERAGE_PARAMS"
        exit 0
        ;;

    "test-osx-swift")
        xcrealmswift "-scheme RealmSwift -configuration $CONFIGURATION test"
        exit 0
        ;;

    ######################################
    # Full verification
    ######################################
    "verify")
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
        sh build.sh verify-ios-device
        sh build.sh verify-watchos
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

    "verify-ios-device")
        sh build.sh test-ios-devices
        exit 0
        ;;

    "verify-docs")
        sh scripts/build-docs.sh
        if [ -s docs/swift_output/undocumented.txt ]; then
          echo "Undocumented RealmSwift declarations:"
          echo "$(cat docs/swift_output/undocumented.txt)"
          exit 1
        fi
        exit 0
        ;;

    "verify-watchos")
        if [ $REALM_SWIFT_VERSION != '1.2' ]; then
            sh build.sh watchos-swift
        fi
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
        sh build.sh clean
        sh build.sh examples-ios
        sh build.sh examples-ios-swift
        sh build.sh examples-osx
        exit 0
        ;;

    "examples-ios")
        if [[ -d "examples/ios/objc" ]]; then
            project="examples/ios/objc/RealmExamples.xcodeproj"
        elif [[ "$REALM_SWIFT_VERSION" = 1.2 ]]; then
            project="examples/ios/xcode-6/objc/RealmExamples.xcodeproj"
        else
            project="examples/ios/xcode-7/objc/RealmExamples.xcodeproj"
        fi

        xc "-project $project -scheme Simple -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme TableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme Migration -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme Backlink -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme GroupedTableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme Encryption -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"

        if [ ! -z "${JENKINS_HOME}" ]; then
            xc "-project $project -scheme Extension -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        fi

        exit 0
        ;;

    "examples-ios-swift")
        project="examples/ios/swift-$REALM_SWIFT_VERSION/RealmExamples.xcodeproj"
        xc "-project $project -scheme Simple -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme TableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme Migration -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme Encryption -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme Backlink -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project $project -scheme GroupedTableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    "examples-osx")
        xc "-project examples/osx/objc/RealmExamples.xcodeproj -scheme JSONImport -configuration ${CONFIGURATION} build ${CODESIGN_PARAMS}"
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
    # CocoaPods
    ######################################
    "cocoapods-setup")
        if [[ "$2" != "without-core" ]]; then
            sh build.sh download-core
            mv core/librealm.a core/librealm-osx.a
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
            cp -R "$link" "$symlink"
          fi
        done

        if [[ "$2" != "without-core" ]]; then
          # CocoaPods doesn't support multiple header_mappings_dir, so combine
          # both sets of headers into a single directory
          rm -rf include
          cp -R core/include include
          mkdir -p include/Realm
          cp Realm/*.{h,hpp} include/Realm
          cp Realm/ObjectStore/*.hpp include/Realm
          touch include/Realm/RLMPlatform.h
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
        VERSION=$(file realm-objc-*.zip | grep -o '\d*\.\d*\.\d*')
        unzip realm-objc-${VERSION}.zip

        cp $0 realm-objc-${VERSION}
        cp -r $(dirname $0)/scripts realm-objc-${VERSION}
        cd realm-objc-${VERSION}
        REALM_SWIFT_VERSION=1.2 sh build.sh examples-ios
        REALM_SWIFT_VERSION=2.0 sh build.sh examples-ios
        sh build.sh examples-osx
        cd ..
        rm -rf realm-objc-${VERSION}

        unzip realm-swift-${VERSION}.zip

        cp $0 realm-swift-${VERSION}
        cp -r $(dirname $0)/scripts realm-swift-${VERSION}
        cd realm-swift-${VERSION}
        REALM_SWIFT_VERSION=1.2 sh build.sh examples-ios-swift
        REALM_SWIFT_VERSION=2.0 sh build.sh examples-ios-swift
        cd ..
        rm -rf realm-swift-${VERSION}
        ;;

    "package-ios-static")
        cd tightdb_objc

        REALM_SWIFT_VERSION=1.2 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=1.2 sh build.sh test-ios-static
        REALM_SWIFT_VERSION=1.2 sh build.sh ios-static
        move_to_clean_dir build/ios/Realm.framework xcode-6
        rm -rf build

        REALM_SWIFT_VERSION=2.0 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=2.0 sh build.sh test-ios-static
        REALM_SWIFT_VERSION=2.0 sh build.sh ios-static
        move_to_clean_dir build/ios/Realm.framework xcode-7

        zip --symlinks -r build/ios/realm-framework-ios.zip xcode-6 xcode-7
        ;;

    "package-ios-dynamic")
        cd tightdb_objc
        REALM_SWIFT_VERSION=1.2 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=1.2 sh build.sh ios-dynamic
        move_to_clean_dir build/ios-dynamic/Realm.framework xcode-6
        rm -rf build

        REALM_SWIFT_VERSION=2.0 sh build.sh prelaunch-simulator
        REALM_SWIFT_VERSION=2.0 sh build.sh ios-dynamic
        move_to_clean_dir build/ios-dynamic/Realm.framework xcode-7

        zip --symlinks -r build/ios-dynamic/realm-dynamic-framework-ios.zip xcode-6 xcode-7
        ;;

    "package-osx")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.0 sh build.sh test-osx

        cd build/DerivedData/Realm/Build/Products/Release
        zip --symlinks -r realm-framework-osx.zip Realm.framework
        ;;

    "package-ios-swift")
        cd tightdb_objc
        for version in 1.2 2.0; do
            rm -rf build/ios-dynamic
            REALM_SWIFT_VERSION=$version sh build.sh prelaunch-simulator
            REALM_SWIFT_VERSION=$version sh build.sh ios-swift
        done

        cd build/ios
        zip --symlinks -r realm-swift-framework-ios.zip swift-1.2 swift-2.0
        ;;

    "package-osx-swift")
        cd tightdb_objc
        REALM_SWIFT_VERSION=1.2 sh build.sh osx-swift
        REALM_SWIFT_VERSION=2.0 sh build.sh osx-swift

        cd build/osx
        zip --symlinks -r realm-swift-framework-osx.zip swift-1.2 swift-2.0
        ;;

    "package-watchos")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.0 sh build.sh watchos

        cd build/watchos
        zip --symlinks -r realm-framework-watchos.zip Realm.framework
        ;;

    "package-watchos-swift")
        cd tightdb_objc
        REALM_SWIFT_VERSION=2.0 sh build.sh watchos-swift

        cd build/watchos
        zip --symlinks -r realm-swift-framework-watchos.zip RealmSwift.framework Realm.framework
        ;;

    "package-release")
        LANG="$2"
        TEMPDIR=$(mktemp -d $TMPDIR/realm-release-package-${LANG}.XXXX)

        cd tightdb_objc
        VERSION=$(sh build.sh get-version)
        cd ..

        FOLDER=${TEMPDIR}/realm-${LANG}-${VERSION}

        mkdir -p ${FOLDER}/osx ${FOLDER}/ios ${FOLDER}/watchos

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
                rm -rf ios/swift-1.2 ios/swift-2.0
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
        cp tightdb_objc/build/ios/realm-framework-ios.zip .

        echo 'Packaging iOS dynamic'
        sh tightdb_objc/build.sh package-ios-dynamic
        cp tightdb_objc/build/ios-dynamic/realm-dynamic-framework-ios.zip .

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
