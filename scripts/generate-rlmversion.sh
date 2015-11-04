#!/bin/sh

: ${SRCROOT:?"generate-rlmversion.sh must be invoked as part of an Xcode script phase"}

TEMPORARY_FILE="${TARGET_TEMP_DIR}/RLMVersion.h"
DESTINATION_FILE="${DERIVED_FILE_DIR}/RLMVersion.h"

echo "#define REALM_COCOA_VERSION @\"$(sh build.sh get-version)\"" > ${TEMPORARY_FILE}

if ! cmp -s "${TEMPORARY_FILE}" "${DESTINATION_FILE}"; then
  echo "Updating ${DESTINATION_FILE}"
  cp "${TEMPORARY_FILE}" "${DESTINATION_FILE}"
fi
