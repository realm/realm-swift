#!/usr/bin/env bash

if [ -n "$JENKINS_HOME" ]; then
  CI_RUN=true
else
  CI_RUN=${CI_RUN:-false}
fi

get_swift_version() {
    "$1" --version 2>/dev/null | sed -ne 's/^Apple Swift version \([^\b ]*\).*/\1/p'
}

get_xcode_version() {
    "$1" -version 2>/dev/null | sed -ne 's/^Xcode \([^\b ]*\).*/\1/p'
}

find_xcode_with_version() {
    local path required_version
    
    if [ -z "$1" ]; then
        echo "find_xcode_with_version requires an Xcode version" >&2
        exit 1
    fi
    required_version=$1
    
    # First check if the currently active one is fine, unless we are in a CI run
    if [ $CI_RUN == false ] && [ $(get_xcode_version xcodebuild) = "$required_version" ]; then
        DEVELOPER_DIR=$(xcode-select -p)
        return 0
    fi
    
    # Check all of the items in /Applications that look promising per #4534
    for path in /Applications/Xcode*.app/Contents/Developer; do
        if [ $(get_xcode_version "$path/usr/bin/xcodebuild") = "$required_version" ]; then
            DEVELOPER_DIR=$path
            return 0
        fi
    done
    
    # Use Spotlight to see if we can find others installed copies of Xcode
    for path in $(/usr/bin/mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null); do
        path="$path/Contents/Developer"
        if [ ! -d "$path" ]; then
            continue
        fi
        if [ $(get_xcode_version "$path/usr/bin/xcodebuild") = "$required_version" ]; then
            DEVELOPER_DIR=$path
            return 0
        fi
    done

    echo "No Xcode found with version $required_version" >&2
    exit 1
}

test_xcode_for_swift_version() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "test_xcode_for_swift_version called with empty parameter(s): '$1' or '$2'" >&2
        exit 1
    fi
    local path=$1
    local required_version=$2
    
    for swift in "$path"/Toolchains/*.xctoolchain/usr/bin/swift; do
        if [ $(get_swift_version "$swift") = "$required_version" ]; then
            return 0
        fi
    done
    return 1
}

find_xcode_for_swift() {
    local path required_version
    
    if [ -z "$1" ]; then
        echo "find_xcode_for_swift requires a Swift version" >&2
        exit 1
    fi
    required_version=$1
    
    # First check if the currently active one is fine, unless we are in a CI run
    if [ $CI_RUN == false ] && test_xcode_for_swift_version "$(xcode-select -p)" "$required_version"; then
        DEVELOPER_DIR=$(xcode-select -p)
        return 0
    fi

    # Check all of the items in /Applications that look promising per #4534
    for path in /Applications/Xcode*.app/Contents/Developer; do
        if test_xcode_for_swift_version "$path" "$required_version"; then
            DEVELOPER_DIR=$path
            return 0
        fi
    done
    
    # Use Spotlight to see if we can find others installed copies of Xcode
    for path in $(/usr/bin/mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null); do
        path="$path/Contents/Developer"
        if [ ! -d "$path" ]; then
            continue
        fi
        if test_xcode_for_swift_version "$path" "$required_version"; then
            DEVELOPER_DIR=$path
            return 0
        fi
    done
    
    echo "No version of Xcode found that supports Swift $required_version" >&2
    exit 1
}

set_xcode_and_swift_versions() {
    local target_xcode_version=${1:-$REALM_XCODE_VERSION}
    local target_swift_version=${2:-$REALM_SWIFT_VERSION}
    if [ -n "$target_xcode_version" ]; then
        find_xcode_with_version $target_xcode_version
        
        if [ -n "$target_swift_version" ] && ! test_xcode_for_swift_version "$DEVELOPER_DIR" "$target_swift_version"; then
            echo "The version of Xcode specified ($REALM_XCODE_VERSION) does not support the Swift version required: $target_swift_version"
            exit 1
        fi
    elif [ -n "$target_swift_version" ]; then
        find_xcode_for_swift $target_swift_version
    elif [ -z "$DEVELOPER_DIR" ]; then
        DEVELOPER_DIR="$(xcode-select -p)"
        REALM_XCODE_VERSION=
    fi
    export DEVELOPER_DIR
    
    if [ -z "$REALM_XCODE_VERSION" ]; then
        REALM_XCODE_VERSION=$(get_xcode_version "$(xcrun -f xcodebuild)")
    fi
    export REALM_XCODE_VERSION
    
    if [ -z "$REALM_SWIFT_VERSION" ]; then
        REALM_SWIFT_VERSION=$(get_swift_version "$(xcrun -f swift)")
    fi
    export REALM_SWIFT_VERSION
}

return 2>/dev/null || { # only run if called directly
    set_xcode_and_swift_versions
    echo "Found Swift version $REALM_SWIFT_VERSION in $DEVELOPER_DIR"
}
