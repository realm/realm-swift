# XCode Cloud workflows update.

## Update Xcode versions and/or targets.

Follow these steps to automatically create new XCode cloud workflows for any new target and/or XCode version.

1. Add the new target to the [PR-CI Matrix](./scripts/pr-ci-matrix.rb)! target's list. If no new target is added 
   skip to step 3.
2. Add one of the following options (`all`, `latest_only` or `oldest_and_latest`) to the added target, this will be
   dependable of which versions do you want to run your new workflow. The list of XCode versions available are in the same file, in `XCODE_VERSIONS`.
3. Update the XCode version list `XCODE_VERSIONS` if needed in [PR-CI Matrix](./scripts/pr-ci-matrix.rb)!.
3. Create a new PR with the targets and XCode versions changes.
4. Run manually the Github action `Update XCode Cloud Workflows` from the Github actions UI targeting the branch   
   from the PR. 
   https://github.com/realm/realm-swift/actions/workflows/update-xcode-cloud-workflows.yml
5. Each new workflow created should return an url which should be used to enable each of the new workflows. Current 
   API doesn't add this created workflows to the product until this manual step is executed.
6. After the workflows are created, merge this branch to `master`.

## Clear unused workflows.

Follow these steps to clear unused workflows, meaning current remote workflows which are not included in the
`pr-ci-matrix.rb` file.

1. Create a new PR with the targets and XCode versions changes, if `master` is already updated, please 
   skip this step.
4. Run manually the Github action `Clear XCode Cloud Workflows` from the Github actions UI targeting the PR's 
   branch or `master` if not branch is created.
   https://github.com/realm/realm-swift/actions/workflows/clear-unused-xcode-cloud-workflows.yml
5. After the workflows are created, merge this branch to `master` if needed.

## Notes

* Clear unused workflows only after the PR with the targets and Xcode versions changes is merged to `master`.
* New workflows which includes an environment value should update the environment values manually, e.g. targets
  with server test. `App Store Connect API` doesn't have allow to set environment values for workflows in the current
  API.
