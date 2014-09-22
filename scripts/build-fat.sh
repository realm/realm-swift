#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin

set -e
set +u

if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]; then
    SF_SDK_PLATFORM=${BASH_REMATCH[1]}
else
    echo "Could not find platform name from SDK_NAME: $SDK_NAME"
    exit 1
fi

# debug vs release
if [[ "$CONFIGURATION" = "Debug" ]]; then
    SF_CORE_PATH="${SRCROOT}/core/libtightdb-ios-dbg.a"
else
    SF_CORE_PATH="${SRCROOT}/core/libtightdb-ios.a"
fi

# We have to build the other platform and combine with it and the core libraries
REALM_TARGET_NAME="iOS"
SF_OUT_DIR="${SRCROOT}/build/iOS"
XC_OUT_DIR="${BUILT_PRODUCTS_DIR}/.."
SF_REALM_BIN="Realm.framework/Realm"
SF_OUT_BIN="${SF_OUT_DIR}/${SF_REALM_BIN}"

# Step 1 - build other platform
xcrun xcodebuild -project "${PROJECT_FILE_PATH}" -target "${REALM_TARGET_NAME}" -configuration "${CONFIGURATION}" -sdk "iphoneos${SF_SDK_VERSION}" BUILD_DIR="${BUILD_DIR}" OBJROOT="${OBJROOT}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" clean build
xcrun xcodebuild -project "${PROJECT_FILE_PATH}" -target "${REALM_TARGET_NAME}" -configuration "${CONFIGURATION}" -sdk "iphonesimulator${SF_SDK_VERSION}" BUILD_DIR="${BUILD_DIR}" OBJROOT="${OBJROOT}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" clean build

# Step 2 - move files and make fat
mkdir -p "${SF_OUT_DIR}"
cp -R "${XC_OUT_DIR}/${CONFIGURATION}-iphoneos/Realm.framework" "${SF_OUT_DIR}" 
rm "${SF_OUT_BIN}"
xcrun lipo -create "${XC_OUT_DIR}/${CONFIGURATION}-iphoneos/${SF_REALM_BIN}" "${XC_OUT_DIR}/${CONFIGURATION}-iphonesimulator/${SF_REALM_BIN}" -output "${SF_OUT_BIN}"

