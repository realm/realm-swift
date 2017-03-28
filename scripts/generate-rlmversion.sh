#!/bin/sh

: ${SRCROOT:?"generate-rlmversion.sh must be invoked as part of an Xcode script phase"}

TEMPORARY_FILE=${TARGET_TEMP_DIR}/RLMVersion.h
DESTINATION_FILE=${DERIVED_FILE_DIR}/RLMVersion.h
if [ -z "$REALM_VERSION_FILE" ]; then
  REALM_VERSION_FILE=$(cd "$(dirname "$0")/../Realm"; pwd)/Realm-Info.plist
fi
REALM_VERSION=`/usr/bin/defaults read "$REALM_VERSION_FILE" CFBundleVersion`

echo "#define REALM_COCOA_VERSION @\"${REALM_VERSION}\"" > ${TEMPORARY_FILE}

if ! cmp -s "${TEMPORARY_FILE}" "${DESTINATION_FILE}"; then
  echo "Updating ${DESTINATION_FILE}"
  cp "${TEMPORARY_FILE}" "${DESTINATION_FILE}"
fi
