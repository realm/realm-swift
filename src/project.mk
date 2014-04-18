INCLUDE_ROOT = .
ENABLE_INSTALL_DEBUG_LIBS  = 1

# Construct fat binaries on Darwin when using Clang
ifneq ($(TIGHTDB_ENABLE_FAT_BINARIES),)
  ifeq ($(OS),Darwin)
    ifeq ($(COMPILER_IS),clang)
      CFLAGS_ARCH += -arch i386 -arch x86_64
    endif
  endif
endif

ifeq ($(OS),Darwin)
  CFLAGS_ARCH += -mmacosx-version-min=10.7
endif

# FIXME: '-fno-elide-constructors' currently causes TightDB to fail
#CFLAGS_DEBUG += -fno-elide-constructors
CFLAGS_PTHREADS += -pthread
CFLAGS_GENERAL += -Wextra -ansi

# Avoid a warning from Clang when linking on OS X. By default,
# `LDFLAGS_PTHREADS` inherits its value from `CFLAGS_PTHREADS`, so we
# have to override that with an empty value.
ifeq ($(OS),Darwin)
  ifeq ($(LD_IS),clang)
    LDFLAGS_PTHREADS = $(EMPTY)
  endif
endif

# Load dynamic configuration
ifeq ($(NO_CONFIG_MK),)
  CONFIG_MK = $(GENERIC_MK_DIR)/config.mk
  DEP_MAKEFILES += $(CONFIG_MK)
  include $(CONFIG_MK)
  prefix      = $(INSTALL_PREFIX)
  exec_prefix = $(INSTALL_EXEC_PREFIX)
  includedir  = $(INSTALL_INCLUDEDIR)
  bindir      = $(INSTALL_BINDIR)
  libdir      = $(INSTALL_LIBDIR)
  libexecdir  = $(INSTALL_LIBEXECDIR)
  PROJECT_CFLAGS_OPTIM  = $(REALM_CFLAGS)
  PROJECT_CFLAGS_DEBUG  = $(REALM_CFLAGS_DBG)
  PROJECT_CFLAGS_COVER  = $(REALM_CFLAGS_DBG)
  PROJECT_LDFLAGS_OPTIM = $(REALM_LDFLAGS)
  PROJECT_LDFLAGS_DEBUG = $(REALM_LDFLAGS_DBG)
  PROJECT_LDFLAGS_COVER = $(REALM_LDFLAGS_DBG)
endif
