## Releasing from master

Follow these steps to release a new version of the Realm Swift SDK.

1. Open Github actions [Prepare-release](https://github.com/realm/realm-swift/actions/workflows/master-push.yml) page and cancel any workflow runs. This is not mandatory.
2. Update the version number and set the release date in the changelog: `sh build.sh set-version X.Y.Z`
3. Take another look over `CHANGELOG.md` to make sure it looks sensible. Delete any remaining placeholders for things which didn't happen in this release (e.g. the breaking changes section).
4. Commit and push to `master`. This automatically kicks off a build that current takes around 1 hours.
5. Once the [Prepare-release](https://github.com/realm/realm-swift/actions/workflows/master-push.yml) job completes, run the [Publish-release](https://github.com/realm/realm-swift/actions/workflows/publish-release.yml) workflow manually to publish the release. This tags the version, creates a release on github, pushes to CocoaPods, and updates the website, and then runs another set of tests to validate that the published release can be installed. This process takes 1-2 hours.

## Releasing alpha/beta/preview/rc version from other branches

Follow these steps when we have long-lived branches that we are making alpha/beta releases from.

1. Update the version number and set the release date in the changelog: `sh build.sh set-version X.Y.Z-preview`. Note that the presence of `alpha`, `beta`, `preview` or `rc` in the version number is semantically significant and makes the release job not mark the version as the latest release on the web site.
2. Take another look over `CHANGELOG.md` to make sure it looks sensible. Delete any remaining placeholders for things which didn't happen in this release (e.g. the breaking changes section).
3. Commit and push to the branch.
4. Run the [Prepare-release](https://github.com/realm/realm-swift/actions/workflows/master-push.yml) workflow manually using the desired branch (it only automatically runs for pushes to `master`).
5. Run the [Publish-release](https://github.com/realm/realm-swift/actions/workflows/publish-release.yml) job to publish the release, selecting the desired branch. This tags the version, creates a release on github, pushes to CocoaPods, and updates the website, and then runs another set of tests to validate that the published release can be installed. This process takes 1-2 hours.

## Releasing a backported fix

Follow these steps when there are changes in `master` that shouldn't be included in the release.

1. Check out the base release which is being hotfixed (e.g. `git checkout v0.96.0`).
2. Run `sh build.sh add-empty-changelog`and  commit the result.
3. Cherry-pick the commit(s) you want to include in the release.
4. Move the changelog entries from the cherry-picked commit(s) to the section for the version being released (they are likely to end up in the wrong place from the automatic merge).
5. Set version: `sh build.sh set-version X.Y.Z`
6. Push to a new branch of the format `release/0.96.1` or similar.
7. Open a draft PR for the release branch to run the PR CI job on it.
8. Once the PR job passes, run [Prepare-release](https://github.com/realm/realm-swift/actions/workflows/master-push.yml) workflow for the release branch.
8. Run the [release-cocoa](https://ci.realm.io/job/release-cocoa/) job selecting your branch branch name as a parameter and confirm that it succeeded.
10. Close the draft PR for the release branch without merging it.
