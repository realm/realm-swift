#!/usr/bin/env ruby
# A script to generate the `ci_post_clone.sh` file used to run all the Xcode Cloud CI pull request job
XCODE_VERSIONS = %w(14.1 14.2 14.3.1)

all = ->(v) { true }
latest_only = ->(v) { v == XCODE_VERSIONS.last }
oldest_and_latest = ->(v) { v == XCODE_VERSIONS.first or v == XCODE_VERSIONS.last }

def minimum_version(major)
  ->(v) { v.split('.').first.to_i >= major }
end

targets = {
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

output_file = "#!/bin/sh"
output_file << """
# This is a generated file produced by scripts/pr-ci-matrix.rb.

set -o pipefail

# Set the -e flag to stop running the script in case a command returns
# a non-zero exit code.
set -e

# Print env
env

# Create CoreSimulator.log
touch ~/Library/Logs/CoreSimulator/CoreSimulator.log || true

######################################
# CI Helpers
######################################

install_dependencies() {
    echo \">>> Installing dependencies for ${CI_WORKFLOW}\"
    ruby -v

    dependencies=\"moreutils \"

    if [[ \"$CI_WORKFLOW\" == \"docs\"* ]]; then
        gem install jazzy -v 0.14.3
    elif [[ \"$CI_WORKFLOW\" == \"swiftlint\"* ]]; then
        dependencies=\" ${dependencies}swiftlint\"
    elif [[ \"$CI_WORKFLOW\" == \"cocoapods\"* ]]; then
        dependencies=\" ${dependencies}cocoapods\"
    fi

    gem install xcpretty -v 0.3.0

    echo \">>> brew install $dependencies\"
    if [ ! \"$dependencies\" = \"\" ]; then
        brew install ${dependencies}
    fi
}

install_ruby() {
    # Ruby Installation
    echo \">>> Installing new Version of ruby\"
    brew install ruby
    echo 'export PATH=\"/usr/local/opt/ruby/bin:$PATH\"' >> ~/.bash_profile
    source ~/.bash_profile

    echo 'export GEM_HOME=$HOME/gems' >>~/.bash_profile
    echo 'export PATH=$HOME/gems/bin:$PATH' >>~/.bash_profile
    export GEM_HOME=$HOME/gems
    export PATH=\"$GEM_HOME/bin:$PATH\"
    ruby -v
}

: '
xcode_version:#{XCODE_VERSIONS.map { |v| "\n - #{v}" }.join()}
target:#{targets.map { |k, v| "\n - #{k}" }.join()}
configuration:
 - N/A
'

# Dependencies
install_ruby
install_dependencies

# CI Workflows
cd ..
"""

targets.each_with_index { |(name, filter), index|
  XCODE_VERSIONS.each { |version|
    if filter.call(version)
      output_file << """
: '
- xcode_version: #{version}
- target: #{name}
'
"""
      if index == 0
          output_file << "if [ \"$CI_WORKFLOW\" = \"#{name}_#{version}\" ]; then\n"
      else
          output_file << "elif [ \"$CI_WORKFLOW\" = \"#{name}_#{version}\" ]; then\n"
      end
      output_file << "     export target=\"#{name}\"\n"
      output_file << "     sh -x build.sh ci-pr | ts\n"

      if index == targets.size - 1
          output_file << "\nelif [ \"$CI_WORKFLOW\" = \"Realm-Latest\" ] || [ \"$CI_WORKFLOW\" = \"RealmSwift-Latest\" ]; then\n"
          output_file << "     echo \"CI workflows for testing latest XCode releases\"\n"
          output_file << "\nelse\n"
          output_file << "     set +e\n"
          output_file << "     exit 1\n"
          output_file << "fi\n"
      end
    end
  }
}

File.open('ci_scripts/ci_post_clone.sh', "w") do |file|
  file.puts output_file
end
