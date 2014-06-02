set -e
set +u

# Avoid recursively calling this script.
if [[ $SF_MASTER_SCRIPT_RUNNING ]]; then
  exit 0
fi
set -u
export SF_MASTER_SCRIPT_RUNNING=1


# The following conditionals come from
# https://github.com/kstenerud/iOS-Universal-Framework

if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]; then
  SF_SDK_PLATFORM=${BASH_REMATCH[1]}
else
  echo "Could not find platform name from SDK_NAME: $SDK_NAME"
  exit 1
fi

if [[ "$SDK_NAME" =~ ([0-9]+.*$) ]]; then
  SF_SDK_VERSION=${BASH_REMATCH[1]}
else
  echo "Could not find sdk version from SDK_NAME: $SDK_NAME"
  exit 1
fi

if [[ "$SF_SDK_PLATFORM" = "iphoneos" ]]; then
  SF_OTHER_PLATFORM=iphonesimulator
else
  SF_OTHER_PLATFORM=iphoneos
fi

if [[ "$BUILT_PRODUCTS_DIR" =~ (.*)$SF_SDK_PLATFORM$ ]]; then
  SF_OTHER_BUILT_PRODUCTS_DIR="${BASH_REMATCH[1]}${SF_OTHER_PLATFORM}"
else
  echo "Could not find platform name from build products directory: $BUILT_PRODUCTS_DIR"
  exit 1
fi

# debug vs release
if [[ "$CONFIGURATION" = "Debug" ]]; then
    SF_CORE_PATH="${SRCROOT}/realm-core/libtightdb-ios-dbg.a"
else
    SF_CORE_PATH="${SRCROOT}/realm-core/libtightdb-ios.a"
fi


# We have to build the other platform and combine with it and the core libraries
REALM_TARGET_NAME=Realm-iOS
SF_FAT_PATH="${BUILD_DIR}/libRealm-fat.a"
SF_LIB_PATH="${BUILT_PRODUCTS_DIR}/libRealm.a"
SF_OTHER_LIB_PATH="${SF_OTHER_BUILT_PRODUCTS_DIR}/libRealm.a"
SF_COMBINED_PATH="${BUILD_DIR}/libRealm-combined.a"

# Step 1 - build other platform
xcrun xcodebuild -project "${PROJECT_FILE_PATH}" -target "${REALM_TARGET_NAME}" -configuration "${CONFIGURATION}" -sdk ${SF_OTHER_PLATFORM}${SF_SDK_VERSION} BUILD_DIR="${BUILD_DIR}" OBJROOT="${OBJROOT}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" clean build

# Step 2 - move files and make fat
xcrun lipo -create ${SF_LIB_PATH} ${SF_OTHER_LIB_PATH} -output ${SF_FAT_PATH}

# Step 3 - combine with tightdb
xcrun libtool -static -o ${SF_COMBINED_PATH} ${SF_FAT_PATH} ${SF_CORE_PATH}


