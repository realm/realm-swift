#!/usr/bin/env ruby

require 'fileutils'
require 'octokit'
require 'pathname'
require 'tmpdir'

raise 'usage: github_release.rb version xcode_version' unless ARGV.length == 2

VERSION = ARGV[0]
XCODE_VERSION = ARGV[1]
ACCESS_TOKEN = ENV['GITHUB_ACCESS_TOKEN']
raise 'GITHUB_ACCESS_TOKEN must be set to create GitHub releases' unless ACCESS_TOKEN

BUILD_SH = Pathname(__FILE__).+('../../build.sh').expand_path
RELEASE = "v#{VERSION}"

BUILD = BUILD_SH.parent + 'build'
SWIFT_ZIP = BUILD + "realm-swift-#{VERSION}.zip"

REPOSITORY = 'realm/realm-swift'

$uploads = [SWIFT_ZIP]

def sh(*args)
  system(*args, :out=>"/dev/null") || exit(1)
end

def zip(name, *files)
  path = (BUILD + name).to_path
  FileUtils.rm_f path
  sh 'zip', '--symlinks', '-r', path, *files
  $uploads.append Pathname(path)
end

Dir.mktmpdir do |tmp|
  Dir.chdir(tmp) do
    sh 'unzip', SWIFT_ZIP.to_path,
           "realm-swift-#{VERSION}/*/RealmSwift.xcframework/*",
           "realm-swift-#{VERSION}/Realm.xcframework/*"
    Dir.chdir "realm-swift-#{VERSION}" do
      zip 'Realm.xcframework.zip', 'Realm.xcframework'
      Dir.glob '*/RealmSwift.xcframework' do |name|
        version = Pathname(name).parent
        puts "Creating SPM package for #{version}"
        Dir.chdir version do
          zip "RealmSwift@#{version}.xcframework.zip", 'RealmSwift.xcframework'
        end
      end

      puts "Creating Carthage package for #{XCODE_VERSION}"
      FileUtils.mv "#{XCODE_VERSION}/RealmSwift.xcframework",
                   'RealmSwift.xcframework'
      zip 'Carthage.xcframework.zip', 'Realm.xcframework', 'RealmSwift.xcframework'
    end
  end
end

def release_notes(version)
  changelog = BUILD_SH.parent.+('CHANGELOG.md').readlines
  current_version_index = changelog.find_index { |line| line =~ (/^#{Regexp.escape version}/) }
  unless current_version_index
    raise "Update the changelog for the last version (#{version})"
  end
  current_version_index += 2
  previous_version_lines = changelog[(current_version_index+1)...-1]
  previous_version_index = current_version_index + (previous_version_lines.find_index { |line| line =~ /^\d+\.\d+\.\d+(-(alpha|beta|rc)(\.\d+)?)?\s+/ } || changelog.count)

  relevant = changelog[current_version_index..previous_version_index]

  relevant.join.strip
end

RELEASE_NOTES = release_notes(VERSION)

github = Octokit::Client.new
github.access_token = ENV['GITHUB_ACCESS_TOKEN']

puts 'Creating GitHub release'
prerelease = (VERSION =~ /alpha|beta|rc|preview/) ? true : false
response = github.create_release(REPOSITORY, RELEASE, name: RELEASE, body: RELEASE_NOTES, prerelease: prerelease)
release_url = response[:url]

$uploads.each do |upload|
  puts "Uploading #{upload.basename} to GitHub"
  github.upload_asset(release_url, upload.to_path, content_type: 'application/zip')
end
