lib_LIBRARIES = libtightdb-objc.a

ADD_CFLAGS_INCLUDE = -I../../Deliv

libtightdb_objc_a_SOURCES       = Table.mm Cursor.mm Group.mm Query.mm
libtightdb_objc_a_LDFLAGS       = $(shell tightdb-config     --libs)
libtightdb_objc_a_LDFLAGS_DEBUG = $(shell tightdb-config-dbg --libs)
libtightdb_objc_a_LDFLAGS_COVER = $(shell tightdb-config-dbg --libs)

include ../../generic.mk
