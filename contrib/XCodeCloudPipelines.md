## Creating a new pipeline in XCode Cloud manually.

Follow these steps to add a new pipeline to XCode Cloud.

1. Add the new pipeline to the [PR-CI Matrix](./scripts/pr-ci-matrix.rb)! list of available targets.
2. Add one of the following options (`all`, `latest_only` or `oldest_and_latest`) to the added target, this will dependable
   of which version do you want to run your new workflow. The list of XCode versions available are in the same file 
   in `XCODE_VERSIONS`.
3. Run the following command from the project root `ruby scripts/pr-ci-matrix.rb` to generate the data on the
   [CI_POST_CLONE](./ci_scripts/ci_post_clone.sh) file.
4. Create the new workflow on the XCode Cloud App Store Connect dashboard (https://appstoreconnect.apple.com/teams/69a6de86-7f37-47e3-e053-5b8c7c11a4d1/frameworks/E9D174FA-8898-4C93-94F3-EDC79DF32471/workflows) or
   in XCode, navigating to the `Report Navigator` tab and `Cloud` sub-tab.
5. Create the desired workflow using this notation `<target>_<xcode_version>` as a reference for the name.
7. Select the desired Xcode version in the environment tab, and always choose the latest stable macOS version.
8. Add `Pull Request changes` as a start condition, and remove any other condition. 
8. Add a `Build` action to the workflow and select `CI` as the schema.
