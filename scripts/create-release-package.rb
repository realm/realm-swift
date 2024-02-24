#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'
require 'tmpdir'

raise 'usage: create-release-package.rb destination_path version [xcode_versions]' unless ARGV.length >= 3

DESTINATION = Pathname(ARGV[0])
VERSION = ARGV[1]
XCODE_VERSIONS = ARGV[2..]
ROOT = Pathname(__FILE__).+('../..').expand_path
BUILD_SH = Pathname(__FILE__).+('../../build.sh').expand_path
VERBOSE = false
OBJC_XCODE_VERSION = XCODE_VERSIONS.last

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

  sh 'xcodebuild', '-create-xcframework', '-allow-internal-distribution',
     '-output', output, *files.flat_map {|f| ['-framework', f]}
end

def zip(name, *files)
  path = (DESTINATION + name).to_path
  FileUtils.rm_f path
  sh 'zip', '--symlinks', '-r', path, *files
end

puts "Packaging version #{VERSION} for Xcode versions #{XCODE_VERSIONS.join(', ')}"
FileUtils.mkdir_p DESTINATION

Dir.mktmpdir do |tmp|
  # The default temp directory is in /var, which is a symlink to /private/var
  # xcodebuild's relative path resolution breaks due to this and we need to
  # give it the fully resolved path
  tmp = File.realpath tmp

  for version in XCODE_VERSIONS
    puts "Extracting source binaries for Xcode #{version}"
    FileUtils.mkdir_p "#{tmp}/#{version}"
    Dir.chdir("#{tmp}/#{version}") do
      for platform in platforms(version)
        sh 'unzip', "#{ROOT}/realm-#{platform}-#{version}/realm-#{platform}-#{version}.zip"
      end
    end
  end

  for version in XCODE_VERSIONS
    puts "Creating Swift XCFrameworks for Xcode #{version}"
    create_xcframework tmp, version, 'Release', 'RealmSwift'
  end

  puts 'Creating Obj-C XCFrameworks'
  create_xcframework tmp, OBJC_XCODE_VERSION, 'Release', 'Realm'
  create_xcframework tmp, OBJC_XCODE_VERSION, 'Static', 'Realm'

  puts 'Creating release package'
  package_dir = "#{tmp}/realm-swift-#{VERSION}"
  FileUtils.mkdir_p package_dir
  sh 'cp', "#{ROOT}/LICENSE", package_dir
  sh 'unzip', "#{ROOT}/realm-examples/realm-examples.zip", '-d', package_dir
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
  sh 'cp', '-Rca', "#{tmp}/#{OBJC_XCODE_VERSION}/Release/Realm.xcframework", "#{package_dir}"
  FileUtils.mkdir_p "#{package_dir}/static"
  sh 'cp', '-Rca', "#{tmp}/#{OBJC_XCODE_VERSION}/Static/Realm.xcframework", "#{package_dir}/static"
  for version in XCODE_VERSIONS
    FileUtils.mkdir_p "#{package_dir}/#{version}"
    sh 'cp', '-Rca', "#{tmp}/#{version}/Release/RealmSwift.xcframework", "#{package_dir}/#{version}"
  end

  Dir.chdir(tmp) do
    zip "realm-swift-#{VERSION}.zip", "realm-swift-#{VERSION}"
  end

  puts 'Creating SPM release zips'
  Dir.chdir "#{tmp}/#{OBJC_XCODE_VERSION}/Release" do
    zip 'Realm.spm.zip', "Realm.xcframework"
  end
  for version in XCODE_VERSIONS
    Dir.chdir "#{tmp}/#{version}/Release" do
      zip "RealmSwift@#{version}.spm.zip", 'RealmSwift.xcframework'
    end
  end
end

puts 'Creating Carthage release zip'
Dir.mktmpdir do |tmp|
  tmp = File.realpath tmp
  Dir.chdir(tmp) do
    for platform in platforms('15.1')
      sh 'unzip', "#{ROOT}/realm-#{platform}-#{OBJC_XCODE_VERSION}/realm-#{platform}-#{OBJC_XCODE_VERSION}.zip"
    end
    create_xcframework tmp, '', 'Release', 'RealmSwift'
    create_xcframework tmp, '', 'Release', 'Realm'

    Dir.chdir('Release') do
      zip 'Carthage.xcframework.zip', 'Realm.xcframework', 'RealmSwift.xcframework'
    end
  end
end
