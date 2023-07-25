#!/usr/bin/env ruby
# A script to generate the .jenkins.yml file for the CI pull request job
XCODE_VERSIONS = %w(14.1 14.2 14.3.1)

all = ->(v) { true }
latest_only = ->(v) { v == XCODE_VERSIONS.last }
oldest_and_latest = ->(v) { v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last }

def minimum_version(major)
  ->(v) { v.split('.').first.to_i >= major }
end

targets = {
  'docs' => latest_only,
  'swiftlint' => latest_only,

  'osx' => all,
  'osx-encryption' => latest_only,
  'osx-object-server' => oldest_and_latest,

  'swiftpm' => oldest_and_latest,
  'swiftpm-debug' => all,
  'swiftpm-address' => latest_only,
  'swiftpm-thread' => latest_only,
  'ios-xcode-spm' => all,

  'ios-static' => oldest_and_latest,
  'ios' => oldest_and_latest,
  'watchos' => oldest_and_latest,
  'tvos' => oldest_and_latest,

  'osx-swift' => all,
  'ios-swift' => oldest_and_latest,
  'tvos-swift' => oldest_and_latest,

  'osx-swift-evolution' => latest_only,
  'ios-swift-evolution' => latest_only,
  'tvos-swift-evolution' => latest_only,

  'catalyst' => oldest_and_latest,
  'catalyst-swift' => oldest_and_latest,

  'xcframework' => latest_only,

  'cocoapods-osx' => all,
  'cocoapods-ios-static' => latest_only,
  'cocoapods-ios' => latest_only,
  'cocoapods-watchos' => latest_only,
  'cocoapods-tvos' => latest_only,
  'cocoapods-catalyst' => latest_only,
  'swiftui-ios' => latest_only,
  'swiftui-server-osx' => latest_only,
}

output_file = """
# Yaml Axis Plugin
# https://wiki.jenkins-ci.org/display/JENKINS/Yaml+Axis+Plugin
# This is a generated file produced by scripts/pr-ci-matrix.rb.

xcode_version:#{XCODE_VERSIONS.map { |v| "\n - #{v}" }.join()}
target:#{targets.map { |k, v| "\n - #{k}" }.join()}
configuration:
 - N/A

exclude:
"""
targets.each { |name, filter|
  XCODE_VERSIONS.each { |version|
    if not filter.call(version)
      output_file << """
  - xcode_version: #{version}
    target: #{name}
"""
    end
  }
}

File.open('.jenkins.yml', "w") do |file|
  file.puts output_file
end
