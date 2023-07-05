#!/bin/bash

set -o pipefail
set -e

source "$(dirname "$0")/swift-version.sh"
set_xcode_version

"$(dirname "$0")/reset-simulators.rb" "$1"
