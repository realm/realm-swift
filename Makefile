SUBDIRS = src

include generic.mk

# Used by build.sh
get-libdir:
	@echo $(libdir)
