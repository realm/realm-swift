# Contributing

## Filing Issues

Whether you find a bug, typo or an API call that could be clarified, please [file an issue](https://github.com/realm/realm-cocoa/issues) on our GitHub repository.

When filing an issue, please provide as much of the following information as possible in order to help others fix it:

1. **Goals**
2. **Expected results**
3. **Actual results**
4. **Steps to reproduce**
5. **Code sample that highlights the issue** (full Xcode projects that we can compile ourselves are ideal)
6. **Version of Realm / Xcode / OSX**
7. **Version of involved dependency manager (CocoaPods / Carthage)**

If you'd like to send us sensitive sample code to help troubleshoot your issue, you can email <help@realm.io> directly.

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

We love contributions to Realm! If you'd like to contribute code, documentation, or any other improvements, please [file a Pull Request](https://github.com/realm/realm-cocoa/pulls) on our GitHub repository. Make sure to accept our [CLA](#CLA) and to follow our [style guide](https://github.com/realm/realm-cocoa/wiki/Objective-C-Style-Guide).

### CLA

Realm welcomes all contributions! The only requirement we have is that, like many other projects, we need to have a [Contributor License Agreement](https://en.wikipedia.org/wiki/Contributor_License_Agreement) (CLA) in place before we can accept any external code. Our own CLA is a modified version of the Apache Software Foundation’s CLA.

[Please submit your CLA electronically using our Google form](https://docs.google.com/forms/d/1bVp-Wp5nmNFz9Nx-ngTmYBVWVdwTyKj4T0WtfVm0Ozs/viewform?fbzx=4154977190905366979) so we can accept your submissions. The GitHub username you file there will need to match that of your Pull Requests. If you have any questions or cannot file the CLA electronically, you can email <help@realm.io>.
