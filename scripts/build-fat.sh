#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin

set -e
set -u

# Only run for release
if [[ "$CONFIGURATION" != "Release-Combined" ]]; then
    exit 0
fi


# The following conditionals come from
# https://github.com/kstenerud/iOS-Universal-Framework

if [[ "$SDK_NAME" =~ ([0-9]+.*$) ]]; then
    SF_SDK_VERSION=${BASH_REMATCH[1]}
else
    echo "Could not find sdk version from SDK_NAME: $SDK_NAME"
    exit 1
fi

# Step 1 - build platform
xcrun xcodebuild -project "${PROJECT_FILE_PATH}" -target iOS -configuration Release -sdk "iphoneos${SF_SDK_VERSION}" BUILD_DIR="${BUILD_DIR}" OBJROOT="${OBJROOT}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" build
xcrun xcodebuild -project "${PROJECT_FILE_PATH}" -target iOS -configuration Release -sdk "iphonesimulator${SF_SDK_VERSION}" BUILD_DIR="${BUILD_DIR}" OBJROOT="${OBJROOT}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" build

# Step 2 - make fat binary
SF_FRAMEWORK_PATH="${BUILT_PRODUCTS_DIR}/Realm.framework"
SF_RELEASE_IOS_PATH="${BUILT_PRODUCTS_DIR}/../Release-iphoneos/Realm.framework/Realm"
SF_RELEASE_SIM_PATH="${BUILT_PRODUCTS_DIR}/../Release-iphonesimulator/Realm.framework/Realm"
xcrun rm "${SF_FRAMEWORK_PATH}/Realm"
xcrun lipo -create "${SF_RELEASE_IOS_PATH}" "${SF_RELEASE_SIM_PATH}" -output "${SF_FRAMEWORK_PATH}/Realm" 

# Step 3 - copy out
SF_OUT_DIR="${SRCROOT}/build/ios"
if [[ ! -d "${SF_OUT_DIR}" ]]; then
    xcrun mkdir -p "${SF_OUT_DIR}"
fi
xcrun cp -R "${SF_FRAMEWORK_PATH}" "${SF_OUT_DIR}"
