# FIXME: Our language binding requires that Objective-C ARC is enabled, which in turn only is available withing a 64-bit environment, so for now we cannot build a "fat" version.
## Construct fat binaries on Darwin when using Clang
#ifneq ($(TIGHTDB_ENABLE_FAT_BINARIES),)
#ifneq ($(call CC_CXX_AND_LD_ARE,clang),)
#ifeq ($(shell uname),Darwin)
#CFLAGS_DEFAULT  += -arch i386 -arch x86_64
#LDFLAGS_DEFAULT += -arch i386 -arch x86_64
#endif
#endif
#endif

CFLAGS_DEFAULT += -Wextra -ansi -pedantic -Wno-long-long
# FIXME: '-fno-elide-constructors' currently causes TightDB to fail
#CFLAGS_DEBUG   += -fno-elide-constructors
CFLAGS_PTHREAD += -pthread
