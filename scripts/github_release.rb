#!/usr/bin/env ruby

require 'pathname'
require 'octokit'

raise 'usage: github_release.rb version' unless ARGV.length == 1

VERSION = ARGV[0]
ACCESS_TOKEN = ENV['GITHUB_ACCESS_TOKEN']
raise 'GITHUB_ACCESS_TOKEN must be set to create GitHub releases' unless ACCESS_TOKEN

BUILD_SH = Pathname(__FILE__).+('../../build.sh').expand_path
RELEASE = "v#{VERSION}"

REPOSITORY = 'realm/realm-swift'

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

Dir.glob 'build/*.zip' do |upload|
  puts "Uploading #{upload} to GitHub"
  github.upload_asset(release_url, upload, content_type: 'application/zip')
end
