#!/bin/bash

set -eo pipefail

cd "$(dirname "$0")"/..
if [[ "$CI_WORKFLOW" == "sync"* ]]; then
    pwd
    ls -l
    sh build.sh setup-baas
fi
