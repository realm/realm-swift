#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'
require 'tmpdir'

raise 'usage: create-release-package.rb destination_path version [xcode_version]' unless ARGV.length >= 3

DESTINATION = Pathname(ARGV[0])
VERSION = ARGV[1]
XCODE_VERSION = ARGV[2]
OBJC_XCODE_VERSION = ARGV[3]
ROOT = Pathname(__FILE__).+('../..').expand_path
BUILD_SH = Pathname(__FILE__).+('../../build.sh').expand_path
VERBOSE = false

def sh(*args)
  puts "executing: #{args.join(' ')}" if VERBOSE
  system(*args, VERBOSE ? {} : {:out => '/dev/null'}) || exit(1)
end

def platforms(xcode_version)
  if xcode_version.start_with? '15.2'
    %w{osx ios watchos tvos catalyst visionos}
  else
    %w{osx ios watchos tvos catalyst}
  end
end

def create_xcframework(root, xcode_version, configuration, name)
  prefix = "#{root}/#{xcode_version}"
  output = "#{prefix}/#{configuration}/#{name}.xcframework"
  files = Dir.glob "#{prefix}/#{configuration}/*/#{name}.xcframework/*/#{name}.framework"
  puts "Creating xcframework to #{output} from #{prefix}/#{configuration}/*/#{name}.xcframework/*/#{name}.framework returning files #{files}"
  sh 'xcodebuild', '-create-xcframework', '-allow-internal-distribution',
     '-output', output, *files.flat_map {|f| ['-framework', f]}
end

def zip(name, *files)
  path = (DESTINATION + name).to_path
  FileUtils.rm_f path
  puts "Zipping file #{name} into #{path}"
  sh 'zip', '--symlinks', '-r', path, *files
end

def create_xcframework_package
  puts "Packaging version #{VERSION} for Xcode version #{XCODE_VERSION}"
  FileUtils.mkdir_p DESTINATION

  Dir.mktmpdir do |tmp|
    # The default temp directory is in /var, which is a symlink to /private/var
    # xcodebuild's relative path resolution breaks due to this and we need to
    # give it the fully resolved path
    tmp = File.realpath tmp

    # Extracts/Unzip all the binarios for each of the platforms for the current XCode version into a temp
    # folder, which is gonna be used to generate the zip for each XCode version.
    puts "Extracting source binaries for Xcode #{XCODE_VERSION}"
    FileUtils.mkdir_p "#{tmp}/#{XCODE_VERSION}"
    Dir.chdir("#{tmp}/#{XCODE_VERSION}") do
      for platform in platforms(XCODE_VERSION)
        puts "Unziping #{ROOT}/realm-#{platform}-#{XCODE_VERSION}.zip into #{tmp}/#{XCODE_VERSION}"
        sh 'unzip', "#{ROOT}/realm-#{platform}-#{XCODE_VERSION}.zip"
      end
    end

    # Creates a RealmSwift.xcframework from each platform framework for any supported architecture (device and simulator).
    puts "Creating RealmSwift XCFrameworks for Xcode #{XCODE_VERSION}"
    create_xcframework tmp, XCODE_VERSION, 'Release', 'RealmSwift'

    if XCODE_VERSION == OBJC_XCODE_VERSION
      # Creates a Realm.xcframework from each platform framework for any supported architecture (device and simulator).
      puts 'Creating Obj-C XCFrameworks, only for latest xcode version'
      create_xcframework tmp, XCODE_VERSION, 'Release', 'Realm'
       # Creates a Static Realm.xcframework from each platform framework for any supported architecture (device and simulator).
      create_xcframework tmp, XCODE_VERSION, 'Static', 'Realm'
    end

    package_dir = "#{tmp}/realm-swift-#{VERSION}"
    FileUtils.mkdir_p package_dir
    puts "Creating release package on temp #{tmp}/realm-swift-#{VERSION} from generated xcframeworks"

    sh 'cp', "#{ROOT}/LICENSE", package_dir
    sh 'unzip', "#{ROOT}/realm-examples.zip", '-d', package_dir

    for lang in %w(objc swift)
        File.write "#{package_dir}/#{lang}-docs.webloc", %Q{
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>URL</key>
                <string>https://www.mongodb.com/docs/realm-sdks/${lang}/${version}</string>
            </dict>
            </plist>
        }
    end

    # Copy the generated RealmSwift.xcframework into a temp directory following this notation realm-swift-#{VERSION}/#{XCODE_VERSION}/
    puts "Copying Release RealmSwift into a #{XCODE_VERSION} folder"
    FileUtils.mkdir_p "#{package_dir}/#{XCODE_VERSION}"
    sh 'cp', '-Rca', "#{tmp}/#{XCODE_VERSION}/Release/RealmSwift.xcframework", "#{package_dir}/#{XCODE_VERSION}"

    if XCODE_VERSION == OBJC_XCODE_VERSION
      # Copy the generated Realm.xcframework into a temp directory following this notation realm-swift-#{VERSION}
      puts 'Copying Release Obj-C XCFramework, only for latest xcode version'
      sh 'cp', '-Rca', "#{tmp}/#{XCODE_VERSION}/Release/Realm.xcframework", "#{package_dir}"

      # Copy the generated Static Realm.xcframework into a temp directory following this notation realm-swift-#{VERSION}/static
      puts 'Copying Static Obj-C XCFramework, only for latest xcode version'
      FileUtils.mkdir_p "#{package_dir}/static"
      sh 'cp', '-Rca', "#{tmp}/#{XCODE_VERSION}/Static/Realm.xcframework", "#{package_dir}/static"
    end

    # Zip the generated RealmSwift/Realm(Static) xcframework into a generated realm-swift-#{VERSION}.zip
    puts 'Packing all the xcframework into a zip for version'
    Dir.chdir(tmp) do
      zip "realm-swift-#{VERSION}-#{XCODE_VERSION}.zip", "realm-swift-#{VERSION}"
    end

    # Zip generated RealmSwift.xcframework into a generated RealmSwift@#{XCODE_VERSION}.spm.zip
    puts 'Packing RealmSwift@ into a zip'
    Dir.chdir "#{tmp}/#{XCODE_VERSION}/Release" do
      zip "RealmSwift@#{XCODE_VERSION}.spm.zip", 'RealmSwift.xcframework'
    end

    if XCODE_VERSION == OBJC_XCODE_VERSION
      Dir.chdir "#{tmp}/#{XCODE_VERSION}/Release" do
        # Zip generated Realm.xcframework into a generated Realm.spm.zip
        puts 'Packing Obj-C xcframework into a zip'
        zip "Realm.spm.zip", "Realm.xcframework"
      end
    end
  end

  if XCODE_VERSION == OBJC_XCODE_VERSION
    puts 'Creating Carthage release zip'
    Dir.mktmpdir do |tmp|
      tmp = File.realpath tmp
      FileUtils.mkdir_p "#{tmp}/#{XCODE_VERSION}"
      Dir.chdir("#{tmp}/#{XCODE_VERSION}") do
        for platform in platforms('15.1')
          puts "unziping #{ROOT}/realm-#{platform}-#{OBJC_XCODE_VERSION}.zip into #{tmp}"
          sh 'unzip', "#{ROOT}/realm-#{platform}-#{OBJC_XCODE_VERSION}.zip"
        end
      end

      puts "Creating xcframework in #{tmp}"
      create_xcframework tmp, XCODE_VERSION, 'Release', 'RealmSwift'
      create_xcframework tmp, XCODE_VERSION, 'Release', 'Realm'

      Dir.chdir "#{tmp}/#{XCODE_VERSION}/Release" do
        puts "Zipping Carthage.xcframework.zip"
        zip 'Carthage.xcframework.zip', 'Realm.xcframework', 'RealmSwift.xcframework'
      end
    end
  end
end

create_xcframework_package
