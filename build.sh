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
    REALM_CORE_VERSION=0.88.4
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
  ios-dynamic [xcmode]:    builds two iOS 8 dynamic frameworks: one for devices and one for the simulator
  osx [xcmode]:            builds OS X framework with release configuration
  osx-debug [xcmode]:      builds OS X framework with debug configuration
  test-ios [xcmode]:       tests iOS framework with release configuration
  test-ios-devices:        tests iOS on all attached iOS devices with release configuration
  test-ios-devices-debug:  tests iOS on all attached iOS devices with debug configuration
  test-osx [xcmode]:       tests OSX framework with release configuration
  test [xcmode]:           tests iOS and OS X frameworks with release configuration
  test-debug [xcmode]:     tests iOS and OS X frameworks with debug configuration
  test-all [xcmode]:       tests iOS and OS X frameworks with debug and release configurations
  examples [xcmode]:       builds all examples in examples/ in release configuration
  examples-debug [xcmode]: builds all examples in examples/ in debug configuration
  browser [xcmode]:        builds the Realm Browser OSX app
  test-browser [xcmode]:   tests the Realm Browser OSX app
  verify [xcmode]:         cleans, removes docs/output/, then runs docs, test-all, examples & browser
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

build_fat() {
    target="$1"
    config="$2"
    build_prefix="$3"
    out_dir="$4"

    xcrealm "-scheme '$target' -configuration $config -sdk iphoneos"
    xcrealm "-scheme '$target' -configuration $config -sdk iphonesimulator"

    srcdir="build/DerivedData/Realm/Build/Products/$config-dynamic"
    mkdir -p build/$out_dir
    rm -rf build/$out_dir/Realm.framework
    cp -R $build_prefix-iphoneos/Realm.framework build/$out_dir
    if [ -d build/$out_dir/Realm.framework/Modules/Realm.swiftmodule ]; then
        cp $build_prefix-iphonesimulator/Realm.framework/Modules/Realm.swiftmodule/* build/$out_dir/Realm.framework/Modules/Realm.swiftmodule/
    fi
    xcrun lipo -create "$build_prefix-iphonesimulator/Realm.framework/Realm" "$build_prefix-iphoneos/Realm.framework/Realm" -output "build/$out_dir/Realm.framework/Realm"
}

######################################
# Device Test Helper
######################################

test_ios_devices() {
    XCMODE="$2"
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
    configuration="$1"
    for device in "${serial_numbers[@]}"; do
        xcrealm "-scheme 'iOS Device Tests' -configuration $configuration -destination 'id=$device' test"
    done
    exit 0
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
    TMP_DIR="/tmp/core_bin"
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
XCMODE="$2"
: ${XCMODE:=xcodebuild} # must be one of: xcodebuild (default), xcpretty, xctool


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
        if [ -d core -a -d ../tightdb -a ! -L core ]; then
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
        build_fat iOS Release build/DerivedData/Realm/Build/Products/Release ios
        exit 0
        ;;

    "ios-dynamic")
        xcrealm "-scheme 'iOS 8' -configuration Release -sdk iphoneos"
        xcrealm "-scheme 'iOS 8' -configuration Release -sdk iphonesimulator"
        mkdir -p build/ios/Realm-dynamic build/ios/Realm-dynamic-simulator
        mv build/DerivedData/Realm/Build/Products/Release-dynamic-iphoneos/Realm.framework build/ios/Realm-dynamic/Realm.framework
        mv build/DerivedData/Realm/Build/Products/Release-dynamic-iphonesimulator/Realm.framework build/ios/Realm-dynamic-simulator/Realm.framework
        exit 0
        ;;

    "osx")
        xcrealm "-scheme OSX -configuration Release"
        exit 0
        ;;

    "ios-debug")
        build_fat iOS Debug build/DerivedData/Realm/Build/Products/Debug ios
        exit 0
        ;;

    "osx-debug")
        xcrealm "-scheme OSX -configuration Debug"
        exit 0
        ;;

    ######################################
    # Testing
    ######################################
    "test")
        set +e # Run both sets of tests even if the first fails
        failed=0
        sh build.sh test-ios "$XCMODE" || failed=1
        sh build.sh test-ios-devices "$XCMODE" || failed=1
        sh build.sh test-osx "$XCMODE" || failed=1
        exit $failed
        ;;

    "test-debug")
        set +e
        failed=0
        sh build.sh test-ios-debug "$XCMODE" || failed=1
        sh build.sh test-ios-devices-debug "$XCMODE" || failed=1
        sh build.sh test-osx-debug "$XCMODE" || failed=1
        exit $failed
        ;;

    "test-all")
        set +e
        failed=0
        sh build.sh test "$XCMODE" || failed=1
        sh build.sh test-debug "$XCMODE" || failed=1
        exit $failed
        ;;

    "test-ios")
        xcrealm "-scheme iOS -configuration Release -sdk iphonesimulator -destination 'name=iPhone 6' test"
        xcrealm "-scheme iOS -configuration Release -sdk iphonesimulator -destination 'name=iPhone 4S' test"
        xcrealm "-scheme 'iOS 8' -configuration Release -sdk iphonesimulator -destination 'name=iPhone 6' test"
        exit 0
        ;;

    "test-ios-devices")
        test_ios_devices "Release" "$XCMODE"
        ;;

    "test-osx")
        xcrealm "-scheme OSX -configuration Release test"
        exit 0
        ;;

    "test-ios-debug")
        xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator -destination 'name=iPhone 6' test"
        xcrealm "-scheme iOS -configuration Debug -sdk iphonesimulator -destination 'name=iPhone 4S' test"
        xcrealm "-scheme 'iOS 8' -configuration Debug -sdk iphonesimulator -destination 'name=iPhone 6' test"
        exit 0
        ;;

    "test-ios-devices-debug")
        test_ios_devices "Debug" "$XCMODE"
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
        sh build.sh browser "$XCMODE"
        sh build.sh test-browser "$XCMODE"

        (
            cd examples/osx/objc/build/DerivedData/RealmExamples/Build/Products/Release
            DYLD_FRAMEWORK_PATH=. ./JSONImport
        ) || exit 1

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

        cd examples
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme Simple -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme TableView -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme Migration -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme Backlink -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme GroupedTableView -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project osx/objc/RealmExamples.xcodeproj -scheme JSONImport -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Simple -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme TableView -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Migration -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Encryption -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Backlink -configuration Release build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme GroupedTableView -configuration Release build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    "examples-debug")
        sh build.sh clean
        cd examples
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme Simple -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme TableView -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme Migration -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme Backlink -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/objc/RealmExamples.xcodeproj -scheme GroupedTableView -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project osx/objc/RealmExamples.xcodeproj -scheme JSONImport -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Simple -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme TableView -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Migration -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Encryption -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme Backlink -configuration Debug build ${CODESIGN_PARAMS}"
        xc "-project ios/swift/RealmExamples.xcodeproj -scheme GroupedTableView -configuration Debug build ${CODESIGN_PARAMS}"
        exit 0
        ;;

    ######################################
    # Browser
    ######################################
    "browser")
        xc "-project tools/RealmBrowser/RealmBrowser.xcodeproj -scheme RealmBrowser -configuration Release clean build ${CODESIGN_PARAMS}"
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
        sh build.sh browser "$XCMODE"
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
        zip --symlinks -r realm-obj-examples.zip examples
        ;;

    "package-test-examples")
        VERSION=$(file realm-cocoa-*.zip | grep -o '\d*\.\d*\.\d*')
        unzip realm-cocoa-*.zip

        cp $0 realm-cocoa-${VERSION}
        cd realm-cocoa-${VERSION}
        sh build.sh examples "$XCMODE"
        cd ..
        rm -rf realm-cocoa-*
        ;;

    "package-ios")
        cd tightdb_objc
        sh build.sh test-ios "$XCMODE"
        sh build.sh examples "$XCMODE"
        sh build.sh ios-dynamic "$XCMODE"

        cd build/ios
        zip --symlinks -r realm-framework-ios.zip Realm*
        ;;

    "package-osx")
        cd tightdb_objc
        sh build.sh test-osx "$XCMODE"

        cd build/DerivedData/Realm/Build/Products/Release
        zip --symlinks -r realm-framework-osx.zip Realm.framework
        ;;

    "package-release")
        TEMPDIR=$(mktemp -d /tmp/realm-release-package.XXXX)

        cd tightdb_objc
        VERSION=$(sh build.sh get-version)
        cd ..

        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/osx
        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/ios
        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/browser

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
            cd ${TEMPDIR}/realm-cocoa-${VERSION}
            unzip ${WORKSPACE}/realm-obj-examples.zip
        )

        cp -R ${WORKSPACE}/tightdb_objc/plugin ${TEMPDIR}/realm-cocoa-${VERSION}
        cp ${WORKSPACE}/tightdb_objc/LICENSE ${TEMPDIR}/realm-cocoa-${VERSION}/LICENSE.txt
        mkdir -p ${TEMPDIR}/realm-cocoa-${VERSION}/Swift
        cp ${WORKSPACE}/tightdb_objc/Realm/Swift/RLMSupport.swift ${TEMPDIR}/realm-cocoa-${VERSION}/Swift/

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

        echo 'Packaging iOS'
        sh tightdb_objc/build.sh package-ios "$XCMODE"
        cp tightdb_objc/build/ios/realm-framework-ios.zip .

        echo 'Packaging OS X'
        sh tightdb_objc/build.sh package-osx "$XCMODE"
        cp tightdb_objc/build/DerivedData/Realm/Build/Products/Release/realm-framework-osx.zip .

        echo 'Packaging docs'
        sh tightdb_objc/build.sh package-docs
        cp tightdb_objc/docs/output/*/realm-docs.tgz .

        echo 'Packaging examples'
        cd tightdb_objc/examples
        git clean -xfd
        cd ../..

        sh tightdb_objc/build.sh package-examples "$XCMODE"
        cp tightdb_objc/realm-obj-examples.zip .

        echo 'Packaging browser'
        sh tightdb_objc/build.sh package-browser "$XCMODE"

        echo 'Building final release package'
        sh tightdb_objc/build.sh package-release

        echo 'Testing packaged examples'
        sh tightdb_objc/build.sh package-test-examples "$XCMODE"

        ;;

    *)
        usage
        exit 1
        ;;
esac
