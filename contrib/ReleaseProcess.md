## Releasing from master

Follow these steps to release a new version of the Realm Cocoa SDK.

1. Open the [cocoa-pipeline](https://ci.realm.io/job/cocoa-pipeline/) job in Jenkins and cancel any existing jobs running (optional, but it takes a while).
2. Update the version number and set the release date in the changelog: `sh build.sh set-version X.Y.Z`
3. Take another look over `CHANGELOG.md` to make sure it looks sensible. Delete any remaining placeholders for things which didn't happen in this release (e.g. the breaking changes section).
4. Commit and push to `master`. This automatically kicks off a build that current takes around 2 hours.
5. Once the [cocoa-pipeline](https://ci.realm.io/job/cocoa-pipeline/) job completes, run the [release-cocoa](https://ci.realm.io/job/release-cocoa/) job to publish the release. This tags the version, creates a release on github, pushes to CocoaPods, and updates the website, and then runs another set of tests to validate that the published release can be installed. This process takes 2-3 hours.
6. Copy and paste the release notes from the Github release into a slack post in the `#realm-releases` channel.
7. Run `sh build.sh add-empty-changelog`, commit the result, and push to `master`.

## Releasing alpha/beta version from other branches

Follow these steps when we have long-lived branches that we are making alpha/beta releases from.

1. Update the version number and set the release date in the changelog: `sh build.sh set-version X.Y.Z-alpha.w`. Note that the presence of `alpha` or `beta` in the version number is semantically significant and makes the release job not mark the version as the latest release on the web site.
2. Take another look over `CHANGELOG.md` to make sure it looks sensible. Delete any remaining placeholders for things which didn't happen in this release (e.g. the breaking changes section).
3. Commit and push to the branch.
4. Run the [cocoa-pipeline](https://ci.realm.io/job/cocoa-pipeline/) job targeting your branch (it only automatically runs for pushes to `master`).
5. Run the [release-cocoa](https://ci.realm.io/job/release-cocoa/) job to publish the release. This tags the version, creates a release on github, pushes to CocoaPods, and updates the website, and then runs another set of tests to validate that the published release can be installed. This process takes 2-3 hours.
6. Copy and paste the release notes from the Github release into a slack post in the `#realm-releases` channel.
7. Run `sh build.sh add-empty-changelog`, commit the result, and push to the branch.

## Releasing a backported fix

Follow these steps when there are changes in `master` that shouldn't be included in the release.

1. Check out the base release which is being hotfixed (e.g. `git checkout v0.96.0`).
2. Run `sh build.sh add-empty-changelog`and  commit the result.
3. Cherry-pick the commit(s) you want to include in the release.
4. Move the changelog entries from the cherry-picked commit(s) to the section for the version being released (they are likely to end up in the wrong place from the automatic merge).
5. Set version: `sh build.sh set-version X.Y.Z`
6. Push to a new branch of the format `release/0.96.1` or similar.
7. Open a draft PR for the release branch to run the PR CI job on it.
8. Once the PR job passes, run [cocoa-pipeline](https://ci.realm.io/job/cocoa-pipeline/) passing in your branch's name as a parameter
8. If the `cocoa-pipeline` job passes, run the [release-cocoa](https://ci.realm.io/job/release-cocoa/) job on Jenkins passing in your branch name as a parameter and confirm that it succeeded
9. Copy and paste the release notes from the Github release into a slack post in the `#realm-releases` channel.
10. Close the draft PR for the release branch without merging it.
