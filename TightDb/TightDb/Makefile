lib_LIBRARIES = libtightdb-objc.a

TIGHTDB_CONFIG = tightdb-config

libtightdb_objc_a_SOURCES       = Table.mm Cursor.mm Group.mm Query.mm
libtightdb_objc_a_CFLAGS        = -fobjc-arc -fobjc-abi-version=2
libtightdb_objc_a_CFLAGS_OPTIM  = $(shell $(TIGHTDB_CONFIG)     --cflags) -I../../Deliv
libtightdb_objc_a_CFLAGS_DEBUG  = $(shell $(TIGHTDB_CONFIG)-dbg --cflags) -I../../Deliv
libtightdb_objc_a_CFLAGS_COVER  = $(shell $(TIGHTDB_CONFIG)-dbg --cflags) -I../../Deliv
libtightdb_objc_a_LDFLAGS       = -fobjc-link-runtime
libtightdb_objc_a_LDFLAGS_OPTIM = $(shell $(TIGHTDB_CONFIG)     --libs)
libtightdb_objc_a_LDFLAGS_DEBUG = $(shell $(TIGHTDB_CONFIG)-dbg --libs)
libtightdb_objc_a_LDFLAGS_COVER = $(shell $(TIGHTDB_CONFIG)-dbg --libs)

include ../../generic.mk
