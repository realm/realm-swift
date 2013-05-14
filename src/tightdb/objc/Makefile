SUBDIRS = test
test_DEPS = .

TIGHTDB_H = tightdb.h

GENERATED_SOURCES = $(TIGHTDB_H)

INST_HEADERS = type.h cursor.h group.h query.h table.h group_shared.h helper_macros.h $(TIGHTDB_H)

lib_LIBRARIES = libtightdb-objc.a

libtightdb_objc_a_SOURCES       = table_objc.mm cursor_objc.mm group_objc.mm query_objc.mm group_shared_objc.mm
libtightdb_objc_a_CFLAGS        = -fobjc-arc -fobjc-abi-version=2
libtightdb_objc_a_CFLAGS_OPTIM  = $(shell tightdb-config     --cflags)
libtightdb_objc_a_CFLAGS_DEBUG  = $(shell tightdb-config-dbg --cflags)
libtightdb_objc_a_CFLAGS_COVER  = $(shell tightdb-config-dbg --cflags)
libtightdb_objc_a_LDFLAGS       = -fobjc-link-runtime -framework Cocoa
libtightdb_objc_a_LDFLAGS_OPTIM = $(shell tightdb-config     --libs)
libtightdb_objc_a_LDFLAGS_DEBUG = $(shell tightdb-config-dbg --libs)
libtightdb_objc_a_LDFLAGS_COVER = $(shell tightdb-config-dbg --libs)

# Format: CURRENT[:REVISION[:AGE]]
#
# At each new public release:
#   If the interface has changed at all:
#     Increment CURRENT and reset REVISION to zero
#     Let COMPAT be the least number such that the new library (in
#       its binary form) can be used as a drop-in replacement for
#       all previous releases whose CURRENT is greater than or equal
#       to COMPAT
#     If COMPAT + AGE < CURRENT:
#       Increment AGE
#     Else:
#       Reset AGE to zero
#   Else:
#     Increment REVISION
#
# The meaning of this version string is identical to the one defined
# by GNU Libtool. See also
# http://www.gnu.org/software/libtool/manual/libtool.html#Libtool-versioning
libtightdb_objc_a_VERSION = 1:0:0

include ../../../generic.mk

# Code generation
$(TIGHTDB_H): tightdb.h.sh tightdb.h.py
	$(SHELL) tightdb.h.sh $(TIGHTDB_H)

uninstall/extra:
	$(RM) $(DESTDIR)$(includedir)/tightdb/objc/*.h
	-rmdir $(DESTDIR)$(includedir)/tightdb/objc
	-rmdir $(DESTDIR)$(includedir)/tightdb
