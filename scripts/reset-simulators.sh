#!/bin/bash

set -o pipefail
set -e

source "$(dirname "$0")/swift-version.sh"

while pgrep -q Simulator; do
    # Kill all the current simulator processes as they may be from a
    # different Xcode version
    pkill Simulator 2>/dev/null || true
    # CoreSimulatorService doesn't exit when sent SIGTERM
    pkill -9 Simulator 2>/dev/null || true
done

# Run until we get a result since switching simulator versions often causes CoreSimulatorService to throw an exception.
devices=""
until [ "$devices" != "" ]; do
    devices="$(xcrun simctl list devices -j || true)"
done
