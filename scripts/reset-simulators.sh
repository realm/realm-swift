#!/bin/bash

set -o pipefail
set -e

source "$(dirname "$0")/swift-version.sh"
set_xcode_and_swift_versions

"$(dirname "$0")/reset-simulators.rb"
