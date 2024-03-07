Check https://developer.apple.com/documentation/xcode-release-notes to see new Xcode releases
 and https://developer.apple.com/xcode-cloud/release-notes/ for Xcode cloud release notes. Xcode cloud doesn't
 update Xcode versions immediately after release, this may take from a few a hours to some days.

# Update Xcode cloud workflow's Xcode version(s)

## https://github.com/realm/realm-swift

1. Update `pr-ci-matrix.rb`. Add or remove version(s) from XCODE_VERSIONS.
2. Run `ruby ./scripts/xcode_cloud_helper.rb -t {APP_STORE_CONNECT_TOKEN} synchronize-workflows` and select `create` if you want just to create new workflows, `delete` to remove unused workflows and `both` if you want both create and clean.
2. You can also run the `update-xcode-cloud-workflows` Github action manually for step 2.
3. Enable manually the new created workflows.
4. If needed, add environment values to the newly created workflows.
5. Update version(s) from xcode_versions in `scripts/package-examples.rb`.
6. Update XCODE_VERSION in `.github/workflows/master-push.yml` and `.github/workflows/publish-release.yml` and check if DOC_VERSION, RELEASE_VERSION and TEST_VERSION needs to be updated.
7. Search for `#if swift` and see if there's any we can remove.
8. Update the Carthage version in CHANGELOG.md (and add a changelog entry).
9. If there's new project settings migrations, open each of the Xcode projects and apply/skip them as applicable. Note that we generally do *not* want to use the Swift version migrations as we support multiple Swift versions at once.

## Notes

* New workflows which includes an environment value should update the environment values manually, e.g. targets
  with server test. `App Store Connect API` doesn't have allow to set environment values for workflows in the 
  current API.
