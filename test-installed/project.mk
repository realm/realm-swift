ifeq ($(OS),Darwin)
  CFLAGS_ARCH += -mmacosx-version-min=10.7
endif

CFLAGS_PTHREADS += -pthread
CFLAGS_GENERAL += -Wextra -ansi -pedantic -Wno-long-long

# Avoid a warning from Clang when linking on OS X. By default,
# `LDFLAGS_PTHREADS` inherits its value from `CFLAGS_PTHREADS`, so we
# have to override that with an empty value.
ifeq ($(OS),Darwin)
  ifeq ($(LD_IS),clang)
    LDFLAGS_PTHREADS = $(EMPTY)
  endif
endif

ifneq ($(TIGHTDB_OBJC_INCLUDEDIR),)
  PROJECT_CFLAGS = -I$(TIGHTDB_OBJC_INCLUDEDIR)
endif

ifneq ($(TIGHTDB_OBJC_LIBDIR),)
  PROJECT_LDFLAGS = -L$(TIGHTDB_OBJC_LIBDIR) -Wl,-rpath,$(TIGHTDB_OBJC_LIBDIR)
endif
