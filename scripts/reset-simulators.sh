#!/bin/bash

set -o pipefail
set -e

while pgrep -q Simulator; do
    # Kill all the current simulator processes as they may be from a
    # different Xcode version
    pkill Simulator 2>/dev/null || true
    # CoreSimulatorService doesn't exit when sent SIGTERM
    pkill -9 Simulator 2>/dev/null || true
  done

# Shut down simulators until there's no booted ones left
# Only do one at a time because devices sometimes show up multiple times
while xcrun simctl list | grep -q Booted; do
  xcrun simctl list | grep Booted | sed 's/.* (\(.*\)) (Booted)/\1/' | head -n 1 | xargs xcrun simctl shutdown
done

# Clean up all available simulators
(
    previous_device=''
    IFS=$'\n' # make newlines the only separator
    for LINE in $(xcrun simctl list); do
        if [[ $LINE =~ unavailable || $LINE =~ disconnected ]]; then
            # skip unavailable simulators
            continue
        fi

        if [[ $LINE =~ "--" ]]; then
            # Reset the last seen device so we won't consider devices with the same name to be duplicates
            # if they appear in different sections.
            previous_device=""
            continue
        fi

        regex='^(.*) [(]([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})[)]'
        if [[ $LINE =~ $regex ]]; then
            device="${BASH_REMATCH[1]}"
            guid="${BASH_REMATCH[2]}"

            # Delete the simulator if it's a duplicate of the last seen one
            # Otherwise delete all contents and settings for it
            if [[ $device == $previous_device ]]; then
                xcrun simctl delete $guid
            else
                xcrun simctl erase $guid
                previous_device="$device"
            fi
        fi
    done
)

if [[ -a "${DEVELOPER_DIR}/Applications/iOS Simulator.app" ]]; then
    open "${DEVELOPER_DIR}/Applications/iOS Simulator.app"
elif [[ -a "${DEVELOPER_DIR}/Applications/Simulator.app" ]]; then
    open "${DEVELOPER_DIR}/Applications/Simulator.app"
fi

