get_swift_version() {
    xcrun swift --version 2>/dev/null | sed -ne 's/^Apple Swift version \([^\b ]*\).*/\1/p'
}

find_xcode_for_swift() {
    # First check if the currently active one is fine
    version="$(get_swift_version || true)"
    if [[ "$version" = "$1" ]]; then
        return 0
    fi

    local xcodes dev_dir version

    # Check all installed copies of Xcode for the desired Swift version
    xcodes=()
    dev_dir="Contents/Developer"
    for dir in $(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null); do
        [[ -d "$dir" && -n "$(ls -A "$dir/$dev_dir")" ]] && xcodes+=("$dir/$dev_dir")
    done

    for dir in "${xcodes[@]}"; do
        export DEVELOPER_DIR="$dir"
        version="$(get_swift_version)"
        if [[ "$version" = "$1" ]]; then
            return 0
        fi
    done

    >&2 echo "No version of Xcode found that supports Swift $1"
    return 1
}

if [[ "$REALM_SWIFT_VERSION" ]]; then
    find_xcode_for_swift $REALM_SWIFT_VERSION
else
    REALM_SWIFT_VERSION=$(get_swift_version)
    if [[ -z "$DEVELOPER_DIR" ]]; then
        export DEVELOPER_DIR="$(xcode-select -p)"
    fi
fi
