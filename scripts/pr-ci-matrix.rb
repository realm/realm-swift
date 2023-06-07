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
  'swiftpm' => oldest_and_latest,
  'swiftpm-debug' => all,
  'swiftpm-address' => latest_only,
  'swiftpm-thread' => latest_only,
  'swiftpm-ios' => all,
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
