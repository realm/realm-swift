#!/usr/bin/env ruby

require 'pathname'
require 'octokit'
require 'fileutils'

BUILD_SH = Pathname(__FILE__).+('../../build.sh').expand_path

REPOSITORY = 'realm/realm-swift'

def sh(*args)
  puts "executing: #{args.join(' ')}" if false
  system(*args, false ? {} : {:out => '/dev/null'}) || exit(1)
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

def create_release(version)
  access_token = ENV['GITHUB_ACCESS_TOKEN']
  raise 'GITHUB_ACCESS_TOKEN must be set to create GitHub releases' unless access_token

  release_notes = release_notes(version)
  github = Octokit::Client.new
  github.access_token = ENV['GITHUB_ACCESS_TOKEN']

  puts 'Creating GitHub release'
  prerelease = (version =~ /alpha|beta|rc|preview/) ? true : false
  release = "v#{version}"
  response = github.create_release(REPOSITORY, release, name: release, body: release_notes, prerelease: prerelease)
  release_url = response[:url]

  Dir.glob 'release-package/*.zip' do |upload|
    puts "Uploading #{upload} to GitHub"
    github.upload_asset(release_url, upload, content_type: 'application/zip')
  end
end

def package_release_notes(version)
  release_notes = release_notes(version)
  FileUtils.mkdir_p("ExtractedChangelog")
  out_file = File.new("ExtractedChangelog/CHANGELOG.md", "w")
  out_file.puts(release_notes)
end

def download_artifacts(key, sha)
  access_token = ENV['GITHUB_ACCESS_TOKEN']
  raise 'GITHUB_ACCESS_TOKEN must be set to create GitHub releases' unless access_token

  github = Octokit::Client.new
  github.auto_paginate = true
  github.access_token = ENV['GITHUB_ACCESS_TOKEN']

  response = github.repository_artifacts(REPOSITORY)
  sha_artifacts = response[:artifacts].filter { |artifact| artifact[:workflow_run][:head_sha] == sha && artifact[:name] == key }
  sha_artifacts.each { |artifact|
    download_url = github.artifact_download_url(REPOSITORY, artifact[:id])
    download(artifact[:name], download_url)
  }
end

def download(name, url)
  sh 'curl', '--output', "#{name}.zip", "#{url}"
end

if ARGV[0] == 'create-release'
  version = ARGV[1]
  create_release(version)
elsif ARGV[0] == 'package-release-notes'
  version = ARGV[1]
  package_release_notes(version)
elsif ARGV[0] == 'download-artifacts'
  key = ARGV[1]
  sha = ARGV[2]
  download_artifacts(key, sha)
end
