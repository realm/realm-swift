#!/bin/sh

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

mongodb_version=4.2.5
go_version=1.13
node_version=8.11.2
stitch_rev=ce699769dbbb51162bf71567f95aa3187814685e

mongodb_url="https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-$mongodb_version.tgz"
transpiler_target="node8-macos"
server_stitch_lib_url="https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/stitch-support/macos-debug/e791a2ea966bb302ff180dd4538d87c078e74747/stitch-support-4.3.2-721-ge791a2e-patch-5e2a6ad2a4cf473ae2e67b09.tgz"

BASE_DIR=`pwd`/Realm/ObjectServerTests/build
PID_FILE="$BASE_DIR/pid.txt"

function setup_mongod() {
    set -e
    if [ ! -d "mongodb-macos-x86_64-$mongodb_version" ]
    then
        curl --silent ${mongodb_url} | tar xz
        pushd mongodb-*
        mkdir db_files
        popd
    fi
}

function run_mongod() {
    set -e
    pushd mongodb-*
    echo "starting mongod..."
    ./bin/mongod --dbpath ./db_files --port 26000 --replSet test --pidfilepath $PID_FILE
    popd
}

function wait_for_mongod() {
    set -e
    pushd mongodb-*
    echo "waiting for mongod to start up"
    ./bin/mongo --nodb --eval 'assert.soon(function(x){try{var d = new Mongo("localhost:26000"); return true}catch(e){return false}}, "timed out connecting")'
    ./bin/mongo --port 26000 --eval 'rs.initiate()'
    echo "mongod is up."
    popd
}

function shutdown_mongod() {
    set -e
    pushd mongodb-*
    ./bin/mongo --port 26000 admin --eval "db.adminCommand({replSetStepDown: 0, secondaryCatchUpPeriodSecs: 0, force: true})"
    ./bin/mongo --port 26000 admin --eval "db.shutdownServer()"
    echo "mongod is down."
    popd
}

function setup_stitch() {
    set -e
    OG_DIR=`pwd`
    echo "setting up stitch"
    if [ ! -d stitch ]
    then
        echo "cloning stitch"
        git clone git@github.com:10gen/stitch

        cd stitch
        git checkout $stitch_rev
        echo "downloading mdb dylibs"
        mkdir -p etc/dylib
        cd etc/dylib
        curl -s "https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/stitch-support/macos-debug/e791a2ea966bb302ff180dd4538d87c078e74747/stitch-support-4.3.2-721-ge791a2e-patch-5e2a6ad2a4cf473ae2e67b09.tgz" | tar xvfz - --strip-components=1
        cd $OG_DIR

        echo "downloading update_doc"
        curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7a5c9ec4432c400181c_17_10_15_01_19_33/update_doc"
        echo "downloading assisted_agg"
        curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7ab2a60ed5647001827_17_10_15_01_19_39/assisted_agg"
        chmod +x update_doc
        chmod +x assisted_agg

        mkdir -p stitch/etc/dylib
        cd stitch/etc/dylib
        curl -s ${server_stitch_lib_url} | tar xvfz - --strip-components=1
        cd -

        echo "building transpiler"
        cd stitch/etc/transpiler
        if !command -v node >/dev/null 2>&1; then
            echo "downloading node 🚀"
            curl -O "https://nodejs.org/dist/v8.11.2/node-v$node_version-darwin-x64.tar.gz"
            tar zxf node-v8.11.2-darwin-x64.tar.gz
            export PATH=`pwd`/node-v8.11.2-darwin-x64/bin/:$PATH
        fi

        rm -rf $HOME/.yarn
        curl -o- -L https://yarnpkg.com/install.sh | bash
        export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
        yarn install && yarn run build -t ${transpiler_target}

        cd $OG_DIR
        export ROOT_DIR=`pwd`
        export PATH=$ROOT_DIR/:$PATH

        echo "downloading go"
        curl --silent "https://dl.google.com/go/go$go_version.darwin-amd64.tar.gz" | tar xz
        export GOROOT=$ROOT_DIR/go
        export PATH=$GOROOT/bin:$PATH

        export STITCH_PATH=$ROOT_DIR/stitch
        export PATH="$PATH:$STITCH_PATH/etc/transpiler/bin"
        export LD_LIBRARY_PATH="$STITCH_PATH/etc/dylib/lib"
        echo "running stitch"
        cd $STITCH_PATH
        go run cmd/auth/user.go addUser \
            -domainID 000000000000000000000000 \
            -mongoURI mongodb://localhost:26000 \
            -salt 'DQOWene1723baqD!_@#' \
            -id "unique_user@domain.com" \
            -password "password"
        cd $OG_DIR
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# MAIN

echo "Running with ACTION=${ACTION}"

function build_action() {
    echo "building baas"
    mkdir -p $BASE_DIR
    cd $BASE_DIR
    setup_mongod
    run_mongod &
    wait_for_mongod
    setup_stitch
    shutdown_mongod
}

function clean_action() {
    echo "cleaning baas"
    shutdown_mongod
    rm -rf $BASE_DIR
}

case $1 in
    "")
        build_action
        ;;

    "clean")
        clean_action
        ;;
esac
