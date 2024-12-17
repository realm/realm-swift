#!/usr/bin/env ruby
XCODE_VERSIONS = %w(15.3 15.4 16 16.1 16.2)
DOC_VERSION = '15.4'

all = ->(v) { true }
latest_only = ->(v) { v == XCODE_VERSIONS.last }
oldest_and_latest = ->(v) { v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last }

def minimum_version(major)
  ->(v) { v.split('.').first.to_i >= major }
end

targets = {
  'osx' => all,
  'osx-encryption' => latest_only,

  'swiftpm' => oldest_and_latest,
  'swiftpm-debug' => all,
  'swiftpm-address' => latest_only,
  'swiftpm-thread' => latest_only,

  'ios-static' => oldest_and_latest,
  'ios' => oldest_and_latest,
  'watchos' => oldest_and_latest,
  'tvos' => oldest_and_latest,
  'visionos' => oldest_and_latest,

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
  'ios-swiftui' => latest_only,
}

output_file = """
# This is a generated file produced by scripts/pr-ci-matrix.rb.
name: Pull request build and test
on:
  pull_request:
    paths-ignore:
      - '**.md'
  workflow_dispatch:

jobs:
  docs:
    runs-on: macos-14
    name: Test docs
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: sudo xcode-select -switch /Applications/Xcode_#{DOC_VERSION}.app
      - run: bundle exec sh build.sh verify-docs
  swiftlint:
    runs-on: macos-14
    name: Check swiftlint
    steps:
      - uses: actions/checkout@v4
      - run: sudo xcode-select -switch /Applications/Xcode_#{DOC_VERSION}.app
      - run: brew install swiftlint
      - run: sh build.sh verify-swiftlint
"""

targets.each { |name, filter|
  XCODE_VERSIONS.each { |version|
    if not filter.call(version)
      next
    end
    image = version.start_with?('16') ? 'macos-15' : 'macos-14'
    output_file << """
  #{name}-#{version.gsub(' ', '_').gsub('.', '_')}:
    runs-on: #{image}
    name: Test #{name} on Xcode #{version}
    env:
      DEVELOPER_DIR: '/Applications/Xcode_#{version}.app/Contents/Developer'
    steps:
      - uses: actions/checkout@v4
      - run: sh -x build.sh ci-pr #{name}
"""
  }
}

File.open('.github/workflows/build-pr.yml', "w") do |file|
  file.puts output_file
end
