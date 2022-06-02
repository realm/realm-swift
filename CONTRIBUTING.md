# Contributing

## Filing Issues

Whether you find a bug, typo or an API call that could be clarified, please [file an issue](https://github.com/realm/realm-swift/issues) on our GitHub repository.

When filing an issue, please provide as much of the following information as possible in order to help others fix it:

1. **Goals**
2. **Expected results**
3. **Actual results**
4. **Steps to reproduce**
5. **Code sample that highlights the issue** (full Xcode projects that we can compile ourselves are ideal)
6. **Version of Realm / Xcode / macOS**
7. **Version of involved dependency manager (CocoaPods / Carthage)**

If you'd like to send us sensitive sample code to help troubleshoot your issue, you can email <help-realm@mongodb.com> directly.

### Speeding things up :runner:

You may just copy this little script below and run it directly in your project directory in **Terminal.app**. It will take of compiling a list of relevant data as described in points 6. and 7. in the list above. It copies the list directly to your pasteboard for your convenience, so you can attach it easily when filing a new issue without having to worry about formatting and we may help you faster because we don't have to ask for particular details of your local setup first.

```shell
echo "\`\`\`
$(sw_vers)

$(xcode-select -p)
$(xcodebuild -version)

$(which pod && pod --version)
$(test -e Podfile.lock && cat Podfile.lock | sed -nE 's/^  - (Realm(Swift)? [^:]*):?/\1/p' || echo "(not in use here)")

$(which bash && bash -version | head -n1)

$(which carthage && carthage version)
$(test -e Cartfile.resolved && cat Cartfile.resolved | grep --color=no realm || echo "(not in use here)")

$(which git && git --version)
\`\`\`" | tee /dev/tty | pbcopy
```

## Contributing Enhancements

We love contributions to Realm! If you'd like to contribute code, documentation, or any other improvements, please [file a Pull Request](https://github.com/realm/realm-swift/pulls) on our GitHub repository. Make sure to accept our [CLA](#cla) and to follow our [style guide](https://github.com/realm/realm-swift/wiki/Objective-C-Style-Guide).

### Commit Messages

Although we don’t enforce a strict format for commit messages, we prefer that you follow the guidelines below, which are common among open source projects. Following these guidelines helps with the review process, searching commit logs and documentation of implementation details. At a high level, the contents of the commit message should convey the rationale of the change, without delving into much detail. For example, `setter names were not set right` leaves the reviewer wondering about which bits and why they weren’t “right”. In contrast, `[RLMProperty] Correctly capitalize setterName` conveys almost all there is to the change.

Below are some guidelines about the format of the commit message itself:

* Separate the commit message into a single-line title and a separate body that describes the change.
* Make the title concise to be easily read within a commit log.
* Make the body concise, while including the complete reasoning. Unless required to understand the change, additional code examples or other details should be left to the pull request.
* If the commit fixes a bug, include the number of the issue in the message.
* Use the first person present tense - for example "Fix …" instead of "Fixes …" or "Fixed …".
* For text formatting and spelling, follow the same rules as documentation and in-code comments — for example, the use of capitalization and periods.
* If the commit is a bug fix on top of another recently committed change, or a revert or reapply of a patch, include the Git revision number of the prior related commit, e.g. `Revert abcd3fg because it caused #1234`.

### CLA

Realm welcomes all contributions! The only requirement we have is that, like many other projects, we need to have a [Contributor License Agreement](https://en.wikipedia.org/wiki/Contributor_License_Agreement) (CLA) in place before we can accept any external code. Our own CLA is a modified version of the Apache Software Foundation’s CLA.

[Please submit your CLA electronically using our Google form](https://docs.google.com/forms/d/e/1FAIpQLSeQ9ROFaTu9pyrmPhXc-dEnLD84DbLuT_-tPNZDOL9J10tOKQ/viewform) so we can accept your submissions. The GitHub username you file there will need to match that of your Pull Requests. If you have any questions or cannot file the CLA electronically, you can email <realm-help@mongodb.com>.
