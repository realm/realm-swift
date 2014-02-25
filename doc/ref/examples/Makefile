EXAMPLES := $(wildcard *.m)

check_PROGRAMS := $(patsubst %.m,%,$(EXAMPLES))

PROG_SUFFIX = .example

EXTRA_CLEAN = *.example

define EXAMPLE_PROPS
$(1)_SOURCES = $(2)
$(1)_CFLAGS  = -fobjc-arc -fobjc-abi-version=2
$(1)_LDFLAGS = -fobjc-link-runtime -framework Cocoa
$(1)_LIBS    = ../../../src/tightdb/objc/libtightdb-objc.a
endef

$(foreach x,$(EXAMPLES),$(eval $(call EXAMPLE_PROPS,$(subst -,_,$(patsubst %.m,%,$(x))),$(x))))

include ../../../src/generic.mk
