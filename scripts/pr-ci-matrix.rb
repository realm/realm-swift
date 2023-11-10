#!/usr/bin/env ruby
# Matrix of current targets and XCode versions, and is used to add/update/delete XCode cloud workflows.

# The target should have the following structure, target = <platform>-<scheme>_<extra>
# this will help to create new workflows and their build actions automatically.
#
# platform: ios, tvos, osx, catalyst
# For any other values different than the ones mentioned above, a default build action will be created
# and all the tests must be run on the `ci_post_clone.sh` step.
#
# scheme:
# swift => RealmSwift
# swiftui => SwiftUITests
# swiftuiserver => SwiftUISyncTests
# default => For any other value Realm will be used as the scheme.
#
# To add new workflows which includes new platforms or schemes, the corresponding configuration should be
# added to the `xcode_cloud-helper.rb` file.
module WORKFLOWS
  XCODE_VERSIONS = %w(14.1 14.2 14.3.1)

  all = ->(v) { true }
  latest_only = ->(v) { v == XCODE_VERSIONS.last }
  oldest_and_latest = ->(v) { v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last }

  TARGETS = {
    'osx' => all,
    'osx-encryption' => latest_only,
    'osx-swift' => all,
    'osx-swift-evolution' => latest_only,

    'ios' => oldest_and_latest,
    'ios-static' => oldest_and_latest,
    'ios-swift' => oldest_and_latest,
    'ios-swift-evolution' => latest_only,

    'tvos' => oldest_and_latest,
    'tvos-swift' => oldest_and_latest,
    'tvos-swift-evolution' => latest_only,

    'catalyst' => oldest_and_latest,
    'catalyst-swift' => oldest_and_latest,

    'watchos' => oldest_and_latest,

    'ios-swiftui' => latest_only,

    'swiftuiserver-osx' => latest_only,
    'objectserver-osx' => oldest_and_latest,

    'docs' => latest_only,
    'swiftlint' => latest_only,

    'swiftpm' => oldest_and_latest,
    'swiftpm-debug' => all,
    'swiftpm-address' => latest_only,
    'swiftpm-thread' => latest_only,

    'xcframework' => latest_only,

    'cocoapods-osx' => all,
    'cocoapods-ios-static' => latest_only,
    'cocoapods-ios' => latest_only,
    'cocoapods-watchos' => latest_only,
    'cocoapods-tvos' => latest_only,
    'cocoapods-catalyst' => latest_only,

    'spm-ios' => all,
  }
end
