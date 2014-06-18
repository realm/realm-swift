#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin

set -e
set +u

# lib/framework paths
SF_FRAMEWORK_PATH="${SRCROOT}/build/${CONFIGURATION}/${PRODUCT_NAME}.framework"
SF_COMBINED_PATH="${BUILD_DIR}/${CONFIGURATION}/libRealm-combined.a"

# very simple structure - it doesn't follow Apple's documentation
rm -rf "${SF_FRAMEWORK_PATH}"
mkdir -p "${SF_FRAMEWORK_PATH}/Headers"

# Step 1 - copy combined binary into framework
cp ${SF_COMBINED_PATH} "${SF_FRAMEWORK_PATH}/${PRODUCT_NAME}"

# Step 2 - copy headers into framework
if [[ "$CONFIGURATION" = "Debug" ]]; then
    cp -R "${BUILT_PRODUCTS_DIR}/include/Realm" "${SF_FRAMEWORK_PATH}/Headers"
else
    cp -R "${BUILT_PRODUCTS_DIR}/../Release-iphonesimulator/include/Realm" "${SF_FRAMEWORK_PATH}/Headers"
fi

# Step 3 - copy resources
mkdir -p "${SF_FRAMEWORK_PATH}/Resources"
xcrun cp "${SRCROOT}/LICENSE" "${SF_FRAMEWORK_PATH}/Resources"
xcrun cp "${SRCROOT}/CHANGELOG.md" "${SF_FRAMEWORK_PATH}/Resources"
xcrun cp "${SRCROOT}/Realm/Realm-Info.plist" "${SF_FRAMEWORK_PATH}/Resources/Info.plist"

cd "${SF_FRAMEWORK_PATH}"
mkdir -p "Versions/A/Headers"
mv Headers/Realm/* Versions/A/Headers/
rm -rf Headers
mv "${PRODUCT_NAME}" "Versions/A/${PRODUCT_NAME}"
ln -fs "Versions/A/${PRODUCT_NAME}" "${PRODUCT_NAME}"
ln -fs "Versions/A/Headers" "Headers"
