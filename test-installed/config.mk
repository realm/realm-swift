ifeq ($(OS),Darwin)
CFLAGS_ARCH += -mmacosx-version-min=10.7
endif

CFLAGS_PTHREAD += -pthread
CFLAGS_GENERAL += -Wextra -ansi -pedantic -Wno-long-long

ifneq ($(TIGHTDB_OBJC_INCLUDEDIR),)
PROJECT_CFLAGS = -I$(TIGHTDB_OBJC_INCLUDEDIR)
endif

ifneq ($(TIGHTDB_OBJC_LIBDIR),)
PROJECT_CFLAGS = -L$(TIGHTDB_OBJC_LIBDIR) -Wl,-rpath,$(TIGHTDB_OBJC_LIBDIR)
endif
