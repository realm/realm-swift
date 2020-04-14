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

mongodb_url=http://fastdl.mongodb.org/osx/mongodb-osx-ssl-x86_64-4.0.2.tgz;
transpiler_target=node8-macos;
server_stitch_lib_url="https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/stitch-support/osx-1010/80f9a13324fc36b2deb400e5a185968f6fa8f64a/stitch-support-4.1.7-319-g80f9a13324.tgz";

function setup_mongod() {
    curl --silent ${mongodb_url} | tar xz
    pushd mongodb-*
    mkdir db_files
    popd
}

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

function setup_stitch() {
    OG_DIR=`pwd`
    echo "cloning stitch"
    git clone git@github.com:10gen/stitch

    cd stitch
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
    curl -s "$server_stitch_lib_url" | tar xvfz - --strip-components=1
    cd -

    echo "building transpiler"
    cd stitch/etc/transpiler
    curl -O "https://nodejs.org/dist/v8.11.2/node-v8.11.2-darwin-x64.tar.gz"
    tar zxf node-v8.11.2-darwin-x64.tar.gz
    export PATH=`pwd`/node-v8.11.2-darwin-x64/bin/:$PATH
    rm -rf $HOME/.yarn
    curl -o- -L https://yarnpkg.com/install.sh | bash
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    yarn install && yarn run build -t ${transpiler_target}

    cd $OG_DIR
    export ROOT_DIR=`pwd`
    export PATH=$ROOT_DIR/:$PATH
    curl --silent https://dl.google.com/go/go1.13.darwin-amd64.tar.gz | tar xz
    export GOROOT=$ROOT_DIR/go
    export PATH=$GOROOT/bin:$PATH
    export STITCH_PATH=$ROOT_DIR/stitch
    export PATH="$PATH:$STITCH_PATH/etc/transpiler/bin"
    export LD_LIBRARY_PATH="$STITCH_PATH/etc/dylib/lib"
    echo "running stitch"
    cd $STITCH_PATH
    go run cmd/auth/user.go addUser -domainID 000000000000000000000000 -mongoURI mongodb://localhost:26000 -salt 'DQOWene1723baqD!_@#' -id "unique_user@domain.com" -password "password"
    cd $OG_DIR
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
    cd $ROOT_DIR
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

set -e

top=`pwd`
if
    mkdir build;
    cd build;

    setup_mongod
    run_mongod &
    wait_for_mongod
    setup_stitch
    run_stitch &
    wait_for_stitch
then
    echo "success"
else
    cd $top
    rm -rf build
fi
