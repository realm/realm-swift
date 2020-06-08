#!/usr/bin/ruby

require 'net/http'

ROOT_DIR="#{Dir.pwd}/../.."
MONGO_DIR="#{ROOT_DIR}/build/mongodb-*"

def run_mongod
    puts "starting mongod..."
    `#{MONGO_DIR}/bin/mongod --quiet \
        --dbpath #{MONGO_DIR}/db_files \
        --bind_ip localhost \
        --port 26000 \
        --replSet test \
        --fork --logpath #{MONGO_DIR}/mongod.log`
    puts "mongod starting"

    retries = 0
    begin
        puts '🟠 attempting to connect to mongod'
        Net::HTTP.get(URI('http://localhost:26000'))
    rescue => exception
        sleep(1)
        retries += 1
        if retries == 5
            abort('🔴 could not connect to mongod')
        end
    end

    puts "mongod started"
end

def clean_mongo_test_data
    puts '🧹 cleaning mongo test data'
    begin
        puts `#{MONGO_DIR}/bin/mongo --port 26000 test_data --eval "db.dropDatabase()"`
        puts `#{MONGO_DIR}/bin/mongo --port 26000 __realm_sync --eval "db.dropDatabase()"`
    rescue => exception
        puts('🔴 error: #{exception}')
    end
end

def shutdown_mongod
    puts '🍂 shutting down mongod'
    begin
        puts `#{MONGO_DIR}/bin/mongo --port 26000 admin --eval "db.adminCommand({replSetStepDown: 0, secondaryCatchUpPeriodSecs: 0, force: true})"`
        puts `#{MONGO_DIR}/bin/mongo --port 26000 admin --eval "db.shutdownServer({force: true})"`
        `rm -rf #{MONGO_DIR}/db_files`
        `cd #{MONGO_DIR} && mkdir db_files`
    rescue => exception
    end
end

def run_stitch
    current_dir = Dir.pwd
    root_dir = "#{current_dir}/../.."
    stitch_path = "#{root_dir}/stitch"

    exports = []
    if Dir.exist?("#{root_dir}/go")
        exports << "export GOROOT=#{root_dir}/go"
        exports << "export PATH=$GOROOT/bin:$PATH"
    end

    exports << "export STITCH_PATH=\"#{root_dir}/stitch\""
    exports << "export PATH=\"$PATH:$STITCH_PATH\""
    exports << "export PATH=\"$PATH:$STITCH_PATH/etc/transpiler/bin\""
    exports << "export LD_LIBRARY_PATH=\"$STITCH_PATH/etc/dylib/lib\""
    
    puts 'starting stitch'

    puts exports
    pid = Process.fork {
        puts `#{MONGO_DIR}/bin/mongo --port 26000 --eval 'rs.initiate()'`
        puts `#{exports.join(' && ')} && \
        cd #{stitch_path} && \
        go run -exec "env LD_LIBRARY_PATH=$LD_LIBRARY_PATH" cmd/auth/user.go addUser \
            -domainID 000000000000000000000000 \
            -mongoURI mongodb://localhost:26000 \
            -salt 'DQOWene1723baqD!_@#' \
            -id "unique_user@domain.com" \
            -password "password"`
        `cd #{stitch_path} && \
        #{exports.join(' && ')} && \
        go run -exec "env LD_LIBRARY_PATH=$LD_LIBRARY_PATH" #{stitch_path}/cmd/server/main.go --configFile "#{stitch_path}/etc/configs/test_config.json" >> output.log`
    }
    Process.detach(pid)
    retries = 0
    begin
        puts '🟠 attempting to connect to stitch'
        Net::HTTP.get(URI('http://localhost:9090'))
    rescue => exception
        sleep(1)
        retries += 1
        if retries == 50
            abort('🔴 could not connect to baas')
        end
        retry
    end
    puts '🟢 stitch is running'
end

def shutdown_stitch
    puts '🍂 shutting down baas'
    `pkill -f stitch`
end

def start
    run_mongod
    # clean any old state
    clean_mongo_test_data
    run_stitch
end

if ARGV.length < 1
    abort("🔴 too few arguments")
end

case ARGV[0]
when "start"
    start
when "start_proxy"
    if ARGV.length < 3
        abort("🔴 too few arguments to start proxy. requires [port] and [delay]")
    end
    require_relative 'proxy.rb'
    Proxy.new.run(ARGV[1].to_i, ARGV[2].to_i)
when "shutdown"
    shutdown_stitch
    clean_mongo_test_data
    shutdown_mongod
when "clean"
    clean_mongo_test_data
end
