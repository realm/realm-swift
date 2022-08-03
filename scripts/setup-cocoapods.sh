#!/usr/bin/env bash

set -euo pipefail
source_root="$(dirname "$0")/.."
readonly source_root

if [ ! -f "$source_root/core/version.txt" ]; then
  sh "$source_root/scripts/download-core.sh"
fi

rm -rf "$source_root/include"
mkdir -p "$source_root/include"
cp -R "$source_root/core/realm-monorepo.xcframework/ios-arm64_armv7/Headers" "$source_root/include/core"

mkdir -p "$source_root/include"
echo '' > "$source_root/Realm/RLMPlatform.h"
cp "$source_root/Realm/"*.h "$source_root/Realm/"*.hpp "$source_root/include"
