SUBDIRS = Realm
PASSIVE_SUBDIRS = 

PASSIVE_SUBDIRS += doc/ref/examples
doc_ref_examples_DEPS = src

# Build and run documentation examples
.PHONY: check-doc-examples
check-doc-examples: check-debug-norun/subdir/src
	@$(MAKE) -C doc/ref/examples check-debug

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


include src/generic.mk
