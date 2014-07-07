Objective-C
===========

This README file explains how to build and install the Realm
framework for Objective-C. **It assumes that the Realm core
library has already been installed.**

You can use CocoaPods to install the Realm Core library. In the
root folder of this repository you find the file `Podfile`. It points
to the latest version of the Realm Core library. To create an 
Xcode workspace and download the Realm Core library you must
run the following command:

    pod install


Prerequisites
-------------

Currently, the Objective-C binding is available only for iOS and OS X. 
The following is a suggestion of how to install the
prerequisites on Mac OS X 10.7, 10.8, and 10.9:

The build procedure uses Clang as the C/C++ compiler by default. It
needs at least Clang 3.0 which comes with Xcode 4.2. On OS X 10.9
(Mavericks) we recommend at least Xcode 5.0, since in some cases when
a previous version of OS X is upgraded to 10.9, you will be left with
a malfunctioning set of command line tools (in particular the `lipo`
command), and this is most easily fixed by upgrading to Xcode 5. Run
the following command in the command prompt to see if you have Xcode
installed, and, if so, what version it is:

    xcodebuild -version

The Xcode "Command Line Tools" are required to build the framework. 
If you have Xcode 5 on OS X 10.9 or later, you can install the Xcode 
Command Line Tools by running `xcode-select --install`. In Xcode 4, however, 
the "Command Line tools" is an optional Xcode add-on that you must install. 
You can find it under the "Downloads" pane of the "Preferences" dialog 
in the Xcode 4 menu.

In addition, if you want to generate the documentation you must install [Appledoc](https://github.com/tomaz/appledoc/releases/tag/v2.2-963).

In order to build the `ci-test` target of `build.sh` it is also required to 
install [xctool](https://github.com/facebook/xctool). If you use
[Homebrew](http://brew.sh/) you do that with

    brew install xctool


Configure, build, install
-------------------------

Run the following commands to configure, build, and install the language binding for OSX:

    sh build.sh config
    sh build.sh build
    sudo sh build.sh install

Headers are installed in:

    /usr/local/include/tightdb/objc/

The following libraries are installed:

    /usr/local/lib/librealm-objc.dylib
    /usr/local/lib/librealm-objc-dbg.dylib

Here is a more complete set of build-related commands:

    sh build.sh config
    sh build.sh clean
    sh build.sh build
    sh build.sh test
    sh build.sh ci-test
    sh build.sh test-debug
    sh build.sh show-install
    sudo sh build.sh install
    sh build.sh test-intalled
    sudo sh build.sh uninstall


Building for iOS
-------------------

On Mac OS X it is possible to build a version of the Objective-C
language binding for iOS. It requires that the iPhoneOS and iPhoneSimulator 
SDKs for Xcode are installed.

It also requires that a prebuilt version of the core library for iOS
is available. By default, the configuration step will look for it in
`../tightdb/iphone_lib`. If this is not the correct location of it,
set the environment variable REALM_IPHONE_CORE_LIB to the correct
path before invoking the configuration step.

Run the following command to build the Objective-C language binding
for iOS:

    sh build.sh build-iphone

This produces the following files and directories:

    iphone-lib/include/
    iphone-lib/librealm-objc-ios.a
    iphone-lib/librealm-objc-ios-dbg.a

The `include` directory holds a copy of the header files, which are
identical to the ones installed by `sh build.sh install`. There are
two versions of the static library, one that is compiled with
optimization, and one that is compiled for debugging. Each one
contains code compiled for both iOS devices and for the iOS
Simulator. Each one also includes the Realm core library and is
therefore self-contained.

After building, the iOS version of the Objective-C language binding
can be tested via the Xcode project in:

    test-iphone/

To ease the development using Xcode, you can generate a framework using
the command:

    sh build.sh ios-framework

The framework is created both in the root directory and stored 
in the `realm-ios.zip` file.

Configuration
-------------

It is possible to install into a non-default location by running the
following command before building and installing:

    sh build.sh config [PREFIX]

Here, `PREFIX` is the installation prefix. If it is not specified, it
defaults to `/usr/local`.

By default, the configuration step uses `which tightdb-config` to
locate the installation of the Realm core library. If this is not
appropriate, because you have multiple versions of the Realm core
library installed, or `tightdb-config` is not available in your
`PATH`, set the environment variable `REALM_CONFIG` before calling
`sh build.sh config`. For example:

    REALM_CONFIG=/opt/tightdb-v0.1.2/bin/tightdb-config build.sh config

To use a nondefault compiler, or a compiler in a nondefault location,
set the environment variable `CC` before calling `sh build.sh build`,
as in the following example:

    CC=clang sh build.sh build

Documentation
-------------

The documentation is generated with the following command:

    sh build.sh docs

Please note that this will also install the documentation to your machine.

![analytics](https://ga-beacon.appspot.com/UA-50247013-2/realm-cocoa/README?pixel)
