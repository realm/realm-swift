# FIXME: Our language binding requires that Objective-C ARC is enabled, which, in turn, is only available on a 64-bit architecture, so for now we cannot build a "fat" version.
## Construct fat binaries on Darwin when using Clang
#ifneq ($(TIGHTDB_ENABLE_FAT_BINARIES),)
#ifneq ($(call CC_CXX_AND_LD_ARE,clang),)
#ifeq ($(shell uname),Darwin)
#CFLAGS_ARCH  += -arch i386 -arch x86_64
#endif
#endif
#endif

# FIXME: '-fno-elide-constructors' currently causes TightDB to fail
#CFLAGS_DEBUG   += -fno-elide-constructors
CFLAGS_PTHREAD += -pthread
CFLAGS_GENERAL += -Wextra -ansi -pedantic -Wno-long-long
