#!/bin/bash

set -eo pipefail

env

if [[ "$CI_WORKFLOW" == "sync"* ]]; then
    cd ..
    sh build.sh setup-baas
    sh build.sh download-core
fi
