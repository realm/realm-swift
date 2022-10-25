#!/bin/sh

######################################
# Dependency Installer
######################################

JAZZY_VERSION="0.14.4"
RUBY_VERSION="3.1.2"
XCPRETTY_VERSION="0.3.0"
COCOAPODS_VERSION="1.14.2"

install_dependencies() {
    echo ">>> Installing dependencies for ${CI_WORKFLOW}"

    brew install moreutils

    if [[ "$CI_WORKFLOW" == "docs"* ]]; then
        install_ruby
        gem install jazzy -v ${JAZZY_VERSION}
    elif [[ "$CI_WORKFLOW" == "swiftlint"* ]]; then
        brew install swiftlint
    elif [[ "$CI_WORKFLOW" == "cocoapods"* ]]; then
        install_ruby
        gem install cocoapods -v ${COCOAPODS_VERSION}
    elif [[ "$$CI_WORKFLOW" = *"xcode"* ]] || [[ "$target" = "xcframework"* ]]; then
        install_ruby
    fi
}

install_ruby() {
    # Ruby Installation
    echo ">>> Installing new Version of ruby"
    brew install rbenv ruby-build
    rbenv install ${RUBY_VERSION}
    rbenv global ${RUBY_VERSION}
    echo 'export PATH=$HOME/.rbenv/bin:$PATH' >>~/.bash_profile
    eval "$(rbenv init -)"
}

update_scheme_configuration() {
    local target="$1"
    configuration="Release"
    case "$target" in
        *-debug)
            configuration="Debug"
            ;;
        *-static)
            configuration="Static"
            ;;
    esac

    schemes=("RealmSwift" "Realm" "Object Server Tests" "SwiftUITestHost" "SwiftUISyncTestHost")
    for ((i = 0; i < ${#schemes[@]}; i++)) do
        filename="Realm.xcodeproj/xcshareddata/xcschemes/${schemes[$i]}.xcscheme"
        sed -i '' "s/buildConfiguration = \"Debug\"/buildConfiguration = \"$configuration\"/" "$filename"
    done
}

set -o pipefail

# Set the -e flag to stop running the script in case a command returns
# a non-zero exit code.
set -e

# Print env
env

# Setup environment
echo 'export GEM_HOME=$HOME/gems' >>~/.bash_profile
echo 'export PATH=$HOME/gems/bin:$PATH' >>~/.bash_profile
export GEM_HOME=$HOME/gems
export PATH="$GEM_HOME/bin:$PATH"

# Dependencies
install_dependencies

# CI Workflows
cd ..

# Get target name
TARGET=$(echo "$CI_WORKFLOW" | cut -f1 -d_)

# Update schemes configuration
update_scheme_configuration ${TARGET}

export target="${TARGET}"
sh -x build.sh ci-pr | ts