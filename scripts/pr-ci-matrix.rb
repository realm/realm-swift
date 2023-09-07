#!/usr/bin/env ruby
# Matrix of current targets and XCode versions, and is used to add/update/delete XCode cloud workflows.

module WORKFLOWS
  XCODE_VERSIONS = %w(14.1 14.2 14.3.1)

  all = ->(v) { true }
  latest_only = ->(v) { v == XCODE_VERSIONS.last }
  oldest_and_latest = ->(v) { v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last }

  TARGETS = {
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
end
