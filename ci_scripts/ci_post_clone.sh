#!/bin/sh

# Set the -e flag to stop running the script in case a command returns
# a non-zero exit code.
set -e

if [ "$CI_WORKFLOW" = "SwiftLint" ]; then
    brew install swiftlint
fi
