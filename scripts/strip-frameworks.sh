#!/usr/bin/env bash

# This script stripped all non-valid architectures from dynamic libraries in
# the application's `Frameworks` directory.
# 
# The following environment variables are required:
# 
# BUILT_PRODUCTS_DIR
# FRAMEWORKS_FOLDER_PATH
# VALID_ARCHS

echo "Stripping frameworks"
cd "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

exit_code=0
for file in $(find . -type f -perm +111); do
  # Skip non-dynamic libraries
  if ! [[ "$(file "$file")" == *"dynamically linked shared library"* ]]; then
    continue
  fi
  # Get architectures for current file
  archs="$(lipo -info "${file}" | rev | cut -d ':' -f1 | rev)"
  stripped=""
  for arch in $archs; do
    if ! [[ "${VALID_ARCHS}" == *"$arch"* ]]; then
      # Strip non-valid architectures in-place
      lipo -remove "$arch" -output "$file" "$file" || exit_code=1
      stripped="$stripped $arch"
    fi
  done
  if [[ "$stripped" != "" ]]; then
    echo "Stripped $file of architectures:$stripped"
  fi
done

exit $exit_code
