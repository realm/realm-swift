#!/bin/bash

set -eo pipefail

######################################
# Dependency Installer
######################################

USE_BUNDLE_EXEC=''
install_dependencies() {
    echo ">>> Installing dependencies for ${CI_WORKFLOW}"

    if [[ "$CI_WORKFLOW" == "docs"* ]]; then
        install_ruby
    elif [[ "$CI_WORKFLOW" == "swiftlint"* ]]; then
        brew install swiftlint
    elif [[ "$CI_WORKFLOW" == "cocoapods"* ]]; then
        install_ruby
    elif [[ "$CI_WORKFLOW" == "sync"* ]]; then
    # elif [[ "$CI_WORKFLOW" == "sync"* ]] || [[ "$CI_WORKFLOW" == "swiftpm"* ]]; then
        sh build.sh setup-baas
        sh build.sh download-core
    elif [[ "$CI_WORKFLOW" = *"spm"* ]] || [[ "$CI_WORKFLOW" = "xcframework"* ]]; then
        install_ruby
    elif [[ "$CI_WORKFLOW" == *"carthage"* ]]; then
        brew install carthage
    else
        sh build.sh download-core
    fi
}

install_ruby() {
    echo ">>> Installing new Version of ruby"
    brew install rbenv ruby-build
    rbenv install
    eval "$(rbenv init -)"
    bundle install
    USE_BUNDLE_EXEC=true
}

env

cd "$(dirname "$0")"/..
install_dependencies

# Xcode Cloud doesn't let us set the configuration to build, so set it by
# modifying the scheme files
target=$(echo "$CI_WORKFLOW" | cut -f1 -d_)
configuration="Release"
case "$target" in
    *-debug) configuration="Debug" ;;
    *-static) configuration="Static" ;;
esac

find Realm.xcodeproj -name '*.xcscheme' \
    -exec sed -i '' "s/buildConfiguration = \"Debug\"/buildConfiguration = \"$configuration\"/" {} \;

# If testing library evolution mode, patch the config to enable it
if [[ "$target" == *-evolution ]]; then
    filename='Configuration/RealmSwift/RealmSwift.xcconfig'
    sed -i '' "s/REALM_BUILD_LIBRARY_FOR_DISTRIBUTION = NO;/REALM_BUILD_LIBRARY_FOR_DISTRIBUTION = YES;/" "$filename"
fi

# If testing encryption, patch the scheme to enable it
if [[ "$target" == *-encryption ]]; then
    filename='Realm.xcodeproj/xcshareddata/xcschemes/Realm.xcscheme'
    xmllint --shell "$filename" << EOF
        cd /Scheme/LaunchAction/EnvironmentVariables/EnvironmentVariable[@key='REALM_ENCRYPT_ALL']/@isEnabled
        set YES
        save
EOF
fi

# In release we are creating some workflows which build the framework for each platform, target and configuration, 
# and we need to set the linker flags in the Configuration file.
if [[ "$target" == "release-package-build-"* ]]; then
    filename="Configuration/Release.xcconfig"
    sed -i '' "s/REALM_HIDE_SYMBOLS = NO;/REALM_HIDE_SYMBOLS = YES;/" "$filename"
fi

# Xcode cloud currently doesn't have visionOS installed for Xcode 15.3
if [[ "$CI_WORKFLOW" == release-package-build-vision*_15.3 ]]; then
    xcodebuild -downloadAllPlatforms
fi

# If we're building the dummy CI target then run the test. Other schemes are
# built via Xcode cloud's xcodebuild invocation. We can't do this via a build
# step on the CI target as that results in nested invocations of xcodebuild,
# which doesn't work.
if [[ "$CI_XCODE_SCHEME" == CI ]]; then
    if [[ -n "$USE_BUNDLE_EXEC" ]]; then
        bundle exec sh build.sh ci-pr
    else
        sh build.sh ci-pr
    fi
fi
