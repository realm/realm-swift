#!/bin/sh

set -o pipefail

# Set the -e flag to stop running the script in case a command returns
# a non-zero exit code.
set -e

# Print env
env

# Create CoreSimulator.log
touch ~/Library/Logs/CoreSimulator/CoreSimulator.log || true

# Setup environment
echo 'export GEM_HOME=$HOME/gems' >>~/.bash_profile
echo 'export PATH=$HOME/gems/bin:$PATH' >>~/.bash_profile
export GEM_HOME=$HOME/gems
export PATH="$GEM_HOME/bin:$PATH"

######################################
# Dependency Installer
######################################

JAZZY_VERSION="0.14.4"
RUBY_VERSION="3.1.2"
XCPRETTY_VERSION="0.3.0"

install_dependencies() {
    echo ">>> Installing dependencies for ${CI_WORKFLOW}"

    brew install moreutils

    if [[ "$CI_WORKFLOW" == "docs"* ]]; then
        install_ruby
        gem install activesupport -v 7.0.8 # Workaround until this is fixed https://github.com/realm/jazzy/issues/1370
        gem install jazzy -v ${JAZZY_VERSION}
    elif [[ "$CI_WORKFLOW" == "swiftlint"* ]]; then
        brew install swiftlint
    elif [[ "$CI_WORKFLOW" == "cocoapods"* ]]; then
        install_ruby
        brew install cocoapods
    elif [[ "$$CI_WORKFLOW" = *"xcode"* ]] || [[ "$target" = "xcframework"* ]]; then
        install_ruby
    fi

    gem install xcpretty -v ${XCPRETTY_VERSION}
    echo ">>> Using ruby version $(ruby -v)"
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

# Dependencies
install_dependencies

# CI Workflows
cd ..

export target=$(echo "$CI_WORKFLOW" | cut -f1 -d_)
sh -x build.sh ci-pr | ts

# Print environment at the end of ci_post_clone.sh
env
