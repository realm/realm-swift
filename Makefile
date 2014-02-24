SUBDIRS = src
PASSIVE_SUBDIRS = examples

include src/generic.mk

# Used by build.sh
.PHONY: get-exec-prefix get-includedir get-bindir get-libdir get-libexecdir
get-exec-prefix:
	@echo $(exec_prefix)
get-includedir:
	@echo $(includedir)
get-bindir:
	@echo $(bindir)
get-libdir:
	@echo $(libdir)
get-libexecdir:
	@echo $(libexecdir)
