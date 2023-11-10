#!/usr/bin/env ruby
# Matrix of resulting build actions for each release workflow

release_destinations = { "osx" => BuildDestination.macOS, 
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
BuildDestination = Struct.new(:build_platform, :destination) do |cls|
  def cls.macOS
    Destination.new('MACOS', {
      'destination' => 'ANY_MAC'
    })
  end

  def cls.catalyst
    Destination.new('MACOS', {
      'destination' => 'ANY_MAC_CATALYST'
    })
  end

  def cls.iOS
    Destination.new('IOS', {
      'destination' => 'ANY_IOS_DEVICE'
    })
  end

  def cls.iOSSimulator
    Destination.new('IOS', {
      'destination' => 'ANY_IOS_SIMULATOR'
    })
  end

  def cls.tvOS
    Destination.new('TVOS', {
      'destination' => 'ANY_TVOS_DEVICE'
    })
  end

  def cls.tvOSSimulator
    Destination.new('TVOS', {
      'destination' => 'ANY_TVOS_DEVICE'
    })
  end

  def cls.watchOS
    Destination.new('WATCHOS', {
      'destination' => 'ANY_WATCHOS_DEVICE'
    })
  end

  def cls.watchOSSimulator
    Destination.new('WATCHOS', {
      'destination' => 'ANY_WATCHOS_SIMULATOR'
    })
  end

  def cls.visionOS
    Destination.new('VISIONOS', {
      'destination' => 'ANY_VISIONOS_DEVICE'
    })
  end

  def cls.visionOSSimulator
    Destination.new('VISIONOS', {
      'destination' => 'ANY_VISIONOS_SIMULATOR'
    })
  end

  def cls.generic
    Destination.new('MACOS', nil)
  end
end

ReleaseTarget = Struct.new(:name, :scheme, :destination_string) do
  def action
    destination = release_destinations[:destination_string]
    action = {
      name: self.name,
      actionType: 'BUILD',
      destination: self.destination.destination,
      buildDistributionAudience: nil,
      scheme: self.scheme,
      platform: self.destination.build_platform,
      isRequiredToPass: true
    }

    return action
  end
end