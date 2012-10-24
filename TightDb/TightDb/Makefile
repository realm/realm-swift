lib_LIBRARIES = libtightdb-objc.a

libtightdb_objc_a_SOURCES       = Table.mm Cursor.mm Group.mm Query.mm
libtightdb_objc_a_CFLAGS        = -fobjc-arc
libtightdb_objc_a_CFLAGS_OPTIM  = $(shell tightdb-config     --cflags) -I../../Deliv
libtightdb_objc_a_CFLAGS_DEBUG  = $(shell tightdb-config-dbg --cflags) -I../../Deliv
libtightdb_objc_a_CFLAGS_COVER  = $(shell tightdb-config-dbg --cflags) -I../../Deliv
libtightdb_objc_a_LDFLAGS       = -fobjc-link-runtime
libtightdb_objc_a_LDFLAGS_OPTIM = $(shell tightdb-config     --libs)
libtightdb_objc_a_LDFLAGS_DEBUG = $(shell tightdb-config-dbg --libs)
libtightdb_objc_a_LDFLAGS_COVER = $(shell tightdb-config-dbg --libs)

include ../../generic.mk
