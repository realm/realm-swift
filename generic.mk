# Generic makefile that captures some of the ideas of GNU Automake,
# especially with respect to naming targets.
#
# Author: Kristian Spangsege
#
# This makefile requires GNU Make. It has been tested with version
# 3.81, and it is known to work well on both Linux and OS X.
#
#
# Building installable programs and libraries
# -------------------------------------------
#
# Here is an example of a complete `Makefile` that uses `generic.mk`
# to build a program called `myprog` out of two source files called
# `foo.cpp` and `bar.cpp`:
#
#   bin_PROGRAMS = myprog
#   myprog_SOURCES = foo.cpp bar.cpp
#   include generic.mk
#
# The `bin` in `bin_PROGRAMS` means that your program will be
# installed in the directory specified by the `bindir` variable which
# is set to `/usr/local/bin` by default. This can be overridden by
# setting `prefix`, `exec_prefix`, or `bindir`.
#
# Note: You can place `generic.mk` anywhere you like inside your
# project, but you must always refer to it by a relative path, and if
# you have multiple `Makefile`s in multiple directories, they must all
# refer to the same `generic.mk`.
#
# Here is how to build a library:
#
#   lib_LIBRARIES = libfoo.a
#   libfoo_a_SOURCES = libfoo.cpp
#   INST_HEADERS = foo.hpp
#
# Again, the `lib` prefix in `lib_LIBRARIES` means that your library
# will be installed in the directory specified by the `libdir`
# variable which is typically set to `/usr/local/lib` by default. The
# exact default path depends on the chosen installation prefix as well
# as platform policies, for example, on a 64 bit Fedora, it will be
# `/usr/local/lib64`. This can be overridden by setting `prefix`,
# `exec_prefix`, or `libdir`.
#
# The `lib` prefix in `libfoo.a` is mandatory for all installed
# libraries. The `.a` suffix is mandatory for both installed an
# non-installed libraries. The actual extension of the installed
# library is not necessarily going to be `.a`. For a shared library on
# Linux, it will be `.so` by default. The important point is that the
# specified library name is a logical name that is mapped to one or
# more physical names by `generic.mk`.
#
# Note that `.` is replaced by `_` when referring to `libfoo.a` in
# `libfoo_a_SOURCES`. In general, when a target (program or library)
# name is used as part of a variable name, any character that is
# neither alphanumeric nor an underscore, is converted to an
# underscore.
#
# Installed libraries are generally accompanied by one or more headers
# to be included by applications that use the library. Such headers
# must be listed in the `INST_HEADERS` variable. Headers are installed
# in `/usr/local/include` by default, but this can be changed by
# setting the `prefix` or `includedir` variable. Note also that
# headers can be installed in a subdirectory of `/usr/local/include`
# or even into a multi-level hierarchy of subdirectories (see the
# 'Subdirectories' section for more on this).
#
# To build more than one program, or more than one library, simply
# list all of them in `bin_PROGRAMS` or `lib_LIBRARIES`. For
# example:
#
#   bin_PROGRAMS = hilbert banach
#   hilbert_SOURCES = ...
#   banach_SOURCES = ...
#
# Here is how to build a library as well as a program that uses the
# library:
#
#   lib_LIBRARIES = libmyparser.a
#   bin_PROGRAMS = parser
#   libmyparser_a_SOURCES = myparser.c
#   parser_SOURCES = parser.c
#   parser_LIBS = libmyparser.a
#
# I you have two libraries, and one depends on the other:
#
#   lib_LIBRARIES = libfoo.a libbar.a
#   libbar_a_LIBS = libfoo.a
#
# The installation directory for programs and libraries is determined
# by the primary prefix being used. Note that `PROGRAMS` and
# `LIBRARIES` are primaries, and that `bin` is a primary prefix in
# `bin_PROGRAMS`, for example. The following primary prefixes are
# supported directly by `generic.mk`:
#
#   Prefix    Variable     Default value
#   ------------------------------------------------------------------
#   bin       bindir       $(exec_prefix)/bin     (/usr/local/bin)
#   sbin      sbindir      $(exec_prefix)/sbin    (/usr/local/sbin)
#   lib       libdir       $(exec_prefix)/lib (*) (/usr/local/lib)
#   libexec   libexecdir   $(exec_prefix)/libexec (/usr/local/libexec)
#
#   (*) The actual default value depends on the platform.
#
# You can also install a program or a library into a non-default
# directory by defining a custom primary prefix. This is usefull when
# you want (for other purposes) to maintain the default values of the
# standard prefixes. Here is an example:
#
#   EXTRA_PRIMARY_PREFIXES = lib_home
#   lib_home_INSTALL_DIR = /usr/lib/mydeamon/bin
#   lib_home_PROGRAMS = mydaemon
#
# When doing 'filtered installs' (using `make install
# INSTALL_FILTER=...`) there is a distinction between two categories
# of programs, ordinary programs and 'developer programs'. When a
# project that provides a library gets distributed in compiled form,
# it is customary to offer two packages, the main one, that provides
# the shared library, and a secondary one that provides the header
# files. Some such projects offer programs that are packaged together
# with the shared library, and other programs that are packaged
# together with the headers. The latter category is what we refer to
# as 'developer programs' when working with filtered installs.
#
# To mark a program as a 'developer program' use the special primary
# prefix 'DEV' as in the following example:
#
#   DEV_PROGRAMS = mylib-config
#   mylib_config_SOURCES = ...
#
# These programs are installed into the same directory as
# `bin_PROGRAMS`.
#
#
# Convenience libraries
# ---------------------
#
# A convenience library is one that is not installed, but gets linked
# statically into programs that are built as part of the same
# project. Convenience libraries are created by using the special
# primary prefix `NOINST`, for example:
#
#   NOINST_LIBRARIES = util.a
#   bin_PROGRAMS = foo
#   foo_SOURCES = foo.cpp
#   foo_LIBS = util.a
#
# Note that in contrast to installed libraries, names of convenience
# libraries are not required to have `lib` as a prefix, but the `.a`
# suffix is still mandatory. Additionally, convenience library names
# do not have to be unique. Indeed, it is valid for a program to be
# linked against two convenience libraries of the same name, as long
# as they reside in different subdirectories within the
# project. Installed libraries, on the other hand, need to have
# system-wide unique names.
#
# It is an error to list a convenience library as a dependency of
# another convenience library or as a dependency of an installed
# library. Only programs can be declared to depend on convenience
# libraries.
#
# A convenience library such as `util.a` can be made to depend on
# project-local installed libraries by listing them in the
# `util_a_LIBS` variable. This can be done because code in `util.a`
# depends on those other libraries, or it can be done simply to avoid
# specifying them repeatedly for multiple programs. On top of that, it
# is possible to attach a set of extra linker flags to a convenience
# library, to be used when linking programs against it. Such flags are
# listed in `util_a_LDFLAGS`. This can be used, for example, to
# specify linking against system libraries or other separately
# installed libraries.
#
#
# Programs that should not be installed
# -------------------------------------
#
# Sometimes it is desirable to build a program that is not supposed to
# be installed when running `make install`. One reason could be that
# the program is used only for testing. Such programs are created by
# using the special primary prefix `NOINST`, for example:
#
#   NOINST_PROGRAMS = performance
#
# There is another related category of programs called 'test programs'
# that are both built and executed when running `make test`. These
# programs are created by using the `TEST` primary prefix, and are
# also not installed:
#
#   TEST_PROGRAMS = test_foo test_bar
#
# It is also possible to create a convenience library that is built
# only when 'test programs' are built. List libraries of this kind in
# `TEST_LIBRARIES`.
#
#
# Subdirectories
# --------------
#
# In larger projects it is desirable to organize the source files into
# multiple subdirectories. This can be done in two ways, using a
# single `Makefile` or using multiple `Makefile`s. When using a single
# `Makefile`, refer to the source files using relative paths as
# follows:
#
#   EXTRA_CLEAN_DIRS = foo bar
#   myprog_SOURCES = foo/alpha.cpp bar/beta.cpp
#
# Mentioning the involved subdirectories in `EXTRA_CLEAN_DIRS` is
# necessary and tells `generic.mk` to remove temporary files in those
# directories during `make clean`.
#
# The alternative is to use multiple `Makefile`s. This requires one or
# more subdirectories each one with an extra subordinate
# `Makefile`. The top-level `Makefile` must then use the `SUBDIRS`
# variable to list each of the involved subdirectories. When there is
# a dependency between two subdirectories, the top-level `Makefile`
# must declare this. Here is an example:
#
#   Makefile:
#     SUBDIRS = foo bar
#     bar_DEPS = foo
#     include generic.mk
#
#   foo/Makefile:
#     lib_LIBRARIES = util.a
#     util_a_SOURCES = ...
#     include ../generic.mk
#
#   bar/Makefile:
#     bin_PROGRAMS = myprog
#     myprog_SOURCES = ...
#     myprog_LIBS = ../foo/util.a
#
# To declare that a subdirectory `foo` depends on stuff in the current
# directory (presumably libraries), include `.` in `foo_DEPS`. To
# declare that the current directory depends on stuff in a
# subdirectory, list that subdirectory in the `DIR_DEPS` variable as
# in the following example:
#
#   Makefile:
#     SUBDIRS = util
#     DIR_DEPS = util
#     bin_PROGRAMS = myprog
#     myprog_SOURCES = ...
#     myprog_LIBS = util/util.a
#     include generic.mk
#
#   util/Makefile:
#     NOINST_LIBRARIES = util.a
#     util_a_SOURCES = ...
#     include ../generic.mk
#
# FIXME: Mention `PASSIVE_SUBDIRS` (such directories are cleaned but
# not otherwise included during recursive `make` invocations).
#
#
# Compiler and linker flags
# -------------------------
#
# Extra compiler and linker flags can be specified for each target
# (program or library):
#
#   bin_PROGRAMS = myprog
#   myprog_SOURCES = foo.cpp bar.cpp
#   myprog_CFLAGS = -Wno-long-long
#   myprog_LDFLAGS = -lparser
#
# Compiler flags can also be specified for individual object files,
# for example, to add flags just to the compilation of `foo.o`:
#
#   foo_o_CFLAGS = -I/opt/parser-1.5/include
#
# Compiler and linker flags can be specified for all targets in a
# directory (the directory containing the `Makefile`) as follows:
#
#   DIR_CFLAGS = ...
#   DIR_LDFLAGS = ...
#
# In a project that consists of multiple subprojects (each one in its
# own subdirectory and with its own `Makefile`,) compiler and linker
# flags can be specified for all targets in the project by setting
# `PROJECT_CFLAGS` and `PROJECT_LDFLAGS` in `config.mk`:
#
#   PROJECT_CFLAGS = ...
#   PROJECT_LDFLAGS = ...
#
# All these compiler and linker flag specifications are additive.
#
#
# Debug and coverage analysis modes
# ---------------------------------
#
#   foo_o_CFLAGS_OPTIM
#   foo_o_CFLAGS_DEBUG
#   foo_o_CFLAGS_COVER
#
#
# Library versioning
# ------------------
#
#   lib_LIBRARIES = libmyparser.a
#   libmyparser_a_VERSION = 4:0:0
#
# Format: CURRENT[:REVISION[:AGE]]
#
# At each new public release:
#   If the interface has changed at all:
#     Increment CURRENT and reset REVISION to zero
#     Let COMPAT be the least number such that the new library (in
#       its binary form) can be used as a drop-in replacement for
#       all previous releases whose CURRENT is greater than or equal
#       to COMPAT
#     If COMPAT + AGE < CURRENT:
#       Increment AGE
#     Else:
#       Reset AGE to zero
#   Else:
#     Increment REVISION
#
# The meaning of this version string is identical to the one defined
# by GNU Libtool. See also
# http://www.gnu.org/software/libtool/manual/libtool.html#Libtool-versioning
#
#
# Generated sources
# -----------------
#
# FIXME: Describe `GENERATED_SOURCES`.
#
#
# Configuration variables
# -----------------------
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
# include option (`-I`) is added to the compiler command
# line. Specifying it, also permits installation of headers. Headers
# will be installed under the same relative path as they have with
# respect to the directory specified here. Headers are marked for
# installation by adding them to the `INST_HEADERS` variable in the
# local `Makefile`.
SOURCE_ROOT =

CFLAGS_OPTIM          = -DNDEBUG
CFLAGS_DEBUG          =
CFLAGS_COVER          =
CFLAGS_SHARED         =
CFLAGS_PTHREAD        =
CFLAGS_GENERAL        =
CFLAGS_C              =
CFLAGS_CXX            =
CFLAGS_OBJC           =
CFLAGS_ARCH           =
CFLAGS_INCLUDE        =
CFLAGS_AUTODEP        =
LDFLAGS_OPTIM         = $(filter-out -D%,$(CFLAGS_OPTIM))
LDFLAGS_DEBUG         = $(filter-out -D%,$(CFLAGS_DEBUG))
LDFLAGS_COVER         = $(filter-out -D%,$(CFLAGS_COVER))
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

LIB_SUFFIX_STATIC     = .a
LIB_SUFFIX_SHARED     = .so
LIB_SUFFIX_LIBDEPS    = .libdeps

BASE_DENOM            =
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

# When set to an empty value, 'make install' will not install the
# static versions of the libraries mentioned in lib_LIBRARIES, and a
# plain 'make' will not even build them. When set to a nonempty value,
# the opposite is true.
ENABLE_INSTALL_STATIC_LIBS =

# When set to an empty value, 'make install' will not install the
# debug versions of the libraries mentioned in lib_LIBRARIES, and a
# plain 'make' will not even build them. When set to a nonempty value,
# the opposite is true.
ENABLE_INSTALL_DEBUG_LIBS =

# When set to an empty value, 'make install' will not install the
# debug versions of the programs mentioned in bin_PROGRAMS, and a
# plain 'make' will not even build them. When set to a nonempty value,
# the opposite is true.
ENABLE_INSTALL_DEBUG_PROGS =

# Use this if you want to install only a subset of what is usually
# installed. For example, to produce a separate binary and development
# package for a library product, you can run 'make install
# INSTALL_FILTER=shared-libs,progs' for the binary package and 'make
# install INSTALL_FILTER=static-libs,dev-progs,headers' for the
# development package. This filter also affects 'uninstall', but note
# that 'uninstall' makes no attempt to uninstall headers, instead it
# invokes a custom target 'uninstall/extra' if 'extra' is included in
# the filter. It is then up to the application to decide what actions
# to take on 'uninstall/extra'.
INSTALL_FILTER = shared-libs,static-libs,progs,dev-progs,headers,extra

# Installation (GNU style)
prefix          = /usr/local
exec_prefix     = $(prefix)
includedir      = $(prefix)/include
bindir          = $(exec_prefix)/bin
sbindir         = $(exec_prefix)/sbin
libdir          = $(if $(USE_LIB64),$(exec_prefix)/lib64,$(exec_prefix)/lib)
libexecdir      = $(exec_prefix)/libexec
INSTALL         = install
INSTALL_DIR     = $(INSTALL) -d
INSTALL_DATA    = $(INSTALL) -m 644
INSTALL_LIBRARY = $(INSTALL) -m 644
INSTALL_PROGRAM = $(INSTALL)

# Alternative filesystem root for installation
DESTDIR =



# UTILITY FUNCTIONS

EMPTY =
SPACE = $(EMPTY) $(EMPTY)
COMMA = ,
EQUALS = $(if $(word 2,$(sort $(1) $(2))),,$(1))
COND_PREPEND = $(if $(2),$(1)$(2))
COND_APPEND = $(if $(1),$(1)$(2))
# ARGS: predicate, list, optional_arg
# Expands to first matching entry
FIND = $(call FIND_1,$(1),$(strip $(2)),$(3))
FIND_1 = $(if $(2),$(call FIND_2,$(1),$(2),$(3),$(word 1,$(2))))
FIND_2 = $(if $(call $(1),$(4),$(3)),$(4),$(call FIND_1,$(1),$(wordlist 2,$(words $(2)),$(2)),$(3)))
# ARGS: func, init_accum, list
FOLD_LEFT = $(call FOLD_LEFT_1,$(1),$(2),$(strip $(3)))
FOLD_LEFT_1 = $(if $(3),$(call FOLD_LEFT_1,$(1),$(call $(1),$(2),$(word 1,$(3))),$(wordlist 2,$(words $(3)),$(3))),$(2))
UNION = $(call FOLD_LEFT,UNION_1,$(1),$(2))
UNION_1 = $(if $(call FIND,EQUALS,$(1),$(2)),$(1),$(1) $(2))
# If `a` and `b` are relative or absolute paths (without a final
# slash), and `b` points to a directory, then PATH_DIFF(a,b) expands
# to the relative path from `b` to `a`. If abspath(a) and abspath(b)
# are the same path, then PATH_DIFF(a,b) expands to the empty string.
PATH_DIFF = $(call PATH_DIFF_1,$(subst /,$(SPACE),$(abspath $(1))),$(subst /,$(SPACE),$(abspath $(2))))
PATH_DIFF_1 = $(if $(and $(1),$(2),$(call EQUALS,$(word 1,$(1)),$(word 1,$(2)))),$(call PATH_DIFF_1,$(wordlist 2,$(words $(1)),$(1)),$(wordlist 2,$(words $(2)),$(2))),$(subst $(SPACE),/,$(strip $(patsubst %,..,$(2)) $(1))))
# If `p` is already an absolute path, then MAKE_ABS_PATH(p,base)
# expands to `p`. Otherwise it exands to abspath(base/p). If `base` is
# unspecified, it defaults to `.`.
MAKE_ABS_PATH = $(if $(filter /%,$(1)),$(1),$(abspath $(or $(2),.)/$(1)))
# If `p` and `base` are paths, then MAKE_REL_PATH(p,base) expands to
# the relative path from abspath(base) to abspath(p). If the two paths
# are equal, it expands to `.`. If `base` is unspecified, it defaults
# to `.`.
MAKE_REL_PATH = $(or $(call PATH_DIFF,$(1),$(or $(2),.)),.)
IN_THIS_DIR = $(call EQUALS,$(realpath $(dir $(1))),$(realpath ./))
HAVE_CMD = $(shell which $(1))
MATCH_CMD = $(filter $(1) $(1)-%,$(notdir $(2)))
MAP_CMD = $(if $(call MATCH_CMD,$(1),$(3)),$(if $(findstring /,$(3)),$(dir $(3)))$(patsubst $(1)%,$(2)%,$(notdir $(3))))
CAT_OPT_FILE = $(and $(wildcard $(1)),$(shell cat $(1)))

define NEW_RECIPE
$(EMPTY)
	$(EMPTY)
endef

# Library for non-negative integer arithmetic.
#
# Note: It is an error if a numeric (unencoded) argument is greater
# than 65536.
#
# This implementation is an adaptation of John Graham-Cumming's work at
# http://www.cmcrossroads.com/article/learning-gnu-make-functions-arithmetic
INT_ADD = $(call INT_DEC,$(call INT_ADD_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2))))
INT_SUB = $(call INT_DEC,$(call INT_SUB_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2))))
INT_MUL = $(call INT_DEC,$(call INT_MUL_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2))))
INT_DIV = $(call INT_DEC,$(call INT_DIV_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2))))
INT_MAX = $(call INT_DEC,$(call INT_MAX_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2))))
INT_MIN = $(call INT_DEC,$(call INT_MIN_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2))))
INT_EQ  = $(call INT_EQ_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2)))
INT_NE  = $(call INT_NE_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2)))
INT_GT  = $(call INT_GT_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2)))
INT_LT  = $(call INT_LT_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2)))
INT_GTE = $(call INT_GTE_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2)))
INT_LTE = $(call INT_LTE_E,$(call INT_ENC,$(1)),$(call INT_ENC,$(2)))
INT_ADD_E = $(1) $(2)
INT_SUB_E = $(if $(call INT_GTE_E,$(1),$(2)),$(filter-out xx,$(join $(1),$(2))),$(error Subtraction underflow))
INT_MUL_E = $(foreach a,$(1),$(2))
INT_DIV_E = $(if $(filter-out $(words $(2)),0),$(call INT_DIV_2,$(1),$(2)),$(error Division by zero))
INT_DIV_2 = $(if $(call INT_GTE_E,$(1),$(2)),x $(call INT_DIV_2,$(call INT_SUB_E,$(1),$(2)),$(2)))
INT_MAX_E = $(subst xx,x,$(join $(1),$(2)))
INT_MIN_E = $(subst xx,x,$(filter xx,$(join $(1),$(2))))
INT_EQ_E  = $(filter $(words $(1)),$(words $(2)))
INT_NE_E  = $(filter-out $(words $(1)),$(words $(2)))
INT_GT_E  = $(filter-out $(words $(2)),$(words $(call INT_MAX_E,$(1),$(2))))
INT_LT_E  = $(filter-out $(words $(1)),$(words $(call INT_MAX_E,$(1),$(2))))
INT_GTE_E = $(call INT_GT_E,$(1),$(2))$(call INT_EQ_E,$(1),$(2))
INT_LTE_E = $(call INT_LT_E,$(1),$(2))$(call INT_EQ_E,$(1),$(2))
# More efficient increment / decrement
INT_INC_E = $(1) x
INT_DEC_E = $(wordlist 2,$(words $(1)),$(1))
# More efficient double / halve
INT_DBL_E = $(1) $(1)
INT_HLV_E = $(subst xx,x,$(filter-out xy x y,$(join $(1),$(foreach a,$(1),y x))))
# Encode / decode
INT_DEC = $(words $(1))
INT_ENC = $(wordlist 1,$(1),$(INT_65536))
INT_16    := x x x x x x x x x x x x x x x
INT_65536 := $(foreach a,$(INT_16),$(foreach b,$(INT_16),$(foreach c,$(INT_16),$(INT_16))))



# PLATFORM SPECIFICS

OS   := $(shell uname)
ARCH := $(shell uname -m)

ifeq ($(OS),Darwin)
LIB_SUFFIX_SHARED = .dylib
endif

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
CFLAGS_OPTIM   = -O3 -DNDEBUG
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
LD_SPECIFIED = $(filter-out undefined default,$(origin LD))
ifeq ($(LD_SPECIFIED),)
LD := $(CXX)
endif
endif
LD_IS_GCC_LIKE = $(or $(call IS_GCC_LIKE,$(LD)),$(call IS_GXX_LIKE,$(LD)))
ifneq ($(LD_IS_GCC_LIKE),)
LDFLAGS_SHARED = -shared
endif

LDFLAGS_LIBRARY_PATH =

# Work-around for CLANG < v3.2 ignoring LIBRARY_PATH
LD_IS_CLANG = $(or $(call MATCH_CMD,clang,$(LD)),$(call MATCH_CMD,clang++,$(LD)))
ifneq ($(LD_IS_CLANG),)
CLANG_VERSION := $(shell printf '\#ifdef __clang__\n\#if defined __clang_major__ && defined __clang_minor__\n__clang_major__ __clang_minor__\n\#else\n0 0\n\#endif\n\#endif' | $(LD) -E - | grep -v -e '^\#' -e '^$$')
ifneq ($(CLANG_VERSION),)
CLANG_MAJOR = $(word 1,$(CLANG_VERSION))
CLANG_MINOR = $(word 2,$(CLANG_VERSION))
ifeq ($(shell echo $$(($(CLANG_MAJOR) < 3 || ($(CLANG_MAJOR) == 3 && $(CLANG_MINOR) < 2)))),1)
LDFLAGS_LIBRARY_PATH = $(foreach x,$(subst :,$(SPACE),$(LIBRARY_PATH)),-L$(x))
endif
endif
endif



# LOAD PROJECT SPECIFIC CONFIGURATION

EXTRA_CFLAGS  =
EXTRA_LDFLAGS =

CC_CXX_AND_LD_ARE = $(call CC_CXX_AND_LD_ARE_1,$(1),$(call MAP_CC_TO_CXX,$(1)))
CC_CXX_AND_LD_ARE_1 = $(and $(call MATCH_CMD,$(1),$(CC)),$(strip $(foreach x,$(1) $(2),$(call MATCH_CMD,$(x),$(CXX)))),$(strip $(foreach x,$(1) $(2),$(call MATCH_CMD,$(x),$(LD)))))
CC_CXX_AND_LD_ARE_GCC_LIKE = $(strip $(foreach x,$(GCC_LIKE_COMPILERS),$(call CC_CXX_AND_LD_ARE,$(x))))

GENERIC_MK := $(lastword $(MAKEFILE_LIST))
GENERIC_MK_DIR = $(abspath $(patsubst %/,%,$(dir $(GENERIC_MK))))
CONFIG_MK = $(call MAKE_REL_PATH,$(GENERIC_MK_DIR)/config.mk)
DEP_MAKEFILES = Makefile $(GENERIC_MK)
ifneq ($(wildcard $(CONFIG_MK)),)
DEP_MAKEFILES += $(CONFIG_MK)
endif
-include $(CONFIG_MK)

ifneq ($(SOURCE_ROOT),)
ABS_SOURCE_ROOT = $(abspath $(GENERIC_MK_DIR)/$(SOURCE_ROOT))
REL_SOURCE_ROOT = $(call MAKE_REL_PATH,$(ABS_SOURCE_ROOT))
endif


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
CFLAGS_GENERAL  += $(EXTRA_CFLAGS)
LDFLAGS_GENERAL += $(EXTRA_LDFLAGS)

CC_STATIC_OPTIM   = $(CC) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C)
CC_SHARED_OPTIM   = $(CC) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C)
CC_STATIC_DEBUG   = $(CC) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C)
CC_SHARED_DEBUG   = $(CC) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C)
CC_STATIC_COVER   = $(CC) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C)
CC_SHARED_COVER   = $(CC) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C)

CXX_STATIC_OPTIM  = $(CXX) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_CXX)
CXX_SHARED_OPTIM  = $(CXX) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_CXX)
CXX_STATIC_DEBUG  = $(CXX) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_CXX)
CXX_SHARED_DEBUG  = $(CXX) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_CXX)
CXX_STATIC_COVER  = $(CXX) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_CXX)
CXX_SHARED_COVER  = $(CXX) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_CXX)

OCC_STATIC_OPTIM  = $(OCC) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C) $(CFLAGS_OBJC)
OCC_SHARED_OPTIM  = $(OCC) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C) $(CFLAGS_OBJC)
OCC_STATIC_DEBUG  = $(OCC) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C) $(CFLAGS_OBJC)
OCC_SHARED_DEBUG  = $(OCC) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C) $(CFLAGS_OBJC)
OCC_STATIC_COVER  = $(OCC) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C) $(CFLAGS_OBJC)
OCC_SHARED_COVER  = $(OCC) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_C) $(CFLAGS_OBJC)

OCXX_STATIC_OPTIM = $(OCXX) $(CFLAGS_OPTIM) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_OBJC) $(CFLAGS_CXX)
OCXX_SHARED_OPTIM = $(OCXX) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_OBJC) $(CFLAGS_CXX)
OCXX_STATIC_DEBUG = $(OCXX) $(CFLAGS_DEBUG) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_OBJC) $(CFLAGS_CXX)
OCXX_SHARED_DEBUG = $(OCXX) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_OBJC) $(CFLAGS_CXX)
OCXX_STATIC_COVER = $(OCXX) $(CFLAGS_COVER) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_OBJC) $(CFLAGS_CXX)
OCXX_SHARED_COVER = $(OCXX) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREAD) $(CFLAGS_GENERAL) $(CFLAGS_OBJC) $(CFLAGS_CXX)

LD_LIB_OPTIM      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_OPTIM) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_LIB_DEBUG      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_DEBUG) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_LIB_COVER      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_COVER) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_PROG_OPTIM     = $(LD) $(LDFLAGS_OPTIM) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_PROG_DEBUG     = $(LD) $(LDFLAGS_DEBUG) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)
LD_PROG_COVER     = $(LD) $(LDFLAGS_COVER) $(LDFLAGS_PTHREAD) $(LDFLAGS_GENERAL)



BASE_DENOM_2            = $(if $(BASE_DENOM),-$(BASE_DENOM))
SUFFIX_OBJ_STATIC_OPTIM = $(BASE_DENOM_2)$(OBJ_DENOM_OPTIM).o
SUFFIX_OBJ_SHARED_OPTIM = $(BASE_DENOM_2)$(OBJ_DENOM_OPTIM)$(OBJ_DENOM_SHARED).o
SUFFIX_OBJ_STATIC_DEBUG = $(BASE_DENOM_2)$(OBJ_DENOM_DEBUG).o
SUFFIX_OBJ_SHARED_DEBUG = $(BASE_DENOM_2)$(OBJ_DENOM_DEBUG)$(OBJ_DENOM_SHARED).o
SUFFIX_OBJ_STATIC_COVER = $(BASE_DENOM_2)$(OBJ_DENOM_COVER).o
SUFFIX_OBJ_SHARED_COVER = $(BASE_DENOM_2)$(OBJ_DENOM_COVER)$(OBJ_DENOM_SHARED).o
SUFFIX_LIB_STATIC_OPTIM = $(BASE_DENOM_2)$(LIB_DENOM_OPTIM)$(LIB_SUFFIX_STATIC)
SUFFIX_LIB_SHARED_OPTIM = $(BASE_DENOM_2)$(LIB_DENOM_OPTIM)$(LIB_SUFFIX_SHARED)
SUFFIX_LIB_STATIC_DEBUG = $(BASE_DENOM_2)$(LIB_DENOM_DEBUG)$(LIB_SUFFIX_STATIC)
SUFFIX_LIB_SHARED_DEBUG = $(BASE_DENOM_2)$(LIB_DENOM_DEBUG)$(LIB_SUFFIX_SHARED)
SUFFIX_LIB_STATIC_COVER = $(BASE_DENOM_2)$(LIB_DENOM_COVER)$(LIB_SUFFIX_STATIC)
SUFFIX_LIB_SHARED_COVER = $(BASE_DENOM_2)$(LIB_DENOM_COVER)$(LIB_SUFFIX_SHARED)
SUFFIX_PROG_OPTIM       = $(BASE_DENOM_2)$(PROG_DENOM_OPTIM)
SUFFIX_PROG_DEBUG       = $(BASE_DENOM_2)$(PROG_DENOM_DEBUG)
SUFFIX_PROG_COVER       = $(BASE_DENOM_2)$(PROG_DENOM_COVER)

GET_FLAGS = $($(1)) $($(1)$(2))
FOLD_TARGET = $(subst /,_,$(subst .,_,$(subst -,_,$(1))))
GET_LIBRARY_NAME = $(patsubst %.a,%,$(1))
GET_OBJECTS_FROM_SOURCES = $(patsubst %.c,%$(2),$(patsubst %.cpp,%$(2),$(patsubst %.m,%$(2),$(patsubst %.mm,%$(2),$(1)))))
GET_OBJECTS_FOR_TARGET   = $(call GET_OBJECTS_FROM_SOURCES,$($(call FOLD_TARGET,$(1))_SOURCES),$(2))
GET_CFLAGS_FOR_TARGET    = $(foreach x,PROJECT DIR $(foreach y,$(GMK_$(call FOLD_TARGET,$(1))_TARGETS) $(1),$(call FOLD_TARGET,$(y))),$(call GET_FLAGS,$(x)_CFLAGS,$(2)))
GET_LDFLAGS_FOR_TARGET   = $(foreach x,PROJECT DIR $(call FOLD_TARGET,$(1)),$(call GET_FLAGS,$(x)_LDFLAGS,$(2)))
GET_DEPS_FOR_TARGET      = $($(call FOLD_TARGET,$(1))_DEPS)
GET_VERSION_FOR_TARGET   = $(call GET_VERSION_FOR_TARGET_2,$(strip $($(call FOLD_TARGET,$(1))_VERSION)))
GET_VERSION_FOR_TARGET_2 = $(if $(1),$(wordlist 1,3,$(subst :, ,$(1):0:0)))

INC_FLAGS         = $(CFLAGS_INCLUDE)
INC_FLAGS_ABS     = $(CFLAGS_INCLUDE)
ifneq ($(SOURCE_ROOT),)
INC_FLAGS        += -I$(REL_SOURCE_ROOT)
INC_FLAGS_ABS    += -I$(ABS_SOURCE_ROOT)
endif

PRIMARY_PREFIXES = bin sbin lib libexec $(EXTRA_PRIMARY_PREFIXES)

bin_INSTALL_DIR     = $(bindir)
sbin_INSTALL_DIR    = $(sbindir)
lib_INSTALL_DIR     = $(libdir)
libexec_INSTALL_DIR = $(libexecdir)

# ARGS: primary_prefix
GET_INSTALL_DIR = $(if $(strip $($(1)_INSTALL_DIR)),$(DESTDIR)$(strip $($(1)_INSTALL_DIR)),$(error No INSTALL_DIR defined for primary prefix '$(1)'))

# ARGS: primary_prefix, install_dir
define RECORD_LIB_INSTALL_DIR
$(foreach x,$($(1)_LIBRARIES),GMK_$(call FOLD_TARGET,$(x))_INSTALL_DIR = $(2)
)
endef

define RECORD_LIB_INSTALL_DIRS
$(foreach x,$(PRIMARY_PREFIXES),$(call RECORD_LIB_INSTALL_DIR,$(x),$(call GET_INSTALL_DIR,$(x)))
)
endef

$(eval $(RECORD_LIB_INSTALL_DIRS))

# ARGS: installable_target
GET_INSTALL_DIR_FOR_TARGET = $(GMK_$(call FOLD_TARGET,$(1))_INSTALL_DIR)

INST_LIBRARIES = $(strip $(foreach x,$(PRIMARY_PREFIXES),$($(x)_LIBRARIES)))
INST_PROGRAMS  = $(strip $(foreach x,$(PRIMARY_PREFIXES),$($(x)_PROGRAMS)))

LIBRARIES = $(INST_LIBRARIES) $(NOINST_LIBRARIES) $(TEST_LIBRARIES)
PROGRAMS  = $(INST_PROGRAMS) $(DEV_PROGRAMS) $(NOINST_PROGRAMS) $(TEST_PROGRAMS)

OBJECTS_STATIC_OPTIM = $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_OPTIM)))
OBJECTS_SHARED_OPTIM = $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_OPTIM)))
OBJECTS_STATIC_DEBUG = $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_DEBUG)))
OBJECTS_SHARED_DEBUG = $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_DEBUG)))
OBJECTS_STATIC_COVER = $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_COVER)))
OBJECTS_SHARED_COVER = $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_COVER)))
OBJECTS = $(sort $(OBJECTS_STATIC_OPTIM) $(OBJECTS_SHARED_OPTIM) $(OBJECTS_STATIC_DEBUG) $(OBJECTS_SHARED_DEBUG) $(OBJECTS_STATIC_COVER) $(OBJECTS_SHARED_COVER))

TARGETS_LIB_STATIC_OPTIM   = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_LIB_SHARED_OPTIM   = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_SHARED_OPTIM))
TARGETS_LIB_STATIC_DEBUG   = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_LIB_SHARED_DEBUG   = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_SHARED_DEBUG))
TARGETS_LIB_STATIC_COVER   = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_LIB_SHARED_COVER   = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_SHARED_COVER))
TARGETS_INST_LIB_LIBDEPS   = $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(LIB_SUFFIX_LIBDEPS))
TARGETS_NOINST_LIB_OPTIM   = $(foreach x,$(NOINST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_NOINST_LIB_DEBUG   = $(foreach x,$(NOINST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_NOINST_LIB_COVER   = $(foreach x,$(NOINST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_NOINST_LIB_LIBDEPS = $(foreach x,$(NOINST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(LIB_SUFFIX_LIBDEPS))
TARGETS_TEST_LIB_OPTIM     = $(foreach x,$(TEST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_TEST_LIB_DEBUG     = $(foreach x,$(TEST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_TEST_LIB_COVER     = $(foreach x,$(TEST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_TEST_LIB_LIBDEPS   = $(foreach x,$(TEST_LIBRARIES),$(call GET_LIBRARY_NAME,$(x))$(LIB_SUFFIX_LIBDEPS))
TARGETS_PROG_OPTIM         = $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_PROG_DEBUG         = $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_PROG_COVER         = $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))
TARGETS_DEV_PROG_OPTIM     = $(foreach x,$(DEV_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_DEV_PROG_DEBUG     = $(foreach x,$(DEV_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_NOINST_PROG_OPTIM  = $(foreach x,$(NOINST_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_NOINST_PROG_DEBUG  = $(foreach x,$(NOINST_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_NOINST_PROG_COVER  = $(foreach x,$(NOINST_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))
TARGETS_TEST_PROG_OPTIM    = $(foreach x,$(TEST_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_TEST_PROG_DEBUG    = $(foreach x,$(TEST_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_TEST_PROG_COVER    = $(foreach x,$(TEST_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))

TARGETS_DEFAULT     =
ifneq ($(ENABLE_INSTALL_STATIC_LIBS),)
TARGETS_DEFAULT    += $(TARGETS_LIB_STATIC_OPTIM)
endif
TARGETS_DEFAULT    += $(TARGETS_LIB_SHARED_OPTIM)
ifneq ($(or $(ENABLE_INSTALL_DEBUG_LIBS),$(ENABLE_INSTALL_DEBUG_PROGS)),)
TARGETS_DEFAULT    += $(TARGETS_LIB_SHARED_DEBUG)
endif
TARGETS_DEFAULT    += $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_DEFAULT    += $(TARGETS_NOINST_LIB_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_PROGS),)
TARGETS_DEFAULT    += $(TARGETS_NOINST_LIB_DEBUG)
endif
TARGETS_DEFAULT    += $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_DEFAULT    += $(TARGETS_PROG_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_PROGS),)
TARGETS_DEFAULT    += $(TARGETS_PROG_DEBUG)
endif
TARGETS_DEFAULT    += $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG) $(TARGETS_NOINST_PROG_OPTIM)

TARGETS_MINIMAL     = $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_MINIMAL    += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_MINIMAL    += $(TARGETS_PROG_OPTIM) $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_NOINST_PROG_OPTIM)
TARGETS_NODEBUG     = $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_NODEBUG    += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_NODEBUG    += $(TARGETS_PROG_OPTIM) $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_NOINST_PROG_OPTIM)
TARGETS_DEBUG       = $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_DEBUG      += $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_DEBUG      += $(TARGETS_PROG_DEBUG) $(TARGETS_DEV_PROG_DEBUG) $(TARGETS_NOINST_PROG_DEBUG)
TARGETS_COVER       = $(TARGETS_LIB_SHARED_COVER) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_COVER      += $(TARGETS_NOINST_LIB_COVER) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_COVER      += $(TARGETS_PROG_COVER) $(TARGETS_NOINST_PROG_COVER)
TARGETS_TEST        = $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_TEST       += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_TEST       += $(TARGETS_TEST_LIB_OPTIM) $(TARGETS_TEST_LIB_LIBDEPS)
TARGETS_TEST       += $(TARGETS_PROG_OPTIM) $(TARGETS_TEST_PROG_OPTIM)
TARGETS_TEST_DEBUG  = $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_TEST_DEBUG += $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_TEST_DEBUG += $(TARGETS_TEST_LIB_DEBUG) $(TARGETS_TEST_LIB_LIBDEPS)
TARGETS_TEST_DEBUG += $(TARGETS_PROG_DEBUG) $(TARGETS_TEST_PROG_DEBUG)
TARGETS_TEST_COVER  = $(TARGETS_LIB_SHARED_COVER) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_TEST_COVER += $(TARGETS_NOINST_LIB_COVER) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_TEST_COVER += $(TARGETS_TEST_LIB_COVER) $(TARGETS_TEST_LIB_LIBDEPS)
TARGETS_TEST_COVER += $(TARGETS_PROG_COVER) $(TARGETS_TEST_PROG_COVER)

TARGETS_EVERYTHING  = $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_OPTIM)
TARGETS_EVERYTHING += $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_EVERYTHING += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_EVERYTHING += $(TARGETS_TEST_LIB_OPTIM) $(TARGETS_TEST_LIB_DEBUG) $(TARGETS_TEST_LIB_LIBDEPS)
TARGETS_EVERYTHING += $(TARGETS_PROG_OPTIM) $(TARGETS_PROG_DEBUG)
TARGETS_EVERYTHING += $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG)
TARGETS_EVERYTHING += $(TARGETS_NOINST_PROG_OPTIM) $(TARGETS_NOINST_PROG_DEBUG)
TARGETS_EVERYTHING += $(TARGETS_TEST_PROG_OPTIM) $(TARGETS_TEST_PROG_DEBUG)

TARGETS_LIB_STATIC  = $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_STATIC_DEBUG) $(TARGETS_LIB_STATIC_COVER)
TARGETS_LIB_SHARED  = $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_LIB_SHARED_COVER)
TARGETS_NOINST_LIB  = $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_COVER)
TARGETS_TEST_LIB    = $(TARGETS_TEST_LIB_OPTIM) $(TARGETS_TEST_LIB_DEBUG) $(TARGETS_TEST_LIB_COVER)
TARGETS_PROG        = $(TARGETS_PROG_OPTIM) $(TARGETS_PROG_DEBUG) $(TARGETS_PROG_COVER)
TARGETS_DEV_PROG    = $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG)
TARGETS_NOINST_PROG = $(TARGETS_NOINST_PROG_OPTIM) $(TARGETS_NOINST_PROG_DEBUG) $(TARGETS_NOINST_PROG_COVER)
TARGETS_TEST_PROG   = $(TARGETS_TEST_PROG_OPTIM) $(TARGETS_TEST_PROG_DEBUG) $(TARGETS_TEST_PROG_COVER)
TARGETS_PROG_ALL    = $(foreach x,$(TARGETS_PROG) $(TARGETS_DEV_PROG),$(x) $(x)-noinst) $(TARGETS_NOINST_PROG) $(TARGETS_TEST_PROG)

TARGETS_LIB_SHARED_ALIASES   = $(foreach x,$(INST_LIBRARIES),$(foreach y,OPTIM DEBUG COVER,$(call TARGETS_LIB_SHARED_ALIASES_2,$(x),$(SUFFIX_LIB_SHARED_$(y)))))
TARGETS_LIB_SHARED_ALIASES_2 = $(call GET_SHARED_LIB_ALIASES,$(call GET_LIBRARY_NAME,$(1))$(2),$(call GET_VERSION_FOR_TARGET,$(1)))

TARGETS  = $(TARGETS_LIB_STATIC) $(TARGETS_LIB_SHARED_ALIASES) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS += $(TARGETS_NOINST_LIB) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS += $(TARGETS_TEST_LIB) $(TARGETS_TEST_LIB_LIBDEPS) $(TARGETS_PROG_ALL)

# ARGS: qual_name, version
GET_SHARED_LIB_ALIASES = $(1)

ifeq ($(OS),Linux)

GET_SHARED_LIB_ALIASES   = $(if $(2),$(call GET_SHARED_LIB_ALIASES_2,$(1),$(call MAP_SHARED_LIB_VERSION,$(2))),$(1))
GET_SHARED_LIB_ALIASES_2 = $(1) $(1).$(word 1,$(2)) $(1).$(word 2,$(2))

MAP_SHARED_LIB_VERSION   = $(call MAP_SHARED_LIB_VERSION_2,$(word 1,$(1)),$(word 2,$(1)),$(word 3,$(1)))
MAP_SHARED_LIB_VERSION_2 = $(call MAP_SHARED_LIB_VERSION_3,$(call INT_SUB,$(1),$(3)),$(3),$(2))
MAP_SHARED_LIB_VERSION_3 = $(1) $(1).$(2).$(3)

endif

ifeq ($(OS),Darwin)

GET_SHARED_LIB_ALIASES = $(if $(2),$(1) $(word 1,$(call MAP_SHARED_LIB_VERSION,$(1),$(2))),$(1))

MAP_SHARED_LIB_VERSION   = $(call MAP_SHARED_LIB_VERSION_2,$(1),$(word 1,$(2)),$(word 2,$(2)),$(word 3,$(2)))
MAP_SHARED_LIB_VERSION_2 = $(call MAP_SHARED_LIB_VERSION_3,$(1),$(call INT_SUB,$(2),$(4)),$(call INT_ADD,$(2),1),$(3))
MAP_SHARED_LIB_VERSION_3 = $(patsubst %.dylib,%,$(1)).$(2).dylib $(3) $(3).$(4)

endif

RECURSIVE_MODES = default minimal nodebug debug cover everything clean install-only uninstall test-norun test-debug-norun test test-debug test-cover memtest memtest-debug

.PHONY: all
all: default

default/local:          $(TARGETS_DEFAULT)
minimal/local:          $(TARGETS_MINIMAL)
nodebug/local:          $(TARGETS_NODEBUG)
debug/local:            $(TARGETS_DEBUG)
cover/local:            $(TARGETS_COVER)
everything/local:       $(TARGETS_EVERYTHING)
test-norun/local:       $(TARGETS_TEST)
test-debug-norun/local: $(TARGETS_TEST_DEBUG)


# Update everything if any makefile or any generated source has changed
$(GENERATED_SOURCES) $(OBJECTS) $(TARGETS): $(DEP_MAKEFILES)
$(OBJECTS): $(GENERATED_SOURCES)

# Disable all suffix rules and some interfering implicit pattern rules
.SUFFIXES:
%: %.o
%: %.c
%: %.cpp



# SUBDIRECTORIES

# ARGS: mode, dep
define LOCAL_DIR_DEP_RULE
$(1)/this-dir: $(1)/subdir/$(2)
endef

# ARGS: subdir, mode, dep
define SUBDIR_DEP_RULE
ifeq ($(3),.)
$(2)/subdir/$(1): $(2)/this-dir
else
$(2)/subdir/$(1): $(2)/subdir/$(3)
endif
endef

# ARGS: mode
GET_LOCAL_DIR_DEPS = $(if $(filter clean install-only,$(1)),,$(if $(filter uninstall,$(1)),$(SUBDIRS),$(DIR_DEPS)))

# ARGS: subdir, mode
GET_SUBDIR_DEPS = $(if $(filter clean uninstall,$(2)),,$(if $(filter install-only,$(2)),.,$($(call FOLD_TARGET,$(1))_DEPS)))

# ARGS: subdir, mode
define SUBDIR_MODE_RULES
.PHONY: $(2)/subdir/$(1)
$(foreach x,$(call GET_SUBDIR_DEPS,$(1),$(2)),$(call SUBDIR_DEP_RULE,$(1),$(2),$(x))
)
ifeq ($(2),default)
$(2)/subdir/$(1):
	@$$(MAKE) -w -C $(1)
else
$(2)/subdir/$(1):
	@$$(MAKE) -w -C $(1) $(2)
endif
endef

AVAIL_PASSIVE_SUBDIRS = $(foreach x,$(PASSIVE_SUBDIRS),$(if $(realpath $(x)),$(x)))

# ARGS: mode
GET_SUBDIRS_FOR_MODE = $(if $(filter clean,$(1)),$(SUBDIRS) $(AVAIL_PASSIVE_SUBDIRS),$(SUBDIRS))

# ARGS: mode
define RECURSIVE_MODE_RULES
.PHONY: $(1) $(1)/this-dir $(1)/local
$(foreach x,$(call GET_LOCAL_DIR_DEPS,$(1)),$(call LOCAL_DIR_DEP_RULE,$(1),$(x))
)
$(1): $(1)/this-dir $(patsubst %,$(1)/subdir/%,$(call GET_SUBDIRS_FOR_MODE,$(1)))
ifeq ($(strip $(call GET_LOCAL_DIR_DEPS,$(1))),)
$(1)/this-dir: $(1)/local
else
$(1)/this-dir:
	@$$(MAKE) --no-print-directory $(1)/local
endif
endef

define SUBDIR_RULES
$(foreach x,$(SUBDIRS) $(PASSIVE_SUBDIRS),$(foreach y,$(RECURSIVE_MODES),$(call SUBDIR_MODE_RULES,$(x),$(y))
))
$(foreach x,$(RECURSIVE_MODES),$(call RECURSIVE_MODE_RULES,$(x))
)
endef

$(eval $(SUBDIR_RULES))



# CLEANING

ifneq ($(strip $(TARGETS)),)
define CLEANING_RULES

.PHONY: clean/extra
clean/local: clean/extra
	$(RM) $(strip *.d *.o *.gcno *.gcda $(TARGETS))
$(foreach x,$(EXTRA_CLEAN_DIRS),$(NEW_RECIPE)$(RM) $(x)/*.d $(x)/*.o $(x)/*.gcno $(x)/*.gcda)

endef
$(eval $(CLEANING_RULES))
endif



# INSTALL / UNINSTALL

.PHONY: install
install: default
	@$(MAKE) install-only

.PHONY: install-header-dir install-lib-dirs install-prog-dirs
.PHONY: install-headers install-static-libs install-shared-libs install-progs install-dev-progs
.PHONY: uninstall-static-libs uninstall-shared-libs uninstall-progs uninstall-dev-progs uninstall/extra

INSTALL_FILTER_2 = $(subst $(COMMA),$(SPACE),$(INSTALL_FILTER))

ifneq ($(filter headers,$(INSTALL_FILTER_2)),)
install-only/local: install-headers
endif
ifneq ($(filter static-libs,$(INSTALL_FILTER_2)),)
install-only/local: install-static-libs
endif
ifneq ($(filter shared-libs,$(INSTALL_FILTER_2)),)
install-only/local: install-shared-libs
endif
ifneq ($(filter progs,$(INSTALL_FILTER_2)),)
install-only/local: install-progs
endif
ifneq ($(filter dev-progs,$(INSTALL_FILTER_2)),)
install-only/local: install-dev-progs
endif

ifneq ($(filter dev-progs,$(INSTALL_FILTER_2)),)
uninstall/local: uninstall-dev-progs
endif
ifneq ($(filter progs,$(INSTALL_FILTER_2)),)
uninstall/local: uninstall-progs
endif
ifneq ($(filter shared-libs,$(INSTALL_FILTER_2)),)
uninstall/local: uninstall-shared-libs
endif
ifneq ($(filter static-libs,$(INSTALL_FILTER_2)),)
uninstall/local: uninstall-static-libs
endif
ifneq ($(filter extra,$(INSTALL_FILTER_2)),)
uninstall/local: uninstall/extra
endif

HEADER_INSTALL_DIR =
ifneq ($(INST_HEADERS),)
ifeq ($(SOURCE_ROOT),)
$(warning Cannot install headers without a value for SOURCE_ROOT)
else
HEADER_REL_PATH = $(call PATH_DIFF,.,$(ABS_SOURCE_ROOT))
INSIDE_SOURCE = $(call EQUALS,$(ABS_SOURCE_ROOT)$(call COND_PREPEND,/,$(HEADER_REL_PATH)),$(abspath .))
ifeq ($(INSIDE_SOURCE),)
$(warning Cannot install headers outside SOURCE_ROOT)
else
HEADER_INSTALL_DIR = $(DESTDIR)$(includedir)$(call COND_PREPEND,/,$(HEADER_REL_PATH))
endif
endif
endif

INSTALL_RECIPE_DIRS    = $(if $(1),$(NEW_RECIPE)$(INSTALL_DIR) $(1))
INSTALL_RECIPE_LIBS    = $(if $(2),$(NEW_RECIPE)$(INSTALL_LIBRARY) $(2) $(call GET_INSTALL_DIR,$(1)))
INSTALL_RECIPE_PROGS   = $(if $(2),$(NEW_RECIPE)$(INSTALL_PROGRAM) $(2) $(call GET_INSTALL_DIR,$(1)))
UNINSTALL_RECIPE_LIBS  = $(if $(2),$(NEW_RECIPE)$(RM) $(foreach x,$(2),$(call GET_INSTALL_DIR,$(1))/$(x)))
UNINSTALL_RECIPE_PROGS = $(if $(2),$(NEW_RECIPE)$(RM) $(foreach x,$(2),$(call GET_INSTALL_DIR,$(1))/$(x)))

# ARGS: install_prefix, qual_name, version
INSTALL_RECIPE_LIB_SHARED   = $(INSTALL_RECIPE_LIBS)
UNINSTALL_RECIPE_LIB_SHARED = $(UNINSTALL_RECIPE_LIBS)

ifeq ($(OS),Linux)
INSTALL_RECIPE_LIB_SHARED     = $(if $(3),$(call INSTALL_RECIPE_LIB_SHARED_2,$(1),$(2),$(call MAP_SHARED_LIB_VERSION,$(3))),$(INSTALL_RECIPE_LIBS))
INSTALL_RECIPE_LIB_SHARED_2   = $(call INSTALL_RECIPE_LIB_SHARED_3,$(1),$(2),$(2).$(word 1,$(3)),$(2).$(word 2,$(3)))
INSTALL_RECIPE_LIB_SHARED_3   = $(call INSTALL_RECIPE_LIBS,$(1),$(4))$(NEW_RECIPE)cd $(call GET_INSTALL_DIR,$(1)) && ln -s -f $(4) $(3) && ln -s -f $(3) $(2)
UNINSTALL_RECIPE_LIB_SHARED   = $(if $(3),$(call UNINSTALL_RECIPE_LIB_SHARED_2,$(1),$(2),$(call MAP_SHARED_LIB_VERSION,$(3))),$(UNINSTALL_RECIPE_LIBS))
UNINSTALL_RECIPE_LIB_SHARED_2 = $(call UNINSTALL_RECIPE_LIB_SHARED_3,$(1),$(2),$(2).$(word 1,$(3)),$(2).$(word 2,$(3)))
UNINSTALL_RECIPE_LIB_SHARED_3 = $(call UNINSTALL_RECIPE_LIBS,$(1),$(2) $(3) $(4))
endif

ifeq ($(OS),Darwin)
INSTALL_RECIPE_LIB_SHARED     = $(if $(3),$(call INSTALL_RECIPE_LIB_SHARED_2,$(1),$(2),$(word 1,$(call MAP_SHARED_LIB_VERSION,$(2),$(3)))),$(INSTALL_RECIPE_LIBS))
INSTALL_RECIPE_LIB_SHARED_2   = $(call INSTALL_RECIPE_LIBS,$(1),$(3))$(NEW_RECIPE)cd $(call GET_INSTALL_DIR,$(1)) && ln -s -f $(3) $(2)
UNINSTALL_RECIPE_LIB_SHARED   = $(if $(3),$(call UNINSTALL_RECIPE_LIB_SHARED_2,$(1),$(2),$(word 1,$(call MAP_SHARED_LIB_VERSION,$(2),$(3)))),$(UNINSTALL_RECIPE_LIBS))
UNINSTALL_RECIPE_LIB_SHARED_2 = $(call UNINSTALL_RECIPE_LIBS,$(1),$(2) $(3))
endif

INST_STATIC_LIB_SUFFICES   =
INST_SHARED_LIB_SUFFICES   =
ifneq ($(ENABLE_INSTALL_STATIC_LIBS),)
INST_STATIC_LIB_SUFFICES  += +$(SUFFIX_LIB_STATIC_OPTIM)
endif
INST_SHARED_LIB_SUFFICES  += +$(SUFFIX_LIB_SHARED_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_LIBS),)
INST_SHARED_LIB_SUFFICES  += +$(SUFFIX_LIB_SHARED_DEBUG)
endif
INST_PROG_SUFFICES  = +$(SUFFIX_PROG_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_PROGS),)
INST_PROG_SUFFICES += +$(SUFFIX_PROG_DEBUG)
endif

# ARGS: install_prefix
GET_STATIC_LIB_INST_NAMES = $(foreach x,$($(1)_LIBRARIES),$(foreach y,$(INST_STATIC_LIB_SUFFICES),$(call GET_LIBRARY_NAME,$(x))$(patsubst +%,%,$(y))))
GET_PROG_INST_NAMES       = $(foreach x,$($(1)_PROGRAMS),$(foreach y,$(INST_PROG_SUFFICES),$(x)$(patsubst +%,%,$(y))))

define INSTALL_RULES

ifneq ($(HEADER_INSTALL_DIR),)
install-headers: install-header-dir
	$(INSTALL_DATA) $(INST_HEADERS) $(HEADER_INSTALL_DIR)
install-header-dir:
	$(INSTALL_DIR) $(HEADER_INSTALL_DIR)
endif

install-static-libs: install-lib-dirs
$(foreach x,$(PRIMARY_PREFIXES),$(call INSTALL_RECIPE_LIBS,$(x),$(strip $(call GET_STATIC_LIB_INST_NAMES,$(x)))))

install-shared-libs: install-lib-dirs
$(foreach x,$(PRIMARY_PREFIXES),$(foreach y,$($(x)_LIBRARIES),$(foreach z,$(INST_SHARED_LIB_SUFFICES),$(call INSTALL_RECIPE_LIB_SHARED,$(x),$(call GET_LIBRARY_NAME,$(y))$(patsubst +%,%,$(z)),$(call GET_VERSION_FOR_TARGET,$(y))))))

uninstall-static-libs:
$(foreach x,$(PRIMARY_PREFIXES),$(call UNINSTALL_RECIPE_LIBS,$(x),$(strip $(call GET_STATIC_LIB_INST_NAMES,$(x)))))

uninstall-shared-libs:
$(foreach x,$(PRIMARY_PREFIXES),$(foreach y,$($(x)_LIBRARIES),$(foreach z,$(INST_SHARED_LIB_SUFFICES),$(call UNINSTALL_RECIPE_LIB_SHARED,$(x),$(call GET_LIBRARY_NAME,$(y))$(patsubst +%,%,$(z)),$(call GET_VERSION_FOR_TARGET,$(y))))))

install-progs: install-prog-dirs
$(foreach x,$(PRIMARY_PREFIXES),$(call INSTALL_RECIPE_PROGS,$(x),$(strip $(call GET_PROG_INST_NAMES,$(x)))))

uninstall-progs:
$(foreach x,$(PRIMARY_PREFIXES),$(call UNINSTALL_RECIPE_PROGS,$(x),$(strip $(call GET_PROG_INST_NAMES,$(x)))))

install-dev-progs: install-dev-prog-dirs
$(call INSTALL_RECIPE_PROGS,bin,$(strip $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG)))

uninstall-dev-progs:
$(call UNINSTALL_RECIPE_PROGS,bin,$(strip $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG)))

install-lib-dirs:
$(call INSTALL_RECIPE_DIRS,$(strip $(foreach x,$(PRIMARY_PREFIXES),$(if $($(x)_LIBRARIES),$(call GET_INSTALL_DIR,$(x))))))

install-prog-dirs:
$(call INSTALL_RECIPE_DIRS,$(strip $(foreach x,$(PRIMARY_PREFIXES),$(if $($(x)_PROGRAMS),$(call GET_INSTALL_DIR,$(x))))))

install-dev-prog-dirs:
$(call INSTALL_RECIPE_DIRS,$(strip $(if $(DEV_PROGRAMS),$(call GET_INSTALL_DIR,bin))))

endef

$(eval $(INSTALL_RULES))



# TESTING

define TEST_RULES

test/local: $(TARGETS_TEST)
$(foreach x,$(TARGETS_TEST_PROG_OPTIM),$(NEW_RECIPE)./$(x))

test-debug/local: $(TARGETS_TEST_DEBUG)
$(foreach x,$(TARGETS_TEST_PROG_DEBUG),$(NEW_RECIPE)./$(x))

memtest/local: $(TARGETS_TEST)
$(foreach x,$(TARGETS_TEST_PROG_OPTIM),$(NEW_RECIPE)valgrind --quiet --error-exitcode=1 --track-origins=yes --leak-check=yes --leak-resolution=low ./$(x) --no-error-exitcode)

memtest-debug/local: $(TARGETS_TEST_DEBUG)
$(foreach x,$(TARGETS_TEST_PROG_DEBUG),$(NEW_RECIPE)valgrind --quiet --error-exitcode=1 --track-origins=yes --leak-check=yes --leak-resolution=low ./$(x) --no-error-exitcode)

ifneq ($(strip $(TARGETS_TEST_COVER)),)
test-cover/local: $(TARGETS_TEST_COVER)
	$(RM) *.gcda
$(foreach x,$(EXTRA_CLEAN_DIRS),$(NEW_RECIPE)$(RM) $(x)/*.gcda)
$(foreach x,$(TARGETS_TEST_PROG_COVER),$(NEW_RECIPE)-./$(x))
endif

endef

$(eval $(TEST_RULES))



# LINKING PROGRAMS

# ARGS: origin_pattern, target_pattern, list
FILTER_PATSUBST = $(patsubst $(1),$(2),$(filter $(1),$(3)))

# ARGS: patterns, list
FILTER_UNPACK   = $(foreach x,$(2),$(call FILTER_UNPACK_1,$(call FIND,FILTER_UNPACK_2,$(1),$(x)),$(x)))
FILTER_UNPACK_1 = $(and $(1),$(patsubst $(1),%,$(2)))
FILTER_UNPACK_2 = $(filter $(1),$(2))

# ARGS: func, patterns, list, optional_arg
PATTERN_UNPACK_MAP   = $(foreach x,$(3),$(call PATTERN_UNPACK_MAP_1,$(1),$(call FIND,PATTERN_UNPACK_MAP_2,$(2),$(x)),$(x),$(4)))
# ARGS: func, optional_matching_pattern, entry, optional_arg
PATTERN_UNPACK_MAP_1 = $(if $(2),$(patsubst %,$(2),$(call $(1),$(patsubst $(2),%,$(3)),$(4))),$(3))
PATTERN_UNPACK_MAP_2 = $(filter $(1),$(2))

# Expand the contents of the target_LIBS variable for the specified
# target. The target must either be a program or an installed library.
# ARGS: prog_target
EXPAND_PROG_LIBS = $(call FOLD_LEFT,EXPAND_LIB_DEP,,$(strip $($(call FOLD_TARGET,$(1))_LIBS)))
# ARGS: inst_lib_target
EXPAND_INST_LIB_LIBS = $(call FOLD_LEFT,EXPAND_LIB_DEP,rpath:$(call GET_INSTALL_DIR_FOR_TARGET,$(1)) noinst-rpath:.,$(strip $($(call FOLD_TARGET,$(1))_LIBS)))

# ARGS: accum, dependency_lib
EXPAND_LIB_DEP = $(call EXPAND_LIB_DEP_2,$(1),$(call GET_LIBRARY_NAME,$(2)),$(call READ_LIB_LIBDEPS,$(2)))
# ARGS: accum, dependency_lib, contents_of_libdeps_for_dependency_lib
EXPAND_LIB_DEP_2 = $(if $(filter noinst,$(3)),$(call EXPAND_NOINST_LIB_REF,$(1),$(2),$(3)),$(call EXPAND_INST_LIB_REF,$(1),$(2),$(3)))
EXPAND_NOINST_LIB_REF = $(call EXPAND_LIB_DEP_3,$(1),noinst:$(2) libdeps:$(2)$(LIB_SUFFIX_LIBDEPS) $(filter-out noinst,$(3)))
EXPAND_INST_LIB_REF   = $(call EXPAND_LIB_DEP_3,$(1),lib:$(2).a libdeps:$(2)$(LIB_SUFFIX_LIBDEPS) $(3))
# ARGS: accum, partially_expanded_libdeps
EXPAND_LIB_DEP_3 = $(call UNION,$(1),$(call PATTERN_UNPACK_MAP,MAKE_ABS_PATH,noinst-rpath:%,$(call EXPAND_LIB_DEP_4,$(2))))
# ARGS: partially_expanded_libdeps
EXPAND_LIB_DEP_4 = $(foreach x,$(1),$(if $(filter lib:%,$(x)),$(call EXPAND_LIB_DEP_5,$(call GET_LIBRARY_NAME,$(patsubst lib:%,%,$(x)))),$(x)))
# ARGS: library_reference_without_suffix
EXPAND_LIB_DEP_5 = $(call EXPAND_LIB_DEP_6,$(notdir $(1)),$(patsubst %/,%,$(dir $(1))))
# ARGS: nondir_part_of_library_reference, dir_part
EXPAND_LIB_DEP_6 = inst:$(2)/$(1) $(patsubst lib%,lib:%,$(1)) dir:$(2)

# Read the contents of the .libdeps file for the specified library and translate relative paths.
# For libraries in the local directory, the contents needs to be computed "on the fly" because the file may not be up to date.
READ_LIB_LIBDEPS   = $(if $(call IN_THIS_DIR,$(1)),$(call READ_LIB_LIBDEPS_1,$(notdir $(1))),$(call READ_LIB_LIBDEPS_2,$(1)))
READ_LIB_LIBDEPS_1 = $(if $(call IS_NOINST_LIB,$(1)),$(call MAKE_NOINST_LIB_LIBDEPS,$(1)),$(call MAKE_INST_LIB_LIBDEPS,$(1)))
READ_LIB_LIBDEPS_2 = $(call PATTERN_UNPACK_MAP,READ_LIB_LIBDEPS_3,lib:% noinst-rpath:%,$(call CAT_OPT_FILE,$(call GET_LIBRARY_NAME,$(1))$(LIB_SUFFIX_LIBDEPS)),$(1))
READ_LIB_LIBDEPS_3 = $(call MAKE_REL_PATH,$(dir $(2))$(1))

IS_NOINST_LIB   = $(call FIND,IS_NOINST_LIB_1,$(NOINST_LIBRARIES) $(TEST_LIBRARIES),$(1))
IS_NOINST_LIB_1 = $(and $(call IN_THIS_DIR,$(1)),$(call EQUALS,$(notdir $(1)),$(2)))

# ARGS: noinst_lib_target
MAKE_NOINST_LIB_LIBDEPS   = $(strip noinst $(call MAKE_NOINST_LIB_LIBDEPS_1,$(1)) $(call MAKE_NOINST_LIB_LIBDEPS_2,$(1)))
MAKE_NOINST_LIB_LIBDEPS_1 = $(foreach x,$($(call FOLD_TARGET,$(1))_LIBS),lib:$(x) $(call READ_LIB_LIBDEPS,$(x)))
MAKE_NOINST_LIB_LIBDEPS_2 = $(call MAKE_NOINST_LIB_LIBDEPS_3,$(1)) $(call MAKE_NOINST_LIB_LIBDEPS_4,$(1)) $(call MAKE_NOINST_LIB_LIBDEPS_5,$(1))
MAKE_NOINST_LIB_LIBDEPS_3 = $(foreach x,$(call GET_FLAGS,$(call FOLD_TARGET,$(1))_LDFLAGS,_OPTIM),ldflag-opt:$(x))
MAKE_NOINST_LIB_LIBDEPS_4 = $(foreach x,$(call GET_FLAGS,$(call FOLD_TARGET,$(1))_LDFLAGS,_DEBUG),ldflag-dbg:$(x))
MAKE_NOINST_LIB_LIBDEPS_5 = $(foreach x,$(call GET_FLAGS,$(call FOLD_TARGET,$(1))_LDFLAGS,_COVER),ldflag-cov:$(x))

# ARGS: inst_lib_target
MAKE_INST_LIB_LIBDEPS = $(call EXTRACT_INST_LIB_LIBDEPS,$(call EXPAND_INST_LIB_LIBS,$(1)))

# Pick out rpath:% and noinst-rpath:% entries and transform the paths
# of the noinst-rpaths:% entries such that they are expressed relative
# to the directory holding the executing Makefile.
# ARGS: expanded_target_libs
EXTRACT_INST_LIB_LIBDEPS = $(call PATTERN_UNPACK_MAP,MAKE_REL_PATH,noinst-rpath:%,$(filter rpath:% noinst-rpath:%,$(1)))

# ARGS: expanded_target_libs, qual_type
QUALIFY_LIB_REFS   = $(call SELECT_LDFLAGS$(2),$(call QUALIFY_LIB_REFS_1,$(1),$(2)))
QUALIFY_LIB_REFS_1 = $(call QUALIFY_LIB_REFS_2,$(1),$(SUFFIX_LIB_STATIC$(2)),$(SUFFIX_LIB_SHARED$(2)),$(BASE_DENOM_2)$(LIB_DENOM$(2)))
QUALIFY_LIB_REFS_2 = $(patsubst noinst:%,noinst:%$(2),$(patsubst inst:%,inst:%$(3),$(patsubst lib:%,lib:%$(4),$(1))))

SELECT_LDFLAGS_OPTIM = $(patsubst ldflag-opt:%,ldflag:%,$(filter-out ldflag-dbg:% ldflag-cov:%,$(1)))
SELECT_LDFLAGS_DEBUG = $(patsubst ldflag-dbg:%,ldflag:%,$(filter-out ldflag-opt:% ldflag-cov:%,$(1)))
SELECT_LDFLAGS_COVER = $(patsubst ldflag-cov:%,ldflag:%,$(filter-out ldflag-opt:% ldflag-dbg:%,$(1)))

UNPACK_LIB_REFS = $(call FILTER_UNPACK,noinst:%,$(1)) $(call FILTER_PATSUBST,lib:%,-l%,$(1)) $(call FILTER_PATSUBST,dir:%,-L%,$(1)) $(call FILTER_UNPACK,ldflag:%,$(1))

# ARGS: expanded_target_libs
GET_RPATHS_FROM_LIB_REFS = $(foreach x,$(call FILTER_UNPACK,rpath:%,$(1)),-Wl,-rpath,$(x))
GET_NOINST_RPATHS_FROM_LIB_REFS = $(foreach x,$(call FILTER_UNPACK,noinst-rpath:%,$(1)),-Wl,-rpath,$(x))

# ARGS: qual_prog_name, objects, qual_expanded_target_libs, deps, link_cmd, ldflags
define NOINST_PROG_RULE
$(1): $(2) $(call FILTER_UNPACK,noinst:% inst:% libdeps:%,$(3)) $(4)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(call GET_NOINST_RPATHS_FROM_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)
endef

# ARGS: qual_prog_name, objects, qual_expanded_target_libs, deps, link_cmd, ldflags
define INST_PROG_RULE
ifeq ($(filter noinst-rpath:%,$(3)),)
$(1): $(2) $(call FILTER_UNPACK,noinst:% inst:% libdeps:%,$(3)) $(4)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(call GET_RPATHS_FROM_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)
else
$(1) $(1)-noinst: $(2) $(call FILTER_UNPACK,noinst:% inst:% libdeps:%,$(3)) $(4)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(call GET_RPATHS_FROM_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)
	$(strip $(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(call GET_NOINST_RPATHS_FROM_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH)) -o $(1)-noinst
endif
endef

define RECORD_TARGETS_FOR_OBJECT
GMK_$(call FOLD_TARGET,$(1))_TARGETS += $(2)
$(EMPTY)
endef

# ARGS: unqual_prog_name, expanded_target_libs, deps
define NOINST_PROG_RULES
$(call NOINST_PROG_RULE,$(1)$(SUFFIX_PROG_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(call QUALIFY_LIB_REFS,$(2),_OPTIM),$(3),$(LD_PROG_OPTIM),$(call GET_LDFLAGS_FOR_TARGET,$(1),_OPTIM))
$(call NOINST_PROG_RULE,$(1)$(SUFFIX_PROG_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(call QUALIFY_LIB_REFS,$(2),_DEBUG),$(3),$(LD_PROG_DEBUG),$(call GET_LDFLAGS_FOR_TARGET,$(1),_DEBUG))
$(call NOINST_PROG_RULE,$(1)$(SUFFIX_PROG_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(call QUALIFY_LIB_REFS,$(2),_COVER),$(3),$(LD_PROG_COVER),$(call GET_LDFLAGS_FOR_TARGET,$(1),_COVER))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

# ARGS: unqual_target, expanded_target_libs, deps
define INST_PROG_RULES
$(call INST_PROG_RULE,$(1)$(SUFFIX_PROG_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(call QUALIFY_LIB_REFS,$(2),_OPTIM),$(3),$(LD_PROG_OPTIM),$(call GET_LDFLAGS_FOR_TARGET,$(1),_OPTIM))
$(call INST_PROG_RULE,$(1)$(SUFFIX_PROG_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(call QUALIFY_LIB_REFS,$(2),_DEBUG),$(3),$(LD_PROG_DEBUG),$(call GET_LDFLAGS_FOR_TARGET,$(1),_DEBUG))
$(call INST_PROG_RULE,$(1)$(SUFFIX_PROG_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(call QUALIFY_LIB_REFS,$(2),_COVER),$(3),$(LD_PROG_COVER),$(call GET_LDFLAGS_FOR_TARGET,$(1),_COVER))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

$(foreach x,$(NOINST_PROGRAMS) $(TEST_PROGRAMS),$(eval $(call NOINST_PROG_RULES,$(x),$(call EXPAND_PROG_LIBS,$(x)),$(call GET_DEPS_FOR_TARGET,$(x)))))
$(foreach x,$(INST_PROGRAMS) $(DEV_PROGRAMS),$(eval $(call INST_PROG_RULES,$(x),$(call EXPAND_PROG_LIBS,$(x)),$(call GET_DEPS_FOR_TARGET,$(x)))))



# CREATING/LINKING LIBRARIES

# For each library `libfoo.a` (installed or uninstalled) a 'libdeps'
# file called `libfoo.libdeps` is also created. This file contains a
# space-separated list of entries of various different kinds needed
# when linking project-local targets against the library. The order of
# entries is immaterial.
#
#
# If `libinst.a` is an installed library, then `libinst.libdeps`
# contains a number of `rpath:` and `noninst-rpath:` entries. The
# `rpath:` entries are used in `-rpath` flags when linking installed
# programs against `libinst.a`. The `noinst-rpath:` entries are
# similar, but they are used when linking programs that are not
# installed (i.e., those that can be executed before `libinst.a` is
# installed). While the paths specified by the `rpath:` entries are
# absolute, the paths specified by the `noninst-rpath:` entries are
# always relative to the directory containing the 'libdeps' file.
#
# First of all, `libinst.libdeps` contains an `rpath:` and a
# `noinst-rpath:` entry for itself. For instance:
#
#   rpath:/usr/local/lib noinst-rpath:.
#
# Further more, `libinst.libdeps` contains an `rpath:` and a
# `noinst-rpath:` entry for each installed library `libxxx.a`, that
# `libinst.a` depends on, and which is also part of this project,
# unless those entries would lead to duplicates. This is true even
# when `libxxx.a` is an indirect dependency of `libinst.a`
# (transitivity). For example, if `libxxx.a` is an dependency of
# `libyyy.a` and `libyyy.a` is a dependency of `libinst.a`, then
# `libxxx.a` is an indirect dependency of `libinst.a`. Let us assume
# that `libinst.a`, `libxxx.a`, and `libyyy.a` are located in
# subdirectories `inst`, `xxx`, and `yyy` respectively, and all are
# installed in `/usr/local/lib`, then `libinst.libdeps` will contain
#
#   rpath:/usr/local/lib noinst-rpath:. noinst-rpath:../xxx
#   noinst-rpath:../yyy
#
# Had they all been located in the same directory, `libinst.libdeps`
# would instead contain
#
#   rpath:/usr/local/lib noinst-rpath:.
#
#
# If `libconv.a` is a convenience library (not installed), then
# `libconv.libdeps` contains a `noinst` entry that identifies it as a
# convenience library to `Makefile`s in other subdirectories. Apart
# from that, it contains a `lib:` entry for each installed
# project-local library that `libconv.a` directly depends on, and it
# contains the union of the contents of the 'libdeps' files associated
# with each of those `lib:` entries with relative paths transformed as
# necessary. For example, if `libconv.a` depends on `libinst.a`, and
# `libconv.a` is located in the root directory of the project, and the
# installed libraries are located in distinct subdirectories as
# described in an example above, then `libconv.libdeps` will contain
#
#   noinst lib:inst/libinst.a rpath:/usr/local/lib noinst-rpath:inst
#   noinst-rpath:xxx noinst-rpath:yyy
#
# Note how the relative paths in the `noinst-rpath:` entries have been
# transformed such that they are now relative to the root directory.
#
# When extra linker flags are attached to a convenience library, those
# flags will also be carried in the 'libdeps' file. For example,
# `libconv.libdeps` might contain
#
#   ldflag-opt:-lmagic ldflag-opt:-L/opt/magic/lib
#   ldflag-dbg:-lmagic ldflag-dbg:-L/opt/magic-debug/lib
#   ldflag-cov:-lmagic ldflag-cov:-L/opt/magic-debug/lib
#
# The `ldflag-opt:` entries are used when compiling in optimized
# (default) mode, while the `ldflag-dbg:` and the `ldflag-cov:`
# entries are used when compiling in debug and coverage modes
# respectively.

# ARGS: target, objects, extra_deps
define STATIC_LIBRARY_RULE
$(1): $(2) $(3)
	$(RM) $(1)
	$(strip $(AR) $(ARFLAGS_GENERAL) $(1) $(2))
endef

# ARGS: qual_lib_name, objects, qual_expanded_target_libs, extra_deps, link_cmd, ldflags, lib_version
SHARED_LIBRARY_RULE_HELPER = $(call SHARED_LIBRARY_RULE,$(1),$(2) $(call FILTER_UNPACK,inst:% libdeps:%,$(3)) $(4),$(5) $(2) $(call UNPACK_LIB_REFS,$(3)) $(6) $(LDFLAGS_ARCH) $(LDFLAGS_LIBRARY_PATH),$(7))

# ARGS: qual_lib_name, deps, cmd, version
SHARED_LIBRARY_RULE = $(SHARED_LIBRARY_RULE_DEFAULT)
define SHARED_LIBRARY_RULE_DEFAULT
$(1): $(2)
	$(strip $(3) -o $(1))
endef

ifeq ($(OS),Linux)

# ARGS: qual_lib_name, deps, cmd, version
SHARED_LIBRARY_RULE = $(if $(4),$(call SHARED_LIBRARY_RULE_VER,$(1),$(2),$(3),$(call MAP_SHARED_LIB_VERSION,$(4))),$(SHARED_LIBRARY_RULE_DEFAULT))

# ARGS: qual_lib_name, deps, cmd, mapped_version
SHARED_LIBRARY_RULE_VER = $(call SHARED_LIBRARY_RULE_VER_2,$(1),$(2),$(3),$(word 1,$(4)),$(word 2,$(4)))

# ARGS: qual_lib_name, deps, cmd, major_version, full_version
define SHARED_LIBRARY_RULE_VER_2
$(1) $(1).$(4) $(1).$(5): $(2)
	$(strip $(3) -Wl,-soname,$(1).$(4) -o $(1).$(5))
	ln -s -f $(1).$(5) $(1).$(4)
	ln -s -f $(1).$(4) $(1)
endef

endif

ifeq ($(OS),Darwin)

# See http://www.mikeash.com/pyblog/friday-qa-2009-11-06-linking-and-install-names.html

# ARGS: qual_lib_name, deps, cmd, version
SHARED_LIBRARY_RULE = $(if $(4),$(call SHARED_LIBRARY_RULE_VER,$(1),$(2),$(3),$(call MAP_SHARED_LIB_VERSION,$(1),$(4))),$(SHARED_LIBRARY_RULE_DEFAULT))

# ARGS: qual_lib_name, deps, cmd, mapped_version
SHARED_LIBRARY_RULE_VER = $(call SHARED_LIBRARY_RULE_VER_2,$(1),$(2),$(3),$(word 1,$(4)),$(word 2,$(4)),$(word 3,$(4)))

# ARGS: qual_lib_name, deps, cmd, qual_lib_name_with_version, compatibility_version, current_version
define SHARED_LIBRARY_RULE_VER_2
$(1) $(4): $(2)
	$(strip $(3) -install_name @rpath/$(4) -compatibility_version $(5) -current_version $(6) -o $(4))
	ln -s -f $(4) $(1)
endef

endif

# ARGS: lib_name, contents, deps
define LIBDEPS_RULE
$(1)$(LIB_SUFFIX_LIBDEPS): $(3) $(DEP_MAKEFILES)
	echo $(2) >$(1)$(LIB_SUFFIX_LIBDEPS)
endef

# ARGS: unqual_lib_name, extra_deps
define NOINST_LIB_RULES
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(3))
$(call LIBDEPS_RULE,$(call GET_LIBRARY_NAME,$(1)),$(call MAKE_NOINST_LIB_LIBDEPS,$(1)),$(foreach x,$($(call FOLD_TARGET,$(1))_LIBS),$(call GET_LIBRARY_NAME,$(x))$(LIB_SUFFIX_LIBDEPS)))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

# ARGS: unqual_lib_name, expanded_target_libs, extra_deps
define INST_LIB_RULES
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_STATIC_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(3))
$(call SHARED_LIBRARY_RULE_HELPER,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_SHARED_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_OPTIM)),$(call QUALIFY_LIB_REFS,$(2),_OPTIM),$(3),$(LD_LIB_OPTIM),$(call GET_LDFLAGS_FOR_TARGET,$(1),_OPTIM),$(call GET_VERSION_FOR_TARGET,$(1)))
$(call SHARED_LIBRARY_RULE_HELPER,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_SHARED_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_DEBUG)),$(call QUALIFY_LIB_REFS,$(2),_DEBUG),$(3),$(LD_LIB_DEBUG),$(call GET_LDFLAGS_FOR_TARGET,$(1),_DEBUG),$(call GET_VERSION_FOR_TARGET,$(1)))
$(call SHARED_LIBRARY_RULE_HELPER,$(call GET_LIBRARY_NAME,$(1))$(SUFFIX_LIB_SHARED_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_COVER)),$(call QUALIFY_LIB_REFS,$(2),_COVER),$(3),$(LD_LIB_COVER),$(call GET_LDFLAGS_FOR_TARGET,$(1),_COVER),$(call GET_VERSION_FOR_TARGET,$(1)))
$(call LIBDEPS_RULE,$(call GET_LIBRARY_NAME,$(1)),$(call EXTRACT_INST_LIB_LIBDEPS,$(2)),$(call FILTER_UNPACK,libdeps:%,$(2)))
$(foreach x,$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call RECORD_TARGETS_FOR_OBJECT,$(x),$(1)))
endef

$(foreach x,$(NOINST_LIBRARIES) $(TEST_LIBRARIES),$(eval $(call NOINST_LIB_RULES,$(x),$(call GET_DEPS_FOR_TARGET,$(x)))))
$(foreach x,$(INST_LIBRARIES),$(eval $(call INST_LIB_RULES,$(x),$(call EXPAND_INST_LIB_LIBS,$(x)),$(call GET_DEPS_FOR_TARGET,$(x)))))



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
