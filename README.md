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

    export PATH="$TIGHTDB_HOME/src/tightdb:$PATH"
    export CPATH="$TIGHTDB_HOME/src"
    export LIBRARY_PATH="$TIGHTDB_HOME/src/tightdb"
    sh build.sh clean
    sh build.sh build
    sh build.sh test
    sudo sh build.sh install
    sh build.sh test-intalled


Configuration
-------------

To use a nondefault compiler, or a compiler in a nondefault location,
set the environment variable `CC` before calling `sh build.sh build`,
as in the following example:

    CC=clang sh build.sh build


Notes
-----

Naming of database fields: Must start with capital letter.
