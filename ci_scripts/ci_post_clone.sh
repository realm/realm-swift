#!/bin/bash

set -eo pipefail

######################################
# Dependency Installer
######################################

JAZZY_VERSION="0.14.4"
RUBY_VERSION="3.1.2"
COCOAPODS_VERSION="1.14.2"

install_dependencies() {
    echo ">>> Installing dependencies for ${CI_WORKFLOW}"

    if [[ "$CI_WORKFLOW" == "docs"* ]]; then
        install_ruby
        gem install jazzy -v ${JAZZY_VERSION} --no-document
    elif [[ "$CI_WORKFLOW" == "swiftlint"* ]]; then
        brew install swiftlint
    elif [[ "$CI_WORKFLOW" == "cocoapods"* ]]; then
        install_ruby
        gem install cocoapods -v ${COCOAPODS_VERSION} --no-document
    elif [[ "$CI_WORKFLOW" == "objectserver"* ]] || [[ "$target" == "swiftpm"* ]]; then
        sh build.sh setup-baas
        sh build.sh download-core
    elif [[ "$$CI_WORKFLOW" = *"xcode"* ]] || [[ "$target" = "xcframework"* ]]; then
        install_ruby
    else
        sh build.sh download-core
    fi
}

install_ruby() {
    echo ">>> Installing new Version of ruby"
    brew install rbenv ruby-build
    rbenv install ${RUBY_VERSION}
    rbenv global ${RUBY_VERSION}
    eval "$(rbenv init -)"
}

env

# Setup environment
export GEM_HOME="$HOME/gems"
export PATH="$GEM_HOME/bin:$PATH"

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

# If we're building the dummy CI target then run the test. Other schemes are
# built via Xcode cloud's xcodebuild invocation. We can't do this via a build
# step on the CI target as that results in nested invocations of xcodebuild,
# which doesn't work.
if [[ "$CI_XCODE_SCHEME" == CI ]]; then
    sh build.sh ci-pr
fi
