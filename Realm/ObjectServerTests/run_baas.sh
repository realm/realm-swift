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

function run_mongod() {
    pushd mongodb-*
    echo "starting mongod..."
    ./bin/mongod --dbpath ./db_files --port 26000 --replSet test --pidfilepath ./pid.txt
    popd
}

function wait_for_mongod() {
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

function run_stitch() {
    ROOT_DIR=`pwd`
    export PATH=$ROOT_DIR/:$PATH
    export GOROOT=$ROOT_DIR/go
    export PATH=$GOROOT/bin:$PATH
    export STITCH_PATH=$ROOT_DIR/stitch
    export PATH="$PATH:$STITCH_PATH/etc/transpiler/bin"
    export LD_LIBRARY_PATH="$STITCH_PATH/etc/dylib/lib"
    cd $STITCH_PATH
    go run cmd/server/main.go --configFile $STITCH_PATH/etc/configs/test_config.json
}

function wait_for_stitch() {
    counter=0
    until $(curl --output /dev/null --silent --head --fail http://localhost:9090); do
      echo "checking for API server to be up..."
      sleep 1
      let counter++
      if [ $counter -gt 100 ]; then
        exit 1
      fi
    done
}

function clean_action() {
    echo "cleaning baas"
    cd build
    shutdown_mongod
}

function build_action() {
    cd build
    run_mongod &
    wait_for_mongod
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
