#!/usr/bin/env bash

set -euo pipefail
source_root="$(dirname "$0")/.."
readonly source_root

# override this env variable if you need to download from a private mirror
: "${REALM_BASE_URL:="https://static.realm.io/downloads"}"
# set to "current" to always use the current build
: "${REALM_CORE_VERSION:=$(sed -n 's/^REALM_CORE_VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")}"
# Provide a fallback value for TMPDIR, relevant for Xcode Bots
: "${TMPDIR:=$(getconf DARWIN_USER_TEMP_DIR)}"

readonly dst="$source_root/core"
copy_core() {
    local src="$1"
    rm -rf "$dst"
    mkdir "$dst"
    ditto "$src" "$dst"

    # XCFramework processing only copies the "realm" headers, so put the third-party ones in a known location
    mkdir -p "$dst/include"
    find "$src" -name external -exec ditto "{}" "$dst/include/external" \; -quit
}

tries_left=3
readonly version="$REALM_CORE_VERSION"
readonly url="${REALM_BASE_URL}/core/realm-monorepo-xcframework-v${version}.tar.xz"

# First check if we need to do anything
if [ -e "$dst" ]; then
    if [ -e "$dst/version.txt" ]; then
        if [ "$(cat "$dst/version.txt")" == "$version" ]; then
            echo "Version ${version} already present"
            exit 0
        else
            echo "Switching from version $(cat "$dst/version.txt") to ${version}"
        fi
    else
        if [ "$(find "$dst" -name librealm-monorepo.a)" ]; then
            echo 'Using existing custom core build without checking version'
            exit 0
        fi
    fi
fi

# We may already have this version downloaded and just need to set it as
# the active one
readonly versioned_name="realm-core-${version}-xcframework"
readonly versioned_dir="$source_root/$versioned_name"
if [ -e "$versioned_dir/version.txt" ]; then
    echo "Setting ${version} as the active version"
    copy_core "$versioned_dir"
    exit 0
fi

echo "Downloading dependency: ${version} from ${url}"

if [ -z "$TMPDIR" ]; then
    TMPDIR='/tmp'
fi
temp_dir=$(dirname "$TMPDIR/waste")/realm-core-tmp
readonly temp_dir
mkdir -p "$temp_dir"
readonly tar_path="${temp_dir}/${versioned_name}.tar.xz"
readonly temp_path="${tar_path}.tmp"

while [ 0 -lt $tries_left ] && [ ! -f "$tar_path" ]; do
    if ! error=$(/usr/bin/curl --fail --silent --show-error --location "$url" --output "$temp_path" 2>&1); then
        tries_left=$((tries_left-1))
    else
        mv "$temp_path" "$tar_path"
    fi
done

if [ ! -f "$tar_path" ]; then
    printf "Downloading core failed:\n\t%s\n\t%s\n" "$url" "$error"
    exit 1
fi

(
    cd "$temp_dir"
    rm -rf core
    tar xf "$tar_path" --xz
    if [ ! -f core/version.txt ]; then
        printf %s "${version}" > core/version.txt
    fi

    mv core "${versioned_name}"
)

rm -rf "${versioned_dir}"
mv "${temp_dir}/${versioned_name}" "$source_root"
copy_core "$versioned_dir"
