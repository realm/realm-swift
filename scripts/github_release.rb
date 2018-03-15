#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'
require 'tmpdir'

require 'octokit'

BUILD_SH = Pathname(__FILE__).+('../../build.sh').expand_path
VERSION = `sh '#{BUILD_SH}' get-version`.strip
RELEASE = "v#{VERSION}"

BUILD = BUILD_SH.parent + 'build'
OBJC_ZIP = BUILD + "realm-objc-#{VERSION}.zip"
SWIFT_ZIP = BUILD + "realm-swift-#{VERSION}.zip"
CARTHAGE_ZIP = BUILD + 'Carthage.framework.zip'

REPOSITORY = 'realm/realm-cocoa'

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
prerelease = (VERSION =~ /alpha|beta|rc/) ? true : false
response = github.create_release(REPOSITORY, RELEASE, name: RELEASE, body: RELEASE_NOTES, prerelease: prerelease)
release_url = response[:url]

uploads = [OBJC_ZIP, SWIFT_ZIP, CARTHAGE_ZIP]
uploads.each do |upload|
  puts "Uploading #{upload.basename} to GitHub"
  github.upload_asset(release_url, upload.to_path, content_type: 'application/zip')
end
