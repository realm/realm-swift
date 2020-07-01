#!/usr/bin/ruby

require 'net/http'
require 'fileutils'

MONGODB_VERSION='4.4.0-rc5'
GO_VERSION='1.14.2'
NODE_VERSION='8.11.2'
STITCH_VERSION='84893c521b3bc1e493b12c967b0d950694333a2a'

BASE_DIR = Dir.pwd
BUILD_DIR = "#{BASE_DIR}/build"
PID_FILE = "#{BUILD_DIR}/pid.txt"
STITCH_DIR = "#{BASE_DIR}/stitch"

MONGODB_URL="https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-#{MONGODB_VERSION}.tgz"
TRANSPILER_TARGET='node8-macos'
SERVER_STITCH_LIB_URL="https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/stitch-support/macos-debug/e791a2ea966bb302ff180dd4538d87c078e74747/stitch-support-4.3.2-721-ge791a2e-patch-5e2a6ad2a4cf473ae2e67b09.tgz"
MONGO_DIR="'#{BUILD_DIR}'/mongodb-macos-x86_64-#{MONGODB_VERSION}"

def setup_mongod
    if !Dir.exists?(MONGO_DIR)
        `cd '#{BUILD_DIR}' && curl --silent '#{MONGODB_URL}' | tar xz && mkdir #{MONGO_DIR}/db_files`
    end
end

def run_mongod
    puts "starting mongod..."
    puts `#{MONGO_DIR}/bin/mongod --quiet \
        --dbpath #{MONGO_DIR}/db_files \
        --port 26000 \
        --replSet test \
        --fork \
        --logpath #{MONGO_DIR}/mongod.log`
    puts "mongod starting"

    retries = 0
    begin
        Net::HTTP.get(URI('http://localhost:26000'))
    rescue => exception
        sleep(1)
        retries += 1
        if retries == 20
            abort('could not connect to mongod')
        end
    end
    puts `#{MONGO_DIR}/bin/mongo --port 26000 --eval 'rs.initiate()'`
    puts "mongod started"
end

def shutdown_mongod
    puts 'shutting down mongod'
    if Dir.exists?(MONGO_DIR)
        puts `#{MONGO_DIR}/bin/mongo --port 26000 admin --eval "db.adminCommand({replSetStepDown: 0, secondaryCatchUpPeriodSecs: 0, force: true})"`
        puts `#{MONGO_DIR}/bin/mongo --port 26000 admin --eval "db.shutdownServer({force: true})"`
    end
    puts 'mongod is down'
end

def setup_stitch
    puts "setting up stitch"
    exports = []

    if !Dir.exists?(STITCH_DIR)
        puts 'cloning stitch'
        `git clone git@github.com:10gen/baas stitch`
    end

    puts 'checking out stitch'
    `git -C '#{STITCH_DIR}' fetch && git -C '#{STITCH_DIR}' checkout #{STITCH_VERSION}`

    dylib_dir = "#{STITCH_DIR}/etc/dylib"
    if !Dir.exists?(dylib_dir)
        puts 'downloading mongodb dylibs'
        Dir.mkdir dylib_dir
        puts `curl -s "#{SERVER_STITCH_LIB_URL}" | tar xvfz - --strip-components=1 -C '#{dylib_dir}'`
    end

    update_doc_filepath = "#{STITCH_DIR}/update_doc"
    if !File.exists?(update_doc_filepath)
        puts "downloading update_doc"
        puts `cd '#{STITCH_DIR}' && curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7a5c9ec4432c400181c_17_10_15_01_19_33/update_doc"`
        puts `chmod +x '#{update_doc_filepath}'`
    end

    assisted_agg_filepath = "#{STITCH_DIR}/assisted_agg"
    if !File.exists?(assisted_agg_filepath)
        puts "downloading assisted_agg"
        puts `cd '#{STITCH_DIR}' && curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7ab2a60ed5647001827_17_10_15_01_19_39/assisted_agg"`
        puts `chmod +x '#{assisted_agg_filepath}'`
    end

    if `which node`.empty?
        puts "downloading node 🚀"
        puts `cd '#{STITCH_DIR}' && curl -O "https://nodejs.org/dist/v#{NODE_VERSION}/node-v#{NODE_VERSION}-darwin-x64.tar.gz" | tar xzf node-v#{NODE_VERSION}-darwin-x64.tar.gz`
        exports << "export PATH=\"#{STITCH_DIR}/node-v8.11.2-darwin-x64/bin/:$PATH\""
    end

    if `which yarn`.empty?
        `rm -rf "$HOME/.yarn"`
        `export PATH=\"#{STITCH_DIR}/node-v#{NODE_VERSION}-darwin-x64/bin/:$PATH\" && curl -o- -L https://yarnpkg.com/install.sh | bash`
        exports << "export PATH=\"$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH\""
    end

    puts 'building transpiler'
    puts `#{exports.length() == 0 ? "" : exports.join(' && ') + ' &&'} \
        cd '#{STITCH_DIR}/etc/transpiler' && yarn install && yarn run build -t "#{TRANSPILER_TARGET}"`

    if !Dir.exists?('go')
        puts 'downloading go'
        `curl --silent "https://dl.google.com/go/go#{GO_VERSION}.darwin-amd64.tar.gz" | tar xz`
    end

    exports << "export GOROOT=\"#{BASE_DIR}/go\""
    exports << "export PATH=\"$GOROOT/bin:$PATH\""

    exports << "export STITCH_PATH=\"#{BASE_DIR}/stitch\""
    exports << "export PATH=\"$PATH:$STITCH_PATH/etc/transpiler/bin\""
    exports << "export LD_LIBRARY_PATH=\"$STITCH_PATH/etc/dylib/lib\""

    puts 'running stitch'

    puts `#{exports.join(' && ')} && \
        cd '#{STITCH_DIR}' && \
        go run -exec "env LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\"" cmd/auth/user.go addUser \
            -domainID 000000000000000000000000 \
            -mongoURI mongodb://localhost:26000 \
            -salt 'DQOWene1723baqD!_@#' \
            -id "unique_user@domain.com" \
            -password "password"`

    puts 'user created'
end

def build_action
    puts 'building baas'
    begin
        FileUtils.mkdir_p BUILD_DIR
        setup_mongod
        run_mongod
        setup_stitch
    rescue => exception
        puts "error setting up: #{exception}"
    ensure
        shutdown_mongod
    end
end

def clean_action
    puts 'cleaning'
    shutdown_mongod
    `rm -rf #{MONGO_DIR}`
    `cd #{STITCH_DIR} && git rm -rf . && git clean -fxd`
end

if ARGV.length < 1
    build_action
end

case ARGV[0]
when ""
    build_action
when "clean"
    clean_action
end
