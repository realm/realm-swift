SUBDIRS = test
test_DEPS = .

nobase_subinclude_HEADERS = type.h cursor.h transaction.h query.h table.h group_shared.h helper_macros.h table_macros.h tightdb.h version.h \
descriptor.h table_view.h binary.h column_proxy.h mixed.h

nobase_subinclude_HEADERS_EXTRA_UNINSTALL = *.h

lib_LIBRARIES = libtightdb-objc.a

libtightdb_objc_a_SOURCES = table_objc.mm cursor_objc.mm transaction_objc.mm query_objc.mm \
group_shared_objc.mm support.mm version_objc.mm descriptor_objc.mm table_view_objc.mm \
binary_objc.mm mixed_objc.mm column_proxy.mm

libtightdb_objc_a_CFLAGS  = -fobjc-arc -fobjc-abi-version=2
libtightdb_objc_a_LDFLAGS = -fobjc-link-runtime -framework Cocoa

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
libtightdb_objc_a_VERSION = 4:0:0


# Code generation
ifeq ($(DISABLE_CHEETAH_CODE_GEN),)
GENERATED_SOURCES += table_macros.h
table_macros.h: table_macros.h.cheetah cheetah.sh
	$(SHELL) cheetah.sh $< $@
endif


# Used by ../../../build.sh
.PHONY: get-inst-headers
get-inst-headers:
	@echo $(nobase_subinclude_HEADERS)


include ../../generic.mk
