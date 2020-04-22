#!/bin/bash

######################################
#
# Copyright 2020 Realm Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
######################################

set -e
set -o pipefail

source_root="$(cd "$(dirname "$0")"/../..; pwd)"
export $(xargs < "${source_root}/dependencies.list")

mongodb_version=4.3.6
go_version=1.14.2
node_version=8.11.2
STITCH_VERSION=f95f9bda40b5f886d1757bb17e60e8b9f3c56599

mongodb_url="https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-$mongodb_version.tgz"
transpiler_target="node8-macos"
server_stitch_lib_url="https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/stitch-support/macos-debug/e791a2ea966bb302ff180dd4538d87c078e74747/stitch-support-4.3.2-721-ge791a2e-patch-5e2a6ad2a4cf473ae2e67b09.tgz"
mongodb_directory="mongodb-macos-x86_64-$mongodb_version"

BASE_DIR=$(pwd)
BUILD_DIR=${BASE_DIR}/build/baas
PID_FILE="$BUILD_DIR/pid.txt"

setup_mongod() {
    if [ ! -d "$mongodb_directory" ]; then
        curl --silent ${mongodb_url} | tar xz
        mkdir "$mongodb_directory/db_files"
    fi
}

run_mongod() {
    echo "starting mongod..."
    "$mongodb_directory/bin/mongod" \
        --dbpath "$mongodb_directory/db_files" \
        --bind_ip 127.0.0.1 \
        --port 26000 \
        --replSet test \
        --pidfilepath "$PID_FILE"
}

wait_for_mongod() {
    echo "waiting for mongod to start up"
    "$mongodb_directory/bin/mongo" --nodb --eval 'assert.soon(function(x){try{var d = new Mongo("127.0.0.1:26000"); return true}catch(e){return false}}, "timed out connecting")'
    "$mongodb_directory/bin/mongo" --port 26000 --eval 'rs.initiate()'
    echo "mongod is up."
}

shutdown_mongod() {
    "$mongodb_directory/bin/mongo" --port 26000 admin --eval "db.adminCommand({replSetStepDown: 0, secondaryCatchUpPeriodSecs: 0, force: true})"
    "$mongodb_directory/bin/mongo" --port 26000 admin --eval "db.shutdownServer()"
    echo "mongod is down."
}

setup_stitch() {
    pushd "$BASE_DIR"

    echo "setting up stitch"

    if [ ! -d stitch ]; then
        git clone git@github.com:10gen/stitch
    fi

    echo "checking out stitch"

    cd stitch

    if [ -d .git ]; then
        git checkout $STITCH_VERSION
    fi

    if [ ! -d etc/dylib ]; then
        echo "downloading mdb dylibs"
        mkdir -p etc/dylib
        curl -s "${server_stitch_lib_url}" \
            | tar xvfz - --strip-components=1 -C etc/dylib
    fi

    if [ ! -f update_doc ]; then
        echo "downloading update_doc"
        curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7a5c9ec4432c400181c_17_10_15_01_19_33/update_doc"
        chmod +x update_doc
    fi
    if [ ! -f assisted_agg ]; then
        echo "downloading assisted_agg"
        curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7ab2a60ed5647001827_17_10_15_01_19_39/assisted_agg"
        chmod +x assisted_agg
    fi

    if ! command -v node >/dev/null 2>&1; then
        echo "downloading node 🚀"
        curl -O "https://nodejs.org/dist/v8.11.2/node-v$node_version-darwin-x64.tar.gz"
        tar zxf node-v8.11.2-darwin-x64.tar.gz
        export PATH="$(pwd)/node-v8.11.2-darwin-x64/bin/:$PATH"
    fi

    if ! command -v yarn >/dev/null 2>&1; then
        rm -rf "$HOME/.yarn"
        curl -o- -L https://yarnpkg.com/install.sh | bash
        export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    fi

    echo "building transpiler"
    cd etc/transpiler
    yarn install && yarn run build -t "${transpiler_target}"

    cd $BASE_DIR

    if [ ! -d go ]; then
        echo "downloading go"
        curl --silent "https://dl.google.com/go/go$go_version.darwin-amd64.tar.gz" | tar xz
    fi

    export GOROOT="$BASE_DIR/go"
    export PATH="$GOROOT/bin:$PATH"

    export STITCH_PATH="$BASE_DIR/stitch"
    export PATH="$PATH:$STITCH_PATH/etc/transpiler/bin"
    export LD_LIBRARY_PATH="$STITCH_PATH/etc/dylib/lib"
    echo "running stitch"
    cd "$STITCH_PATH"
    
    go run cmd/auth/user.go addUser \
        -domainID 000000000000000000000000 \
        -mongoURI mongodb://127.0.0.1:26000 \
        -salt 'DQOWene1723baqD!_@#' \
        -id "unique_user@domain.com" \
        -password "password"
    popd
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# MAIN

echo "Running with ACTION=${ACTION}"

build_action() {
    echo "building baas"
    trap shutdown_mongod ERR
    if [ ! -d "${BUILD_DIR}/mongodb-macos-x86_64-$mongodb_version" ]; then
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        setup_mongod
        run_mongod &
        wait_for_mongod
        setup_stitch
        shutdown_mongod
    else
        echo "MongoDB Realm already exists"
    fi
}

clean_action() {
    echo "cleaning baas"
    shutdown_mongod
    rm -rf "$BUILD_DIR"
}

case $1 in
    "")
        build_action
        ;;

    "clean")
        clean_action
        ;;
esac
