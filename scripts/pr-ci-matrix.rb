#!/usr/bin/env ruby
# A script to generate the .jenkins.yml file for the CI pull request job
XCODE_VERSIONS = %w(10.0 10.1 10.3 11.1 11.2.1 11.3)
CONFIGURATIONS = %w(Debug Release)

default = ->(v, c) { c == 'Release' or v == XCODE_VERSIONS.last }
release_only = ->(v, c) { c == 'Release' }
latest_only = ->(v, c) { c == 'Release' and v == XCODE_VERSIONS.last }
oldest_and_latest = ->(v, c) { c == 'Release' and (v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last) }

def minimum_version(major)
  ->(v, c) { v.split('.').first.to_i >= major and (c == 'Release' or v == XCODE_VERSIONS.last) }
end

targets = {
  'docs' => latest_only,
  'swiftlint' => latest_only,

  'osx' => ->(v, c) { true },
  'osx-encryption' => oldest_and_latest,
  'osx-object-server' => oldest_and_latest,

  'ios-static' => default,
  'ios-dynamic' => default,
  'watchos' => default,
  'tvos' => default,

  'ios-swift' => default,
  'osx-swift' => default,
  'tvos-swift' => default,

  'catalyst' => minimum_version(11),
  'catalyst-swift' => minimum_version(11),

  'cocoapods-osx' => release_only,
  'cocoapods-ios' => release_only,
  'cocoapods-ios-dynamic' => release_only,
  'cocoapods-watchos' => release_only,

  'swiftpm' => ->(v, c) { c == 'Release' && (v == '10.3' or v == XCODE_VERSIONS.last) },
  'swiftpm-address' => latest_only,
  'swiftpm-thread' => latest_only,

  # These are disabled because the machine with the devices attached is currently offline
  # - ios-device-objc-ios8
  # - ios-device-objc-ios10
  # - tvos-device
  # These are disabled because they were very unreliable on CI
  # - ios-device-swift-ios8
  # - ios-device-swift-ios10
}

output_file = """
# Yaml Axis Plugin
# https://wiki.jenkins-ci.org/display/JENKINS/Yaml+Axis+Plugin
# This is a generated file produced by scripts/pr-ci-matrix.rb.

xcode_version: #{XCODE_VERSIONS.map { |v| "\n - #{v}" }.join()}
target: #{targets.map { |k, v| "\n - #{k}" }.join()}
configuration: #{CONFIGURATIONS.map { |v| "\n - #{v}" }.join()}

exclude:
"""
targets.each { |name, filter|
  XCODE_VERSIONS.each { |version|
    CONFIGURATIONS.each { |configuration|
      if not filter.call(version, configuration)
        output_file << """
  - xcode_version: #{version}
    target: #{name}
    configuration: #{configuration}
"""
      end
    }
  }
}

File.open('.jenkins.yml', "w") do |file|
  file.puts output_file
end
