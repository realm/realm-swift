#!/bin/sh

##################################################################################
# Custom build tool for Realm Objective C binding.
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
: ${REALM_CORE_VERSION:=0.89.0} # set to "current" to always use the current build

# You can override the xcmode used
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool

# Whether or not to package RealmSwift
# TODO: Remove all references when RealmSwift is released
: ${PACKAGE_REALM_SWIFT:=false}

PATH=/usr/local/bin:/usr/bin:/bin:/usr/libexec:$PATH

if ! [ -z "${JENKINS_HOME}" ]; then
    XCPRETTY_PARAMS="--no-utf --report junit --output build/reports/junit.xml"
    CODESIGN_PARAMS="CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO"
fi

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  clean:                clean up/remove all generated files
  download-core:        downloads core library (binary version)
  build:                builds all iOS  and OS X frameworks
  ios-static:           builds fat iOS static framework
  ios-dynamic:          builds iOS dynamic frameworks
  ios-swift:            builds RealmSwift frameworks for iOS
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
  browser:              builds the Realm Browser
  test-browser:         tests the Realm Browser
  get-version:          get the current version
  set-version version:  set the version
  cocoapods-setup:      download realm-core and create a stub RLMPlatform.h file to enable building via CocoaPods


argument:
  version: version in the x.y.z format

environment variables:
  XCMODE: xcodebuild (default), xcpretty or xctool
  CONFIGURATION: Debug or Release (default)
  REALM_CORE_VERSION: version in x.y.z format or "current" to use local build
EOF
}

######################################
# Xcode Helpers
######################################

xcode() {
    mkdir -p build/DerivedData
    CMD="xcodebuild -IDECustomDerivedDataLocation=build/DerivedData $@"
    echo "Building with command:" $CMD
    eval $CMD
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

build_combined() {
    local scheme="$1"
    local config="$2"
    local module_name="$3"
    local scope_suffix="$4"

    # Derive build paths
    local build_products_path="build/DerivedData/$module_name/Build/Products"
    local product_name="$module_name.framework"
    local binary_path="$module_name"
    local iphoneos_path="$build_products_path/$config-iphoneos$scope_suffix/$product_name"
    local iphonesimulator_path="$build_products_path/$config-iphonesimulator$scope_suffix/$product_name"
    local out_path="build/ios"

    # Build for each platform
    if [[ "$module_name" == "Realm" ]]; then
      xcrealm "-scheme '$scheme' -configuration $config -sdk iphoneos"
      xcrealm "-scheme '$scheme' -configuration $config -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO"
    elif [[ "$module_name" == "RealmSwift" ]]; then
      xcrealmswift "-scheme '$scheme' -configuration $config -sdk iphoneos"
      xcrealmswift "-scheme '$scheme' -configuration $config -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO"
    fi

    # Combine .swiftmodule
    if [ -d $iphoneos_path/Modules/$module_name.swiftmodule ]; then
      cp $iphoneos_path/Modules/$module_name.swiftmodule/* $iphonesimulator_path/Modules/$module_name.swiftmodule/
    fi

    # Retrieve build products
    clean_retrieve $iphoneos_path $out_path $product_name

    # Combine ar archives
    xcrun lipo -create "$iphonesimulator_path/$binary_path" "$iphoneos_path/$binary_path" -output "$out_path/$product_name/$module_name"
}

clean_retrieve() {
  mkdir -p $2
  rm -rf $2/$3
  cp -R $1 $2
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
    configuration="$2"
    failed=0
    for device in "${serial_numbers[@]}"; do
        $cmd "-scheme 'iOS Device Tests' -configuration $configuration -destination 'id=$device' test" || failed=1
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
    CORE_TMP_ZIP="${TMP_DIR}/core-${REALM_CORE_VERSION}.zip.tmp"
    CORE_ZIP="${TMP_DIR}/core-${REALM_CORE_VERSION}.zip"
    if [ ! -f "${CORE_ZIP}" ]; then
        curl -L -s "http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip" -o "${CORE_TMP_ZIP}"
        mv "${CORE_TMP_ZIP}" "${CORE_ZIP}"
    fi
    (
        cd "${TMP_DIR}"
        rm -rf core
        unzip "${CORE_ZIP}"
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

case "$COMMAND" in

    ######################################
    # Clean
    ######################################
    "clean")
        find . -type d -name build -exec rm -r "{}" +\;
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
        elif ! $(head -n 1 core/release_notes.txt | grep -i ${REALM_CORE_VERSION} >/dev/null); then
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
        sh build.sh ios-static
        sh build.sh ios-dynamic
        sh build.sh ios-swift
        sh build.sh osx
        sh build.sh osx-swift
        exit 0
        ;;

    "ios-static")
        build_combined iOS "$CONFIGURATION" Realm
        exit 0
        ;;

    "ios-dynamic")
        xcrealm "-scheme 'iOS Dynamic' -configuration $CONFIGURATION build -sdk iphoneos"
        xcrealm "-scheme 'iOS Dynamic' -configuration $CONFIGURATION build -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO"
        exit 0
        ;;

    "ios-swift")
        xcrealmswift "-scheme 'RealmSwift iOS' -configuration $CONFIGURATION build -sdk iphoneos"
        xcrealmswift "-scheme 'RealmSwift iOS' -configuration $CONFIGURATION build -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO"
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
        xcrealmswift "-scheme 'RealmSwift OSX' -configuration $CONFIGURATION build"
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
        xcrealm "-scheme iOS -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4S' test"
        exit 0
        ;;

    "test-ios-dynamic")
        xcrealm "-scheme 'iOS Dynamic' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' test"
        xcrealm "-scheme 'iOS Dynamic' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4S' test"
        exit 0
        ;;

    "test-ios-swift")
        xcrealmswift "-scheme 'RealmSwift iOS' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 6' test"
        xcrealmswift "-scheme 'RealmSwift iOS' -configuration $CONFIGURATION -sdk iphonesimulator -destination 'name=iPhone 4S' test"
        exit 0
        ;;

    "test-ios-devices")
        failed=0
        test_ios_devices xcrealm "$CONFIGURATION" || failed=1
        test_ios_devices xcrealmswift "$CONFIGURATION" || failed=1
        exit $failed
        ;;

    "test-osx")
        xcrealm "-scheme OSX -configuration $CONFIGURATION test"
        exit 0
        ;;

    "test-osx-swift")
        xcrealmswift "-scheme 'RealmSwift OSX' -configuration $CONFIGURATION test"
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
        sh build.sh verify-ios-dynamic
        sh build.sh verify-ios-dynamic-debug
        sh build.sh verify-ios-swift
        sh build.sh verify-ios-swift-debug
        sh build.sh verify-ios-device
        ;;

    "verify-osx")
        sh build.sh test-osx
        sh build.sh test-browser
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
          echo "Undocumented RealmSwift declarations"
          exit 1
        fi
        exit 0
        ;;


    # FIXME: remove these targets from ci
    "verify-ios")
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
        xc "-project examples/ios/objc/RealmExamples.xcodeproj -scheme Simple -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/objc/RealmExamples.xcodeproj -scheme TableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/objc/RealmExamples.xcodeproj -scheme Migration -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/objc/RealmExamples.xcodeproj -scheme Backlink -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/objc/RealmExamples.xcodeproj -scheme GroupedTableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/objc/RealmExamples.xcodeproj -scheme Encryption -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"

        if [ ! -z "${JENKINS_HOME}" ]; then
            xc "-project examples/ios/objc/RealmExamples.xcodeproj -scheme Extension -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        fi

        # Old swift api examples
        xc "-project examples/ios/swift/RealmExamples.xcodeproj -scheme Simple -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift/RealmExamples.xcodeproj -scheme TableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift/RealmExamples.xcodeproj -scheme Migration -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift/RealmExamples.xcodeproj -scheme Encryption -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift/RealmExamples.xcodeproj -scheme Backlink -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift/RealmExamples.xcodeproj -scheme GroupedTableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"

        exit 0
        ;;

    "examples-ios-swift")
        xc "-project examples/ios/swift-next/RealmExamples.xcodeproj -scheme Simple -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift-next/RealmExamples.xcodeproj -scheme TableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift-next/RealmExamples.xcodeproj -scheme Migration -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift-next/RealmExamples.xcodeproj -scheme Encryption -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift-next/RealmExamples.xcodeproj -scheme Backlink -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        xc "-project examples/ios/swift-next/RealmExamples.xcodeproj -scheme GroupedTableView -configuration $CONFIGURATION build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    "examples-osx")
        xc "-project examples/osx/objc/RealmExamples.xcodeproj -scheme JSONImport -configuration ${CONFIGURATION} build ${CODESIGN_PARAMS}"
        ;;

    ######################################
    # Browser
    ######################################
    "browser")
        xc "-project tools/RealmBrowser/RealmBrowser.xcodeproj -scheme RealmBrowser -configuration $CONFIGURATION clean build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    "test-browser")
        xc "-project tools/RealmBrowser/RealmBrowser.xcodeproj -scheme RealmBrowser test ${CODESIGN_PARAMS}"
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

        # CocoaPods doesn't support multiple header_mappings_dir, so combine
        # both sets of headers into a single directory
        rm -rf include
        mv core/include include
        mkdir -p include/Realm
        cp Realm/*.h include/Realm
        touch include/Realm/RLMPlatform.h
        ;;

    ######################################
    # Release packaging
    ######################################
    "package-browser")
        cd tightdb_objc
        sh build.sh browser
        cd ${WORKSPACE}/tightdb_objc/tools/RealmBrowser/build/DerivedData/RealmBrowser/Build/Products/Release
        zip -r realm-browser.zip Realm\ Browser.app
        mv realm-browser.zip ${WORKSPACE}
        ;;

    "package-docs")
        cd tightdb_objc
        sh build.sh docs
        cd docs/output/*
        tar --exclude='realm-docset.tgz' \
            --exclude='realm.xar' \
            -cvzf \
            realm-docs.tgz *
        ;;

    "package-examples")
        cd tightdb_objc
        ./scripts/package_examples.rb
        if [[ $PACKAGE_REALM_SWIFT == false ]]; then
          rm -rf examples/ios/swift-next
        fi
        zip --symlinks -r realm-examples.zip examples
        ;;

    "package-test-examples")
        VERSION=$(file realm-cocoa-*.zip | grep -o '\d*\.\d*\.\d*')
        unzip realm-cocoa-*.zip

        cp $0 realm-cocoa-${VERSION}
        cd realm-cocoa-${VERSION}
        if [[ $PACKAGE_REALM_SWIFT == false ]]; then
          sh build.sh examples-ios
          sh build.sh examples-osx
        else
          sh build.sh examples
        fi
        cd ..
        rm -rf realm-cocoa-${VERSION}
        ;;

    "package-ios-static")
        cd tightdb_objc
        sh build.sh test-ios-static
        sh build.sh ios-static

        cd build/ios
        zip --symlinks -r realm-framework-ios.zip Realm.framework
        ;;

    "package-osx")
        cd tightdb_objc
        sh build.sh test-osx

        cd build/DerivedData/Realm/Build/Products/Release
        zip --symlinks -r realm-framework-osx.zip Realm.framework
        ;;

    "package-swift-source")
        cd tightdb_objc
        sh build.sh ios-dynamic
        mkdir -p dynamic_frameworks/iphoneos dynamic_frameworks/iphonesimulator
        cp -R build/DerivedData/Realm/Build/Products/Release-iphoneos-dynamic/Realm.framework dynamic_frameworks/iphoneos/Realm.framework/
        cp -R build/DerivedData/Realm/Build/Products/Release-iphonesimulator-dynamic/Realm.framework dynamic_frameworks/iphonesimulator/Realm.framework/
        rm RealmSwift/RealmSwift-Info.plist RealmSwift/Tests/RealmSwiftTests-Info.plist
        cp Realm/Realm-Info.plist RealmSwift/RealmSwift-Info.plist
        cp Realm/Tests/RealmTests-Info.plist RealmSwift/Tests/RealmSwiftTests-Info.plist
        zip --symlinks -r realm-swift-source.zip RealmSwift.xcodeproj RealmSwift dynamic_frameworks
    ;;

    "package-release")
        TEMPDIR=$(mktemp -d $TMPDIR/realm-release-package.XXXX)

        cd tightdb_objc
        VERSION=$(sh build.sh get-version)
        cd ..

        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/osx
        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/ios
        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/browser
        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/Swift

        (
            cd ${TEMPDIR}/realm-cocoa-${VERSION}/osx
            unzip ${WORKSPACE}/realm-framework-osx.zip
        )

        (
            cd ${TEMPDIR}/realm-cocoa-${VERSION}/ios
            unzip ${WORKSPACE}/realm-framework-ios.zip
        )

        (
            cd ${TEMPDIR}/realm-cocoa-${VERSION}/browser
            unzip ${WORKSPACE}/realm-browser.zip
        )

        (
            if [[ $PACKAGE_REALM_SWIFT == true ]]; then
              cd ${TEMPDIR}/realm-cocoa-${VERSION}/Swift
              unzip ${WORKSPACE}/realm-swift-source.zip
            fi
        )

        (
            cd ${WORKSPACE}/tightdb_objc
            cp -R plugin ${TEMPDIR}/realm-cocoa-${VERSION}
            cp LICENSE ${TEMPDIR}/realm-cocoa-${VERSION}/LICENSE.txt
            cp Realm/Swift/RLMSupport.swift ${TEMPDIR}/realm-cocoa-${VERSION}/Swift/
        )

        (
            cd ${TEMPDIR}/realm-cocoa-${VERSION}
            unzip ${WORKSPACE}/realm-examples.zip
        )

        cat > ${TEMPDIR}/realm-cocoa-${VERSION}/docs.webloc <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>URL</key>
    <string>http://realm.io/docs/ios/latest</string>
</dict>
</plist>
EOF

        (
          cd ${TEMPDIR}
          zip --symlinks -r realm-cocoa-${VERSION}.zip realm-cocoa-${VERSION}
          mv realm-cocoa-${VERSION}.zip ${WORKSPACE}
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

        REALM_SOURCE=$(pwd)
        mkdir $WORKSPACE
        cd $WORKSPACE
        git clone $REALM_SOURCE tightdb_objc

        echo 'Packaging iOS static'
        sh tightdb_objc/build.sh package-ios-static
        cp tightdb_objc/build/ios/realm-framework-ios.zip .

        echo 'Packaging OS X'
        sh tightdb_objc/build.sh package-osx
        cp tightdb_objc/build/DerivedData/Realm/Build/Products/Release/realm-framework-osx.zip .

        echo 'Packaging docs'
        sh tightdb_objc/build.sh package-docs
        cp tightdb_objc/docs/output/*/realm-docs.tgz .

        echo 'Packaging examples'
        cd tightdb_objc/examples
        git clean -xfd
        cd ../..

        sh tightdb_objc/build.sh package-examples
        cp tightdb_objc/realm-examples.zip .

        echo 'Packaging browser'
        sh tightdb_objc/build.sh package-browser

        echo 'Packaging Swift source'
        (
            # Reset repo state
            cd tightdb_objc
            git reset --hard
            git clean -xdf
        )
        sh tightdb_objc/build.sh package-swift-source
        cp tightdb_objc/realm-swift-source.zip .

        echo 'Building final release package'
        (
            # Reset repo state
            cd tightdb_objc
            git reset --hard
            git clean -xdf
        )
        sh tightdb_objc/build.sh package-release

        echo 'Testing packaged examples'
        sh tightdb_objc/build.sh package-test-examples

        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
