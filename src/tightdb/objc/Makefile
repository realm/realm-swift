SUBDIRS = test
test_DEPS = .

TIGHTDB_H = tightdb.h

GENERATED_SOURCES = $(TIGHTDB_H)

INST_HEADERS = column_type.h cursor.h group.h query.h table.h group_shared.h helper_macros.h $(TIGHTDB_H)

lib_LIBRARIES = libtightdb-objc.a

TIGHTDB_CONFIG = tightdb-config

libtightdb_objc_a_SOURCES       = table_objc.mm cursor_objc.mm group_objc.mm query_objc.mm group_shared_objc.mm
libtightdb_objc_a_CFLAGS        = -fobjc-arc -fobjc-abi-version=2
libtightdb_objc_a_CFLAGS_OPTIM  = $(shell $(TIGHTDB_CONFIG)     --cflags)
libtightdb_objc_a_CFLAGS_DEBUG  = $(shell $(TIGHTDB_CONFIG)-dbg --cflags)
libtightdb_objc_a_CFLAGS_COVER  = $(shell $(TIGHTDB_CONFIG)-dbg --cflags)
libtightdb_objc_a_LDFLAGS       = -fobjc-link-runtime -framework Cocoa
libtightdb_objc_a_LDFLAGS_OPTIM = $(shell $(TIGHTDB_CONFIG)     --libs)
libtightdb_objc_a_LDFLAGS_DEBUG = $(shell $(TIGHTDB_CONFIG)-dbg --libs)
libtightdb_objc_a_LDFLAGS_COVER = $(shell $(TIGHTDB_CONFIG)-dbg --libs)

include ../../../generic.mk

# Code generation
$(TIGHTDB_H): tightdb.h.sh tightdb.h.py
	$(SHELL) tightdb.h.sh $(TIGHTDB_H)

uninstall/extra:
	$(RM) $(DESTDIR)$(includedir)/tightdb/objc/*.h
	-rmdir $(DESTDIR)$(includedir)/tightdb/objc
