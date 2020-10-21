#!/usr/bin/ruby

require 'net/http'
require 'fileutils'
require 'pathname'

BASE_DIR = Dir.pwd
BUILD_DIR = "#{BASE_DIR}/build"
PID_FILE = "#{BUILD_DIR}/pid.txt"

DEPENDENCIES = File.open("#{BASE_DIR}/dependencies.list").map { |line|
  line.chomp.split("=")
}.to_h

MONGODB_VERSION='4.4.0-rc5'
GO_VERSION='1.15.2'
NODE_VERSION='8.11.2'
STITCH_VERSION=DEPENDENCIES["STITCH_VERSION"]

MONGODB_URL="https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-#{MONGODB_VERSION}.tgz"
TRANSPILER_TARGET='node8-macos'
SERVER_STITCH_LIB_URL="https://s3.amazonaws.com/stitch-artifacts/stitch-support/stitch-support-macos-debug-4.3.2-721-ge791a2e-patch-5e2a6ad2a4cf473ae2e67b09.tgz"
MONGO_DIR="'#{BUILD_DIR}'/mongodb-macos-x86_64-#{MONGODB_VERSION}"

def setup_mongod
    if !Dir.exists?(MONGO_DIR)
        `cd '#{BUILD_DIR}' && curl --silent '#{MONGODB_URL}' | tar xz`
    end
end

def run_mongod
    puts "starting mongod..."
    puts `mkdir #{MONGO_DIR}/db_files`
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
        puts `#{MONGO_DIR}/bin/mongo --port 26000 admin --eval "db.shutdownServer({force: true})"`
    end
    puts 'mongod is down'
end

def setup_stitch
    puts "setting up stitch"
    exports = []
    go_root = "#{BUILD_DIR}/go"

    if !File.exists?("#{go_root}/bin/go")
        puts 'downloading go'
        `cd #{BUILD_DIR} && curl --silent "https://dl.google.com/go/go#{GO_VERSION}.darwin-amd64.tar.gz" | tar xz`
        puts `mkdir -p #{go_root}/src/github.com/10gen`
    end

    stitch_dir = "#{BUILD_DIR}/stitch"
    if !Dir.exists?(stitch_dir)
        puts 'cloning stitch'
        `git clone git@github.com:10gen/baas #{stitch_dir}`
    else
        puts 'stitch dir exists'
    end

    puts 'checking out stitch'
    `git -C '#{stitch_dir}' fetch && git -C '#{stitch_dir}' checkout #{STITCH_VERSION}`

    `mv #{stitch_dir} #{go_root}/src/github.com/10gen`
    stitch_dir = "#{go_root}/src/github.com/10gen/stitch"
    dylib_dir = "#{stitch_dir}/etc/dylib"
    if !Dir.exists?(dylib_dir)
        puts 'downloading mongodb dylibs'
        Dir.mkdir dylib_dir
        puts `curl -s "#{SERVER_STITCH_LIB_URL}" | tar xvfz - --strip-components=1 -C '#{dylib_dir}'`
    end

    update_doc_filepath = "#{stitch_dir}/update_doc"
    if !File.exists?(update_doc_filepath)
        puts "downloading update_doc"
        puts `cd '#{stitch_dir}' && curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7a5c9ec4432c400181c_17_10_15_01_19_33/update_doc"`
        puts `chmod +x '#{update_doc_filepath}'`
    end

    assisted_agg_filepath = "#{stitch_dir}/assisted_agg"
    if !File.exists?(assisted_agg_filepath)
        puts "downloading assisted_agg"
        puts `cd '#{stitch_dir}' && curl --silent -O "https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_b1c679a26ecb975372de41238ea44e4719b8fbf0_5f3d91c10ae6066889184912_20_08_19_20_57_17/assisted_agg"`
        puts `chmod +x '#{assisted_agg_filepath}'`
    end

    if `which node`.empty? && !Dir.exists?("#{stitch_dir}/node-v#{NODE_VERSION}-darwin-x64")
        puts "downloading node 🚀"
        puts `cd '#{stitch_dir}' && curl -O "https://nodejs.org/dist/v#{NODE_VERSION}/node-v#{NODE_VERSION}-darwin-x64.tar.gz" && tar xzf node-v#{NODE_VERSION}-darwin-x64.tar.gz`
        exports << "export PATH=\"#{stitch_dir}/node-v#{NODE_VERSION}-darwin-x64/bin/:$PATH\""
    end

    if `which yarn`.empty?
        `rm -rf "$HOME/.yarn"`
        `export PATH=\"#{stitch_dir}/node-v#{NODE_VERSION}-darwin-x64/bin/:$PATH\" && curl -o- -L https://yarnpkg.com/install.sh | bash`
        exports << "export PATH=\"$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH\""
    end

    puts 'building transpiler'
    puts `#{exports.length() == 0 ? "" : exports.join(' && ') + ' &&'} \
        cd '#{stitch_dir}/etc/transpiler' && yarn install && yarn run build -t "#{TRANSPILER_TARGET}"`

    puts "TRANSPILER SIZE"
    puts `ls -l #{stitch_dir}/etc/transpiler/bin`

    exports << "export GOROOT=\"#{go_root}\""
    exports << "export PATH=\"$GOROOT/bin:$PATH\""

    exports << "export STITCH_PATH=\"#{stitch_dir}\""
    exports << "export PATH=\"$PATH:$STITCH_PATH/etc/transpiler/bin\""
    exports << "export LD_LIBRARY_PATH=\"$STITCH_PATH/etc/dylib/lib\""

    puts 'build create_user binary'

    puts `#{exports.join(' && ')} && \
        cd '#{stitch_dir}' && \
        #{go_root}/bin/go build -o create_user cmd/auth/user.go`

    puts 'create_user binary built'

    puts 'building server binary'

    puts `#{exports.join(' && ')} && \
        cd '#{stitch_dir}' && \
        #{go_root}/bin/go build -o stitch_server cmd/server/main.go`

    puts 'server binary built'
end

def build_action
    puts 'building baas'
    begin
        FileUtils.mkdir_p BUILD_DIR
        setup_mongod
        run_mongod
        shutdown_mongod
        setup_stitch
    rescue => exception
        puts "error setting up: #{exception}"
    end
end

def clean_action
    puts 'cleaning'
    `rm -rf #{MONGO_DIR}`
    `cd #{BUILD_DIR} && git rm -rf . && git clean -fxd`
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
