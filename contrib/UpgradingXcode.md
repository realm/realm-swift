Follow https://twitter.com/xcodereleases to get notified of new Xcode releases since Apple doesn't provide anything.

# Removing old Xcode versions

We can only fit ~6 Xcode versions in the VM image before the machine which builds the VM images runs out of space (note: make sure we get more disk space when we finally upgrade the machines). This typically means that each version added also requires removing a version. Check Mixpanel to determine which version is the least used of the current set; it's often not the oldest version.

## https://github.com/realm/bootstrap_osx_ci

1. Remove the version to be removed from config.rb
2. If removing the oldest version, update `pkgs/xcodes_postinstall/files/xcodes_postinstall.rb` to make the Xcode-10.app symlink point at the new oldest version

## realm-core, realm-sync, realm-js

Each of these repositories points at a specific major version of Xcode in their Jenkinsfile, which needs to be updated when dropping a major version. Dropping minor versions should not require any changes to them.

## https://github.com/realm/realm-swift

1. Update `Jenkinsfile.releasability`. Remove the version from xcodeVersions. If removing the version objcXcodeVersion is set to, bump that to the new oldest version.
2. Remove the old Xcode version from XCODE_VERSIONS `scripts/ci-pr-matrix.rb`. Run `scripts/ci-pr-matrix.rb` to regenerate `.jenkins.yml`.
3. Remove the old version from xcode_versions in `scripts/package-examples.rb`.
4. Search for `#if swift` and see if there's any we can remove.
5. Update the Carthage version in CHANGELOG.md and build.sh (and add a changelog entry)
6. If there's new project settings migrations, open each of the Xcode projects and apply/skip them as applicable. Note that we generally do *not* want to use the Swift version migrations as we support multiple Swift versions at once.

# Adding new Xcode versions

Download the new Xcode version locally and try to build/run all of the realm-swift tests. Fix anything that doesn't work or produces new warnings. Some things to check:

1. `sh build.sh build`: builds fat frameworks for each platform
2. `sh build.sh test`: runs the tests on each platform
3. `sh build.sh test-swiftpm`: tests SPM package
4. `sh build.sh verify-docs`: tests building the docs and that everything is documented

## https://github.com/realm/bootstrap_osx_ci

1. Make sure the new version is available at https://developer.apple.com/download/more/. This typically happens a few hours after it hits the app store.
2. Add the new Xcode version to config.rb.
3. Push to a new branch.

## https://github.com/realm/realm-swift

1. Update `Jenkinsfile.releasability`. Add the version to xcodeVersions and update carthageXcodeVersion. Do not bump objcXcodeVersion; that should always be the oldest version we support. docsSwiftVersion should normally be the latest swift (not Xcode!) version we support.
2. Add the new version to XCODE_VERSIONS in `scripts/ci-pr-matrix.rb`. Run `scripts/ci-pr-matrix.rb` to regenerate `.jenkins.yml`.
3. Add the new version to xcode_versions in `scripts/package-examples.rb`.
4. Make a PR for your branch
5. Once the PR is passing, run `https://ci.realm.io/job/cocoa-pipeline/build` on your branch to make sure the release packages build

# Building and deploying the CI worker image

1. Screenshare into lv_host4.realm.io. This requires connecting to the MacStadium VPN.
2. A HTTP server process should be running in a terminal window. Exit the server.
3. Close VMWare if it's running.
4. `rm -r ~/Library/Caches/RealmCI/BuildImages/`
5. `rm -r ~/VMs`
6. Restart lv_host4 (via the gui and not the command line; the machine doesn't automatically start back up following `reboot` or `shutdown -r`)
7. Check out your branch with changes
8. Run "rake buildhost:build_image[`git rev-parse HEAD`]" to build the VM image. This takes 1-12 hours depending on how much has to be rebuilt.
9. Run `rake buildhost:serve` to deploy the built image to the worker machines. This typically takes 2-3 hours.

This whole process is supposed to be fully automated, but the automation doesn't work because the VM images are too big relative to the amount of disk space lv_host4 has. Once we move the CI setup to new machines with more disk space we will hopefully be able to re-enable the automatic build queue.
