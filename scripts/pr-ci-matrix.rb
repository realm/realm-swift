#!/usr/bin/env ruby
# A script to generate the .jenkins.yml file for the CI pull request job
xcode_versions = %w(10.0 10.1 10.2.1 10.3 11.0)
configurations = %w(Debug Release)

default = ->(v, c) { c == 'Release' or v == xcode_versions.last }
release_only = ->(v, c) { c == 'Release' }
latest_only = ->(v, c) { c == 'Release' and v == xcode_versions.last }
oldest_and_latest = ->(v, c) { c == 'Release' and (v == xcode_versions.first or v == xcode_versions.last) }

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

  'cocoapods-osx' => release_only,
  'cocoapods-ios' => release_only,
  'cocoapods-watchos' => release_only,

  'swiftpm' => ->(v, c) { c == 'Release' && (v == '10.3' or v == xcode_versions.last) }

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

xcode_version: #{xcode_versions.map { |v| "\n - #{v}" }.join()}
target: #{targets.map { |k, v| "\n - #{k}" }.join()}
configuration: #{configurations.map { |v| "\n - #{v}" }.join()}

exclude:
"""
targets.each { |name, filter|
  xcode_versions.each { |version|
    configurations.each { |configuration|
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
