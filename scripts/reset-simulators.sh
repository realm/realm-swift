#!/bin/bash

set -o pipefail
set -e

if [ -n "$JENKINS_HOME" ]; then
  CI_RUN=true
elif [ "$CI_RUN" != true ]; then
  CI_RUN=false
fi

if [ $CI_RUN == true ] || [ "$CLEAN_IOS_SIMULATOR" == true ]; then
  CLEAN_IOS_SIMULATOR=true
else
  CLEAN_IOS_SIMULATOR=false
fi

ios_sim_default_device_type=${ios_sim_default_device_type:-iPhone 5s}
ios_sim_default_ios_version=${ios_sim_default_ios_version:-iOS 10.2}

# - Ensure one version of xcode is chosen by all tools
if [ -z "$DEVELOPER_DIR" ];then
  if [ -f "$(dirname "$0")/swift-version.sh" ]; then
    source "$(dirname "$0")/swift-version.sh"
  elif [ -f "$(dirname "$0")/scripts/swift-version.sh" ]; then
    source "$(dirname "$0")/scripts/swift-version.sh"
  else
    echo "*** Unable to find swift-version.sh ***" >&2
    exit 1
  fi
  set_xcode_and_swift_versions
fi

validate_ios_simulator() {
  local explicit_hardware=$1
  local explicit_os=$2
  
  if [ -z "$IOS_SIM_DEVICE" ]; then
    echo "*** Failed to determine the iOS simulator device to use ***" >&2
    exit 1
  fi
  export IOS_SIM_HARDWARE=$(ruby -rjson -e "puts JSON.parse(%x{/usr/bin/xcrun simctl list devices --json})['devices'].each{|os,group| group.each{|dev| dev['os'] = os}}.flat_map{|x| x[1]}.select{|x| x['udid'] == '$IOS_SIM_DEVICE'}.first['name']")
  export IOS_SIM_OS=$(ruby -rjson -e "puts JSON.parse(%x{/usr/bin/xcrun simctl list devices --json})['devices'].each{|os,group| group.each{|dev| dev['os'] = os}}.flat_map{|x| x[1]}.select{|x| x['udid'] == '$IOS_SIM_DEVICE'}.first['os']")
  
  if [ -n "$explicit_hardware" ] && [ "$explicit_hardware" != "$IOS_SIM_HARDWARE" ]; then
    echo "*** Failed to find the specified hardware ($explicit_hardware), got: $IOS_SIM_HARDWARE" >&2
    exit 1
  fi
  if [ -n "$explicit_os" ] && [ "$explicit_os" != "$IOS_SIM_OS" ]; then
    echo "*** Failed to find the specified ios version ($explicit_os), got: $IOS_SIM_OS" >&2
    exit 1
  fi
}

choose_ios_simulator() {
  local explicit_hardware=$1
  local explicit_os=$2
  
  if [ -n "$explicit_hardware" ] || [ -n "$explicit_os" ]; then
    IOS_SIM_DEVICE=
  fi
  
  local default_hardware=${explicit_hardware:-$ios_sim_default_device_type}
  local default_os=${explicit_os:-$ios_sim_default_ios_version}
  
  local deadline=$((SECONDS+5))
  while [ -z "$IOS_SIM_DEVICE" ] && [ $SECONDS -lt $deadline ]; do
    export IOS_SIM_DEVICE=$(ruby -rjson -e "puts JSON.parse(%x{/usr/bin/xcrun simctl list devices --json})['devices'].each{|os,group| group.each{|dev| dev['os'] = os}}.flat_map{|x| x[1]}.select{|x| x['availability'] == '(available)'}.each{|x| x['score'] = (x['name'] == '$default_hardware' ? 1 : 0) + (x['os'] == '$default_os' ? 1 : 0)}.sort_by!{|x| [x['score'], x['name']]}.reverse![0]['udid']" 2>/dev/null || true)
  done
  
  validate_ios_simulator "$explicit_hardware" "$explicit_os"
}

setup_ios_simulator() {
  local explicit_hardware=$1
  local explicit_os=$2
  
  # -- Ensure that the simulator is ready
  
  # - Check if the wrong version of the CoreSimulatorService is running
  if ! [[ `/usr/bin/pgrep -lf com.apple.CoreSimulator.CoreSimulatorService | /usr/bin/awk '{print substr($0, index($0, $2))}'` =~ ^$DEVELOPER_DIR/* ]]; then
    if [ $CI_RUN == true ] || [ "$ENABLE_QUIT" == true ]; then
      printf "Resetting iOS simulator using toolchain from: $DEVELOPER_DIR..."
      stop_ios_simulator_tools
      echo " done"
      
      if pgrep -qx Simulator 'Simulator (Watch)' simctl com.apple.CoreSimulator.CoreSimulatorService; then
        echo "Failed to quit Simulator, Simulator (Watch), simctl, or CoreSimulatorService" >&2
        exit 1
      fi
    else
      echo "It appears that a different version of the CoreSimulatorService is curently running.\n\tPlease either reset it yourself or se the ENABLE_QUIT env variable to `true`." >&2
      exit 1
    fi
  fi
  
  # - Prod `simctl` a few times as sometimes it fails the first couple of times after switching XCode vesions
  local deadline=$((SECONDS+5))
  while [ -z "$(/usr/bin/xcrun simctl list devices 2>/dev/null)" ] && [ $SECONDS -lt $deadline ]; do
    : # nothing to see here, will stop cycling on the first successful run
  done
  
  # - Choose a device, this sets $IOS_SIM_DEVICE, IOS_SIM_HARDWARE, and IOS_SIM_OS
  # see if we have something acceptable already booted
  export IOS_SIM_DEVICE=$(ruby -rjson -e "puts JSON.parse(%x{/usr/bin/xcrun simctl list devices --json})['devices'].each{|os,group| group.each{|dev| dev['os'] = os}}.flat_map{|x| x[1]}.select{|x| x['state'] == 'Booted'}.select{|x| ['$explicit_hardware', x['name']].include?('') && ['$explicit_os', x['os']].include?('')}.first['udid']" 2>/dev/null || true)
  if [ -z "$IOS_SIM_DEVICE" ]; then
    choose_ios_simulator "$explicit_hardware" "$explicit_os"
  else
    validate_ios_simulator "$explicit_hardware" "$explicit_os" # sets IOS_SIM_HARDWARE and IOS_SIM_OS
  fi
  
  echo "Setting up $IOS_SIM_HARDWARE simulator running $IOS_SIM_OS ($IOS_SIM_DEVICE)" 
  
  # - Optionally reset the device
  if [ $CLEAN_IOS_SIMULATOR == true ]; then
    printf "  Cleaning device..."
    /usr/bin/xcrun simctl shutdown "$IOS_SIM_DEVICE" 1>/dev/null 2>/dev/null || true # sometimes simctl gets confused
    /usr/bin/xcrun simctl erase "$IOS_SIM_DEVICE"
    echo " done"
  fi
  
  # - Start the target if it is not running
  if ruby -rjson -e "exit JSON.parse(%x{/usr/bin/xcrun simctl list devices --json})['devices'].flat_map{|x| x[1]}.none?{|x| x['state'] == 'Booted' && x['udid'] == '$IOS_SIM_DEVICE'}" 2>/dev/null; then
    printf "  Starting device..."
    /usr/bin/open "$DEVELOPER_DIR/Applications/Simulator.app" --args -CurrentDeviceUDID "$IOS_SIM_DEVICE"
    
    # Wait until the boot completes
    until ruby -rjson -e "exit JSON.parse(%x{/usr/bin/xcrun simctl list devices --json})['devices'].flat_map { |d| d[1] }.any?{ |d| d['availability'] == '(available)' && d['state'] == 'Booted' }" 2>/dev/null; do
      sleep 0.25
    done
    
    # Wait for springboard to come up
    until /usr/bin/xcrun simctl launch "$IOS_SIM_DEVICE" com.apple.springboard 1>/dev/null 2>/dev/null; do
      sleep 0.25
    done
    
    echo " done"
  fi
}

stop_ios_simulator_tools() {
  # Quit Simulator.app (if it is running) to give it a chance to go down gracefully
  if pgrep -qx Simulator; then
    osascript -e 'tell app "Simulator" to quit without saving' || true
    sleep 0.25 # otherwise the pkill following will get it too early
  fi
  if pgrep -qx 'Simulator (Watch)'; then
    osascript -e 'tell app "Simulator (Watch)" to quit without saving' || true
    sleep 0.25 # otherwise the pkill following will get it too early
  fi
  
  # kill any instances of simctl, since they might hold onto (or restart) the CoreSimulatorService service
  if pgrep -qx simctl; then
    pkill -qx simctl || true
    sleep 0.25 # otherwise the pkill following will get it too early
  fi
  
  # stop CoreSimulatorService
  launchctl remove com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
  sleep 0.25 # launchtl can take a moment to kill services
  
  # kill them with fire
  while pgrep -qx Simulator 'Simulator (Watch)' simctl com.apple.CoreSimulator.CoreSimulatorService; do
    pkill -9 -x Simulator com.apple.CoreSimulator.CoreSimulatorService || true
    sleep 0.05
  done
}

stop_ios_simulator() {
  # Shut down and clean the setup we were using
  if [ -n "$IOS_SIM_HARDWARE" ]; then
    printf "Stopping $IOS_SIM_HARDWARE simulator running $IOS_SIM_OS ($IOS_SIM_DEVICE)..."
    /usr/bin/xcrun simctl shutdown "$IOS_SIM_DEVICE" 1>/dev/null 2>/dev/null || true # sometimes simctl gets confused
    /usr/bin/xcrun simctl erase "$IOS_SIM_DEVICE" || true
    echo " done"
  fi
  
  # Clean off all tools
  if [ $CI_RUN == true ] || [ "$ENABLE_QUIT" == true ]; then
    # Stop all simulators
    for device in `ruby -rjson -e "JSON.parse(%x{/usr/bin/xcrun simctl list devices --json})['devices'].flat_map { |d| d[1] }.select{ |d| d['state'] == 'Booted' }.each{|d| puts d['udid']}" 2>/dev/null || true`; do
      printf "  Stoping $device..."
      /usr/bin/xcrun simctl shutdown "$device" 1>/dev/null 2>/dev/null || true
      echo " done"
    done
    
    printf "  Shutting down used resources..."
    stop_ios_simulator_tools
    echo " done"
    
    if pgrep -qx Simulator simctl com.apple.CoreSimulator.CoreSimulatorService; then
      echo "WARNING: Failed to quit Simulator, simctl, or CoreSimulatorService"
    fi
  fi
}

return 2>/dev/null || { # will only run if this file is called directly
	setup_ios_simulator
	echo "$IOS_SIM_HARDWARE simulator running $IOS_SIM_OS ($IOS_SIM_DEVICE) is now ready"
	if [ -n "$RESET_SIMULATOR_DEBUG" ]; then
  	stop_ios_simulator
  fi
}
