# Generic makefile that captures some of the ideas of GNU Automake,
# especially with respect to naming targets.
#
# Author: Kristian Spangsege
#
# This makefile requires GNU Make, it has been tested with version
# 3.81.
#
# All variables listed in the section CONFIG VARIABLES are available
# for modification in config.mk, and they may also be overridden on
# the command line. For example, to enable PTHREADS and disable
# automatic dependency tracking, you could do this:
#
#   make CFLAGS_PTHREAD=-pthread CFLAGS_AUTODEP=""
#
# If CFLAGS is specified in the environment or on the command line, it
# will replace the value of CFLAGS_GENERAL. Similarly with LDFLAGS and
# ARFLAGS.
#
# If EXTRA_CFLAGS is specified on the command line, its contents will
# be added to CFLAGS_GENERAL. Similarly with LDFLAGS.
#
# If CC, CXX, LD, or AR is specified in the environment or on the
# command line, its value will be respected.
#
# NOTE: When you change the configuration specified via the
# environment or the command line from one invocation of make to the
# next, you should always start with a 'make clean'. MAKE does this
# automatically when you change config.mk.
#
# A function CC_CXX_AND_LD_ARE is made available to check for a
# specific compiler in config.mk. For example:
#
#   ifneq ($(call CC_CXX_AND_LD_ARE,clang),)
#   # Clang specific stuff
#   endif
#
# Likewise, a variable CC_CXX_AND_LD_ARE_GCC_LIKE is made available to
# check for any GCC like compiler in config.mk (gcc, llvm-gcc,
# clang). For example:
#
#   ifneq ($(CC_CXX_AND_LD_ARE_GCC_LIKE),)
#   # GCC specific stuff
#   endif



# CONFIG VARIABLES

# Relative path to root of source tree. If specified, a corresponding
# include option (-I) is added to the compiler command
# line. Specifying it, also permits installation of headers. Headers
# will be installed under the same relative path as they have with
# respect to the directory specified here. Headers are marked for
# installation by adding them to the INST_HEADERS variable in the
# local Makefile.
SOURCE_ROOT =

CFLAGS_OPTIM          =
CFLAGS_DEBUG          =
CFLAGS_COVER          =
CFLAGS_SHARED         =
CFLAGS_PTHREAD        =
CFLAGS_CXX            =
CFLAGS_OBJC           =
CFLAGS_GENERAL        =
CFLAGS_ARCH           =
CFLAGS_INCLUDE        =
CFLAGS_AUTODEP        =
LDFLAGS_OPTIM         = $(CFLAGS_OPTIM)
LDFLAGS_DEBUG         = $(CFLAGS_DEBUG)
LDFLAGS_COVER         = $(CFLAGS_COVER)
LDFLAGS_SHARED        =
LDFLAGS_PTHREAD       = $(CFLAGS_PTHREAD)
LDFLAGS_GENERAL       =
LDFLAGS_ARCH          = $(CFLAGS_ARCH)
ARFLAGS_GENERAL       = csr

PROJECT_CFLAGS        =
PROJECT_CFLAGS_OPTIM  =
PROJECT_CFLAGS_DEBUG  =
PROJECT_CFLAGS_COVER  =
PROJECT_LDFLAGS       =
PROJECT_LDFLAGS_OPTIM =
PROJECT_LDFLAGS_DEBUG =
PROJECT_LDFLAGS_COVER =

OBJ_DENOM_SHARED      = .pic
OBJ_DENOM_OPTIM       =
OBJ_DENOM_DEBUG       = .dbg
OBJ_DENOM_COVER       = .cov
LIB_DENOM_OPTIM       =
LIB_DENOM_DEBUG       = -dbg
LIB_DENOM_COVER       = -cov
PROG_DENOM_OPTIM      =
PROG_DENOM_DEBUG      = -dbg
PROG_DENOM_COVER      = -cov

# When set to an empty value, 'make install' will also attempt to
# build everything as if by 'make all'. Set this variable to a
# nonempty value if you would rather want 'install' to simply accept
# what is there and attempt an installation from that.
NO_BUILD_ON_INSTALL =

# When set to an empty value, 'make install' will not install the
# debug versions of the programs mentioned in bin_PROGRAMS, and a
# plain 'make' will not even build them. When set to a nonempty value,
# the opposite is true.
INSTALL_DEBUG_PROGS =

# Installation (GNU style)
prefix          = /usr/local
exec_prefix     = $(prefix)
includedir      = $(prefix)/include
bindir          = $(exec_prefix)/bin
libdir          = $(if $(USE_LIB64),$(exec_prefix)/lib64,$(exec_prefix)/lib)
INSTALL         = install
INSTALL_DIR     = $(INSTALL) -d
INSTALL_DATA    = $(INSTALL) -m 644
INSTALL_LIBRARY = $(INSTALL)
INSTALL_PROGRAM = $(INSTALL)

# Alternative filesystem root for installation
DESTDIR =



# UTILITY FUNCTIONS

EMPTY =
EQUALS = $(if $(word 2,$(sort $(1) $(2))),,$(1))
COND_PREPEND = $(if $(2),$(1)$(2),)
COND_APPEND = $(if $(1),$(1)$(2),)
# ARGS: predicate, list, optional_arg
FIND = $(call FIND_1,$(1),$(strip $(2)),$(3))
FIND_1 = $(if $(2),$(call FIND_2,$(1),$(2),$(3),$(word 1,$(2))),)
FIND_2 = $(if $(call $(1),$(4),$(3)),$(4),$(call FIND_1,$(1),$(wordlist 2,$(words $(2)),$(2)),$(3)))
# ARGS: func, init_accum, list
FOLD_LEFT = $(call FOLD_LEFT_1,$(1),$(2),$(strip $(3)))
FOLD_LEFT_1 = $(if $(3),$(call FOLD_LEFT_1,$(1),$(call $(1),$(2),$(word 1,$(3))),$(wordlist 2,$(words $(3)),$(3))),$(2))
UNION = $(call FOLD_LEFT,UNION_1,$(1),$(2))
UNION_1 = $(if $(call FIND,EQUALS,$(1),$(2)),$(1),$(1) $(2))
PATH_DIFF = $(call PATH_DIFF_1,$(subst /, ,$(abspath $(1))),$(subst /, ,$(abspath $(2))))
PATH_DIFF_1 = $(if $(and $(1),$(2),$(call EQUALS,$(word 1,$(1)),$(word 1,$(2)))),$(call PATH_DIFF_1,$(wordlist 2,$(words $(1)),$(1)),$(wordlist 2,$(words $(2)),$(2))),$(subst $(EMPTY) ,/,$(strip $(patsubst %,..,$(2)) $(1))))
MAKE_ABS_PATH = $(if $(filter /%,$(1)),$(1),$(abspath $(2)/$(1)))
IN_THIS_DIR = $(call EQUALS,$(realpath $(dir $(1))),$(realpath ./))
HAVE_CMD = $(shell which $(1))
MATCH_CMD = $(filter $(1) $(1)-%,$(notdir $(2)))
MAP_CMD = $(if $(call MATCH_CMD,$(1),$(3)),$(if $(findstring /,$(3)),$(dir $(3)),)$(patsubst $(1)%,$(2)%,$(notdir $(3))),)
CAT_OPT_FILE = $(and $(wildcard $(1)),$(shell cat $(1)))



# PLATFORM SPECIFICS

OS        = $(shell uname)
ARCH      = $(shell uname -m)

USE_LIB64 =
ifeq ($(OS),Linux)
IS_64BIT = $(filter x86_64 ia64,$(ARCH))
ifneq ($(IS_64BIT),)
ifeq ($(shell [ -e /etc/redhat-release -o -e /etc/SuSE-release ] && echo yes),yes)
USE_LIB64 = 1
else ifneq ($(shell [ -e /etc/system-release ] && grep Amazon /etc/system-release),)
USE_LIB64 = 1
endif
endif
endif

GET_SPECIAL_SHARED_LIB_OPTS =
ifeq ($(OS),Darwin)
GET_SPECIAL_SHARED_LIB_OPTS = -install_name @rpath/$(1)
endif



# SETUP A GCC-LIKE DEFAULT COMPILER IF POSSIBLE

# The general idea is as follows: If neither CC nor CXX is specified,
# then check for available C compilers, and set CC and CXX
# accordingly. Otherwise, if CC is specified, but CXX is not, then set
# CXX to the C++ version of CC.

# Note: No correspondence is required between the compilers
# mentioned in GCC_LIKE_COMPILERS, and those mentioned in
# MAP_CC_TO_CXX
ifeq ($(OS),Darwin)
GCC_LIKE_COMPILERS = clang llvm-gcc gcc
else
GCC_LIKE_COMPILERS = gcc llvm-gcc clang
endif
MAP_CC_TO_CXX = $(or $(call MAP_CMD,gcc,g++,$(1)),$(call MAP_CMD,llvm-gcc,llvm-g++,$(1)),$(call MAP_CMD,clang,clang++,$(1)))

GXX_LIKE_COMPILERS = $(strip $(foreach x,$(GCC_LIKE_COMPILERS),$(call MAP_CC_TO_CXX,$(x))))
IS_GCC_LIKE = $(strip $(foreach x,$(GCC_LIKE_COMPILERS),$(call MATCH_CMD,$(x),$(1))))
IS_GXX_LIKE = $(strip $(foreach x,$(GXX_LIKE_COMPILERS),$(call MATCH_CMD,$(x),$(1))))

# C and C++
CC_SPECIFIED        = $(filter-out undefined default,$(origin CC))
CXX_SPECIFIED       = $(filter-out undefined default,$(origin CXX))
CC_OR_CXX_SPECIFIED = $(or $(CC_SPECIFIED),$(CXX_SPECIFIED))
ifeq ($(CC_OR_CXX_SPECIFIED),)
# Neither CC nor CXX is specified
X := $(call FIND,HAVE_CMD,$(GCC_LIKE_COMPILERS))
ifneq ($(X),)
CC := $(X)
X := $(call MAP_CC_TO_CXX,$(CC))
ifneq ($(X),)
CXX := $(X)
endif
endif
else ifeq ($(CXX_SPECIFIED),)
# CXX is not specified, but CC is
X := $(call MAP_CC_TO_CXX,$(CC))
ifneq ($(X),)
CXX := $(X)
endif
endif
CC_AND_CXX_ARE_GCC_LIKE = $(and $(call IS_GCC_LIKE,$(CC)),$(or $(call IS_GCC_LIKE,$(CXX)),$(call IS_GXX_LIKE,$(CXX))))
ifneq ($(CC_AND_CXX_ARE_GCC_LIKE),)
CFLAGS_OPTIM   = -O3
CFLAGS_DEBUG   = -ggdb
CFLAGS_COVER   = --coverage
CFLAGS_SHARED  = -fPIC -DPIC
CFLAGS_GENERAL = -Wall
CFLAGS_AUTODEP = -MMD -MP
endif

# Objective-C and Objective-C++
OCC_SPECIFIED         = $(filter-out undefined default,$(origin OCC))
OCXX_SPECIFIED        = $(filter-out undefined default,$(origin OCXX))
OCC_OR_OCXX_SPECIFIED = $(or $(OCC_SPECIFIED),$(OCXX_SPECIFIED))
ifeq ($(OCC_OR_OCXX_SPECIFIED),)
# Neither OCC nor OCXX is specified
OCC  := $(CC)
OCXX := $(CXX)
else ifeq ($(OCXX_SPECIFIED),)
# OCXX is not specified, but OCC is
X := $(call MAP_CC_TO_CXX,$(OCC))
ifneq ($(X),)
OCXX := $(X)
endif
endif
OCC_AND_OCXX_ARE_GCC_LIKE = $(and $(call IS_GCC_LIKE,$(OCC)),$(or $(call IS_GCC_LIKE,$(OCXX)),$(call IS_GXX_LIKE,$(OCXX))))



# SETUP A GCC-LIKE DEFAULT LINKER IF POSSIBLE

ifneq ($(CC_AND_CXX_ARE_GCC_LIKE),)
ifeq ($(LD_SPECIFIED),)
LD := $(CXX)
endif
endif
LD_IS_GCC_LIKE = $(or $(call IS_GCC_LIKE,$(LD)),$(call IS_GXX_LIKE,$(LD)))
ifneq ($(LD_IS_GCC_LIKE),)
LDFLAGS_SHARED = -shared
endif

# Workaround for CLANG < v3.2 ignoring LIBRARY_PATH
LD_IS_CLANG = $(or $(call MATCH_CMD,clang,$(LD)),$(call MATCH_CMD,clang++,$(LD)))
ifneq ($(LD_IS_CLANG),)
CLANG_VERSION = $(shell $(LD) --version | grep -i 'clang version' | sed 's/.*clang version \([^ ][^ ]*\).*/\1/' | sed 's/[._-]/ /g')
CLANG_MAJOR = $(word 1,$(CLANG_VERSION))
CLANG_MINOR = $(word 2,$(CLANG_VERSION))
ifeq ($(shell echo $$(($(CLANG_MAJOR) < 3 || ($(CLANG_MAJOR) == 3 && $(CLANG_MINOR) < 2)))),1)
LDFLAGS_LIBRARY_PATH = $(foreach x,$(subst :, ,$(LIBRARY_PATH)),-L$(x))
endif
endif



# LOAD PROJECT SPECIFIC CONFIGURATION

CC_CXX_AND_LD_ARE = $(call CC_CXX_AND_LD_ARE_1,$(1),$(call MAP_CC_TO_CXX,$(1)))
CC_CXX_AND_LD_ARE_1 = $(and $(call MATCH_CMD,$(1),$(CC)),$(strip $(foreach x,$(1) $(2),$(call MATCH_CMD,$(x),$(CXX)))),$(strip $(foreach x,$(1) $(2),$(call MATCH_CMD,$(x),$(LD)))))
CC_CXX_AND_LD_ARE_GCC_LIKE = $(strip $(foreach x,$(GCC_LIKE_COMPILERS),$(call CC_CXX_AND_LD_ARE,$(x))))

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
ROOT = $(patsubst %/,%,$(dir $(THIS_MAKEFILE)))
ABS_ROOT = $(abspath $(ROOT))
CONFIG_MK = $(ROOT)/config.mk
-include $(CONFIG_MK)



# SETUP BUILD COMMANDS

CFLAGS_SPECIFIED  = $(filter-out undefined default,$(origin CFLAGS))
LDFLAGS_SPECIFIED = $(filter-out undefined default,$(origin LDFLAGS))
ARFLAGS_SPECIFIED = $(filter-out undefined default,$(origin ARFLAGS))
ifneq ($(CFLAGS_SPECIFIED),)
CFLAGS_GENERAL = $(CFLAGS)
endif
ifneq ($(LDFLAGS_SPECIFIED),)
PROJECT_GENERAL = $(LDFLAGS)
endif
ifneq ($(ARFLAGS_SPECIFIED),)
ARFLAGS_GENERAL = $(ARFLAGS)
endif
EXTRA_CFLAGS  =
EXTRA_LDFLAGS =
CFLAGS_GENERAL  += $(EXTRA_CFLAGS)
LDFLAGS_GENERAL += $(EXTRA_LDFLAGS)

CC_STATIC_OPTIM   = $(CC) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL)
CC_SHARED_OPTIM   = $(CC) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL)
CC_STATIC_DEBUG   = $(CC) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL)
CC_SHARED_DEBUG   = $(CC) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL)
CC_STATIC_COVER   = $(CC) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL)
CC_SHARED_COVER   = $(CC) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL)

CXX_STATIC_OPTIM  = $(CXX) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
CXX_SHARED_OPTIM  = $(CXX) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
CXX_STATIC_DEBUG  = $(CXX) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
CXX_SHARED_DEBUG  = $(CXX) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
CXX_STATIC_COVER  = $(CXX) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
CXX_SHARED_COVER  = $(CXX) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_CXX) $(CFLAGS_GENERAL)

OCC_STATIC_OPTIM  = $(OCC) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_GENERAL)
OCC_SHARED_OPTIM  = $(OCC) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_GENERAL)
OCC_STATIC_DEBUG  = $(OCC) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_GENERAL)
OCC_SHARED_DEBUG  = $(OCC) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_GENERAL)
OCC_STATIC_COVER  = $(OCC) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_GENERAL)
OCC_SHARED_COVER  = $(OCC) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_GENERAL)

OCXX_STATIC_OPTIM = $(OCXX) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
OCXX_SHARED_OPTIM = $(OCXX) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
OCXX_STATIC_DEBUG = $(OCXX) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
OCXX_SHARED_DEBUG = $(OCXX) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
OCXX_STATIC_COVER = $(OCXX) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_CXX) $(CFLAGS_GENERAL)
OCXX_SHARED_COVER = $(OCXX) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_OBJC) $(CFLAGS_CXX) $(CFLAGS_GENERAL)

LD_LIB_OPTIM      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_OPTIM) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_LIB_DEBUG      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_DEBUG) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_LIB_COVER      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_COVER) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_PROG_OPTIM     = $(LD) $(LDFLAGS_OPTIM) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_PROG_DEBUG     = $(LD) $(LDFLAGS_DEBUG) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_PROG_COVER     = $(LD) $(LDFLAGS_COVER) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)



SUFFIX_OBJ_STATIC_OPTIM = $(OBJ_DENOM_OPTIM).o
SUFFIX_OBJ_SHARED_OPTIM = $(OBJ_DENOM_OPTIM)$(OBJ_DENOM_SHARED).o
SUFFIX_OBJ_STATIC_DEBUG = $(OBJ_DENOM_DEBUG).o
SUFFIX_OBJ_SHARED_DEBUG = $(OBJ_DENOM_DEBUG)$(OBJ_DENOM_SHARED).o
SUFFIX_OBJ_STATIC_COVER = $(OBJ_DENOM_COVER).o
SUFFIX_OBJ_SHARED_COVER = $(OBJ_DENOM_COVER)$(OBJ_DENOM_SHARED).o
SUFFIX_LIB_STATIC_OPTIM = $(LIB_DENOM_OPTIM).a
SUFFIX_LIB_SHARED_OPTIM = $(LIB_DENOM_OPTIM).so
SUFFIX_LIB_STATIC_DEBUG = $(LIB_DENOM_DEBUG).a
SUFFIX_LIB_SHARED_DEBUG = $(LIB_DENOM_DEBUG).so
SUFFIX_LIB_STATIC_COVER = $(LIB_DENOM_COVER).a
SUFFIX_LIB_SHARED_COVER = $(LIB_DENOM_COVER).so
SUFFIX_PROG_OPTIM       = $(PROG_DENOM_OPTIM)
SUFFIX_PROG_DEBUG       = $(PROG_DENOM_DEBUG)
SUFFIX_PROG_COVER       = $(PROG_DENOM_COVER)

FOLD_TARGET = $(subst /,_,$(subst .,_,$(subst -,_,$(1))))
GET_LIBRARY_NAME = $(patsubst %.a,%,$(1))
GET_OBJECTS_FROM_SOURCES = $(patsubst %.c,%$(2),$(patsubst %.cpp,%$(2),$(patsubst %.m,%$(2),$(patsubst %.mm,%$(2),$(1)))))
GET_OBJECTS_FOR_TARGET = $(call GET_OBJECTS_FROM_SOURCES,$($(call FOLD_TARGET,$(1))_SOURCES),$(2))
GET_FLAGS = $($(1)) $($(1)$(2))
GET_CFLAGS_FOR_TARGET = $(foreach x,PROJECT DIR $(foreach y,$(GMK_$(call FOLD_TARGET,$(1))_TARGETS) $(1),$(call FOLD_TARGET,$(y))),$(call GET_FLAGS,$(x)_CFLAGS,$(2)))
GET_LDFLAGS_FOR_TARGET = $(foreach x,PROJECT DIR $(call FOLD_TARGET,$(1)),$(call GET_FLAGS,$(x)_LDFLAGS,$(2)))
GET_DEPS_FOR_TARGET = $($(call FOLD_TARGET,$(1))_DEPS)

INC_FLAGS         = $(CFLAGS_INCLUDE)
INC_FLAGS_ABS     = $(CFLAGS_INCLUDE)
ifneq ($(SOURCE_ROOT),)
INC_FLAGS        += -I$(ROOT)/$(SOURCE_ROOT)
INC_FLAGS_ABS    += -I$(ABS_ROOT)/$(SOURCE_ROOT)
endif

INST_LIBRARIES = $(foreach x,lib $(EXTRA_INSTALL_PREFIXES),$($(x)_LIBRARIES))
INST_PROGRAMS  = $(foreach x,bin $(EXTRA_INSTALL_PREFIXES),$($(x)_PROGRAMS))

LIBRARIES = $(INST_LIBRARIES) $(NOINST_LIBRARIES)
PROGRAMS  = $(INST_PROGRAMS) $(NOINST_PROGRAMS) $(TEST_PROGRAMS)

OBJECTS_STATIC_OPTIM = $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_OPTIM)))
OBJECTS_SHARED_OPTIM = $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_OPTIM)))
OBJECTS_STATIC_DEBUG = $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_DEBUG)))
OBJECTS_SHARED_DEBUG = $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_DEBUG)))
OBJECTS_STATIC_COVER = $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_COVER)))
OBJECTS_SHARED_COVER = $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_COVER)))
OBJECTS = $(sort $(OBJECTS_STATIC_OPTIM) $(OBJECTS_SHARED_OPTIM) $(OBJECTS_STATIC_DEBUG) $(OBJECTS_SHARED_DEBUG) $(OBJECTS_STATIC_COVER) $(OBJECTS_SHARED_COVER))

TARGETS_LIB_STATIC_OPTIM  = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_LIB_SHARED_OPTIM  = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_SHARED_OPTIM))
TARGETS_LIB_STATIC_DEBUG  = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_LIB_SHARED_DEBUG  = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_SHARED_DEBUG))
TARGETS_LIB_STATIC_COVER  = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_LIB_SHARED_COVER  = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_SHARED_COVER))
TARGETS_NOINST_LIB_OPTIM  = $(foreach x,$(NOINST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_NOINST_LIB_DEBUG  = $(foreach x,$(NOINST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_NOINST_LIB_COVER  = $(foreach x,$(NOINST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_PROG_OPTIM        = $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_PROG_DEBUG        = $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_PROG_COVER        = $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))
TARGETS_NOINST_PROG_OPTIM = $(foreach x,$(NOINST_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_NOINST_PROG_DEBUG = $(foreach x,$(NOINST_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_NOINST_PROG_COVER = $(foreach x,$(NOINST_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))
TARGETS_TEST_PROG_OPTIM   = $(foreach x,$(TEST_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_TEST_PROG_DEBUG   = $(foreach x,$(TEST_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_TEST_PROG_COVER   = $(foreach x,$(TEST_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))

ifeq ($(INSTALL_DEBUG_PROGS),)
TARGETS_DEFAULT     = $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_PROG_OPTIM) $(TARGETS_NOINST_PROG_OPTIM)
else
TARGETS_DEFAULT     = $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_PROG_OPTIM) $(TARGETS_PROG_DEBUG) $(TARGETS_NOINST_PROG_OPTIM)
endif
TARGETS_MINIMAL     = $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_PROG_OPTIM) $(TARGETS_NOINST_PROG_OPTIM)
TARGETS_NODEBUG     = $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_PROG_OPTIM) $(TARGETS_NOINST_PROG_OPTIM)
TARGETS_DEBUG       = $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_PROG_DEBUG) $(TARGETS_NOINST_PROG_DEBUG)
TARGETS_COVER       = $(TARGETS_LIB_SHARED_COVER) $(TARGETS_NOINST_LIB_COVER) $(TARGETS_PROG_COVER) $(TARGETS_NOINST_PROG_COVER)
TARGETS_TEST        = $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_TEST_PROG_OPTIM)
TARGETS_TEST_DEBUG  = $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_TEST_PROG_DEBUG)
TARGETS_TEST_COVER  = $(TARGETS_LIB_SHARED_COVER) $(TARGETS_NOINST_LIB_COVER) $(TARGETS_TEST_PROG_COVER)

TARGETS_LIB_STATIC  = $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_STATIC_DEBUG) $(TARGETS_LIB_STATIC_COVER)
TARGETS_LIB_SHARED  = $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_LIB_SHARED_COVER)
TARGETS_NOINST_LIB  = $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_COVER)
TARGETS_PROG        = $(TARGETS_PROG_OPTIM) $(TARGETS_PROG_DEBUG) $(TARGETS_PROG_COVER)
TARGETS_NOINST_PROG = $(TARGETS_NOINST_PROG_OPTIM) $(TARGETS_NOINST_PROG_DEBUG) $(TARGETS_NOINST_PROG_COVER)
TARGETS_TEST_PROG   = $(TARGETS_TEST_PROG_OPTIM) $(TARGETS_TEST_PROG_DEBUG) $(TARGETS_TEST_PROG_COVER)

TARGETS  = $(TARGETS_LIB_STATIC) $(TARGETS_LIB_SHARED) $(TARGETS_NOINST_LIB)
TARGETS += $(foreach x,$(TARGETS_PROG),$(x) $(x)-noinst) $(TARGETS_NOINST_PROG) $(TARGETS_TEST_PROG)

RECURSIVE_MODES = default minimal nodebug debug cover clean install uninstall test-norun test-debug-norun test test-debug test-cover memtest memtest-debug

.PHONY: all
all: default

default/local:    $(TARGETS_DEFAULT) update-libdeps-files
minimal/local:    $(TARGETS_MINIMAL) update-libdeps-files
nodebug/local:    $(TARGETS_NODEBUG) update-libdeps-files
debug/local:      $(TARGETS_DEBUG) update-libdeps-files
cover/local:      $(TARGETS_COVER) update-libdeps-files
test-norun:       $(TARGETS_TEST) update-libdeps-files
test-debug-norun: $(TARGETS_TEST_DEBUG) update-libdeps-files


# Update everything if any makefile has changed
DEP_MAKEFILES = Makefile $(THIS_MAKEFILE)
ifneq ($(wildcard $(CONFIG_MK)),)
DEP_MAKEFILES += $(CONFIG_MK)
endif
$(OBJECTS) $(TARGETS): $(DEP_MAKEFILES)
$(OBJECTS): $(GENERATED_SOURCES)

# Disable all suffix rules and some interfering implicit pattern rules
.SUFFIXES:
%: %.o
%: %.c
%: %.cpp



# SUBDIRECTORIES

define SUBDIR_DEP_RULE
ifeq ($(3),.)
subdir/$(1)/$(2): $(2)/local
else
subdir/$(1)/$(2): subdir/$(3)/$(2)
endif
endef

define SUBDIR_MODE_RULES
.PHONY: subdir/$(1)/$(2)
$$(foreach x,$$($$(call FOLD_TARGET,$(1))_DEPS),$$(eval $$(call SUBDIR_DEP_RULE,$(1),$(2),$$(x))))
ifeq ($(2),default)
subdir/$(1)/$(2):
	@$$(MAKE) -C $(1)
else
subdir/$(1)/$(2):
	@$$(MAKE) -C $(1) $(2)
endif
endef

SUBDIR_RULES = $(foreach x,$(RECURSIVE_MODES),$(eval $(call SUBDIR_MODE_RULES,$(1),$(x))))

$(foreach x,$(SUBDIRS) $(PASSIVE_SUBDIRS),$(eval $(call SUBDIR_RULES,$(x))))

define RECURSIVE_MODE_RULES
.PHONY: $(1) $(1)/local $(1)/after
$(1): $(1)/local $(patsubst %,subdir/%/$(1),$(SUBDIRS)) $(1)/after
$(1)/after: $(1)/local $(patsubst %,subdir/%/$(1),$(SUBDIRS))
endef

$(foreach x,$(RECURSIVE_MODES),$(eval $(call RECURSIVE_MODE_RULES,$(x))))



# CLEANING

ifneq ($(strip $(TARGETS)),)
define CLEANING_RULES

.PHONY: clean/extra
clean/local: clean/extra
	$(RM) $(strip *.d *.o *.libdeps *.gcno *.gcda $(TARGETS))
	$(foreach x,$(EXTRA_CLEAN_DIRS),$(RM) $(x)/*.d $(x)/*.o $(x)/*.gcno $(x)/*.gcda
	)

endef
$(eval $(CLEANING_RULES))
endif

clean clean/after: $(patsubst %,subdir/%/clean,$(PASSIVE_SUBDIRS))



# INSTALL / UNINSTALL

.PHONY: install/header/dir install/lib/dirs install/prog/dirs
.PHONY: install/headers install/libs install/progs
.PHONY: uninstall/libs uninstall/progs uninstall/extra

ifeq ($(NO_BUILD_ON_INSTALL),)
install/local: default/local
install/libs: $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_DEBUG)
install/progs: $(TARGETS_PROG_OPTIM)
ifneq ($(INSTALL_DEBUG_PROGS),)
install/progs: $(TARGETS_PROG_DEBUG)
endif
endif

install/local: install/headers install/libs install/progs
uninstall/after: uninstall/progs uninstall/libs uninstall/extra

HEADER_INSTALL_DIR =
ifneq ($(INST_HEADERS),)
ifeq ($(SOURCE_ROOT),)
$(warning Cannot install headers without a value for SOURCE_ROOT)
else
HEADER_REL_PATH = $(call PATH_DIFF,.,$(ROOT)/$(SOURCE_ROOT))
SOURCE_ABS_ROOT = $(ABS_ROOT)/$(SOURCE_ROOT)
INSIDE_SOURCE = $(call EQUALS,$(SOURCE_ABS_ROOT)$(call COND_PREPEND,/,$(HEADER_REL_PATH)),$(abspath .))
ifeq ($(INSIDE_SOURCE),)
$(warning Cannot install headers lying outside SOURCE_ROOT)
else
HEADER_INSTALL_DIR = $(DESTDIR)$(includedir)$(call COND_PREPEND,/,$(HEADER_REL_PATH))
endif
endif
endif

GET_LIB_INSTALL_DIR   = $(if $($(1)_DIR),$($(1)_DIR),$(DESTDIR)$(libdir))
GET_PROG_INSTALL_DIR  = $(if $($(1)_DIR),$($(1)_DIR),$(DESTDIR)$(bindir))

INSTALL_RECIPE_DIR    = $(if $(1),$(INSTALL_DIR) $(1),)
INSTALL_RECIPE_LIB    = $(if $(2),$(INSTALL_LIBRARY) $(2) $(call GET_LIB_INSTALL_DIR,$(1)),)
INSTALL_RECIPE_PROG   = $(if $(2),$(INSTALL_PROGRAM) $(2) $(call GET_PROG_INSTALL_DIR,$(1)),)
UNINSTALL_RECIPE_LIB  = $(RM) $(call GET_LIB_INSTALL_DIR,$(1))/$(2)
UNINSTALL_RECIPE_PROG = $(RM) $(call GET_PROG_INSTALL_DIR,$(1))/$(2)

GET_INST_LIB_TARGETS  = $(foreach x,$($(1)_LIBRARIES),$(foreach y,$(SUFFIX_LIB_SHARED_OPTIM) $(SUFFIX_LIB_STATIC_OPTIM) $(SUFFIX_LIB_SHARED_DEBUG),$(call GET_LIBRARY_NAME,$(x))$(y)))

ifeq ($(INSTALL_DEBUG_PROGS),)
GET_INST_PROG_TARGETS = $(foreach x,$($(1)_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
else
GET_INST_PROG_TARGETS = $(foreach x,$($(1)_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM) $(x)$(SUFFIX_PROG_DEBUG))
endif

define INSTALL_RULES

ifneq ($(HEADER_INSTALL_DIR),)
install/headers: install/header/dir
	$(INSTALL_DATA) $(INST_HEADERS) $(HEADER_INSTALL_DIR)
install/header/dir:
	$(INSTALL_DIR) $(HEADER_INSTALL_DIR)
endif

install/libs: install/lib/dirs
	$(foreach x,lib $(EXTRA_INSTALL_PREFIXES),$(call INSTALL_RECIPE_LIB,$(x),$(call GET_INST_LIB_TARGETS,$(x)))
	)

install/progs: install/prog/dirs
	$(foreach x,bin $(EXTRA_INSTALL_PREFIXES),$(call INSTALL_RECIPE_PROG,$(x),$(call GET_INST_PROG_TARGETS,$(x)))
	)

uninstall/libs:
	$(foreach x,lib $(EXTRA_INSTALL_PREFIXES),$(foreach y,$(call GET_INST_LIB_TARGETS,$(x)),$(call UNINSTALL_RECIPE_LIB,$(x),$(y))
	))

uninstall/progs:
	$(foreach x,bin $(EXTRA_INSTALL_PREFIXES),$(foreach y,$(call GET_INST_PROG_TARGETS,$(x)),$(call UNINSTALL_RECIPE_PROG,$(x),$(y))
	))

install/lib/dirs:
	$(call INSTALL_RECIPE_DIR,$(strip $(foreach x,lib $(EXTRA_INSTALL_PREFIXES),$(if $($(x)_LIBRARIES),$(call GET_LIB_INSTALL_DIR,$(x)),))))

install/prog/dirs:
	$(call INSTALL_RECIPE_DIR,$(strip $(foreach x,bin $(EXTRA_INSTALL_PREFIXES),$(if $($(x)_PROGRAMS),$(call GET_PROG_INSTALL_DIR,$(x)),))))

endef

$(eval $(INSTALL_RULES))



# TESTING

define TEST_RULES

test/local: $(TARGETS_TEST) update-libdeps-files
	$(foreach x,$(TARGETS_TEST_PROG_OPTIM),./$(x)
	)

test-debug/local: $(TARGETS_TEST_DEBUG) update-libdeps-files
	$(foreach x,$(TARGETS_TEST_PROG_DEBUG),./$(x)
	)

memtest/local: $(TARGETS_TEST) update-libdeps-files
	$(foreach x,$(TARGETS_TEST_PROG_OPTIM),valgrind --quiet --error-exitcode=1 --track-origins=yes --leak-check=yes --leak-resolution=low ./$(x) --no-error-exit-staus
	)

memtest-debug/local: $(TARGETS_TEST_DEBUG) update-libdeps-files
	$(foreach x,$(TARGETS_TEST_PROG_DEBUG),valgrind --quiet --error-exitcode=1 --track-origins=yes --leak-check=yes --leak-resolution=low ./$(x) --no-error-exit-staus
	)

ifneq ($(strip $(TARGETS_TEST_COVER)),)
test-cover/local: $(TARGETS_TEST_COVER)
	$(RM) *.gcda
	$(foreach x,$(EXTRA_CLEAN_DIRS),$(RM) $(x)/*.gcda
	)
	$(foreach x,$(TARGETS_TEST_PROG_COVER),-./$(x)
	)
endif
test-cover/local: update-libdeps-files

endef

$(eval $(TEST_RULES))



# LINKING PROGRAMS

# FIXME: Add '-Wl,-rpath' if linking against locally built and installed libraries, but it requires us to know the library installation directory. Or maybe it is better to set LD_RUN_PATH.

# neither inst nor noinst libs can have noinst lib dependencies
# noinst libs can have associated LDFLAGS
# mynoinstlib.libdeps = noinst lib:../libfoo.a lib:libbar.a rpath:. rpath:../dir1 ldflag:-lhest ldflag:-L../dir2 ldflag-dbg:-lhest ldflag-dbg:-L../dir2 ldflag-cov:-lhest ldflag-cov:-L../dir2
# libmyinst.libdeps = rpath:../dir1 rpath:../dir2
# rpaths in inst lib are the the paths of all installed libraries that it depends on (transitively closed)
# rpaths in noinst lib are the union of the rpaths in .libdeps of all the installed libraries that it depends on (transitively closed)
# in lib dep expansion the list of noinst libs are precisely those specified in _LIBS
# in lib dep expansion the list of inst libs are those which the noinst libs depend on plus those specified in _LIBS
# in lib dep expansion noinst libs must precede inst libs
# in lib dep expansion duplicates must be removed

# Expand the contents of the target_LIBS variable for the specified target. The target should be either a program or an installed (i.e. a shared) library.
# Output example for program: noinst:../foo/bar inst:../beta/libalpha lib:alpha dir:../beta rpath:/abs/path/beta ldflag:-ldelta ldflag-dbg:-ldelta ldflag-cov:-ldelta
# Output example for installed library: inst:../beta/libalpha lib:alpha dir:../beta rpath:/abs/path/beta
EXPAND_LIB_REFS   = $(call FOLD_LEFT,EXPAND_LIB_REFS_1,,$(strip $($(call FOLD_TARGET,$(1))_LIBS)))
EXPAND_LIB_REFS_1 = $(call EXPAND_LIB_REFS_2,$(1),$(2),$(call READ_LIB_LIBDEPS,$(2)))
EXPAND_LIB_REFS_2 = $(if $(filter noinst,$(3)),$(call EXPAND_LIB_REFS_3,$(1),$(2),$(3)),$(call EXPAND_LIB_REFS_4,$(1),$(2),$(3)))
EXPAND_LIB_REFS_3 = $(call EXPAND_LIB_REFS_5,$(1),noinst:$(call GET_LIBRARY_NAME,$(2)) $(filter-out noinst,$(3)))
EXPAND_LIB_REFS_4 = $(call EXPAND_LIB_REFS_5,$(1),inst:$(call GET_LIBRARY_NAME,$(2)) lib:$(2) $(3))
EXPAND_LIB_REFS_5 = $(call UNION,$(1),$(call PATTERN_UNPACK_MAP,MAKE_ABS_PATH,rpath:%,$(call EXPAND_LIB_REFS_6,$(2)),.))
EXPAND_LIB_REFS_6 = $(foreach x,$(1),$(if $(filter lib:%,$(x)),$(call EXPAND_LIB_REFS_7,$(patsubst lib:%,%,$(x))),$(x)))
EXPAND_LIB_REFS_7 = $(call EXPAND_LIB_REFS_8,$(notdir $(1)),$(patsubst %/,%,$(dir $(1))))
EXPAND_LIB_REFS_8 = lib:$(patsubst lib%,%,$(call GET_LIBRARY_NAME,$(1))) dir:$(2) rpath:$(2)

# Read the contents of the .libdeps file for the specified library and translate relative paths.
# For libraries in the local directory, the contents needs to be computed "on the fly" because the file may not be up to date.
READ_LIB_LIBDEPS   = $(if $(call IN_THIS_DIR,$(1)),$(call READ_LIB_LIBDEPS_1,$(notdir $(1))),$(call READ_LIB_LIBDEPS_2,$(1)))
READ_LIB_LIBDEPS_1 = $(if $(call IS_NOINST_LIB,$(1)),$(call MAKE_NOINST_LIB_LIBDEPS,$(1)),$(call MAKE_INST_LIB_LIBDEPS,$(1)))
READ_LIB_LIBDEPS_2 = $(call PATTERN_UNPACK_MAP,READ_LIB_LIBDEPS_3,lib:% rpath:%,$(call CAT_OPT_FILE,$(call GET_LIBRARY_NAME,$(1)).libdeps),$(1))
READ_LIB_LIBDEPS_3 = $(call PATH_DIFF,$(call MAKE_ABS_PATH,$(1),$(2)),.)

IS_NOINST_LIB   = $(call FIND,IS_NOINST_LIB_1,$(NOINST_LIBRARIES),$(1))
IS_NOINST_LIB_1 = $(and $(call IN_THIS_DIR,$(1)),$(call EQUALS,$(notdir $(1)),$(2)))

# Example: noinst lib:../libfoo.a lib:libbar.a rpath:. rpath:../dir1 ldflag:-lhest ldflag:-L../dir2 ldflag-dbg:-lhest ldflag-dbg:-L../dir2 ldflag-cov:-lhest ldflag-cov:-L../dir2
MAKE_NOINST_LIB_LIBDEPS   = $(strip noinst $(call MAKE_NOINST_LIB_LIBDEPS_1,$(1)) $(call MAKE_NOINST_LIB_LIBDEPS_2,$(1)))
MAKE_NOINST_LIB_LIBDEPS_1 = $(foreach x,$($(call FOLD_TARGET,$(1))_LIBS),lib:$(x) $(call READ_LIB_LIBDEPS,$(x)))
MAKE_NOINST_LIB_LIBDEPS_2 = $(call MAKE_NOINST_LIB_LIBDEPS_3,$(1)) $(call MAKE_NOINST_LIB_LIBDEPS_4,$(1)) $(call MAKE_NOINST_LIB_LIBDEPS_5,$(1))
MAKE_NOINST_LIB_LIBDEPS_3 = $(foreach x,$(call GET_LDFLAGS_FOR_TARGET,$(1),_OPTIM),ldflag:$(x))
MAKE_NOINST_LIB_LIBDEPS_4 = $(foreach x,$(call GET_LDFLAGS_FOR_TARGET,$(1),_DEBUG),ldflag-dbg:$(x))
MAKE_NOINST_LIB_LIBDEPS_5 = $(foreach x,$(call GET_LDFLAGS_FOR_TARGET,$(1),_COVER),ldflag-cov:$(x))

# Example: rpath:../dir1 rpath:../dir2
MAKE_INST_LIB_LIBDEPS = $(call EXTRACT_INST_LIB_LIBDEPS,$(call EXPAND_LIB_REFS,$(1)))
EXTRACT_INST_LIB_LIBDEPS = $(foreach x,$(filter rpath:%,$(1)),rpath:$(call PATH_DIFF,$(patsubst rpath:%,%,$(x)),.))

# Same handling of noinst and inst libs:
# Noinst lib case can be mapped to: $(call HANDLE,$(1),$(2),noinst:$(2) $(filter-out noinst,$(4)))
# The inst lib case can be mapped to: $(call HANDLE,$(1),$(2),lib:$(notdir $(2)) $(4))
# Each input lib: produces an output lib:, dir:, rpath:
# Each input rpath: must be made absolute
# Each input LDFGLAG is passed through unmodified

# FIXME: REMEMBER TO WRITE DOC ON x_LIBS VARIBALE.

# ARGS: expanded_lib_refs, qual_type
QUALIFY_LIB_REFS   = $(call SELECT_LDFLAGS$(2),$(call QUALIFY_LIB_REFS_1,$(1),$(2)))
QUALIFY_LIB_REFS_1 = $(call QUALIFY_LIB_REFS_2,$(1),$(SUFFIX_LIB_STATIC$(2)),$(SUFFIX_LIB_SHARED$(2)),$(LIB_DENOM$(2)))
QUALIFY_LIB_REFS_2 = $(patsubst noinst:%,noinst:%$(2),$(patsubst inst:%,inst:%$(3),$(patsubst lib:%,lib:%$(4),$(1))))

SELECT_LDFLAGS_OPTIM = $(filter-out ldflag-dbg:% ldflag-cov:%,$(1))
SELECT_LDFLAGS_DEBUG = $(patsubst ldflag-dbg:%,ldflag:%,$(filter-out ldflag:% ldflag-cov:%,$(1)))
SELECT_LDFLAGS_COVER = $(patsubst ldflag-cov:%,ldflag:%,$(filter-out ldflag:% ldflag-dbg:%,$(1)))

UNPACK_LIB_REFS = $(call FILTER_UNPACK,noinst:%,$(1)) $(call FILTER_PATSUBST,lib:%,-l%,$(1)) $(call FILTER_PATSUBST,dir:%,-L%,$(1)) $(call FILTER_UNPACK,ldflag:%,$(1))

GET_RPATHS_FROM_LIB_REFS = $(foreach x,$(call FILTER_UNPACK,rpath:%,$(1)),-Wl,-rpath,$(x))

# ARGS: origin_pattern, target_pattern, list
FILTER_PATSUBST = $(patsubst $(1),$(2),$(filter $(1),$(3)))

# ARGS: patterns, list
FILTER_UNPACK   = $(foreach x,$(2),$(call FILTER_UNPACK_1,$(call FIND,FILTER_UNPACK_2,$(1),$(x)),$(x)))
FILTER_UNPACK_1 = $(and $(1),$(patsubst $(1),%,$(2)))
FILTER_UNPACK_2 = $(filter $(1),$(2))

# ARGS: func, patterns, list, optional_arg
PATTERN_UNPACK_MAP   = $(foreach x,$(3),$(call PATTERN_UNPACK_MAP_1,$(1),$(call FIND,PATTERN_UNPACK_MAP_2,$(2),$(x)),$(x),$(4)))
PATTERN_UNPACK_MAP_1 = $(if $(2),$(patsubst %,$(2),$(call $(1),$(patsubst $(2),%,$(3)),$(4))),$(3))
PATTERN_UNPACK_MAP_2 = $(filter $(1),$(2))

# ARGS: qual_prog_name, objects, qualified_expanded_lib_refs, deps, link_cmd, ldflags
define NOINST_PROG_RULE
$(1): $(2) $(call FILTER_UNPACK,noinst:% inst:%,$(3)) $(4)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(call GET_RPATHS_FROM_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)
endef

# ARGS: qual_prog_name, objects, qualified_expanded_lib_refs, deps, link_cmd, ldflags
define INST_PROG_RULE
ifeq ($(filter rpath:%,$(3)),)
$(1): $(2) $(call FILTER_UNPACK,noinst:% inst:%,$(3)) $(4)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)
else
$(1) $(1)-noinst: $(2) $(call FILTER_UNPACK,noinst:% inst:%,$(3)) $(4)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(call GET_RPATHS_FROM_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)-noinst
endif
endef

define RECORD_TARGETS_FOR_OBJECT
GMK_$(call FOLD_TARGET,$(1))_TARGETS += $(2)
$(EMPTY)
endef

# ARGS: unqual_prog_name, expanded_lib_refs, deps
define NOINST_PROG_RULES
$(call NOINST_PROG_RULE,$(1)$(SUFFIX_PROG_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(call QUALIFY_LIB_REFS,$(2),_OPTIM),$(3),$(LD_PROG_OPTIM),$(call GET_LDFLAGS_FOR_TARGET,$(1),_OPTIM))
$(call NOINST_PROG_RULE,$(1)$(SUFFIX_PROG_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(call QUALIFY_LIB_REFS,$(2),_DEBUG),$(3),$(LD_PROG_DEBUG),$(call GET_LDFLAGS_FOR_TARGET,$(1),_DEBUG))
$(call NOINST_PROG_RULE,$(1)$(SUFFIX_PROG_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(call QUALIFY_LIB_REFS,$(2),_COVER),$(3),$(LD_PROG_COVER),$(call GET_LDFLAGS_FOR_TARGET,$(1),_COVER))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

# ARGS: unqual_target, expanded_lib_refs, deps
define INST_PROG_RULES
$(call INST_PROG_RULE,$(1)$(SUFFIX_PROG_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(call QUALIFY_LIB_REFS,$(2),_OPTIM),$(3),$(LD_PROG_OPTIM),$(call GET_LDFLAGS_FOR_TARGET,$(1),_OPTIM))
$(call INST_PROG_RULE,$(1)$(SUFFIX_PROG_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(call QUALIFY_LIB_REFS,$(2),_DEBUG),$(3),$(LD_PROG_DEBUG),$(call GET_LDFLAGS_FOR_TARGET,$(1),_DEBUG))
$(call INST_PROG_RULE,$(1)$(SUFFIX_PROG_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(call QUALIFY_LIB_REFS,$(2),_COVER),$(3),$(LD_PROG_COVER),$(call GET_LDFLAGS_FOR_TARGET,$(1),_COVER))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

$(foreach x,$(NOINST_PROGRAMS) $(TEST_PROGRAMS),$(eval $(call NOINST_PROG_RULES,$(x),$(call EXPAND_LIB_REFS,$(x)),$(call GET_DEPS_FOR_TARGET,$(x)))))
$(foreach x,$(INST_PROGRAMS),$(eval $(call INST_PROG_RULES,$(x),$(call EXPAND_LIB_REFS,$(x)),$(call GET_DEPS_FOR_TARGET,$(x)))))



# CREATING LIBRARIES

# ARGS: target, objects, deps
define STATIC_LIBRARY_RULE
$(1): $(2) $(3)
	$(strip $(AR) $(ARFLAGS_GENERAL)) $(1) $(2)
endef

# ARGS: qual_lib_name, objects, qualified_expanded_lib_refs, deps, link_cmd, ldflags
# FIXME: add -Wl,-soname
# FIXME: Add '-Wl,-rpath' if linking against locally built and installed libraries, but it requires us to know the library installation directory. Or maybe it is better to set LD_RUN_PATH.
define SHARED_LIBRARY_RULE
$(1): $(2) $(call FILTER_UNPACK,inst:%,$(3)) $(4)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(call GET_SPECIAL_SHARED_LIB_OPTS,$(1)) $(LDFLAGS_LIBRARY_PATH)) -o $(1)
endef

.PHONY: update-libdeps-files

define LIBDEPS_RULE
$(1).libdeps: $(DEP_MAKEFILES)
	echo $(2) >$(1).libdeps
update-libdeps-files: $(1).libdeps
endef

# ARGS: unqual_lib_name, deps
define NOINST_LIB_RULES
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(3))
$(call LIBDEPS_RULE,$(call GET_LIBRARY_NAME,$(1)),$(call MAKE_NOINST_LIB_LIBDEPS,$(1)))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

# ARGS: unqual_lib_name, expanded_lib_refs, deps
define INST_LIB_RULES
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(3))
$(call SHARED_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_SHARED_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_OPTIM)),$(call QUALIFY_LIB_REFS,$(2),_OPTIM),$(3),$(LD_LIB_OPTIM),$(call GET_LDFLAGS_FOR_TARGET,$(1),_OPTIM))
$(call SHARED_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_SHARED_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_DEBUG)),$(call QUALIFY_LIB_REFS,$(2),_DEBUG),$(3),$(LD_LIB_DEBUG),$(call GET_LDFLAGS_FOR_TARGET,$(1),_DEBUG))
$(call SHARED_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_SHARED_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_COVER)),$(call QUALIFY_LIB_REFS,$(2),_COVER),$(3),$(LD_LIB_COVER),$(call GET_LDFLAGS_FOR_TARGET,$(1),_COVER))
$(call LIBDEPS_RULE,$(call GET_LIBRARY_NAME,$(1)),$(call EXTRACT_INST_LIB_LIBDEPS,$(2)))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

$(foreach x,$(NOINST_LIBRARIES),$(eval $(call NOINST_LIB_RULES,$(x),$(call GET_DEPS_FOR_TARGET,$(x)))))
$(foreach x,$(INST_LIBRARIES),$(eval $(call INST_LIB_RULES,$(x),$(call EXPAND_LIB_REFS,$(x)),$(call GET_DEPS_FOR_TARGET,$(x)))))



# FLEX AND BISON

%.flex.cpp %.flex.hpp: %.flex $(DEP_MAKEFILES)
	flex --outfile=$*.flex.cpp --header-file=$*.flex.hpp $<

%.bison.cpp %.bison.hpp: %.bison $(DEP_MAKEFILES)
	bison --output=$*.bison.cpp --defines=$*.bison.hpp $<



# COMPILING + AUTOMATIC DEPENDENCIES

%$(SUFFIX_OBJ_STATIC_OPTIM): %.c
	$(strip $(CC_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_OPTIM): %.cpp
	$(strip $(CXX_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.c
	$(strip $(CC_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.cpp
	$(strip $(CXX_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_DEBUG): %.c
	$(strip $(CC_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_DEBUG): %.cpp
	$(strip $(CXX_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.c
	$(strip $(CC_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.cpp
	$(strip $(CXX_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_COVER): %.c
	$(strip $(CC_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_STATIC_COVER): %.cpp
	$(strip $(CXX_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.c
	$(strip $(CC_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.cpp
	$(strip $(CXX_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)



%$(SUFFIX_OBJ_STATIC_OPTIM): %.m
	$(strip $(OCC_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_OPTIM): %.mm
	$(strip $(OCXX_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.m
	$(strip $(OCC_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.mm
	$(strip $(OCXX_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,_OPTIM) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_DEBUG): %.m
	$(strip $(OCC_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_DEBUG): %.mm
	$(strip $(OCXX_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.m
	$(strip $(OCC_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.mm
	$(strip $(OCXX_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,_DEBUG) $(CFLAGS_ARCH) $(INC_FLAGS) $(CFLAGS_AUTODEP)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_COVER): %.m
	$(strip $(OCC_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_STATIC_COVER): %.mm
	$(strip $(OCXX_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.m
	$(strip $(OCC_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.mm
	$(strip $(OCXX_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,_COVER) $(CFLAGS_ARCH) $(INC_FLAGS_ABS) $(CFLAGS_AUTODEP)) -c $(abspath $<) -o $(abspath $@)


-include $(OBJECTS:.o=.d)
