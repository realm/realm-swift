#!/usr/bin/ruby

require 'net/http'
require 'fileutils'
require 'pathname'

BASE_DIR = Dir.pwd
BUILD_DIR = "#{BASE_DIR}/ci_scripts/setup_baas/.baas"
BIN_DIR = "#{BUILD_DIR}/bin"
LIB_DIR = "#{BUILD_DIR}/lib"
PID_FILE = "#{BUILD_DIR}/pid.txt"

MONGO_EXE = "'#{BIN_DIR}'/mongo"
MONGOD_EXE = "'#{BIN_DIR}'/mongod"

DEPENDENCIES = File.open("#{BASE_DIR}/dependencies.list").map { |line|
  line.chomp.split("=")
}.to_h

MONGODB_VERSION='5.0.6'
GO_VERSION='1.21.4'
NODE_VERSION='16.13.1'
STITCH_VERSION=DEPENDENCIES["STITCH_VERSION"]

MONGODB_URL="https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-#{MONGODB_VERSION}.tgz"
TRANSPILER_TARGET='node16-macos'
SERVER_STITCH_LIB_URL="https://s3.amazonaws.com/stitch-artifacts/stitch-support/stitch-support-macos-debug-4.3.2-721-ge791a2e-patch-5e2a6ad2a4cf473ae2e67b09.tgz"
STITCH_SUPPORT_URL="https://static.realm.io/downloads/swift/stitch-support.tar.xz"
MONGO_DIR="#{BUILD_DIR}/mongodb-macos-x86_64-#{MONGODB_VERSION}"

# exit immediately if any subcommand fails
#class Object
#  def `(command)
#    ret = super
#    exit 1 unless $?.success?
#    ret
#  end
#end

def setup_mongod
    if !File.exist?("#{BIN_DIR}/mongo")
        `cd '#{BUILD_DIR}' && curl --silent '#{MONGODB_URL}' | tar xz`
        FileUtils.cp("#{MONGO_DIR}/bin/mongo", BIN_DIR)
        FileUtils.cp("#{MONGO_DIR}/bin/mongod", BIN_DIR)
    end
end

def run_mongod
    puts "starting mongod..."
    puts `mkdir -p '#{BUILD_DIR}'/db_files`
    puts `#{MONGOD_EXE} --quiet \
        --dbpath '#{BUILD_DIR}'/db_files \
        --port 26000 \
        --replSet test \
        --fork \
        --logpath '#{BUILD_DIR}'/mongod.log`
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
    puts `#{MONGO_EXE} --port 26000 --eval 'rs.initiate()'`
    puts "mongod started"
end

def shutdown_mongod
    puts 'shutting down mongod'
    if File.exist?("#{BIN_DIR}/mongo")
        puts `#{MONGO_EXE} --port 26000 admin --eval "db.shutdownServer({force: true})"`
    end
    puts 'mongod is down'
end

def setup_stitch
    puts "setting up stitch"
    exports = []
    go_root = "#{BUILD_DIR}/go"

    if !File.exist?("#{go_root}/bin/go")
        puts 'downloading go'
        `cd #{BUILD_DIR} && curl --silent "https://dl.google.com/go/go#{GO_VERSION}.darwin-amd64.tar.gz" | tar xz`
        puts `mkdir -p #{go_root}/src/github.com/10gen`
    end

    stitch_dir = "#{BUILD_DIR}/stitch"
    if !Dir.exist?(stitch_dir)
        puts 'cloning stitch'
        puts `git clone git@github.com:10gen/baas #{stitch_dir}`
    else
        puts 'stitch dir exists'
    end

    puts 'checking out stitch'
    stitch_worktree = "#{go_root}/src/github.com/10gen/stitch"
    if Dir.exist?("#{stitch_dir}/.git")
        # Fetch the BaaS version if we don't have it
        puts `git -C '#{stitch_dir}' show-ref --verify --quiet #{STITCH_VERSION} || git -C '#{stitch_dir}' fetch`
        # Set the worktree to the correct version
        if Dir.exist?(stitch_worktree)
            puts `git -C '#{stitch_worktree}' checkout #{STITCH_VERSION}`
        else
            puts `git -C '#{stitch_dir}' worktree add '#{stitch_worktree}' #{STITCH_VERSION}`
        end
    else
        # We have a stitch directory with no .git directory, meaning we're
        # running on CI and just need to copy the files into place
        if !Dir.exist?(stitch_worktree)
            puts `cp -Rc '#{stitch_dir}' '#{stitch_worktree}'`
        end
    end

    if !File.exist?("#{BUILD_DIR}/stitch-support.tar.xz")
        puts 'downloading stitch support'
        puts `cd #{BUILD_DIR} && curl --silent -O "#{STITCH_SUPPORT_URL}"`
    end

    stitch_dir = stitch_worktree
    if !File.exist?("#{LIB_DIR}/libstitch_support.dylib")
        FileUtils.mkdir_p "#{stitch_dir}/etc/dylib/include/stitch_support/v1/stitch_support"
        puts `tar --extract --strip-components=1 -C '#{stitch_dir}/etc/dylib' --file '#{BUILD_DIR}/stitch-support.tar.xz' stitch-support/lib stitch-support/include`
        FileUtils.copy "#{stitch_dir}/etc/dylib/lib/libstitch_support.dylib", "#{LIB_DIR}"
        FileUtils.copy "#{stitch_dir}/etc/dylib/include/stitch_support.h", "#{stitch_dir}/etc/dylib/include/stitch_support/v1/stitch_support"
    end

    update_doc_filepath = "#{BIN_DIR}/update_doc"
    if !File.exist?(update_doc_filepath)
        puts `tar --extract --strip-components=2 -C '#{BIN_DIR}' --file '#{BUILD_DIR}/stitch-support.tar.xz' stitch-support/bin/update_doc`
        puts `chmod +x '#{update_doc_filepath}'`
    end

    assisted_agg_filepath = "#{BIN_DIR}/assisted_agg"
    if !File.exist?(assisted_agg_filepath)
        puts `tar --extract --strip-components=2 -C '#{BIN_DIR}' --file '#{BUILD_DIR}/stitch-support.tar.xz' stitch-support/bin/assisted_agg`
        puts `chmod +x '#{assisted_agg_filepath}'`
    end

    puts "Checking node installation #{`which node || true`.empty?}"
    puts "Checking node local installation #{!Dir.exist?("#{BUILD_DIR}/node-v#{NODE_VERSION}-darwin-x64")}"
    if `which node || true`.empty? && !Dir.exist?("#{BUILD_DIR}/node-v#{NODE_VERSION}-darwin-x64")
        puts "downloading node 🚀"
        puts `cd '#{BUILD_DIR}' && curl -O "https://nodejs.org/dist/v#{NODE_VERSION}/node-v#{NODE_VERSION}-darwin-x64.tar.gz" && tar xzf node-v#{NODE_VERSION}-darwin-x64.tar.gz`
        exports << "export PATH=\"#{BUILD_DIR}/node-v#{NODE_VERSION}-darwin-x64/bin/:$PATH\""
    end

    if `which yarn || true`.empty?
        `rm -rf "$HOME/.yarn"`
        `export PATH=\"#{BUILD_DIR}/node-v#{NODE_VERSION}-darwin-x64/bin/:$PATH\" && curl -o- -L https://yarnpkg.com/install.sh | bash`
        exports << "export PATH=\"$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH\""
    end

    puts 'building transpiler'
    # Install a newer version of pkg that actually supports recent versions of node
    puts `#{exports.length() == 0 ? "" : exports.join(' && ') + ' &&'} \
        cd '#{stitch_dir}/etc/transpiler' && yarn add pkg`
    puts `#{exports.length() == 0 ? "" : exports.join(' && ') + ' &&'} \
        cd '#{stitch_dir}/etc/transpiler' && yarn install && yarn run build -t "#{TRANSPILER_TARGET}" &&
        cp -c bin/transpiler #{BUILD_DIR}/bin`

    puts "TRANSPILER SIZE"
    puts `ls -l #{stitch_dir}/etc/transpiler/bin`

    exports << "export GOROOT=\"#{go_root}\""
    exports << "export PATH=\"$GOROOT/bin:$PATH\""

    exports << "export STITCH_PATH=\"#{stitch_dir}\""
    exports << "export PATH=\"$PATH:$STITCH_PATH/etc/transpiler/bin\""
    exports << "export DYLD_LIBRARY_PATH='#{LIB_DIR}'"
    exports << "export GOPRIVATE=\"github.com/10gen/*\""

    puts 'build create_user binary'

    puts `#{exports.join(' && ')} && \
        cd '#{stitch_dir}' && \
        #{go_root}/bin/go build -o create_user cmd/auth/user.go &&
        cp -c create_user '#{BIN_DIR}'`

    puts 'create_user binary built'

    puts 'building server binary'

    puts `#{exports.join(' && ')} && \
        cd '#{stitch_dir}' && \
        #{go_root}/bin/go build -o stitch_server cmd/server/main.go
        cp -c stitch_server '#{BIN_DIR}'`

    puts 'server binary built'
end

def build_action
    puts 'building baas'
    begin
        FileUtils.mkdir_p BIN_DIR
        FileUtils.mkdir_p LIB_DIR
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
