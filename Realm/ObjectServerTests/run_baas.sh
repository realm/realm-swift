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

RUN_DIR="$(pwd)"
BASE_DIR="$RUN_DIR/../.."
BUILD_DIR="$BASE_DIR/build/baas"

run_mongod() {
    pushd mongodb-*
    echo "starting mongod..."
    ./bin/mongod --quiet \
        --dbpath ./db_files \
        --bind_ip 127.0.0.1 \
        --port 26000 \
        --replSet test \
        --pidfilepath ./pid.txt
    popd
}

wait_for_mongod() {
    pushd mongodb-*
    echo "waiting for mongod to start up"
    ./bin/mongo --nodb --eval 'assert.soon(function(x){try{var d = new Mongo("127.0.0.1:26000"); return true}catch(e){return false}}, "timed out connecting")'
    ./bin/mongo --port 26000 --eval 'rs.initiate()'
    echo "mongod is up."
    popd
}

shutdown_mongod() {
    set -e
    pushd mongodb-*
    ./bin/mongo --port 26000 admin --eval "db.adminCommand({replSetStepDown: 0, secondaryCatchUpPeriodSecs: 0, force: true})"
    ./bin/mongo --port 26000 admin --eval "db.shutdownServer()"
    pkill -f mongod
    echo "mongod is down."
    popd
}

run_stitch() {
    ROOT_DIR="$(pwd)"
    if [ -d "$ROOT_DIR/go" ]; then
        export GOROOT="$ROOT_DIR/go"
        export PATH="$GOROOT/bin:$PATH"
    fi
    export STITCH_PATH="$ROOT_DIR/stitch"
    export PATH="$PATH:$STITCH_PATH/etc/transpiler/bin"
    export LD_LIBRARY_PATH="$STITCH_PATH/etc/dylib/lib"
    cd "$STITCH_PATH"
    go run cmd/server/main.go --configFile "$STITCH_PATH/etc/configs/test_config.json"
}

wait_for_stitch() {
    counter=0
    until curl --output /dev/null --silent --head --fail http://127.0.0.1:9090; do
      echo "checking for API server to be up..."
      sleep 1
      (( counter++ ))
      if [ $counter -gt 100 ]; then
        exit 1
      fi
    done
}

clean_action() {
    echo "cleaning baas"
    cd "$BUILD_DIR"
    shutdown_mongod
}

build_action() {
    cd "$BUILD_DIR"
    run_mongod &
    wait_for_mongod
    cd "$BASE_DIR"
    run_stitch &
    wait_for_stitch
    echo "api server up"
}

case $1 in
    "")
        build_action
        ;;

    "clean")
        clean_action
        ;;
esac
