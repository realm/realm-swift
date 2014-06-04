#!/bin/bash
# Download and unpack core library

# FIXME: The location should be realm_core_ios
# FIXME: and we must have a realm_core_osx too

# Location
REALM_CORE=realm_core

# Clean up old version
rm -rf "$REALM_CORE"

# Download
# FIXME: for real
cp ../tightdb/realm-core-ios.tar.gz .

# Unpack
tar xzf realm-core-ios.tar.gz
rm -f realm-core-ios.tar.gz
