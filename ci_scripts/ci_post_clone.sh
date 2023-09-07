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

    if [[ "$CI_WORKFLOW" == "docs"* ]]; then
        gem install jazzy -v 0.14.3
    elif [[ "$CI_WORKFLOW" == "swiftlint"* ]]; then
        brew install swiftlint
    elif [[ "$CI_WORKFLOW" == "cocoapods"* ]]; then
        brew install cocoapods
    fi

    gem install xcpretty -v 0.3.0
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

# Dependencies
install_ruby
install_dependencies

# CI Workflows
cd ..

export target=$(echo "$CI_WORKFLOW" | cut -f1 -d_)
sh -x build.sh ci-pr | ts
