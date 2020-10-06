#!/usr/bin/env ruby
# A script to generate the .jenkins.yml file for the CI pull request job
XCODE_VERSIONS = %w(11.3 11.7 12.0 12.1 12.2)
CONFIGURATIONS = %w(Debug Release)

release_only = ->(v, c) { c == 'Release' }
latest_only = ->(v, c) { c == 'Release' and v == XCODE_VERSIONS.last }
oldest_and_latest = ->(v, c) { c == 'Release' and (v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last) }

def minimum_version(major)
  ->(v, c) { v.split('.').first.to_i >= major and (c == 'Release' or v == XCODE_VERSIONS.last) }
end

targets = {
  'swiftpm' => oldest_and_latest,
  'swiftpm-address' => latest_only,
  'swiftpm-thread' => latest_only,
  'swiftpm-ios' => latest_only,
}

output_file = """
# Yaml Axis Plugin
# https://wiki.jenkins-ci.org/display/JENKINS/Yaml+Axis+Plugin
# This is a generated file produced by scripts/pr-ci-matrix.rb.

xcode_version:#{XCODE_VERSIONS.map { |v| "\n - #{v}" }.join()}
target:#{targets.map { |k, v| "\n - #{k}" }.join()}
configuration:#{CONFIGURATIONS.map { |v| "\n - #{v}" }.join()}

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
