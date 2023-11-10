#!/usr/bin/env ruby

require 'pathname'
require 'octokit'
require 'fileutils'

VERSION = ARGV[1]
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

def create_release
  release_notes = release_notes(VERSION)
  github = Octokit::Client.new
  github.access_token = ENV['GITHUB_ACCESS_TOKEN']

  puts 'Creating GitHub release'
  prerelease = (VERSION =~ /alpha|beta|rc|preview/) ? true : false
  response = github.create_release(REPOSITORY, RELEASE, name: RELEASE, body: release_notes, prerelease: prerelease)
  release_url = response[:url]

  Dir.glob 'release_pkg/*.zip' do |upload|
    puts "Uploading #{upload} to GitHub"
    github.upload_asset(release_url, upload, content_type: 'application/zip')
  end
end

def package_release_notes
  release_notes = release_notes(VERSION)
  FileUtils.mkdir_p("ExtractedChangelog")
  out_file = File.new("ExtractedChangelog/CHANGELOG.md", "w")
  out_file.puts(release_notes)
end

if ARGV[0] == 'create-release'
  create_release
elsif ARGV[0] == 'package-release-notes'
  package_release_notes
end