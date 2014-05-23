SUBDIRS = Tests
test_DEPS = .

# Headers to be installed
nobase_subinclude_HEADERS = RLMAccessor.h RLMConstants.h RLMObjectStore.h RLMSchema.h \
Realm.h RLMArray.h RLMObject.h RLMQueryUtil.h RLMArrayAccessor.h RLMObjectSchema.h \
RLMProperty.h RLMRealm.h

#nobase_subinclude_HEADERS_EXTRA_UNINSTALL = *.h

lib_LIBRARIES = librealm-objc.a

librealm_objc_a_SOURCES = RLMAccessor.mm RLMArrayAccessor.m RLMObject.mm RLMObjectStore.mm \
RLMQueryUtil.mm	RLMSchema.mm RLMArray.mm RLMConstants.m	RLMObjectSchema.mm RLMProperty.m \
RLMRealm.mm RLMUtil.mm

librealm_objc_a_CFLAGS  = -I.. -fobjc-arc -fobjc-abi-version=2 -Wno-comment
librealm_objc_a_LDFLAGS = -fobjc-link-runtime -framework Cocoa

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
librealm_objc_a_VERSION = 4:0:0


# Used by ../build.sh
.PHONY: get-inst-headers
get-inst-headers:
	@echo $(nobase_subinclude_HEADERS)


include generic.mk
