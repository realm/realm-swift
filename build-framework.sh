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

# Step 2
# The -a ensures that the headers maintain the source modification date so that we don't constantly
# cause propagating rebuilds of files that import these headers.
# Headers with Private in the name are not public headers, and must not be copied.
/bin/ls "${SRCROOT}/Realm" | grep -v Private | grep -e "\.h$" | while read header; do
    /bin/cp -a "${SRCROOT}/Realm/${header}" "${SF_FRAMEWORK_PATH}/Headers/${header}"
done


