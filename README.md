Objective-C
===========

This README file explains how to build and install the TightDB
language binding for Objective-C. It assumes that the TightDB core
library has already been installed.


Prerequisites
-------------

You need the standard set of build tools. This includes an
Objective-C/C++ compiler and GNU make. The Objective-C language
binding is thoroughly tested with Clang. It is known to work with
Clang 3.0 and newer.

If you are going to modify the Objective-C language binding, you will
need Cheetah for Python (http://www.cheetahtemplate.org). It is needed
because some source files are generated from Cheetah templates.

Currently, the Objective-C binding is availble only on Mac OS X (and
iPhone). The following is a suggestion of how to install the
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

If you have Xcode 5 or later, you will already have the required
command line tools installed. In Xcode 4, however, the "Command line
tools" is an optional Xcode add-on that you must install. You can find
it under the "Downloads" pane of the "Preferences" dialog in the Xcode
4 menu.

Download the latest version of Python Cheetah
(https://pypi.python.org/packages/source/C/Cheetah/Cheetah-2.4.4.tar.gz),
then:

    tar xf Cheetah-2.4.4.tar.gz
    cd Cheetah-2.4.4/
    sudo python setup.py install


Building, testing, and installing
---------------------------------

    sh build.sh config
    sh build.sh clean
    sh build.sh build
    sh build.sh test
    sh build.sh test-debug
    sh build.sh test-gdb
    sudo sh build.sh install
    sh build.sh test-intalled

Headers are installed in:

    /usr/local/include/tightdb/objc/

The following libraries are installed:

    /usr/local/lib/libtightdb-objc.dylib
    /usr/local/lib/libtightdb-objc-dbg.dylib


Building for iPhone
-------------------

On Mac OS X it is possible to build a version of the Objective-C
language binding for iOS (the iPhone OS). It requires that the
iPhoneOS and iPhoneSimulator SDKs for Xcode are installed.

It also requires that a prebuilt version of the core library for iOS
is available. By default, the configuration step will look for it in
`../tightdb/iphone_lib`. If this is not the correct location of it,
set the environment variable TIGHTDB_IPHONE_CORE_LIB to the correct
path before invoking the configuration step.

Run the following command to build the Objective-C language binding
for iPhone:

    sh build.sh build-iphone

This produces the following files and directories:

    iphone-lib/include/
    iphone-lib/libtightdb-objc-ios.a
    iphone-lib/libtightdb-objc-ios-dbg.a

The `include` directory holds a copy of the header files, which are
identical to the ones installed by `sh build.sh install`. There are
two versions of the static library, one that is compiled with
optimization, and one that is compiled for debugging. Each one
contains code compiled for both iPhone and for the iPhone
simulator. Each one also includes the TightDB core library and is
therefore self contained.

After building, the iPhone version of the Objective-C language binding
can be tested via the Xcode project in:

    test-iphone/


Configuration
-------------

It is possible to install into a non-default location by running the
following command before building and installing:

    sh build.sh config [PREFIX]

Here, `PREFIX` is the installation prefix. If it is not specified, it
defaults to `/usr/local`.

To use a nondefault compiler, or a compiler in a nondefault location,
set the environment variable `CC` before calling `sh build.sh build`,
as in the following example:

    CC=clang sh build.sh build


Notes
-----

Naming of database fields: Must start with capital letter.
