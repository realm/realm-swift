lib_LIBRARIES = libtightdb-objc.a

libtightdb_objc_a_SOURCES       = Table.mm Cursor.mm Group.mm Query.mm
libtightdb_objc_a_CFLAGS_OPTIM  = -fobjc-arc $(shell tightdb-config     --cflags) -I../../Deliv
libtightdb_objc_a_CFLAGS_DEBUG  = -fobjc-arc $(shell tightdb-config-dbg --cflags) -I../../Deliv
libtightdb_objc_a_CFLAGS_COVER  = -fobjc-arc $(shell tightdb-config-dbg --cflags) -I../../Deliv
libtightdb_objc_a_LDFLAGS_OPTIM = -fobjc-link-runtime $(shell tightdb-config     --libs)
libtightdb_objc_a_LDFLAGS_DEBUG = -fobjc-link-runtime $(shell tightdb-config-dbg --libs)
libtightdb_objc_a_LDFLAGS_COVER = -fobjc-link-runtime $(shell tightdb-config-dbg --libs)

include ../../generic.mk
