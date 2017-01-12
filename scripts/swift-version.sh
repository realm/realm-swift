#!/usr/bin/env bash

get_swift_version() {
    "$1" --version 2>/dev/null | sed -ne 's/^Apple Swift version \([^\b ]*\).*/\1/p'
}

test_xcode_for_swift_version() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "test_xcode_for_swift_version called with empty parameter(s): `$1` or `$2`" >&2
        exit 1
    fi
    local path=$1
    local required_version=$2
    
    for swift in "$path"/Toolchains/*.xctoolchain/usr/bin/swift; do
        if [[ $(get_swift_version "$swift") == "$required_version" ]]; then
            return 0
        fi
    done
    return 1
}

find_xcode_for_swift() {
    local path required_version
    
    if [ -z "$1" ]; then
        echo "find_xcode_for_swift requres a Swift version" >&2
        exit 1
    fi
    required_version=$1
    
    # First check if the currently active one is fine, unless we are in a CI run
    if [ -z "$JENKINS_HOME" ]; then
        if [[ $(get_swift_version `xcrun -f swift`) = "$required_version" ]]; then
            export DEVELOPER_DIR=$(xcode-select -p)
            return 0
        fi
    fi

    # Check all of the items in /Applications that look promising per #4534
    for path in /Applications/Xcode*.app/Contents/Developer; do
        if test_xcode_for_swift_version "$path" "$required_version"; then
            export DEVELOPER_DIR=$path
            return 0
        else
            echo "nope: $path"
        fi
    done
    
    # Use Spotlight to see if we can find others installed copies of Xcode
    for path in $(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null); do
        path="$path/Contents/Developer"
        if [ ! -d "$path" ]; then
            continue
        fi
        if test_xcode_for_swift_version "$path" "$required_version"; then
            export DEVELOPER_DIR=$path
            return 0
        fi
    done
    
    echo "No version of Xcode found that supports Swift $required_version" >&2
    exit 1
}

if [[ "$REALM_SWIFT_VERSION" ]]; then
    find_xcode_for_swift $REALM_SWIFT_VERSION
else
    REALM_SWIFT_VERSION=$(get_swift_version xcrun swift)
    if [[ -z "$DEVELOPER_DIR" ]]; then
        export DEVELOPER_DIR="$(xcode-select -p)"
    fi
fi

return 2>/dev/null || { # only run if called directly
    echo "Found Swift version $REALM_SWIFT_VERSION in $DEVELOPER_DIR"
}
