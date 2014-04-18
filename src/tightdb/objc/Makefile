SUBDIRS = test
test_DEPS = .

# Headers to be installed
nobase_subinclude_HEADERS = TDBConstants.h TDBType.h TDBRow.h TDBTransaction.h TDBQuery.h \
TDBTable.h TDBContext.h TDBSmartContext.h PrivateHelperMacros.h PrivateTableMacros.h PrivateTDB.h \
Tightdb.h TDBVersion.h TDBDescriptor.h TDBView.h TDBColumnProxy.h TDBViewProtocol.h \
TightdbFast.h TDBRowFast.h

nobase_subinclude_HEADERS_EXTRA_UNINSTALL = *.h

lib_LIBRARIES = libtightdb-objc.a

libtightdb_objc_a_SOURCES = TDBConstants.m TDBTable.mm TDBRow.mm TDBTransaction.mm TDBQuery.mm \
TDBContext.mm TDBSmartContext.mm util.mm TDBVersion.mm TDBDescriptor.mm TDBView.mm \
TDBColumnProxy.mm NSData+TDBGetBinaryData.mm TDBCrashReportingAgentLauncher.mm


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
GENERATED_SOURCES += PrivateTableMacros.h
PrivateTableMacros.h: PrivateTableMacros.h.cheetah cheetah.sh
	$(SHELL) cheetah.sh $< $@
endif


# Used by ../../../build.sh
.PHONY: get-inst-headers
get-inst-headers:
	@echo $(nobase_subinclude_HEADERS)


include ../../generic.mk
