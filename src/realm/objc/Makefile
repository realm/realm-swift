SUBDIRS = test
test_DEPS = .

# Headers to be installed
nobase_subinclude_HEADERS = RLMConstants.h RLMType.h RLMRow.h RLMTransaction.h RLMQuery.h \
RLMTable.h RLMContext.h RLMSmartContext.h PrivateHelperMacros.h PrivateTableMacros.h PrivateRLM.h \
Realm.h RLMVersion.h RLMDescriptor.h RLMView.h RLMColumnProxy.h RLMViewProtocol.h \
RLMFast.h RLMRowFast.h

nobase_subinclude_HEADERS_EXTRA_UNINSTALL = *.h

lib_LIBRARIES = librealm-objc.a

librealm_objc_a_SOURCES = RLMConstants.m RLMTable.mm RLMRow.mm RLMTransaction.mm RLMQuery.mm \
RLMContext.mm RLMSmartContext.mm util.mm RLMVersion.mm RLMDescriptor.mm RLMView.mm \
RLMColumnProxy.mm NSData+RLMGetBinaryData.mm RLMProperty.mm RLMProxy.mm RLMObjectDescriptor.m

librealm_objc_a_CFLAGS  = -fobjc-arc -fobjc-abi-version=2 -Wno-comment
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
