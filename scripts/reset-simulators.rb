#!/usr/bin/ruby

require 'json'
require 'open3'

prelaunch_simulator = ARGV[0] || ''

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

def simctl(args)
  # When running on a machine with Xcode 11 installed, Xcode 10 sometimes
  # incorrectly thinks that it has not completed its first-run installation.
  # This results in it printing errors related to that to stdout in front of
  # the actual JSON output that we want.
  Open3.popen3('xcrun simctl ' + args) do |stdin, stdout, strerr, wait_thr|
    while line = stdout.gets
      if not line.start_with? 'Install'
        return line + stdout.read, wait_thr.value.exitstatus
      end
    end
  end
end

def wait_for_core_simulator_service
  # Run until we get a result since switching simulator versions often causes CoreSimulatorService to throw an exception.
  while simctl('list devices')[0].empty?
  end
end

def running_devices(devices)
  devices.select { |device| device['state'] != 'Shutdown' }
end

def shutdown_simulator_devices(devices)
  # Shut down any simulators that need it.
  running_devices(devices).each do |device|
    puts "Shutting down simulator #{device['udid']}"
    system("xcrun simctl shutdown #{device['udid']}") or puts "    Failed to shut down simulator #{device['udid']}"
  end
end

attempts = 0
begin
  # Kill all the current simulator processes as they may be from a different Xcode version
  print 'Killing running Simulator processes...'
  while system('pgrep -q Simulator')
    system('pkill Simulator 2>/dev/null')
    # CoreSimulatorService doesn't exit when sent SIGTERM
    system('pkill -9 Simulator 2>/dev/null')
  end
  wait_for_core_simulator_service
  puts ' done!'

  print 'Shut down existing simulator devices...'
  # Shut down any running simulator devices. This may take multiple attempts if some
  # simulators are currently in the process of booting or being created.
  all_available_devices = []
  (0..5).each do |shutdown_attempt|
    begin
      devices_json = simctl('list devices -j')[0]
      all_devices = JSON.parse(devices_json)['devices'].flat_map { |_, devices| devices }
    rescue JSON::ParserError
      sleep shutdown_attempt if shutdown_attempt > 0
      next
    end

    # Exclude devices marked as unavailable as they're from a different version of Xcode.
    all_available_devices = all_devices.reject { |device| device['availability'] =~ /unavailable/ }

    break if running_devices(all_available_devices).empty?

    shutdown_simulator_devices all_available_devices
    sleep shutdown_attempt if shutdown_attempt > 0
  end
  puts ' done!'

  # Delete all simulators.
  print 'Deleting all simulators...'
  (0..5).each do |delete_attempt|
    break if all_available_devices.empty?

    all_available_devices.each do |device|
      simctl("delete #{device['udid']}")
    end

    begin
      devices_json = simctl('list devices -j')[0]
      all_devices = JSON.parse(devices_json)['devices'].flat_map { |_, devices| devices }
    rescue JSON::ParserError
      sleep shutdown_attempt if shutdown_attempt > 0
      next
    end

    all_available_devices = all_devices.reject { |device| device['availability'] =~ /unavailable/ }
    break if all_available_devices.empty?
  end
  puts ' done!'

  if not all_available_devices.empty?
    raise "Failed to delete devices #{all_available_devices}"
  end

  # Recreate all simulators.
  runtimes = JSON.parse(simctl('list runtimes -j')[0])['runtimes']
  device_types = JSON.parse(simctl('list devicetypes -j')[0])['devicetypes']

  runtimes_by_platform = Hash.new { |hash, key| hash[key] = [] }
  runtimes.each do |runtime|
    next unless runtime['availability'] == '(available)' || runtime['isAvailable'] == true
    runtimes_by_platform[platform_for_runtime(runtime)] << runtime
  end

  firstOnly = prelaunch_simulator == '-firstOnly'

  print 'Creating fresh simulators...'
  device_types.each do |device_type|
    platform = platform_for_device_type(device_type)
    runtimes_by_platform[platform].each do |runtime|
      output, ec = simctl("create '#{device_type['name']}' '#{device_type['identifier']}' '#{runtime['identifier']}' 2>&1")
      if ec == 0
        if firstOnly
          # We only want to create a single simulator for each device type so
          # skip the rest.
          runtimes_by_platform[platform] = []
          break
        else
          next
        end
      end

      # Not all runtime and device pairs are valid as newer simulator runtimes
      # don't support older devices. The exact error code for this changes
      # every few versions of Xcode, so this just lists all the ones we've
      # seen.
      next if /domain=com.apple.CoreSimulator.SimError, code=(?<code>\d+)/ =~ output and [161, 162, 163, 403].include? code.to_i

      puts "Failed to create device of type #{device_type['identifier']} with runtime #{runtime['identifier']}:"
      output.each_line do |line|
        puts "    #{line}"
      end
    end
  end
  puts ' done!'

  if firstOnly
    exit 0
  end

  if prelaunch_simulator.include? 'tvos'
    print 'Booting Apple TV simulator...'
    system("xcrun simctl boot 'Apple TV'") or raise "Failed to boot Apple TV simulator"
  else
    print 'Booting iPhone 8 simulator...'
    system("xcrun simctl boot 'iPhone 8'") or raise "Failed to boot iPhone 8 simulator"
  end
  puts ' done!'

  print 'Waiting for dyld shared cache to update...'
  while system('pgrep -q update_dyld_sim_shared_cache')
    sleep 15
  end
  puts ' done!'

rescue => e
  if (attempts += 1) < 5
    puts ''
    puts e.message
    e.backtrace.each { |line| puts line }
    puts ''
    puts 'Retrying...'
    retry
  end
  system('ps auxwww')
  system('xcrun simctl list')
  raise
end
