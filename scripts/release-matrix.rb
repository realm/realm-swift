#!/usr/bin/env ruby
# Matrix of resulting build actions for each release workflow

BuildDestination = Struct.new(:build_platform, :destination) do |cls|
  def cls.macOS
    BuildDestination.new('MACOS', 'ANY_MAC')
  end

  def cls.catalyst
    BuildDestination.new('MACOS', 'ANY_MAC_CATALYST')
  end

  def cls.iOS
    BuildDestination.new('IOS', 'ANY_IOS_DEVICE')
  end

  def cls.iOSSimulator
    BuildDestination.new('IOS', 'ANY_IOS_SIMULATOR')
  end

  def cls.tvOS
    BuildDestination.new('TVOS', 'ANY_TVOS_DEVICE')
  end

  def cls.tvOSSimulator
    BuildDestination.new('TVOS', 'ANY_TVOS_SIMULATOR')
  end

  def cls.watchOS
    BuildDestination.new('WATCHOS', 'ANY_WATCHOS_DEVICE')
  end

  def cls.watchOSSimulator
    BuildDestination.new('WATCHOS', 'ANY_WATCHOS_SIMULATOR')
  end

  def cls.visionOS
    BuildDestination.new('VISIONOS', 'ANY_VISIONOS_DEVICE')
  end

  def cls.visionOSSimulator
    BuildDestination.new('VISIONOS', 'ANY_VISIONOS_SIMULATOR')
  end

  def cls.generic
    BuildDestination.new('MACOS', nil)
  end
end

RELEASE_DESTINATIONS = { "osx" => BuildDestination.macOS, 
                         "catalyst" => BuildDestination.catalyst, 
                         "ios" => BuildDestination.iOS,
                         "iossimulator" => BuildDestination.iOSSimulator, 
                         "tvos" => BuildDestination.tvOS, 
                         "tvossimulator" => BuildDestination.tvOSSimulator,
                         "watchos" => BuildDestination.watchOS, 
                         "watchossimulator" => BuildDestination.watchOSSimulator,
                         "visionos" => BuildDestination.visionOS, 
                         "visionossimulator" => BuildDestination.visionOSSimulator
                        }

ReleaseTarget = Struct.new(:name, :scheme, :platform) do
  def action
    build_destination = RELEASE_DESTINATIONS[platform]
    action = {
      name: self.name,
      actionType: 'BUILD',
      destination: build_destination.destination,
      buildDistributionAudience: nil,
      scheme: self.scheme,
      platform: build_destination.build_platform,
      isRequiredToPass: true
    }

    return action
  end
end