#!/bin/sh

: ${SRCROOT:?"generate-rlmplatform.sh must be invoked as part of an Xcode script phase"}

SOURCE_FILE="${SRCROOT}/Realm/RLMPlatform.h.in"
DESTINATION_FILE="${TARGET_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}/RLMPlatform.h"
TEMPORARY_FILE="${TARGET_TEMP_DIR}/RLMPlatform.h"

PLATFORM_SUFFIX="$SWIFT_PLATFORM_TARGET_PREFIX"
if [ "$IS_MACCATALYST" = "YES" ]; then
  PLATFORM_SUFFIX=maccatalyst
fi

unifdef -B -DREALM_BUILDING_FOR_$(echo ${PLATFORM_SUFFIX} | tr "[:lower:]" "[:upper:]") < "${SOURCE_FILE}" | sed -e "s/''/'/" > "${TEMPORARY_FILE}"

if ! cmp -s "${TEMPORARY_FILE}" "${DESTINATION_FILE}"; then
  echo "Updating ${DESTINATION_FILE}"
  cp "${TEMPORARY_FILE}" "${DESTINATION_FILE}"
fi
