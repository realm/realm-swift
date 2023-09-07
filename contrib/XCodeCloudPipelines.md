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

## Creating/Modifying a pipeline or update Xcode versions.

Follow these steps to add a new pipeline to XCode Cloud, and/or update the Xcode versions for one or several pipelines.

1. Add the new pipeline to the [PR-CI Matrix](./scripts/pr-ci-matrix.rb)! list of available targets.
2. Add one of the following options (`all`, `latest_only` or `oldest_and_latest`) to the added target, this will dependable
   of which version do you want to run your new workflow. The list of XCode versions available are in the same file 
   in `XCODE_VERSIONS`.
3. Run the following command from the project root `ruby scripts/pr-ci-matrix.rb` to generate the data on the
   [CI_POST_CLONE](./ci_scripts/ci_post_clone.sh) file.
4. Run the ruby command `ruby scripts/xcode_cloud_helper.rb -create-new` for creating the new added pipelines to 
   XCode cloud. This will print, in the console, a link to each of the newly created workflows.
5. Before pushing the changes which will use this new workflows, navigate to each workflow created and enable each
   of them for use.

## Clear unused workflows.

Follow these steps to clear unused workflows, meaning current remote workflows which are not included in the
`pr-ci-matrix.rb` file.

1. Run the ruby command `ruby scripts/xcode_cloud_helper.rb -clear-unused`, this will delete the workflows corresponding
to the targets and Xcode version which are not included in the `pr-ci-matrix`.

## Notes

* Have in mind, that while this new workflows may pass in your current PR, others PRs may run this workflows without
  `ci_post_clone.sh` updated, this will cause this workflows to fail.
* Clear unused workflows only after the PR with the targets and Xcode versions changes is merged.
