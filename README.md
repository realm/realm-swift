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
prerequisites on Mac OS X 10.7 and 10.8:

Clang comes with Xcode, so install Xcode if it is not already
installed. If you have a version that preceeds 4.2, we recommend that
you upgrade. This will ensure that the Clang version is at least
3.0. Run the following command in the command prompt to see if you
have Xcode installed, and, if so, what version it is:

    xcodebuild -version

Make sure you also install "Command line tools" found under the
preferences pane "Downloads" in Xcode.

Download the latest version of Python Cheetah
(https://pypi.python.org/packages/source/C/Cheetah/Cheetah-2.4.4.tar.gz),
then:

    tar xf Cheetah-2.4.4.tar.gz
    cd Cheetah-2.4.4/
    sudo python setup.py install


Building, testing, and installing
---------------------------------

    export CPATH="$TIGHTDB_HOME/src"
    export LIBRARY_PATH="$TIGHTDB_HOME/src/tightdb"

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

The following iPhone libraries are built, but not installed:

    src/tightdb/objc/libtightdb-objc-ios.a
    src/tightdb/objc/libtightdb-objc-ios-dbg.a

The iPhone libraries can be tested via the Xcode project in:

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
