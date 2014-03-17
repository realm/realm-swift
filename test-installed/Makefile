check_PROGRAMS = test-installed

test_installed_SOURCES = test.mm
test_installed_CFLAGS  = -fobjc-arc -fobjc-abi-version=2
test_installed_LDFLAGS = -fobjc-link-runtime -framework Cocoa
test_installed_LDFLAGS_OPTIM = -ltightdb-objc
test_installed_LDFLAGS_DEBUG = -ltightdb-objc-dbg
test_installed_LDFLAGS_COVER = -ltightdb-objc-dbg

include generic.mk
