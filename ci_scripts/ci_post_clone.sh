#!/bin/sh
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
    echo ">>> Installing dependencies for ${CI_WORKFLOW}"
    ruby -v

    dependencies="moreutils "

    if [[ "$CI_WORKFLOW" == "docs"* ]]; then
        gem install jazzy -v 0.14.3
    elif [[ "$CI_WORKFLOW" == "swiftlint"* ]]; then
        dependencies=" ${dependencies}swiftlint"
    elif [[ "$CI_WORKFLOW" == "cocoapods"* ]]; then
        dependencies=" ${dependencies}cocoapods"
    fi

    gem install xcpretty -v 0.3.0

    echo ">>> brew install $dependencies"
    if [ ! "$dependencies" = "" ]; then
        brew install ${dependencies}
    fi
}

install_ruby() {
    # Ruby Installation
    echo ">>> Installing new Version of ruby"
    brew install ruby
    echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.bash_profile
    source ~/.bash_profile

    echo 'export GEM_HOME=$HOME/gems' >>~/.bash_profile
    echo 'export PATH=$HOME/gems/bin:$PATH' >>~/.bash_profile
    export GEM_HOME=$HOME/gems
    export PATH="$GEM_HOME/bin:$PATH"
    ruby -v
}

: '
xcode_version:
 - 14.1
 - 14.2
 - 14.3.1
target:
 - docs
 - swiftlint
 - osx
 - osx-encryption
 - osx-object-server
 - swiftpm
 - swiftpm-debug
 - swiftpm-address
 - swiftpm-thread
 - ios-xcode-spm
 - ios-static
 - ios
 - watchos
 - tvos
 - osx-swift
 - ios-swift
 - tvos-swift
 - osx-swift-evolution
 - ios-swift-evolution
 - tvos-swift-evolution
 - catalyst
 - catalyst-swift
 - xcframework
 - cocoapods-osx
 - cocoapods-ios-static
 - cocoapods-ios
 - cocoapods-watchos
 - cocoapods-tvos
 - cocoapods-catalyst
 - swiftui-ios
 - swiftui-server-osx
configuration:
 - N/A
'

# Dependencies
install_ruby
install_dependencies

# CI Workflows
cd ..

: '
- xcode_version: 14.3.1
- target: docs
'
if [ "$CI_WORKFLOW" = "docs_14.3.1" ]; then
     export target="docs"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: swiftlint
'
elif [ "$CI_WORKFLOW" = "swiftlint_14.3.1" ]; then
     export target="swiftlint"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: osx
'
elif [ "$CI_WORKFLOW" = "osx_14.1" ]; then
     export target="osx"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.2
- target: osx
'
elif [ "$CI_WORKFLOW" = "osx_14.2" ]; then
     export target="osx"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: osx
'
elif [ "$CI_WORKFLOW" = "osx_14.3.1" ]; then
     export target="osx"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: osx-encryption
'
elif [ "$CI_WORKFLOW" = "osx-encryption_14.3.1" ]; then
     export target="osx-encryption"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: osx-object-server
'
elif [ "$CI_WORKFLOW" = "osx-object-server_14.1" ]; then
     export target="osx-object-server"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: osx-object-server
'
elif [ "$CI_WORKFLOW" = "osx-object-server_14.3.1" ]; then
     export target="osx-object-server"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: swiftpm
'
elif [ "$CI_WORKFLOW" = "swiftpm_14.1" ]; then
     export target="swiftpm"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: swiftpm
'
elif [ "$CI_WORKFLOW" = "swiftpm_14.3.1" ]; then
     export target="swiftpm"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: swiftpm-debug
'
elif [ "$CI_WORKFLOW" = "swiftpm-debug_14.1" ]; then
     export target="swiftpm-debug"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.2
- target: swiftpm-debug
'
elif [ "$CI_WORKFLOW" = "swiftpm-debug_14.2" ]; then
     export target="swiftpm-debug"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: swiftpm-debug
'
elif [ "$CI_WORKFLOW" = "swiftpm-debug_14.3.1" ]; then
     export target="swiftpm-debug"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: swiftpm-address
'
elif [ "$CI_WORKFLOW" = "swiftpm-address_14.3.1" ]; then
     export target="swiftpm-address"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: swiftpm-thread
'
elif [ "$CI_WORKFLOW" = "swiftpm-thread_14.3.1" ]; then
     export target="swiftpm-thread"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: ios-xcode-spm
'
elif [ "$CI_WORKFLOW" = "ios-xcode-spm_14.1" ]; then
     export target="ios-xcode-spm"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.2
- target: ios-xcode-spm
'
elif [ "$CI_WORKFLOW" = "ios-xcode-spm_14.2" ]; then
     export target="ios-xcode-spm"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: ios-xcode-spm
'
elif [ "$CI_WORKFLOW" = "ios-xcode-spm_14.3.1" ]; then
     export target="ios-xcode-spm"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: ios-static
'
elif [ "$CI_WORKFLOW" = "ios-static_14.1" ]; then
     export target="ios-static"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: ios-static
'
elif [ "$CI_WORKFLOW" = "ios-static_14.3.1" ]; then
     export target="ios-static"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: ios
'
elif [ "$CI_WORKFLOW" = "ios_14.1" ]; then
     export target="ios"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: ios
'
elif [ "$CI_WORKFLOW" = "ios_14.3.1" ]; then
     export target="ios"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: watchos
'
elif [ "$CI_WORKFLOW" = "watchos_14.1" ]; then
     export target="watchos"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: watchos
'
elif [ "$CI_WORKFLOW" = "watchos_14.3.1" ]; then
     export target="watchos"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: tvos
'
elif [ "$CI_WORKFLOW" = "tvos_14.1" ]; then
     export target="tvos"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: tvos
'
elif [ "$CI_WORKFLOW" = "tvos_14.3.1" ]; then
     export target="tvos"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: osx-swift
'
elif [ "$CI_WORKFLOW" = "osx-swift_14.1" ]; then
     export target="osx-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.2
- target: osx-swift
'
elif [ "$CI_WORKFLOW" = "osx-swift_14.2" ]; then
     export target="osx-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: osx-swift
'
elif [ "$CI_WORKFLOW" = "osx-swift_14.3.1" ]; then
     export target="osx-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: ios-swift
'
elif [ "$CI_WORKFLOW" = "ios-swift_14.1" ]; then
     export target="ios-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: ios-swift
'
elif [ "$CI_WORKFLOW" = "ios-swift_14.3.1" ]; then
     export target="ios-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: tvos-swift
'
elif [ "$CI_WORKFLOW" = "tvos-swift_14.1" ]; then
     export target="tvos-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: tvos-swift
'
elif [ "$CI_WORKFLOW" = "tvos-swift_14.3.1" ]; then
     export target="tvos-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: osx-swift-evolution
'
elif [ "$CI_WORKFLOW" = "osx-swift-evolution_14.3.1" ]; then
     export target="osx-swift-evolution"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: ios-swift-evolution
'
elif [ "$CI_WORKFLOW" = "ios-swift-evolution_14.3.1" ]; then
     export target="ios-swift-evolution"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: tvos-swift-evolution
'
elif [ "$CI_WORKFLOW" = "tvos-swift-evolution_14.3.1" ]; then
     export target="tvos-swift-evolution"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: catalyst
'
elif [ "$CI_WORKFLOW" = "catalyst_14.1" ]; then
     export target="catalyst"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: catalyst
'
elif [ "$CI_WORKFLOW" = "catalyst_14.3.1" ]; then
     export target="catalyst"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: catalyst-swift
'
elif [ "$CI_WORKFLOW" = "catalyst-swift_14.1" ]; then
     export target="catalyst-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: catalyst-swift
'
elif [ "$CI_WORKFLOW" = "catalyst-swift_14.3.1" ]; then
     export target="catalyst-swift"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: xcframework
'
elif [ "$CI_WORKFLOW" = "xcframework_14.3.1" ]; then
     export target="xcframework"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.1
- target: cocoapods-osx
'
elif [ "$CI_WORKFLOW" = "cocoapods-osx_14.1" ]; then
     export target="cocoapods-osx"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.2
- target: cocoapods-osx
'
elif [ "$CI_WORKFLOW" = "cocoapods-osx_14.2" ]; then
     export target="cocoapods-osx"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: cocoapods-osx
'
elif [ "$CI_WORKFLOW" = "cocoapods-osx_14.3.1" ]; then
     export target="cocoapods-osx"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: cocoapods-ios-static
'
elif [ "$CI_WORKFLOW" = "cocoapods-ios-static_14.3.1" ]; then
     export target="cocoapods-ios-static"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: cocoapods-ios
'
elif [ "$CI_WORKFLOW" = "cocoapods-ios_14.3.1" ]; then
     export target="cocoapods-ios"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: cocoapods-watchos
'
elif [ "$CI_WORKFLOW" = "cocoapods-watchos_14.3.1" ]; then
     export target="cocoapods-watchos"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: cocoapods-tvos
'
elif [ "$CI_WORKFLOW" = "cocoapods-tvos_14.3.1" ]; then
     export target="cocoapods-tvos"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: cocoapods-catalyst
'
elif [ "$CI_WORKFLOW" = "cocoapods-catalyst_14.3.1" ]; then
     export target="cocoapods-catalyst"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: swiftui-ios
'
elif [ "$CI_WORKFLOW" = "swiftui-ios_14.3.1" ]; then
     export target="swiftui-ios"
     sh -x build.sh ci-pr | ts

: '
- xcode_version: 14.3.1
- target: swiftui-server-osx
'
elif [ "$CI_WORKFLOW" = "swiftui-server-osx_14.3.1" ]; then
     export target="swiftui-server-osx"
     sh -x build.sh ci-pr | ts

elif [ "$CI_WORKFLOW" = "Realm-Latest" ] || [ "$CI_WORKFLOW" = "RealmSwift-Latest" ]; then
     echo "CI workflows for testing latest XCode releases"

else
     set +e
     exit 1
fi
