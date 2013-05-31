Objective-C
===========

This is the TightDB language binding for Objective-C.


Dependencies
------------

The TightDB core library must have been installed.

### OS X 10.8

    Install Xcode
    Install command line tools (via Xcode)


Building, testing, and installing
---------------------------------

    export CPATH="$TIGHTDB_HOME/src"
    export LIBRARY_PATH="$TIGHTDB_HOME/src/tightdb"
    sh build.sh clean
    sh build.sh build
    sh build.sh test
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

To use a nondefault compiler, or a compiler in a nondefault location,
set the environment variable `CC` before calling `sh build.sh build`,
as in the following example:

    CC=clang sh build.sh build


Notes
-----

Naming of database fields: Must start with capital letter.
