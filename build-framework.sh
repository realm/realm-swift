set -e
set +u

# lib/framework paths
SF_FRAMEWORK_PATH="${SRCROOT}/build/${CONFIGURATION}/${PRODUCT_NAME}.framework"
SF_COMBINED_PATH="${BUILD_DIR}/${CONFIGURATION}/libRealm-combined.a"

# very simple structure - it doesn't follow Apple's documentation
/bin/rm -rf "${SF_FRAMEWORK_PATH}"
/bin/mkdir -p "${SF_FRAMEWORK_PATH}/Headers"

# Step 1 - copy combined binary into framework
xcrun cp ${SF_COMBINED_PATH} "${SF_FRAMEWORK_PATH}/${PRODUCT_NAME}"

# Step 2 - copy headers into framework
xcrun cp -R "${BUILT_PRODUCTS_DIR}/include/Realm" "${SF_FRAMEWORK_PATH}/Headers"


