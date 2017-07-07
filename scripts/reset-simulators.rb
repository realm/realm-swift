#!/usr/bin/ruby

require 'json'

# use default DEVELOPER_DIR if not already set
ENV['DEVELOPER_DIR'] = `/usr/bin/xcode-select` unless ENV['DEVELOPER_DIR']

def platform_for_runtime(runtime)
  runtime['identifier'].gsub(/com.apple.CoreSimulator.SimRuntime.([^-]+)-.*/, '\1')
end

def platform_for_device_type(device_type)
  case device_type['identifier']
  when /Watch/
    'watchOS'
  when /TV/
    'tvOS'
  else
    'iOS'
  end
end

begin
  # - Check if the wrong version of the CoreSimulatorService is running, stop it if so
  if ! /^\d+\s+#{ENV['DEVELOPER_DIR']}\/.+/ =~ `/usr/bin/pgrep -lf com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null`; then    
    # Kill all the current simulator processes as they are from a different Xcode version
    print "Killing running Simulator processes and replacing with one from #{ENV['DEVELOPER_DIR']}..."
    
    if ! `/usr/bin/pgrep -qx Simulator`.empty?
      `/usr/bin/osascript -e 'tell app "Simulator" to quit without saving'`
      sleep 0.2 # we are sending AppleEvents, not a kill signal
    end
    if ! `/usr/bin/pgrep -qx 'Simulator (Watch)'`.empty?
      `/usr/bin/osascript -e 'tell app "Simulator (Watch)" to quit without saving'`
      sleep 0.2 # we are sending AppleEvents, not a kill signal
    end
    
    # kill any instances of simctl, since they might hold onto (or restart) the CoreSimulatorService service
    `/usr/bin/pkill -qx simctl`
    
    # stop CoreSimulatorService
    `/bin/launchctl remove com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null`
    sleep 0.2 # launchtl can take a moment to kill services
    
    # kill anything remaining with fire
    until `/usr/bin/pgrep -x Simulator 'Simulator (Watch)' simctl com.apple.CoreSimulator.CoreSimulatorService`.empty?
      `/usr/bin/pkill -9 -x Simulator 'Simulator (Watch)' simctl com.apple.CoreSimulator.CoreSimulatorService`
      sleep 0.2
    end

    puts ' done!'
  end
  
  # - Switching simulator versions often causes CoreSimulatorService to throw an exception.
  print 'Waiting for simulator to be ready...'
  while `xcrun simctl list devices 2>/dev/null`.empty?
    sleep 0.2
  end
  puts ' done!'

  # - Shut down any running simulator devices.
  # This may take multiple attempts if some simulators are in-flight
  all_available_devices = []
  (0..5).each do |shutdown_attempt|
    devices_json = `xcrun simctl list devices -j`
    raise 'xcrun failed!' unless $?.success?
    all_available_devices = JSON.parse(devices_json)['devices'].flat_map { |_, devices| devices }

    # Include only avalible devices, others belong to other versions of the simulator
    all_available_devices = all_available_devices.select { |device| device['availability'] == '(available)' }
    
    # Get the list of non-shutdown devices
    running_devices = all_available_devices.reject { |device| device['state'] == 'Shutdown' }
    
    break if running_devices.empty?
    
    # Shutdown the running devices
    running_devices.each do |device|
      puts "  Shutting down simulator #{device['udid']}"
      system("xcrun simctl shutdown #{device['udid']}") or puts "    Failed to shut down simulator #{device['udid']}"
    end
    sleep shutdown_attempt if shutdown_attempt > 0
  end

  # Delete all avalible simulators
  print 'Deleting all avalible simulators...'
  all_available_devices.each do |device|
    system("xcrun simctl delete #{device['udid']}") or raise "Failed to delete simulator #{device['udid']}"
  end
  puts ' done!'

  # Recreate all simulators.
  runtimes = JSON.parse(`xcrun simctl list runtimes -j`)['runtimes']
  device_types = JSON.parse(`xcrun simctl list devicetypes -j`)['devicetypes']

  runtimes_by_platform = Hash.new { |hash, key| hash[key] = [] }
  runtimes.each do |runtime|
    next unless runtime['availability'] == '(available)'
    runtimes_by_platform[platform_for_runtime(runtime)] << runtime
  end

  print 'Creating fresh simulators...'
  device_types.each do |device_type|
    platform = platform_for_device_type(device_type)
    runtimes_by_platform[platform].each do |runtime|
      output = `xcrun simctl create '#{device_type['name']}' '#{device_type['identifier']}' '#{runtime['identifier']}' 2>&1`
      next if $? == 0

      # Error code 161 and 162 indicate that the given device is not supported by the runtime,
      # such as the iPad 2 and iPhone 4s not being supported by the iOS 10 simulator runtime.
      next if output =~ /(domain=com.apple.CoreSimulator.SimError, code=16[12])/

      puts "\n  Failed to create device of type #{device_type['identifier']} with runtime #{runtime['identifier']}:"
      output.each_line do |line|
        puts "    #{line}"
      end
    end
  end
  puts ' done!'

rescue
  system('ps auxwww')
  system('xcrun simctl list')
  raise
end
