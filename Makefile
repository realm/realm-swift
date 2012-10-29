SUBDIRS = src
PASSIVE_SUBDIRS = test-installed

include generic.mk

.PHONY: test-installed
test-installed:
	@$(MAKE) -C test-installed test
