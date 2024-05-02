#!/usr/bin/env ruby
# Matrix of current targets and XCode versions, and is used to add/update/delete XCode cloud workflows.

Destination = Struct.new(:build_platform, :test_destination) do |cls|
  def cls.macOS
    Destination.new('MACOS', {
      'deviceTypeName' => 'Mac',
      'deviceTypeIdentifier' => 'mac',
      'runtimeName' => 'Same As Selected macOS Version',
      'runtimeIdentifier' => 'builder',
      'kind' => 'MAC'
    })
  end

  def cls.catalyst
    Destination.new('MACOS', {
      'deviceTypeName' => 'Mac (Mac Catalyst)',
      'deviceTypeIdentifier' => 'mac_catalyst',
      'runtimeName' => 'Same As Selected macOS Version',
      'runtimeIdentifier' => 'builder',
      'kind' => 'MAC'
    })
  end

  def cls.iOS
    Destination.new('IOS', {
      'deviceTypeName' => 'iPhone 11',
      'deviceTypeIdentifier' => 'com.apple.CoreSimulator.SimDeviceType.iPhone-11',
      'runtimeName' => 'Latest from Selected Xcode (iOS 16.1)',
      'runtimeIdentifier' => 'default',
      'kind' => 'SIMULATOR'
    })
  end

  def cls.tvOS
    Destination.new('TVOS', {
      'deviceTypeName' => 'Recommended Apple TVs',
      'deviceTypeIdentifier' =>  'recommended_apple_tvs',
      'runtimeName' =>  'Latest from Selected Xcode (tvOS 16.4)',
      'runtimeIdentifier' =>  'default',
      'kind' =>  'SIMULATOR'
    })
  end

  def cls.generic
    Destination.new('MACOS', nil)
  end
end

Target = Struct.new(:name, :scheme, :filter, :destination) do
  def action
    action = {
      name: self.name,
      actionType: 'BUILD',
      destination: nil,
      buildDistributionAudience: nil,
      scheme: self.scheme,
      platform: self.destination.build_platform,
      isRequiredToPass: true
    }

    test_destination = self.destination.test_destination
    if test_destination
      action[:actionType] = 'TEST'
      action[:destination] = 'ANY_MAC'
      action[:testConfiguration] = {
        kind: 'USE_SCHEME_SETTINGS',
        testPlanName: '',
        testDestinations: [test_destination]
      }
    end

    return action
  end
end

# Each test target has a name, a scheme, an xcode version filter, and a
# destination to run tests on. Targets which aren't testing a framework
# use the 'CI' target and always the a 'generic' destination.
#
# To avoid using excess CI resources we don't build the full matrix of
# combinations of targets and Xcode version. We generally test each build
# method (Xcode project, Swift package, and podspec) on every Xcode version for
# a single platform, and everything else is tested with the oldest and newest
# supported Xcode versions. Some things (e.g. swiftlint) only test the latest
# because they don't care about Xcode versions, while some others are latest-only
# because they're particularly slow to run.
module Workflows
  XCODE_VERSIONS = %w(15.1 15.2 15.3)

  all = ->(v) { true }
  latest_only = ->(v) { v == XCODE_VERSIONS.last }
  oldest_and_latest = ->(v) { v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last }

  TARGETS = [
    Target.new('osx', 'Realm', all, Destination.macOS),
    Target.new('osx-encryption', 'Realm', latest_only, Destination.macOS),
    Target.new('osx-swift', 'RealmSwift', all, Destination.macOS),
    Target.new('osx-swift-evolution', 'RealmSwift', latest_only, Destination.macOS),

    Target.new('ios', 'Realm', oldest_and_latest, Destination.iOS),
    Target.new('ios-static', 'Realm', oldest_and_latest, Destination.iOS),
    Target.new('ios-swift', 'RealmSwift', oldest_and_latest, Destination.iOS),
    Target.new('ios-swift-evolution', 'RealmSwift', latest_only, Destination.iOS),

    Target.new('tvos', 'Realm', oldest_and_latest, Destination.tvOS),
    Target.new('tvos-static', 'Realm', oldest_and_latest, Destination.tvOS),
    Target.new('tvos-swift', 'RealmSwift', oldest_and_latest, Destination.tvOS),
    Target.new('tvos-swift-evolution', 'RealmSwift', latest_only, Destination.tvOS),

    Target.new('catalyst', 'Realm', oldest_and_latest, Destination.catalyst),
    Target.new('catalyst-swift', 'RealmSwift', oldest_and_latest, Destination.catalyst),

    Target.new('watchos', 'Realm', oldest_and_latest, Destination.generic),
    Target.new('watchos-swift', 'RealmSwift', oldest_and_latest, Destination.generic),

    Target.new('swiftui', 'SwiftUITests', latest_only, Destination.iOS),
    Target.new('swiftui-sync', 'SwiftUISyncTests', latest_only, Destination.macOS),

    Target.new('sync', 'Object Server Tests', oldest_and_latest, Destination.macOS),

    Target.new('docs', 'CI', latest_only, Destination.generic),
    Target.new('swiftlint', 'CI', latest_only, Destination.generic),

    Target.new('swiftpm', 'CI', oldest_and_latest, Destination.generic),
    Target.new('swiftpm-debug', 'CI', all, Destination.generic),
    Target.new('swiftpm-address', 'CI', latest_only, Destination.generic),
    Target.new('swiftpm-thread', 'CI', latest_only, Destination.generic),
    Target.new('spm-ios', 'CI', all, Destination.generic),

    Target.new('xcframework', 'CI', latest_only, Destination.generic),

    Target.new('cocoapods-osx', 'CI', all, Destination.generic),
    Target.new('cocoapods-ios', 'CI', latest_only, Destination.generic),
    Target.new('cocoapods-ios-static', 'CI', latest_only, Destination.generic),
    Target.new('cocoapods-watchos', 'CI', latest_only, Destination.generic),
    Target.new('cocoapods-tvos', 'CI', latest_only, Destination.generic),
    Target.new('cocoapods-catalyst', 'CI', latest_only, Destination.generic),
  ]
end
