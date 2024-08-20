#!/bin/bash

set -eo pipefail

cd "$(dirname "$0")"/..
USE_BUNDLE_EXEC=''
case "$CI_WORKFLOW" in
    docs* | cocoapods* | *spm* | xcframework*)
        brew install rbenv ruby-build
        rbenv install
        eval "$(rbenv init -)"
        bundle install
        USE_BUNDLE_EXEC=true
        ;;
    swiftlint*)
        brew install swiftlint
        ;;
    carthage*)
        brew install carthage
        ;;
    swiftpm*)
        sh build.sh download-core
        sh build.sh setup-baas
        ;;
    *)
        sh build.sh download-core
        ;;
esac

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

if [[ "$target" == "release-package-build-"* ]]; then
    filename="Configuration/Release.xcconfig"
    sed -i '' "s/REALM_HIDE_SYMBOLS = NO;/REALM_HIDE_SYMBOLS = YES;/" "$filename"
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
