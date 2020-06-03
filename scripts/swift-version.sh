#!/usr/bin/env bash

: "${REALM_XCODE_VERSION:=}"
: "${REALM_SWIFT_VERSION:=}"
: "${DEVELOPER_DIR:=}"

get_swift_version() {
    "$1" --version 2>/dev/null | sed -ne 's/^Apple Swift version \([^\b ]*\).*/\1/p'
}

get_xcode_version() {
    "$1" -version 2>/dev/null | sed -ne 's/^Xcode \([^\b ]*\).*/\1/p'
}

is_xcode_version() {
    test "$(get_xcode_version "$1")" = "$2"
}

find_xcode_with_version() {
    local path required_version

    if [ -z "$1" ]; then
        echo "find_xcode_with_version requires an Xcode version" >&2
        exit 1
    fi
    required_version=$1

    # First check if the currently active one is fine, unless we are in a CI run
    if [ -z "$JENKINS_HOME" ] && is_xcode_version xcodebuild "$required_version"; then
        DEVELOPER_DIR=$(xcode-select -p)
        return 0
    fi

    # Check the spot where we install it on CI machines
    path="/Applications/Xcode-${required_version}.app/Contents/Developer"
    if [ -d "$path" ]; then
        if is_xcode_version "$path/usr/bin/xcodebuild" "$required_version"; then
            DEVELOPER_DIR=$path
            return 0
        fi
    fi

    # Check all of the items in /Applications that look promising per #4534
    for path in /Applications/Xcode*.app/Contents/Developer; do
        if is_xcode_version "$path/usr/bin/xcodebuild" "$required_version"; then
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
        if is_xcode_version "$path/usr/bin/xcodebuild" "$required_version"; then
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
        if [ "$(get_swift_version "$swift")" = "$required_version" ]; then
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
    if [ -z "$JENKINS_HOME" ] && test_xcode_for_swift_version "$(xcode-select -p)" "$required_version"; then
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

find_default_xcode_version() {
    DEVELOPER_DIR="$(xcode-select -p)"
    # Verify that DEVELOPER_DIR points to an Xcode installation, rather than the Xcode command-line tools.
    if [ -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]; then
        # It's an Xcode installation so we're good to go.
        return 0
    fi

    echo "WARNING: The active Xcode command line tools, as returned by 'xcode-select -p', are not from Xcode."
    echo "         The newest version of Xcode will be used instead."

    # Find the newest version of Xcode available on the system, based on CFBundleVersion.
    local xcode_version newest_xcode_version newest_xcode_path
    newest_xcode_version=0
    for path in $(/usr/bin/mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null); do
        xcode_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$path/Contents/Info.plist")
        if echo "$xcode_version" "$newest_xcode_version" | awk '{exit !( $1 > $2)}'; then
            newest_xcode_version="$xcode_version"
            newest_xcode_path="$path"
        fi
    done

    if [ -z "$newest_xcode_path" ]; then
        echo "No version of Xcode could be found" >&2
        exit 1
    fi

    DEVELOPER_DIR="$newest_xcode_path/Contents/Developer"
}

set_xcode_and_swift_versions() {
    if [ -n "$REALM_XCODE_VERSION" ]; then
        find_xcode_with_version "$REALM_XCODE_VERSION"

        if [ -n "$REALM_SWIFT_VERSION" ] && ! test_xcode_for_swift_version "$DEVELOPER_DIR" "$REALM_SWIFT_VERSION"; then
            echo "The version of Xcode specified ($REALM_XCODE_VERSION) does not support the Swift version required: $REALM_SWIFT_VERSION"
            exit 1
        fi
    elif [ -n "$REALM_SWIFT_VERSION" ]; then
        find_xcode_for_swift "$REALM_SWIFT_VERSION"
    elif [ -z "$DEVELOPER_DIR" ]; then
        find_default_xcode_version
    fi
    export DEVELOPER_DIR

    REALM_XCODE_VERSION="$(get_xcode_version "$DEVELOPER_DIR/usr/bin/xcodebuild")"
    export REALM_XCODE_VERSION

    if [ -z "$REALM_SWIFT_VERSION" ]; then
        REALM_SWIFT_VERSION=$(get_swift_version "$(xcrun -f swift)")
    fi
    export REALM_SWIFT_VERSION
}

return 2>/dev/null || { # only run if called directly
    set_xcode_and_swift_versions
    echo "Found Swift version $REALM_SWIFT_VERSION in Xcode $REALM_XCODE_VERSION at $DEVELOPER_DIR"
}
