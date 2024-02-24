#!/usr/bin/env ruby

require 'fileutils'

def usage()
  puts <<~END
    Usage: ruby #{__FILE__} test-all
    Usage: ruby #{__FILE__} platform method [linkage]

    platform:
      ios
      osx
      tvos
      visionos
      watchos

    method:
      cocoapods
      carthage
      spm
      xcframework

    linkage:
      static
      dynamic (default)

    environment variables:
      REALM_XCODE_VERSION: Xcode version to use
      REALM_TEST_RELEASE: Version number to test, or "latest" to test the latest release
      REALM_TEST_BRANCH: Name of a branch to test
  END
  exit 1
end
usage unless ARGV.length >= 1

def read_setting(name)
  `sh -c 'source ../../scripts/swift-version.sh; set_xcode_version; echo "$#{name}"'`.chomp()
end

ENV['DEVELOPER_DIR'] = read_setting 'DEVELOPER_DIR'
ENV['REALM_XCODE_VERSION'] ||= read_setting 'REALM_XCODE_VERSION'

if ENV['REALM_TEST_RELEASE'] == 'latest'
  ENV['REALM_TEST_RELEASE'] = `curl --silent https://static.realm.io/update/cocoa`
end

TEST_RELEASE = ENV['REALM_TEST_RELEASE']
TEST_BRANCH = ENV['REALM_TEST_BRANCH']
XCODE_VERSION = ENV['REALM_XCODE_VERSION']
REALM_CORE_VERSION = ENV['REALM_CORE_VERSION']

DEPENDENCIES = File.open("../../dependencies.list").map { |line| line.chomp.split("=") }.to_h

def replace_in_file(filepath, *args)
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    args.each_slice(2) { |pattern, replacement|
      contents = contents.gsub pattern, replacement
    }
    file.puts contents
  end
end

def sh(*args)
  system(*args) or exit(1)
end

# Copy a xcframework to the location which the installation example looks. This
# shells out to `cp` because Ruby currently doesn't have native bindings for
# clonefile-based copying.
def copy_xcframework(path, framework, dir = '')
  FileUtils.mkdir_p "../../build/#{dir}"
  FileUtils.rm_rf "../../build/#{dir}/#{framework}.xcframework"

  source = "#{path}/#{framework}.xcframework"
  if not Dir.exist? source
    raise "Missing XCFramework to test at '#{source}'"
  end

  puts "Copying xcframework from #{source} into ../../build/#{dir}"
  sh 'cp', '-cR', source, "../../build/#{dir}"
end

def download_release(version)
  # Download and extract the zip if the extracted directory doesn't already
  # exist. For master-push workflow testing, we already downloaded a local copy of the zip that
  # just needs to be extracted.
  unless Dir.exist? "realm-swift-#{version}"
    unless File.exist? "realm-swift-#{version}.zip"
      sh 'curl', '-OL', "https://github.com/realm/realm-swift/releases/download/v#{version}/realm-swift-#{version}.zip"
    end
    sh 'unzip', "realm-swift-#{version}.zip"
    FileUtils.rm "realm-swift-#{version}.zip"
  end

  unless Dir.exist?("realm-swift-#{version}/#{XCODE_VERSION}")
    raise "No build for Xcode version #{XCODE_VERSION} found in #{version} release package"
  end

  copy_xcframework "realm-swift-#{version}", 'Realm'
  copy_xcframework "realm-swift-#{version}/static", 'Realm', 'Static'
  copy_xcframework "realm-swift-#{version}/#{XCODE_VERSION}", 'RealmSwift'
end

def download_realm(platform, method, static)
  case method
  when 'cocoapods'
    # The podfile takes care of reading the env variables and importing the
    # correct thing
    ENV['REALM_PLATFORM'] = platform
    sh 'pod', 'install'

  when 'carthage'
    version = if TEST_RELEASE
      " == #{TEST_RELEASE}"
    elsif TEST_BRANCH
      " \"#{TEST_BRANCH}\""
    else
      ''
    end
    File.write 'Cartfile', 'github "realm/realm-swift"' + version

    platformName = case platform
                   when 'ios' then 'iOS'
                   when 'osx' then 'Mac'
                   when 'tvos' then 'tvOS'
                   when 'watchos' then 'watchOS'
                   else raise "Unsupported platform for Carthage: #{platform}"
                   end
    sh 'carthage', 'update', '--use-xcframeworks', '--platform', platformName

  when 'spm'
    project = static ? 'SwiftPackageManager' : 'SwiftPackageManagerDynamic'
    # We have to hide the spm example from carthage because otherwise
    # it'll fetch the example's package dependencies as part of deciding
    # what to build from this repo.
    unless File.symlink? "#{project}.xcodeproj/project.pbxproj"
      FileUtils.mkdir_p "#{project}.xcodeproj"
      File.symlink "../#{project}.notxcodeproj/project.pbxproj",
                 "#{project}.xcodeproj/project.pbxproj"
    end

    # Update the XcodeProj to reference the requested branch or version
    if TEST_RELEASE
      replace_in_file "#{project}.xcodeproj/project.pbxproj",
        /(branch|version) = .*;/, "version = #{TEST_RELEASE};",
      /kind = .*;/, "kind = exactVersion;"
    elsif TEST_BRANCH
      replace_in_file "#{project}.xcodeproj/project.pbxproj",
      /(branch|version) = .*;/, "branch = #{TEST_BRANCH};",
      /kind = .*;/, "kind = branch;"
    end

    sh 'xcodebuild', '-project', "#{project}.xcodeproj", '-resolvePackageDependencies', '-IDEPackageOnlyUseVersionsFromResolvedFile=NO', '-IDEDisableAutomaticPackageResolution=NO'

  when 'xcframework'
    # If we're testing a branch then we should already have a built zip
    # supplied by Github actions, but we need to know what version tag it has. If
    # we're testing a release, we'll download the zip.
    version = TEST_BRANCH ? DEPENDENCIES['VERSION'] : TEST_RELEASE
    if version
      download_release version
    else
      if static
        copy_xcframework "../../build/Static/#{platform}", 'Realm', 'Static'
      else
        copy_xcframework "../../build/Release/#{platform}", 'Realm'
        copy_xcframework "../../build/Release/#{platform}", 'RealmSwift'
      end
    end

  else
    usage
  end
end

def build_app(platform, method, static)
  archive_path = "#{Dir.pwd}/out.xcarchive"
  FileUtils.rm_rf archive_path

  build_args = ['clean', 'archive', '-archivePath', archive_path]
  case platform
  when 'ios'
    build_args += ['-sdk', 'iphoneos', '-destination', 'generic/platform=iphoneos']
  when 'tvos'
    build_args += ['-sdk', 'appletvos', '-destination', 'generic/platform=appletvos']
  when 'watchos'
    build_args += ['-sdk', 'watchos', '-destination', 'generic/platform=watchos']
  when 'osx'
    build_args += ['-sdk', 'macosx', '-destination', 'generic/platform=macOS']
  when 'catalyst'
    build_args += ['-destination', 'generic/platform=macOS,variant=Mac Catalyst']
  end
  build_args += ['CODE_SIGN_IDENTITY=', 'CODE_SIGNING_REQUIRED=NO', 'AD_HOC_CODE_SIGNING_ALLOWED=YES']

  case method
  when 'cocoapods'
    sh 'xcodebuild', '-workspace', 'CocoaPods.xcworkspace', '-scheme', 'App', *build_args

  when 'carthage'
    sh 'xcodebuild', '-project', 'Carthage.xcodeproj', '-scheme', 'App', *build_args

  when 'spm'
    sh 'xcodebuild', '-project', static ? 'SwiftPackageManager.xcodeproj' : 'SwiftPackageManagerDynamic.xcodeproj', '-scheme', 'App', *build_args

  when 'xcframework'
    if static
      sh 'xcodebuild', '-project', 'Static/StaticExample.xcodeproj', '-scheme', 'StaticExample', *build_args
    else
      sh 'xcodebuild', '-project', 'XCFramework.xcodeproj', '-scheme', 'App', *build_args
    end
  end
end

def validate_build(static)
  has_frameworks = Dir["out.xcarchive/Products/Applications/**/Frameworks/*.framework"].length != 0
  if has_frameworks and static
    raise 'Static build configuration has embedded frameworks'
  elsif not has_frameworks and not static
    raise 'Dyanmic build configuration is missing embedded frameworks'
  end
end

def test(platform, method, linkage = 'dynamic')
  static = linkage == 'static'
  if static
    ENV['REALM_BUILD_STATIC'] = '1'
  else
    ENV.delete 'REALM_BUILD_STATIC'
  end

  puts "Testing #{method} for #{platform} and #{linkage}"

  download_realm(platform, method, static)
  build_app(platform, method, static)
  validate_build(static)
end

if ARGV[0] == 'test-all'
  platforms = ['ios', 'osx', 'tvos', 'watchos', 'catalyst']
  if /15\..*/ =~ XCODE_VERSION
    platforms += ['visionos']
  end

  for platform in platforms
    for method in ['cocoapods', 'carthage', 'spm', 'xcframework']
      next if platform == 'catalyst' && method == 'carthage'
      next if platform == 'visionos' && method != 'spm' && method != 'xcframework'
      test platform, method, 'dynamic'
    end

    test platform, 'cocoapods', 'static' unless platform == 'visionos'
    test platform, 'spm', 'static'
  end

  test 'ios', 'xcframework', 'static'

else
  test(*ARGV)
end
