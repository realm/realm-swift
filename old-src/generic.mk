# Generic makefile that captures some of the ideas of GNU Automake,
# especially with respect to naming targets.
#
# Author: Kristian Spangsege
#
# Version: 1.0.2
#
# This makefile requires GNU Make. It has been tested with version
# 3.81, and it is known to work well on both Linux and OS X.
#
#
# Major goals
# -----------
#
# clean ........ Delete targets and other files that are produced
#                while building.
#
# build (default) Build convenience libraries (`noinst_LIBRARIES`)
#                plus everything that `install-only` wants to install
#                (when disregarding `INSTALL_FILTER`). If necessary,
#                the convenience libraries will also be built in
#                'debug' mode.
#
# install ...... Same as `build` followed by `install-only`.
#
# uninstall .... Uninstall everything that `install` would install.
#
# install-only . Installs `HEADERS`, `LIBRARIES`, `PROGRAMS`, and
#                `DEV_PROGRAMS`. Whether static libraries and/or
#                'debug' mode versions are also installed depends on
#                various configuration parameters. Note that
#                `INSTALL_FILTER` can be used to select a subset of
#                the above.
#
# ### Selective building
#
# release ...... Builds `LIBRARIES`, `noinst_LIBRARIES`, `PROGRAMS`,
#                `DEV_PROGRAMS`, and `noinst_PROGRAMS` in 'release'
#                mode.
#
# nodebug ...... Builds everything that `release` does, plus static
#                versions installable libraries (`LIBRARIES`) in
#                'release' mode.
#
# debug ........ Builds everything that `release` does, but in 'debug'
#                mode.
#
# cover ........ Builds everything that `release` does, but in 'code
#                coverage' mode.
#
# everything ... Builds `LIBRARIES`, `noinst_LIBRARIES`,
#                `check_LIBRARIES`, `PROGRAMS`, `DEV_PROGRAMS`, and
#                `noinst_PROGRAMS` in both 'release' and 'debug' mode.
#
# ### Testing
#
# check ......... Build `LIBRARIES`, `noinst_LIBRARIES`,
#                 `check_LIBRARIES`, `PROGRAMS`, and `check_PROGRAMS`
#                 in 'release' mode, then run all `check_PROGRAMS`.
#
# check-debug ... Same as `check`, but in 'debug' mode.
#
# check-cover ... Same as `check`, but in 'code coverage' mode.
#
# memcheck, memcheck-debug Same as `check` and `check-debug`
#                 respectively, but runs each program under Valgrind.
#
# check-norun, check-debug-norun, check-cover-norun Same as `check`,
#                 `check-debug`, and `check-cover` respectively, but
#                 stop after building.
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
#   include_HEADERS = foo.hpp
#   lib_LIBRARIES = libfoo.a
#   libfoo_a_SOURCES = libfoo.cpp
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
# must be listed in the `include_HEADERS` variable. Headers are
# installed in `/usr/local/include` by default, but this can be
# changed by setting the `prefix` or `includedir` variable. Note also
# that headers can be installed in a subdirectory of
# `/usr/local/include` or even into a multi-level hierarchy of
# subdirectories (see the 'Subdirectories' section for more on this).
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
# The installation directory for programs, libraries, and headers is
# determined by the primary prefix being used. Note that `PROGRAMS`,
# `LIBRARIES`, and `HEADERS` are primaries, and that `bin` is a
# primary prefix in `bin_PROGRAMS`, for example. The following primary
# prefixes are supported directly by `generic.mk`:
#
#   Prefix     Variable    Installation directory  Default value
#   ----------------------------------------------------------------------------
#   bin        bindir      $(exec_prefix)/bin      (/usr/local/bin)
#   sbin       sbindir     $(exec_prefix)/sbin     (/usr/local/sbin)
#   lib        libdir      $(exec_prefix)/lib      (/usr/local/lib)         (*1)
#   libexec    libexecdir  $(exec_prefix)/libexec  (/usr/local/libexec)
#   include    includedir  $(prefix)/include       (/usr/local/include)
#   subinclude includedir  $(prefix)/include/...   (/usr/local/include/...) (*2)
#
#   (*1) The actual default value depends on the platform.
#   (*2) Only available when `INCLUDE_ROOT` is specified.
#
# You can also install a program, a library, or a header into a
# non-default directory by defining a custom primary prefix. This is
# usefull when you want (for other purposes) to maintain the default
# values of the standard prefixes. Here is an example:
#
#   EXTRA_PRIMARY_PREFIXES = libhome
#   libhomedir = /usr/lib/mydeamon/bin
#   libhome_PROGRAMS = mydaemon
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
# primary prefix `noinst`, for example:
#
#   noinst_LIBRARIES = util.a
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
# Installed programs
# ------------------
#
# If a program, that is supposed to be installed, is linked against a
# locally built shared library, then `generic.mk` will pass the
# appropriate `-rpath` option to the program linker, such that the
# dynamic linker can find the library in its installed
# location. Unfortunately this does not enable the program to find the
# locally built library, and therefore it will generally not be
# possible to execute the program until after the library is
# installed.
#
# To work around this problem, `generic.mk` will create an extra
# version of the program, where it sets the `RPATH` in such a way that
# the (yet to be installed) library can be found. The name of the
# extra version is constructed by appending `-noinst` to the name of
# the regular version. The extra 'noinst' version is created only for
# testing purposes, and it will not be included during
# installation. It should be noted that the extra 'noinst' version is
# created only for programs that are linked against locally built,
# shared libraries.
#
# The extra 'noinst' versions of installed programs, as well as test
# programs and programs declared using the special primary prefix
# `noinst`, are all configured with relative `RPATH`s. This means that
# they will continue to work even when the project is relocated to a
# different directory, as long as the internal directory structure
# remains the same.
#
# Note that the standard installation procedure, that places targets
# in system directories according to category (`/usr/local/bin`,
# `/usr/local/lib`, ...), does not in general preserve the relative
# paths between targets with respect to how they occur in your project
# directory. Further more, the standard installation procedure is
# based upon the idea that the final installed location of targets is
# specified and fixed at build time.
#
# As a special option, `generic.mk` can be asked to completely disable
# its support for installation, and instead link all programs as if
# they had been declared as 'noinst' programs in the first place. This
# mode also disables the creation of the extra 'noinst' versions (as
# they would be redundant), and it will disable shared library
# versioning, that is, it will build each library as if no version was
# specified for it (see 'Library versioning' below). This mode is
# enabled by setting the environment variable `ENABLE_NOINST_BUILD` to
# a non-empty value. Be sure to do a `make clean` when you switch
# between 'noinst' and regular mode.
#
#
# Programs that are not installed
# -------------------------------
#
# Sometimes it is desirable to build a program that is not supposed to
# be installed when running `make install`. One reason could be that
# the program is used only for testing. Such programs are created by
# using the special primary prefix `noinst`, for example:
#
#   noinst_PROGRAMS = performance
#
# There is another related category of programs called 'test programs'
# that are both built and executed when running `make test`. These
# programs are created by using the `check` primary prefix, and are
# also not installed:
#
#   check_PROGRAMS = test_foo test_bar
#
# It is also possible to create a convenience library that is built
# only when 'test programs' are built. List libraries of this kind in
# `check_LIBRARIES`.
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
#   myprog_SOURCES = foo/alpha.cpp bar/beta.cpp
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
#     noinst_LIBRARIES = util.a
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
# `PROJECT_CFLAGS` and `PROJECT_LDFLAGS` in `project.mk`:
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
# for modification in `project.mk`, and they may also be overridden on
# the command line. For example, to enable POSIX Threads and disable
# automatic dependency tracking, you could do this:
#
#   make CFLAGS_PTHREADS="-pthreads" CFLAGS_AUTODEP=""
#
# If CFLAGS is specified in the environment or on the command line, it
# will replace the value of CFLAGS_GENERAL. Similarly with LDFLAGS and
# ARFLAGS.
#
# If EXTRA_CFLAGS is specified on the command line, its contents will
# be added to CFLAGS_GENERAL. Similarly with LDFLAGS.
#
# If CC, CXX, OCC, OCXX, LD, and AR are specified in the environment
# or on the command line, their values will be respected.
#
# NOTE: When you change the configuration specified via the
# environment or the command line from one invocation of make to the
# next, you should always start with a 'make clean'. MAKE does this
# automatically when you change `project.mk`.
#
# If `CC` is neither specified in the environment nor on the command
# line, `generic.mk` will look for a number of well-known compilers
# (GCC, Clang), and set `CC` accordingly. If CXX or OCC is neither
# specified in the environment nor on the command line, it will be set
# to whatever `CC` is set to. Likewise, if `OCXX` is neither specified
# in the environment nor on the command line, it will be set to
# whatever `OCC` is set to. If `LD` or `AR` is neither specified in
# the environment nor on the command line, `generic.mk` will attempt
# to derive their values from `CC`.
#
# A number of variables are provided to query about the
# detected/specified tool chain:
#
# If `generic.mk` can identify the contents of `CC` as GCC or Clang,
# it sets `CC_IS` to `gcc` or `clang` respectively, and
# `CC_IS_GCC_LIKE` to `yes`. Otherwise it sets both `CC_IS` and
# `CC_IS_GCC_LIKE` to empty strings. Equivalent variables exist for
# `CXX`, `OCC`, `OCXX`, and `LD`.
#
# Additionally, if `IS_CC`, `IS_CXX`, `IS_OCC`, and `IS_OCXX` are all
# equal, then `COMPILER_IS` is set to that value (`gcc` or
# `clang`). Likewise, if all four are GCC-like, then
# `COMPILER_IS_GCC_LIKE` is set to `yes`.
#
# In general, `generic.mk` can identify a compiler or linker as GCC if
# its name (when arguments are stripped away and path is removed) is
# `gcc` or `g++`, or begins with `gcc-` or `g++-`. Likewise with Clang
# if the name is `clang` or `clang++`.
#
# When `COMPILER_IS_GCC_LIKE` is true (not empty), `generic.mk` will
# add a number of sensible GCC-like compiler flags for optimization,
# debugging, profiling, header dependency tracking, and
# more. Likewise, if `LD_IS_GCC_LIKE` is not empty, extra linker flags
# will be added.
#
# If you set `CC` to something that is GCC-like, but is not
# automatically identified as such (e.g. `arm-linux-androideabi-gcc`),
# you can manually override `CC_IS` (or any of the other classifying
# variables) on the `make` command line. When done right, this will
# fix "chained" classification variables, and reenable the automatic
# addition of extra GCC-like compiler/linker flags.
#
#
# Technicalities
# --------------
#
# Project local files and directories mentioned in variables passed to
# `generic.mk` as part of specifying target, source, or subdirectory
# paths, must consist entirely of letters, digits, `_`, `-`, and `.`
# (all from the ASCII character set). In particular, spaces are not
# allowed. When variable names are constructed from paths, `/`, `-`,
# and `.` are folded to `_`.
#
# The same restriction applies to all installation directories
# (`bindir`, `libdir` `includedir`, etc.).
#
# On the other hand, the value of `DESTDIR` may contain any graphical
# characters from the ASCII character set as well as SPACE and TAB.
#
# Except when you are building in 'code coverage' mode, the absolute
# path to the root of your project may contain any graphical
# characters from ASCII as well as SPACE and TAB. However, when you
# are building in 'code coverage' mode, your project root path must
# adhere to the same restrictions that apply to project local target
# paths passed to `generic.mk`.



# CONFIG VARIABLES

# The relative path to the root of the include tree. If specified, a
# corresponding include option (`-I`) is added to the compiler command
# line for all object file targets in the project, and the primary
# prefix `subinclude` becomes available in Makefiles contained inside
# the specified directory.
INCLUDE_ROOT =

CFLAGS_OPTIM          = -DNDEBUG
CFLAGS_DEBUG          =
CFLAGS_COVER          =
CFLAGS_SHARED         =
CFLAGS_PTHREADS       =
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
LDFLAGS_PTHREADS      = $(CFLAGS_PTHREADS)
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

ifneq ($(filter undefined environment,$(origin PROG_SUFFIX)),)
PROG_SUFFIX           =
endif

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
# development package. This filter affects uninstallation the same way
# it affects installation.
INSTALL_FILTER = shared-libs,static-libs,progs,dev-progs,headers

# Installation (GNU style)
prefix          = /usr/local
exec_prefix     = $(prefix)
bindir          = $(exec_prefix)/bin
sbindir         = $(exec_prefix)/sbin
libdir          = $(if $(USE_LIB64),$(exec_prefix)/lib64,$(exec_prefix)/lib)
libexecdir      = $(exec_prefix)/libexec
includedir      = $(prefix)/include
INSTALL         = install
INSTALL_DIR     = $(INSTALL) -d
INSTALL_DATA    = $(INSTALL) -m 644
INSTALL_LIBRARY = $(INSTALL) -m 644
INSTALL_PROGRAM = $(INSTALL)

VALGRIND       ?= valgrind
VALGRIND_FLAGS ?= --quiet --track-origins=yes --leak-check=yes --leak-resolution=low

# Alternative filesystem root for installation
DESTDIR =



# UTILITY CONSTANTS AND FUNCTIONS

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
COMMA := ,
APOSTROPHE := $(patsubst "%",%,"'")

define NEWLINE
$(EMPTY)
$(EMPTY)
endef

define TAB
	$(EMPTY)
endef

NL_TAB := $(NEWLINE)$(TAB)

IDENTITY = $(1)

IS_EQUAL_TO = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))

# ARGS: prefix, string
IS_PREFIX_OF = $(findstring .$(call IS_PREFIX_OF_1,$(1)),.$(call IS_PREFIX_OF_1,$(2)))
IS_PREFIX_OF_1 = $(subst .,:d:,$(subst :,:c:,$(1)))

COND_PREPEND = $(if $(2),$(1)$(2))
COND_APPEND  = $(if $(1),$(1)$(2))

LIST_CONCAT  = $(if $(and $(1),$(2)),$(1) $(2),$(1)$(2))
LIST_REVERSE = $(if $(1),$(call LIST_CONCAT,$(call LIST_REVERSE,$(wordlist 2,$(words $(1)),$(1))),$(firstword $(1))))

# ARGS: predicate, list, optional_predicate_arg
STABLE_PARTITION = $(call STABLE_PARTITION_1,$(1),$(strip $(2)),$(3))
STABLE_PARTITION_1 = $(if $(2),$(call STABLE_PARTITION_2,$(1),$(wordlist 2,$(words $(2)),$(2)),$(3),$(4),$(5),$(word 1,$(2))),$(strip $(4) $(5)))
STABLE_PARTITION_2 = $(if $(call $(1),$(6),$(3)),$(call STABLE_PARTITION_1,$(1),$(2),$(3),$(4) $(6),$(5)),$(call STABLE_PARTITION_1,$(1),$(2),$(3),$(4),$(5) $(6)))

# ARGS: predicate, list, optional_predicate_arg
# Expands to first entry that satisfies the predicate, or the empty string if no entry satsifies it.
FIND = $(call FIND_1,$(1),$(strip $(2)),$(3))
FIND_1 = $(if $(2),$(call FIND_2,$(1),$(2),$(3),$(word 1,$(2))))
FIND_2 = $(if $(call $(1),$(4),$(3)),$(4),$(call FIND_1,$(1),$(wordlist 2,$(words $(2)),$(2)),$(3)))

# ARGS: func, init_accum, list
FOLD_LEFT = $(call FOLD_LEFT_1,$(1),$(2),$(strip $(3)))
FOLD_LEFT_1 = $(if $(3),$(call FOLD_LEFT_1,$(1),$(call $(1),$(2),$(word 1,$(3))),$(wordlist 2,$(words $(3)),$(3))),$(2))

# ARGS: list_1, list_2
UNION = $(call FOLD_LEFT,UNION_1,$(1),$(2))
UNION_1 = $(if $(call FIND,IS_EQUAL_TO,$(1),$(2)),$(1),$(if $(1),$(1) $(2),$(2)))

# ARGS: list
REMOVE_DUPES = $(call UNION,,$(1))

# ARGS: predicate, list, optional_predicate_arg
FILTER = $(call FILTER_1,$(1),$(strip $(2)),$(3))
FILTER_1 = $(if $(2),$(call FILTER_1,$(1),$(wordlist 2,$(words $(2)),$(2)),$(3),$(call LIST_CONCAT,$(4),$(if $(call $(1),$(word 1,$(2)),$(3)),$(word 1,$(2))))),$(4))

# ARGS: list
REMOVE_PREFIXES = $(call FILTER,REMOVE_PREFIXES_1,$(1),$(1))
REMOVE_PREFIXES_1 = $(if $(call FIND,REMOVE_PREFIXES_2,$(2),$(1)),,x)
REMOVE_PREFIXES_2 = $(if $(call IS_EQUAL_TO,$(2),$(1)),,$(call IS_PREFIX_OF,$(2),$(1)))

HIDE_SPACE   = $(subst $(TAB),:t:,$(subst $(SPACE),:s:,$(subst :,:c:,$(1))))
UNHIDE_SPACE = $(subst :c:,:,$(subst :s:,$(SPACE),$(subst :t:,$(TAB),$(1))))

# If `a` and `b` are relative or absolute paths (without a final
# slash), and `b` points to a directory, then PATH_DIFF(a,b) expands
# to the relative path from `b` to `a`. If abspath(a) and abspath(b)
# are the same path, then PATH_DIFF(a,b) expands to the empty string.
PATH_DIFF = $(call PATH_DIFF_2,$(call PATH_DIFF_1,$(1)),$(call PATH_DIFF_1,$(2)))
PATH_DIFF_1 = $(subst /,$(SPACE),$(abspath $(call HIDE_SPACE,$(if $(filter /%,$(1)),$(1),$(abspath .)/$(1)))))
PATH_DIFF_2 = $(if $(and $(1),$(2),$(call IS_EQUAL_TO,$(word 1,$(1)),$(word 1,$(2)))),$(call PATH_DIFF_2,$(wordlist 2,$(words $(1)),$(1)),$(wordlist 2,$(words $(2)),$(2))),$(call UNHIDE_SPACE,$(subst $(SPACE),/,$(strip $(patsubst %,..,$(2)) $(1)))))

# If `p` is already an absolute path, or if `optional_abs_base` is not
# specified, then `MAKE_ABS_PATH(p, optional_abs_base)` expands to
# `abspath(p)`. Otherwise, `optional_abs_base` must be an absolute
# path, and this function expands to
# `abspath(optional_abs_base+'/'+p)`. As opposed to the built-in
# function `abspath()`, this function properly handles paths that
# contain spaces.
MAKE_ABS_PATH = $(call UNHIDE_SPACE,$(abspath $(call HIDE_SPACE,$(if $(filter /%,$(1)),$(1),$(or $(2),$(abspath .))/$(1)))))

# If `p` and `base` are paths, then MAKE_REL_PATH(p,base) expands to
# the relative path from abspath(base) to abspath(p). If the two paths
# are equal, it expands to `.`. If `base` is unspecified, it defaults
# to `.`.
MAKE_REL_PATH = $(or $(call PATH_DIFF,$(1),$(or $(2),.)),.)

IS_SAME_PATH_AS = $(call IS_EQUAL_TO,$(call CANON_PATH_HIDE_SPACE,$(1)),$(call CANON_PATH_HIDE_SPACE,$(2)))
IS_PATH_CONTAINED_IN = $(call IS_PREFIX_OF,$(call CANON_PATH_HIDE_SPACE,$(2))/,$(call CANON_PATH_HIDE_SPACE,$(1)))
CANON_PATH_HIDE_SPACE = $(abspath $(call HIDE_SPACE,$(patsubst %/,%,$(if $(filter /%,$(1)),$(1),$(abspath .)/$(1)))))

# Only a `*` is recognized, and at most one is allowed per component
# of the wildcard path. Matching is guaranteed to fail if any
# component of the wildcard path has more than one star and the
# non-wildcard path has no stars in it.
#
# ARGS: wildcard_path, path
WILDCARD_PATH_MATCH = $(and $(call WILDCARD_PATH_MATCH_1,$(dir $(1)),$(dir $(2))),$(filter $(subst *,%,$(subst %,\%,$(notdir $(1)))),$(notdir $(2))))
WILDCARD_PATH_MATCH_1 = $(if $(filter-out / ./,$(1) $(2)),$(if $(filter / ./,$(1) $(2)),,$(call WILDCARD_PATH_MATCH,$(patsubst %/,%,$(1)),$(patsubst %/,%,$(2)))),$(filter // ././,$(1)$(2)))

# ARGS: wildcard_paths, paths
WILDCARD_PATHS_FILTER_OUT = $(foreach x,$(2),$(if $(strip $(foreach y,$(1),$(call WILDCARD_PATH_MATCH,$(y),$(x)))),,$(x)))

# Escape space, tab, and the following 21 characters using backslashes: !"#$&'()*;<>?[\]`{|}~
SHELL_ESCAPE = $(shell printf '%s\n' '$(call SHELL_ESCAPE_1,$(1))' | sed $(SHELL_ESCAPE_2))
SHELL_ESCAPE_1 = $(subst $(APOSTROPHE),$(APOSTROPHE)\$(APOSTROPHE)$(APOSTROPHE),$(1))
SHELL_ESCAPE_2 = 's/\([]$(TAB)$(SPACE)!"\#$$&'\''()*;<>?[\`{|}~]\)/\\\1/g'

HAVE_CMD = $(shell which $(word 1,$(1)))

# ARGS: command, prefix_to_class_map
# Returns empty if identification fails
IDENT_CMD = $(call IDENT_CMD_1,$(notdir $(word 1,$(1))),$(2))
IDENT_CMD_1 = $(word 1,$(foreach x,$(2),$(call IDENT_CMD_2,$(1),$(subst :,$(SPACE),$(x)))))
IDENT_CMD_2 = $(call IDENT_CMD_3,$(1),$(word 1,$(2)),$(word 2,$(2)))
IDENT_CMD_3 = $(if $(call IS_PREFIX_OF,$(2)-,$(1)-),$(3))

# ARGS: command, subsitutions
# Returns empty if mapping fails
MAP_CMD = $(call MAP_CMD_1,$(word 1,$(1)),$(wordlist 2,$(words $(1)),$(1)),$(2))
MAP_CMD_1 = $(call MAP_CMD_2,$(if $(findstring /,$(1)),$(dir $(1))),$(notdir $(1)),$(2),$(3))
MAP_CMD_2 = $(call MAP_CMD_3,$(1),$(word 1,$(foreach x,$(4),$(call MAP_CMD_4,$(x),$(2)))),$(3))
MAP_CMD_3 = $(if $(2),$(call LIST_CONCAT,$(1)$(2),$(3)))
MAP_CMD_4 = $(call MAP_CMD_5,$(subst :,$(SPACE),$(1)),$(2))
MAP_CMD_5 = $(call MAP_CMD_6,-$(word 1,$(1))-,-$(word 2,$(1))-,-$(2)-)
MAP_CMD_6 = $(if $(findstring $(1),$(3)),$(call MAP_CMD_7,$(patsubst -%-,%,$(subst $(1),$(2),$(3)))))
MAP_CMD_7 = $(if $(call HAVE_CMD,$(1)),$(1))

CAT_OPT_FILE = $(shell cat $(1) 2>/dev/null)

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

OS := $(shell uname)
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



# SETUP A GCC-LIKE TOOL CHAIN IF POSSIBLE

# If CC is not specified, search PATH for these compilers in the
# specified order.
ifeq ($(OS),Darwin)
  COMPILER_DETECT_LIST = clang llvm-gcc gcc
else
  COMPILER_DETECT_LIST = gcc clang
endif

# Compiler identification. Maps command prefix to compiler class.
COMPILER_IDENT_MAP = gcc:gcc g++:gcc llvm-gcc:gcc llvm-g++:gcc clang:clang clang++:clang

# Compiler classes that are mostly like GCC.
GCC_LIKE_COMPILERS = gcc clang

# How to map C compiler to corresponding C++ linker.
CC_TO_CXXL_MAP = gcc:g++ g++:g++ clang:clang++ clang++:clang++

# How to map C compiler to corresponding archiver (static libraries).
CC_TO_AR_MAP  = gcc:gcc-ar g++:gcc-ar gcc:ar g++:ar clang:clang-ar clang++:clang-ar clang:ar clang++:ar

DETECT_COMPILER = $(call FIND,HAVE_CMD,$(COMPILER_DETECT_LIST))
IDENT_COMPILER = $(call IDENT_CMD,$(1),$(COMPILER_IDENT_MAP))
CLASS_IS_GCC_LIKE = $(if $(filter $(GCC_LIKE_COMPILERS),$(1)),yes)

# C compiler
CC_SPECIFIED := $(filter-out undefined default,$(origin CC))
ifeq ($(CC_SPECIFIED),)
  # CC was not specified
  X := $(call DETECT_COMPILER)
  ifneq ($(X),)
    CC := $(X)
  endif
endif
CC_IS := $(call IDENT_COMPILER,$(CC))
CC_IS_GCC_LIKE := $(call CLASS_IS_GCC_LIKE,$(CC_IS))

# C++ compiler
CXX_SPECIFIED := $(filter-out undefined default,$(origin CXX))
ifeq ($(CXX_SPECIFIED),)
  # CXX was not specified
  CXX := $(CC)
  CXX_IS := $(CC_IS)
  CXX_IS_GCC_LIKE := $(CC_IS_GCC_LIKE)
else
  CXX_IS := $(call IDENT_COMPILER,$(CXX))
  CXX_IS_GCC_LIKE := $(call CLASS_IS_GCC_LIKE,$(CXX_IS))
endif

# Objective-C compiler
OCC_SPECIFIED := $(filter-out undefined default,$(origin OCC))
ifeq ($(OCC_SPECIFIED),)
  # OCC was not specified
  OCC := $(CC)
  OCC_IS := $(CC_IS)
  OCC_IS_GCC_LIKE := $(CC_IS_GCC_LIKE)
else
  OCC_IS := $(call IDENT_COMPILER,$(OCC))
  OCC_IS_GCC_LIKE := $(call CLASS_IS_GCC_LIKE,$(OCC_IS))
endif

# Objective-C++ compiler
OCXX_SPECIFIED := $(filter-out undefined default,$(origin OCXX))
ifeq ($(OCXX_SPECIFIED),)
  # OCXX was not specified
  OCXX := $(OCC)
  OCXX_IS := $(OCC_IS)
  OCXX_IS_GCC_LIKE := $(OCC_IS_GCC_LIKE)
else
  OCXX_IS := $(call IDENT_COMPILER,$(OCXX))
  OCXX_IS_GCC_LIKE := $(call CLASS_IS_GCC_LIKE,$(OCXX_IS))
endif

COMPILER_IS = $(if $(word 2,$(call REMOVE_DUPES,x$(CC_IS) x$(CXX_IS) x$(OCC_IS) x$(OCXX_IS))),,$(CC_IS))
COMPILER_IS_GCC_LIKE := $(and $(CC_IS_GCC_LIKE),$(CXX_IS_GCC_LIKE),$(OCC_IS_GCC_LIKE),$(OCXX_IS_GCC_LIKE))

ifneq ($(COMPILER_IS_GCC_LIKE),)
  CFLAGS_OPTIM   = -O3 -DNDEBUG
  CFLAGS_DEBUG   = -ggdb
  CFLAGS_COVER   = --coverage
  CFLAGS_SHARED  = -fPIC -DPIC
  CFLAGS_GENERAL = -Wall
  CFLAGS_AUTODEP = -MMD -MP
endif

# Linker
X := $(EMPTY)
LD_SPECIFIED = $(filter-out undefined default,$(origin LD))
ifeq ($(LD_SPECIFIED),)
  # LD was not specified
  ifneq ($(CC_IS_GCC_LIKE),)
    X := $(call MAP_CMD,$(CC),$(CC_TO_CXXL_MAP))
    ifneq ($(X),)
      LD := $(X)
      LD_IS := $(CC_IS)
      LD_IS_GCC_LIKE := yes
    endif
  endif
endif
ifeq ($(X),)
  LD_IS := $(call IDENT_COMPILER,$(LD))
  LD_IS_GCC_LIKE := $(call CLASS_IS_GCC_LIKE,$(LD_IS))
endif
ifneq ($(LD_IS_GCC_LIKE),)
  LDFLAGS_SHARED = -shared
endif

# Archiver (static libraries)
AR_SPECIFIED = $(filter-out undefined default,$(origin AR))
ifeq ($(AR_SPECIFIED),)
  # AR was not specified
  ifneq ($(CC_IS_GCC_LIKE),)
    X := $(call MAP_CMD,$(CC),$(CC_TO_AR_MAP))
    ifneq ($(X),)
      AR := $(X)
    endif
  endif
endif



# LOAD PROJECT SPECIFIC CONFIGURATION

EXTRA_CFLAGS  =
EXTRA_LDFLAGS =

GENERIC_MK := $(lastword $(MAKEFILE_LIST))
GENERIC_MK_DIR := $(patsubst %/,%,$(dir $(GENERIC_MK)))
PROJECT_MK := $(GENERIC_MK_DIR)/project.mk
DEP_MAKEFILES := Makefile $(GENERIC_MK)
ifneq ($(wildcard $(PROJECT_MK)),)
  DEP_MAKEFILES += $(PROJECT_MK)
  include $(PROJECT_MK)
endif

ifneq ($(INCLUDE_ROOT),)
  REL_INCLUDE_ROOT := $(call MAKE_REL_PATH,$(dir $(GENERIC_MK))/$(INCLUDE_ROOT))
endif

ROOT_INC_FLAG := $(EMPTY)
ROOT_INC_FLAG_COVER := $(EMPTY)
ifneq ($(REL_INCLUDE_ROOT),)
  ROOT_INC_FLAG += -I$(REL_INCLUDE_ROOT)
  ROOT_INC_FLAG_COVER += -I$(call MAKE_ABS_PATH,$(REL_INCLUDE_ROOT))
endif



# SETUP BUILD COMMANDS

CFLAGS_SPECIFIED  := $(filter-out undefined default,$(origin CFLAGS))
LDFLAGS_SPECIFIED := $(filter-out undefined default,$(origin LDFLAGS))
ARFLAGS_SPECIFIED := $(filter-out undefined default,$(origin ARFLAGS))
ifneq ($(CFLAGS_SPECIFIED),)
CFLAGS_GENERAL = $(CFLAGS)
endif
ifneq ($(LDFLAGS_SPECIFIED),)
LDFLAGS_GENERAL = $(LDFLAGS)
endif
ifneq ($(ARFLAGS_SPECIFIED),)
ARFLAGS_GENERAL = $(ARFLAGS)
endif
CFLAGS_GENERAL  += $(EXTRA_CFLAGS)
LDFLAGS_GENERAL += $(EXTRA_LDFLAGS)

CC_STATIC_OPTIM   = $(CC) $(CFLAGS_OPTIM) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CC_SHARED_OPTIM   = $(CC) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CC_STATIC_DEBUG   = $(CC) $(CFLAGS_DEBUG) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CC_SHARED_DEBUG   = $(CC) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CC_STATIC_COVER   = $(CC) $(CFLAGS_COVER) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)
CC_SHARED_COVER   = $(CC) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)

CXX_STATIC_OPTIM  = $(CXX) $(CFLAGS_OPTIM) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CXX_SHARED_OPTIM  = $(CXX) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CXX_STATIC_DEBUG  = $(CXX) $(CFLAGS_DEBUG) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CXX_SHARED_DEBUG  = $(CXX) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
CXX_STATIC_COVER  = $(CXX) $(CFLAGS_COVER) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)
CXX_SHARED_COVER  = $(CXX) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)

OCC_STATIC_OPTIM  = $(OCC) $(CFLAGS_OPTIM) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCC_SHARED_OPTIM  = $(OCC) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCC_STATIC_DEBUG  = $(OCC) $(CFLAGS_DEBUG) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCC_SHARED_DEBUG  = $(OCC) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCC_STATIC_COVER  = $(OCC) $(CFLAGS_COVER) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(CFLAGS_OBJC) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)
OCC_SHARED_COVER  = $(OCC) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_C) $(CFLAGS_OBJC) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)

OCXX_STATIC_OPTIM = $(OCXX) $(CFLAGS_OPTIM) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCXX_SHARED_OPTIM = $(OCXX) $(CFLAGS_OPTIM) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCXX_STATIC_DEBUG = $(OCXX) $(CFLAGS_DEBUG) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCXX_SHARED_DEBUG = $(OCXX) $(CFLAGS_DEBUG) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(CFLAGS_OBJC) $(ROOT_INC_FLAG) $(CFLAGS_GENERAL)
OCXX_STATIC_COVER = $(OCXX) $(CFLAGS_COVER) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(CFLAGS_OBJC) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)
OCXX_SHARED_COVER = $(OCXX) $(CFLAGS_COVER) $(CFLAGS_SHARED) $(CFLAGS_PTHREADS) $(CFLAGS_CXX) $(CFLAGS_OBJC) $(ROOT_INC_FLAG_COVER) $(CFLAGS_GENERAL)

CFLAGS_OTHER = $(CFLAGS_ARCH) $(CFLAGS_INCLUDE) $(CFLAGS_AUTODEP)

LD_LIB_OPTIM      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_OPTIM) $(LDFLAGS_PTHREADS) $(LDFLAGS_GENERAL)
LD_LIB_DEBUG      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_DEBUG) $(LDFLAGS_PTHREADS) $(LDFLAGS_GENERAL)
LD_LIB_COVER      = $(LD) $(LDFLAGS_SHARED) $(LDFLAGS_COVER) $(LDFLAGS_PTHREADS) $(LDFLAGS_GENERAL)
LD_PROG_OPTIM     = $(LD) $(LDFLAGS_OPTIM) $(LDFLAGS_PTHREADS) $(LDFLAGS_GENERAL)
LD_PROG_DEBUG     = $(LD) $(LDFLAGS_DEBUG) $(LDFLAGS_PTHREADS) $(LDFLAGS_GENERAL)
LD_PROG_COVER     = $(LD) $(LDFLAGS_COVER) $(LDFLAGS_PTHREADS) $(LDFLAGS_GENERAL)



BASE_DENOM_2            := $(if $(BASE_DENOM),-$(BASE_DENOM))
SUFFIX_OBJ_STATIC_OPTIM := $(BASE_DENOM_2)$(OBJ_DENOM_OPTIM).o
SUFFIX_OBJ_SHARED_OPTIM := $(BASE_DENOM_2)$(OBJ_DENOM_OPTIM)$(OBJ_DENOM_SHARED).o
SUFFIX_OBJ_STATIC_DEBUG := $(BASE_DENOM_2)$(OBJ_DENOM_DEBUG).o
SUFFIX_OBJ_SHARED_DEBUG := $(BASE_DENOM_2)$(OBJ_DENOM_DEBUG)$(OBJ_DENOM_SHARED).o
SUFFIX_OBJ_STATIC_COVER := $(BASE_DENOM_2)$(OBJ_DENOM_COVER).o
SUFFIX_OBJ_SHARED_COVER := $(BASE_DENOM_2)$(OBJ_DENOM_COVER)$(OBJ_DENOM_SHARED).o
SUFFIX_LIB_STATIC_OPTIM := $(BASE_DENOM_2)$(LIB_DENOM_OPTIM)$(LIB_SUFFIX_STATIC)
SUFFIX_LIB_SHARED_OPTIM := $(BASE_DENOM_2)$(LIB_DENOM_OPTIM)$(LIB_SUFFIX_SHARED)
SUFFIX_LIB_STATIC_DEBUG := $(BASE_DENOM_2)$(LIB_DENOM_DEBUG)$(LIB_SUFFIX_STATIC)
SUFFIX_LIB_SHARED_DEBUG := $(BASE_DENOM_2)$(LIB_DENOM_DEBUG)$(LIB_SUFFIX_SHARED)
SUFFIX_LIB_STATIC_COVER := $(BASE_DENOM_2)$(LIB_DENOM_COVER)$(LIB_SUFFIX_STATIC)
SUFFIX_LIB_SHARED_COVER := $(BASE_DENOM_2)$(LIB_DENOM_COVER)$(LIB_SUFFIX_SHARED)
SUFFIX_PROG_OPTIM       := $(BASE_DENOM_2)$(PROG_DENOM_OPTIM)$(PROG_SUFFIX)
SUFFIX_PROG_DEBUG       := $(BASE_DENOM_2)$(PROG_DENOM_DEBUG)$(PROG_SUFFIX)
SUFFIX_PROG_COVER       := $(BASE_DENOM_2)$(PROG_DENOM_COVER)$(PROG_SUFFIX)

GET_FLAGS = $($(1)) $($(1)_$(2))
FOLD_TARGET = $(subst /,_,$(subst .,_,$(subst -,_,$(1))))
GET_LIBRARY_STEM         = $(patsubst %.a,%,$(1))
GET_OBJECTS_FOR_TARGET   = $(addsuffix $(2),$(basename $($(call FOLD_TARGET,$(1))_SOURCES)))
GET_LDFLAGS_FOR_TARGET   = $(foreach x,PROJECT DIR $(call FOLD_TARGET,$(1)),$(call GET_FLAGS,$(x)_LDFLAGS,$(2)))
GET_DEPS_FOR_TARGET      = $($(call FOLD_TARGET,$(1))_DEPS)
GET_LIBRARY_VERSION      = $(call GET_LIBRARY_VERSION_2,$(strip $($(call FOLD_TARGET,$(1))_VERSION)))
GET_LIBRARY_VERSION_2    = $(if $(1),$(wordlist 1,3,$(subst :, ,$(1):0:0)))

PRIMARIES := HEADERS LIBRARIES PROGRAMS
PRIMARY_PREFIXES := bin sbin lib libexec include
INCLUDE_SUBDIR :=

USING_SUBINCLUDE := $(strip $(foreach x,$(PRIMARIES) $(PRIMARIES)_EXTRA_UNINSTALL,$(subinclude_$(x))$(nobase_subinclude_$(x))))
ifneq ($(USING_SUBINCLUDE),)
ifeq ($(REL_INCLUDE_ROOT),)
$(error Cannot determine installation directory for `subinclude` when `INCLUDE_ROOT` is unspecified)
endif
INSIDE_INCLUDE_ROOT := $(or $(call IS_SAME_PATH_AS,.,$(REL_INCLUDE_ROOT)),$(call IS_PATH_CONTAINED_IN,.,$(REL_INCLUDE_ROOT)))
ifeq ($(INSIDE_INCLUDE_ROOT),)
$(error Cannot determine installation directory for `subinclude` from outside `INCLUDE_ROOT`)
endif
PRIMARY_PREFIXES += subinclude
INCLUDE_SUBDIR := $(call PATH_DIFF,.,$(REL_INCLUDE_ROOT))
endif

PRIMARY_PREFIXES += $(EXTRA_PRIMARY_PREFIXES)

# ARGS: primary_prefix
GET_INSTALL_DIR = $(if $(filter subinclude,$(1)),$(call GET_ROOT_INSTALL_DIR,include)$(call COND_PREPEND,/,$(INCLUDE_SUBDIR)),$(call GET_ROOT_INSTALL_DIR,$(1)))
GET_ROOT_INSTALL_DIR = $(if $($(1)dir),$(patsubst %/,%,$($(1)dir)),$(error Variable `$(1)dir` was not specified))

# ARGS: folded_lib_target, install_dir
define RECORD_LIB_INSTALL_DIR
GMK_INSTALL_DIR_$(1) = $(2)
endef

# ARGS: primary_prefix, install_dir
RECORD_LIB_INSTALL_DIRS = \
$(foreach x,$($(1)_LIBRARIES),$(eval $(call RECORD_LIB_INSTALL_DIR,$(call FOLD_TARGET,$(x)),$(2))))\
$(foreach x,$(nobase_$(1)_LIBRARIES),$(eval $(call RECORD_LIB_INSTALL_DIR,$(call FOLD_TARGET,$(x)),$(patsubst %/,%,$(dir $(2)/$(x))))))

$(foreach x,$(PRIMARY_PREFIXES),$(call RECORD_LIB_INSTALL_DIRS,$(x),$(call GET_INSTALL_DIR,$(x))))

# ARGS: installable_lib_target
GET_INSTALL_DIR_FOR_LIB_TARGET = $(value GMK_INSTALL_DIR_$(call FOLD_TARGET,$(1)))

INST_PROGRAMS  := $(strip $(foreach x,$(PRIMARY_PREFIXES),$($(x)_PROGRAMS)  $(nobase_$(x)_PROGRAMS)))
INST_LIBRARIES := $(strip $(foreach x,$(PRIMARY_PREFIXES),$($(x)_LIBRARIES) $(nobase_$(x)_LIBRARIES)))

LIBRARIES := $(INST_LIBRARIES) $(noinst_LIBRARIES) $(check_LIBRARIES)
PROGRAMS  := $(INST_PROGRAMS) $(DEV_PROGRAMS) $(noinst_PROGRAMS) $(check_PROGRAMS)

SOURCE_DIRS := $(patsubst ././,./,$(patsubst %,./%,$(call REMOVE_DUPES,$(dir $(foreach x,$(LIBRARIES) $(PROGRAMS),$($(call FOLD_TARGET,$(x))_SOURCES))))))

OBJECTS_STATIC_OPTIM := $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_OPTIM)))
OBJECTS_SHARED_OPTIM := $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_OPTIM)))
OBJECTS_STATIC_DEBUG := $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_DEBUG)))
OBJECTS_SHARED_DEBUG := $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_DEBUG)))
OBJECTS_STATIC_COVER := $(foreach x,$(LIBRARIES) $(PROGRAMS),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_STATIC_COVER)))
OBJECTS_SHARED_COVER := $(foreach x,$(LIBRARIES),$(call GET_OBJECTS_FOR_TARGET,$(x),$(SUFFIX_OBJ_SHARED_COVER)))
OBJECTS := $(sort $(OBJECTS_STATIC_OPTIM) $(OBJECTS_SHARED_OPTIM) $(OBJECTS_STATIC_DEBUG) $(OBJECTS_SHARED_DEBUG) $(OBJECTS_STATIC_COVER) $(OBJECTS_SHARED_COVER))

TARGETS_LIB_STATIC_OPTIM   := $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_LIB_SHARED_OPTIM   := $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_SHARED_OPTIM))
TARGETS_LIB_STATIC_DEBUG   := $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_LIB_SHARED_DEBUG   := $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_SHARED_DEBUG))
TARGETS_LIB_STATIC_COVER   := $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_LIB_SHARED_COVER   := $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_SHARED_COVER))
TARGETS_INST_LIB_LIBDEPS   := $(foreach x,$(INST_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(LIB_SUFFIX_LIBDEPS))
TARGETS_NOINST_LIB_OPTIM   := $(foreach x,$(noinst_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_NOINST_LIB_DEBUG   := $(foreach x,$(noinst_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_NOINST_LIB_COVER   := $(foreach x,$(noinst_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_NOINST_LIB_LIBDEPS := $(foreach x,$(noinst_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(LIB_SUFFIX_LIBDEPS))
TARGETS_CHECK_LIB_OPTIM     := $(foreach x,$(check_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_OPTIM))
TARGETS_CHECK_LIB_DEBUG     := $(foreach x,$(check_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_DEBUG))
TARGETS_CHECK_LIB_COVER     := $(foreach x,$(check_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(SUFFIX_LIB_STATIC_COVER))
TARGETS_CHECK_LIB_LIBDEPS   := $(foreach x,$(check_LIBRARIES),$(call GET_LIBRARY_STEM,$(x))$(LIB_SUFFIX_LIBDEPS))
TARGETS_PROG_OPTIM         := $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_PROG_DEBUG         := $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_PROG_COVER         := $(foreach x,$(INST_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))
TARGETS_DEV_PROG_OPTIM     := $(foreach x,$(DEV_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_DEV_PROG_DEBUG     := $(foreach x,$(DEV_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_NOINST_PROG_OPTIM  := $(foreach x,$(noinst_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_NOINST_PROG_DEBUG  := $(foreach x,$(noinst_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_NOINST_PROG_COVER  := $(foreach x,$(noinst_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))
TARGETS_CHECK_PROG_OPTIM    := $(foreach x,$(check_PROGRAMS),$(x)$(SUFFIX_PROG_OPTIM))
TARGETS_CHECK_PROG_DEBUG    := $(foreach x,$(check_PROGRAMS),$(x)$(SUFFIX_PROG_DEBUG))
TARGETS_CHECK_PROG_COVER    := $(foreach x,$(check_PROGRAMS),$(x)$(SUFFIX_PROG_COVER))

TARGETS_BUILD :=
ifneq ($(ENABLE_INSTALL_STATIC_LIBS),)
TARGETS_BUILD += $(TARGETS_LIB_STATIC_OPTIM)
endif
TARGETS_BUILD += $(TARGETS_LIB_SHARED_OPTIM)
ifneq ($(or $(ENABLE_INSTALL_DEBUG_LIBS),$(ENABLE_INSTALL_DEBUG_PROGS)),)
TARGETS_BUILD += $(TARGETS_LIB_SHARED_DEBUG)
endif
TARGETS_BUILD += $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_BUILD += $(TARGETS_NOINST_LIB_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_PROGS),)
TARGETS_BUILD += $(TARGETS_NOINST_LIB_DEBUG)
endif
TARGETS_BUILD += $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_BUILD += $(TARGETS_PROG_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_PROGS),)
TARGETS_BUILD += $(TARGETS_PROG_DEBUG)
endif
TARGETS_BUILD += $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG) $(TARGETS_NOINST_PROG_OPTIM)

TARGETS_RELEASE     := $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_RELEASE     += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_RELEASE     += $(TARGETS_PROG_OPTIM) $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_NOINST_PROG_OPTIM)
TARGETS_NODEBUG     := $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_NODEBUG     += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_NODEBUG     += $(TARGETS_PROG_OPTIM) $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_NOINST_PROG_OPTIM)
TARGETS_DEBUG       := $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_DEBUG       += $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_DEBUG       += $(TARGETS_PROG_DEBUG) $(TARGETS_DEV_PROG_DEBUG) $(TARGETS_NOINST_PROG_DEBUG)
TARGETS_COVER       := $(TARGETS_LIB_SHARED_COVER) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_COVER       += $(TARGETS_NOINST_LIB_COVER) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_COVER       += $(TARGETS_PROG_COVER) $(TARGETS_NOINST_PROG_COVER)
TARGETS_CHECK       := $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_CHECK       += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_CHECK       += $(TARGETS_CHECK_LIB_OPTIM) $(TARGETS_CHECK_LIB_LIBDEPS)
TARGETS_CHECK       += $(TARGETS_PROG_OPTIM) $(TARGETS_CHECK_PROG_OPTIM)
TARGETS_CHECK_DEBUG := $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_CHECK_DEBUG += $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_CHECK_DEBUG += $(TARGETS_CHECK_LIB_DEBUG) $(TARGETS_CHECK_LIB_LIBDEPS)
TARGETS_CHECK_DEBUG += $(TARGETS_PROG_DEBUG) $(TARGETS_CHECK_PROG_DEBUG)
TARGETS_CHECK_COVER := $(TARGETS_LIB_SHARED_COVER) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_CHECK_COVER += $(TARGETS_NOINST_LIB_COVER) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_CHECK_COVER += $(TARGETS_CHECK_LIB_COVER) $(TARGETS_CHECK_LIB_LIBDEPS)
TARGETS_CHECK_COVER += $(TARGETS_PROG_COVER) $(TARGETS_CHECK_PROG_COVER)

TARGETS_EVERYTHING := $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_SHARED_OPTIM)
TARGETS_EVERYTHING += $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS_EVERYTHING += $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS_EVERYTHING += $(TARGETS_CHECK_LIB_OPTIM) $(TARGETS_CHECK_LIB_DEBUG) $(TARGETS_CHECK_LIB_LIBDEPS)
TARGETS_EVERYTHING += $(TARGETS_PROG_OPTIM) $(TARGETS_PROG_DEBUG)
TARGETS_EVERYTHING += $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG)
TARGETS_EVERYTHING += $(TARGETS_NOINST_PROG_OPTIM) $(TARGETS_NOINST_PROG_DEBUG)
TARGETS_EVERYTHING += $(TARGETS_CHECK_PROG_OPTIM) $(TARGETS_CHECK_PROG_DEBUG)

TARGETS_LIB_STATIC  := $(TARGETS_LIB_STATIC_OPTIM) $(TARGETS_LIB_STATIC_DEBUG) $(TARGETS_LIB_STATIC_COVER)
TARGETS_LIB_SHARED  := $(TARGETS_LIB_SHARED_OPTIM) $(TARGETS_LIB_SHARED_DEBUG) $(TARGETS_LIB_SHARED_COVER)
TARGETS_NOINST_LIB  := $(TARGETS_NOINST_LIB_OPTIM) $(TARGETS_NOINST_LIB_DEBUG) $(TARGETS_NOINST_LIB_COVER)
TARGETS_CHECK_LIB   := $(TARGETS_CHECK_LIB_OPTIM) $(TARGETS_CHECK_LIB_DEBUG) $(TARGETS_CHECK_LIB_COVER)
TARGETS_PROG        := $(TARGETS_PROG_OPTIM) $(TARGETS_PROG_DEBUG) $(TARGETS_PROG_COVER)
TARGETS_DEV_PROG    := $(TARGETS_DEV_PROG_OPTIM) $(TARGETS_DEV_PROG_DEBUG)
TARGETS_NOINST_PROG := $(TARGETS_NOINST_PROG_OPTIM) $(TARGETS_NOINST_PROG_DEBUG) $(TARGETS_NOINST_PROG_COVER)
TARGETS_CHECK_PROG  := $(TARGETS_CHECK_PROG_OPTIM) $(TARGETS_CHECK_PROG_DEBUG) $(TARGETS_CHECK_PROG_COVER)
TARGETS_PROG_ALL    := $(foreach x,$(TARGETS_PROG) $(TARGETS_DEV_PROG),$(x) $(x)-noinst) $(TARGETS_NOINST_PROG) $(TARGETS_CHECK_PROG)

# ARGS: real_local_path, version
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

TARGETS_LIB_SHARED_ALIASES = $(foreach x,$(INST_LIBRARIES),$(foreach y,OPTIM DEBUG COVER,$(call TARGETS_LIB_SHARED_ALIASES_1,$(x),$(SUFFIX_LIB_SHARED_$(y)))))
TARGETS_LIB_SHARED_ALIASES_1 = $(call GET_SHARED_LIB_ALIASES,$(call GET_LIBRARY_STEM,$(1))$(2),$(call GET_LIBRARY_VERSION,$(1)))

TARGETS := $(TARGETS_LIB_STATIC) $(TARGETS_LIB_SHARED_ALIASES) $(TARGETS_INST_LIB_LIBDEPS)
TARGETS += $(TARGETS_NOINST_LIB) $(TARGETS_NOINST_LIB_LIBDEPS)
TARGETS += $(TARGETS_CHECK_LIB) $(TARGETS_CHECK_LIB_LIBDEPS) $(TARGETS_PROG_ALL)

RECURSIVE_GOALS = build release nodebug debug cover everything clean install-only uninstall \
check-norun check-debug-norun check-cover-norun check check-debug check-cover memcheck memcheck-debug

.DEFAULT_GOAL :=

.PHONY: all
all: build

build/local:             $(TARGETS_BUILD)
release/local:           $(TARGETS_RELEASE)
nodebug/local:           $(TARGETS_NODEBUG)
debug/local:             $(TARGETS_DEBUG)
cover/local:             $(TARGETS_COVER)
everything/local:        $(TARGETS_EVERYTHING)
check-norun/local:       $(TARGETS_CHECK)
check-debug-norun/local: $(TARGETS_CHECK_DEBUG)
check-cover-norun/local: $(TARGETS_CHECK_COVER)


# Update everything if any makefile or any generated source has changed
$(GENERATED_SOURCES) $(OBJECTS) $(TARGETS): $(DEP_MAKEFILES)
$(OBJECTS): $(GENERATED_SOURCES)

# Disable all suffix rules and some interfering implicit pattern rules
.SUFFIXES:
%: %.o
%: %.c
%: %.cpp



# SUBPROJECTS

# ARGS: recursive_goal, subdirs_for_goal, subdir_deps_for_this_dir
define RECURSIVE_GOAL_RULES
.PHONY: $(1) $(1)/this-dir $(1)/local
$(1): $(1)/this-dir $(patsubst %,$(1)/subdir/%,$(2))
ifeq ($(strip $(3)),)
$(1)/this-dir: $(1)/local
else
$(1)/this-dir:
	@$$(MAKE) --no-print-directory $(1)/local
endif
endef

# ARGS: recursive_goal, subdir_dep_for_this_dir
define SUBDIR_DEP_FOR_THIS_DIR_RULE
$(1)/this-dir: $(1)/subdir/$(2)
endef

# ARGS: recursive_goal, subdir
define RECURSIVE_GOAL_SUBDIR_RULES
.PHONY: $(1)/subdir/$(2)
ifeq ($(1),build)
$(1)/subdir/$(2):
	@$$(MAKE) -w -C $(2)
else
$(1)/subdir/$(2):
	@$$(MAKE) -w -C $(2) $(1)
endif
endef

# ARGS: recursive_goal, subdir, dep
define SUBDIR_DEP_RULE
ifeq ($(3),.)
$(1)/subdir/$(2): $(1)/this-dir
else
$(1)/subdir/$(2): $(1)/subdir/$(3)
endif
endef

AVAIL_PASSIVE_SUBDIRS := $(foreach x,$(PASSIVE_SUBDIRS),$(if $(realpath $(x)),$(x)))

# ARGS: recursive_goal
GET_SUBDIRS_FOR_RECURSIVE_GOAL = $(if $(filter clean,$(1)),$(SUBDIRS) $(AVAIL_PASSIVE_SUBDIRS),$(SUBDIRS))

# ARGS: recursive_goal
GET_SUBDIR_DEPS_FOR_THIS_DIR = $(if $(filter clean install-only,$(1)),,$(if $(filter uninstall,$(1)),$(SUBDIRS),$(DIR_DEPS)))

# ARGS: recursive_goal, subdir
GET_SUBDIR_DEPS = $(if $(filter clean uninstall,$(1)),,$(if $(filter install-only,$(1)),.,$($(call FOLD_TARGET,$(2))_DEPS)))

# ARGS: recursive_goal, subdir, deps
EVAL_RECURSIVE_GOAL_SUBDIR_RULES = \
$(eval $(call RECURSIVE_GOAL_SUBDIR_RULES,$(1),$(2)))\
$(foreach x,$(call GET_SUBDIR_DEPS,$(1),$(2)),$(eval $(call SUBDIR_DEP_RULE,$(1),$(2),$(x))))

# ARGS: recursive_goal, subdir_deps_for_this_dir
EVAL_RECURSIVE_GOAL_RULES = \
$(eval $(call RECURSIVE_GOAL_RULES,$(1),$(call GET_SUBDIRS_FOR_RECURSIVE_GOAL,$(1)),$(2)))\
$(foreach x,$(2),$(eval $(call SUBDIR_DEP_FOR_THIS_DIR_RULE,$(1),$(x))))\
$(foreach x,$(SUBDIRS) $(PASSIVE_SUBDIRS),$(call EVAL_RECURSIVE_GOAL_SUBDIR_RULES,$(1),$(x)))

$(foreach x,$(RECURSIVE_GOALS),$(call EVAL_RECURSIVE_GOAL_RULES,$(x),$(call GET_SUBDIR_DEPS_FOR_THIS_DIR,$(x))))



# CLEANING

GET_CLEAN_FILES = $(strip $(call WILDCARD_PATHS_FILTER_OUT,$(EXTRA_CLEAN),$(foreach x,$(SOURCE_DIRS),$(foreach y,*.d *.o *.gcno *.gcda,$(patsubst ./%,%,$(x))$(y))) $(TARGETS)) $(EXTRA_CLEAN))

ifneq ($(word 1,$(or $(SOURCE_DIRS),$(TARGETS),$(EXTRA_CLEAN))),)
define CLEANING_RULES
clean/local:
	$$(RM) $$(call GET_CLEAN_FILES)
endef
$(eval $(CLEANING_RULES))
endif



# INSTALL / UNINSTALL

.PHONY: install
install: build
	@$(MAKE) install-only

HAS_STAR = $(call HAS_STAR_1,$(subst *,x$(SPACE)x,$(subst $(SPACE),x,$(1))))
HAS_STAR_1 = $(wordlist 2,$(words $(1)),$(1))

CHECK_WILDCARD = $(if $(call HAS_STAR,$(word 1,$(subst /,$(SPACE),$(1)))),$(error For your safety, uninstallation wildcards are not allowed to appear at the root level of the target installation directory [$(1)]))
CHECK_WILDCARDS = $(foreach x,$(PRIMARIES),$(foreach y,$(notdir $($(1)_$(x)_EXTRA_UNINSTALL)) $(nobase_$(1)_$(x)_EXTRA_UNINSTALL),$(call CHECK_WILDCARD,$(2)$(y))))
$(foreach x,$(PRIMARY_PREFIXES),$(call CHECK_WILDCARDS,$(x),$(if $(filter subinclude,$(x)),$(call COND_APPEND,$(INCLUDE_SUBDIR),/))))

DESTDIR_2 := $(call SHELL_ESCAPE,$(call UNHIDE_SPACE,$(patsubst %/,%,$(call HIDE_SPACE,$(value DESTDIR)))))

# ARGS: install_dir, real_local_paths
INSTALL_RECIPE_FILES   = $(NL_TAB)$$(INSTALL_DATA) $(2) $$(DESTDIR_2)$(1)
UNINSTALL_RECIPE_FILES = $(NL_TAB)$$(RM) $(foreach x,$(2),$$(DESTDIR_2)$(1)/$(x))

# ARGS: install_dir, real_local_paths
INSTALL_RECIPE_LIBS = $(NL_TAB)$$(INSTALL_LIBRARY) $(2) $$(DESTDIR_2)$(1)

# ARGS: real_local_path, version
INSTALL_FILES_VERSIONED_LIB = $(1)

# ARGS: install_dir, real_local_path, version
INSTALL_RECIPE_VERSIONED_LIB = $(INSTALL_RECIPE_LIBS)

ifeq ($(OS),Linux)
INSTALL_FILES_VERSIONED_LIB    = $(if $(2),$(call INSTALL_FILES_VERSIONED_LIB_1,$(1),$(call MAP_SHARED_LIB_VERSION,$(2))),$(1))
INSTALL_FILES_VERSIONED_LIB_1  = $(1) $(1).$(word 1,$(2)) $(1).$(word 2,$(2))
INSTALL_RECIPE_VERSIONED_LIB   = $(if $(3),$(call INSTALL_RECIPE_VERSIONED_LIB_1,$(1),$(2),$(call MAP_SHARED_LIB_VERSION,$(3))),$(INSTALL_RECIPE_LIBS))
INSTALL_RECIPE_VERSIONED_LIB_1 = $(call INSTALL_RECIPE_VERSIONED_LIB_2,$(1),$(2),$(2).$(word 1,$(3)),$(2).$(word 2,$(3)))
INSTALL_RECIPE_VERSIONED_LIB_2 = $(call INSTALL_RECIPE_LIBS,$(1),$(4))$(NL_TAB)cd $$(DESTDIR_2)$(1) && ln -s -f $(notdir $(4)) $(notdir $(3)) && ln -s -f $(notdir $(3)) $(notdir $(2))
endif

ifeq ($(OS),Darwin)
INSTALL_FILES_VERSIONED_LIB    = $(if $(2),$(1) $(word 1,$(call MAP_SHARED_LIB_VERSION,$(1),$(2))),$(1))
INSTALL_RECIPE_VERSIONED_LIB   = $(if $(3),$(call INSTALL_RECIPE_VERSIONED_LIB_1,$(1),$(2),$(word 1,$(call MAP_SHARED_LIB_VERSION,$(2),$(3)))),$(INSTALL_RECIPE_LIBS))
INSTALL_RECIPE_VERSIONED_LIB_1 = $(call INSTALL_RECIPE_LIBS,$(1),$(3))$(NL_TAB)cd $$(DESTDIR_2)$(1) && ln -s -f $(notdir $(3)) $(notdir $(2))
endif

INST_STATIC_LIB_SUFFICES :=
INST_SHARED_LIB_SUFFICES :=
INST_PROG_SUFFICES :=
ifneq ($(ENABLE_INSTALL_STATIC_LIBS),)
INST_STATIC_LIB_SUFFICES += +$(SUFFIX_LIB_STATIC_OPTIM)
endif
INST_SHARED_LIB_SUFFICES += +$(SUFFIX_LIB_SHARED_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_LIBS),)
INST_SHARED_LIB_SUFFICES += +$(SUFFIX_LIB_SHARED_DEBUG)
endif
INST_PROG_SUFFICES += +$(SUFFIX_PROG_OPTIM)
ifneq ($(ENABLE_INSTALL_DEBUG_PROGS),)
INST_PROG_SUFFICES += +$(SUFFIX_PROG_DEBUG)
endif

# ARGS: abstract_targets
INSTALL_FILES_STATIC_LIBS = $(foreach x,$(1),$(foreach y,$(INST_STATIC_LIB_SUFFICES),$(call GET_LIBRARY_STEM,$(x))$(patsubst +%,%,$(y))))
INSTALL_FILES_SHARED_LIBS = $(foreach x,$(1),$(foreach y,$(INST_SHARED_LIB_SUFFICES),$(call INSTALL_FILES_VERSIONED_LIB,$(call GET_LIBRARY_STEM,$(x))$(patsubst +%,%,$(y)),$(call GET_LIBRARY_VERSION,$(x)))))
INSTALL_FILES_PROGRAMS    = $(foreach x,$(1),$(foreach y,$(INST_PROG_SUFFICES),$(x)$(patsubst +%,%,$(y))))

# ARGS: install_dir, abstract_targets
INSTALL_RECIPE_STATIC_LIBS = $(call INSTALL_RECIPE_STATIC_LIBS_1,$(1),$(call INSTALL_FILES_STATIC_LIBS,$(2)))
INSTALL_RECIPE_STATIC_LIBS_1 = $(if $(2),$(call INSTALL_RECIPE_LIBS,$(1),$(2)))
INSTALL_RECIPE_SHARED_LIBS = $(foreach x,$(2),$(foreach y,$(INST_SHARED_LIB_SUFFICES),$(call INSTALL_RECIPE_VERSIONED_LIB,$(1),$(call GET_LIBRARY_STEM,$(x))$(patsubst +%,%,$(y)),$(call GET_LIBRARY_VERSION,$(x)))$(NEWLINE)))
INSTALL_RECIPE_PROGRAMS    = $(NL_TAB)$$(INSTALL_PROGRAM) $(call INSTALL_FILES_PROGRAMS,$(2)) $$(DESTDIR_2)$(1)

# ARGS: primary, is_for_uninstall
GET_INSTALL_DIRS = $(foreach x,$(PRIMARY_PREFIXES),$(if $(filter subinclude,$(x)),$(call GET_INSTALL_DIRS_1,$(call GET_ROOT_INSTALL_DIR,include),$(call COND_APPEND,$(INCLUDE_SUBDIR),/),$(x),$(1),$(2)),$(call GET_INSTALL_DIRS_1,$(call GET_ROOT_INSTALL_DIR,$(x)),,$(x),$(1),$(2))))

# ARGS: root_install_dir, opt_include_subdir_slash, primary_prefix, primary, is_for_uninstall
GET_INSTALL_DIRS_1 = $(call GET_INSTALL_DIRS_2,$(1),$(2),$(notdir $($(3)_$(4))) $(nobase_$(3)_$(4)),$(5))

# ARGS: root_install_dir, opt_include_subdir_slash, nobase_targets, is_for_uninstall
GET_INSTALL_DIRS_2 = $(foreach x,$(call REMOVE_DUPES,$(patsubst %/,%,$(dir $(addprefix $(2),$(3))))),$(if $(filter .,$(x)),$(if $(4),,$(1)),$(foreach y,$(call SUBDIR_PARENT_EXPAND,$(x)),$(1)/$(y))))

SUBDIR_PARENT_EXPAND = $(if $(filter-out ./,$(dir $(1))),$(call SUBDIR_PARENT_EXPAND,$(patsubst %/,%,$(dir $(1)))) $(1),$(1))

# ARGS: primary, get_recipes
GET_INSTALL_RECIPES = $(foreach x,$(PRIMARY_PREFIXES),$(call GET_INSTALL_RECIPES_1,$(2),$(call GET_INSTALL_DIR,$(x)),$(strip $($(x)_$(1))),$(nobase_$(x)_$(1))))

# ARGS: get_recipes, install_dir, abstract_targets, nobase_targets
GET_INSTALL_RECIPES_1 = $(if $(3),$(call $(1),$(2),$(3))$(NEWLINE)) $(foreach x,$(call REMOVE_DUPES,$(dir $(4))),$(call $(1),$(2)$(patsubst %/,/%,$(filter-out ./,$(x))),$(strip $(foreach y,$(4),$(if $(call IS_EQUAL_TO,$(dir $(y)),$(x)),$(y)))))$(NEWLINE))

# ARGS: primary, get_files
GET_UNINSTALL_RECIPES = $(foreach x,$(PRIMARY_PREFIXES),$(call GET_UNINSTALL_RECIPES_1,$(call GET_INSTALL_DIR,$(x)),$(2),$($(x)_$(1)),$(nobase_$(x)_$(1)),$(call REMOVE_DUPES,$(notdir $($(x)_$(1)_EXTRA_UNINSTALL)) $(nobase_$(x)_$(1)_EXTRA_UNINSTALL))))

# ARGS: install_dir, get_files, abstract_targets, nobase_targets, extra_uninstall
GET_UNINSTALL_RECIPES_1 = $(call GET_UNINSTALL_RECIPES_2,$(1),$(strip $(call WILDCARD_PATHS_FILTER_OUT,$(5),$(notdir $(call $(2),$(3))) $(call $(2),$(4))) $(5)))

# ARGS: install_dir, uninstall_paths
GET_UNINSTALL_RECIPES_2 = $(if $(2), $(call UNINSTALL_RECIPE_FILES,$(1),$(2))$(NEWLINE))

INSTALL_DIRS :=
UNINSTALL_DIRS :=
EXTRA_UNINSTALL_DIRS :=
INSTALL_RECIPES :=
UNINSTALL_RECIPES :=

INSTALL_FILTER_2 := $(subst $(COMMA),$(SPACE),$(INSTALL_FILTER))

ifneq ($(filter headers,$(INSTALL_FILTER_2)),)
INSTALL_DIRS += $(call GET_INSTALL_DIRS,HEADERS)
UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,HEADERS,x)
EXTRA_UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,HEADERS_EXTRA_UNINSTALL,x)
INSTALL_RECIPES += $(call GET_INSTALL_RECIPES,HEADERS,INSTALL_RECIPE_FILES)$(NEWLINE)
UNINSTALL_RECIPES += $(call GET_UNINSTALL_RECIPES,HEADERS,IDENTITY)$(NEWLINE)
endif
ifneq ($(filter static-libs,$(INSTALL_FILTER_2)),)
INSTALL_DIRS += $(call GET_INSTALL_DIRS,LIBRARIES)
UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,LIBRARIES,x)
EXTRA_UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,LIBRARIES_EXTRA_UNINSTALL,x)
INSTALL_RECIPES += $(call GET_INSTALL_RECIPES,LIBRARIES,INSTALL_RECIPE_STATIC_LIBS)$(NEWLINE)
UNINSTALL_RECIPES += $(call GET_UNINSTALL_RECIPES,LIBRARIES,INSTALL_FILES_STATIC_LIBS)$(NEWLINE)
endif
ifneq ($(filter shared-libs,$(INSTALL_FILTER_2)),)
INSTALL_DIRS += $(call GET_INSTALL_DIRS,LIBRARIES)
UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,LIBRARIES,x)
EXTRA_UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,LIBRARIES_EXTRA_UNINSTALL,x)
INSTALL_RECIPES += $(call GET_INSTALL_RECIPES,LIBRARIES,INSTALL_RECIPE_SHARED_LIBS)$(NEWLINE)
UNINSTALL_RECIPES += $(call GET_UNINSTALL_RECIPES,LIBRARIES,INSTALL_FILES_SHARED_LIBS)$(NEWLINE)
endif
ifneq ($(filter progs,$(INSTALL_FILTER_2)),)
INSTALL_DIRS += $(call GET_INSTALL_DIRS,PROGRAMS)
UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,PROGRAMS,x)
EXTRA_UNINSTALL_DIRS += $(call GET_INSTALL_DIRS,PROGRAMS_EXTRA_UNINSTALL,x)
INSTALL_RECIPES += $(call GET_INSTALL_RECIPES,PROGRAMS,INSTALL_RECIPE_PROGRAMS)$(NEWLINE)
UNINSTALL_RECIPES += $(call GET_UNINSTALL_RECIPES,PROGRAMS,INSTALL_FILES_PROGRAMS)$(NEWLINE)
endif
ifneq ($(and $(filter dev-progs,$(INSTALL_FILTER_2)),$(strip $(DEV_PROGRAMS))),)
INSTALL_DIRS += $(call GET_ROOT_INSTALL_DIR,bin)
INSTALL_RECIPES += $(call INSTALL_RECIPE_PROGRAMS,$(call GET_ROOT_INSTALL_DIR,bin),$(DEV_PROGRAMS))$(NEWLINE)
UNINSTALL_RECIPES += $(call UNINSTALL_RECIPE_FILES,$(call GET_ROOT_INSTALL_DIR,bin),$(call INSTALL_FILES_PROGRAMS,$(DEV_PROGRAMS)))$(NEWLINE)
endif

# ARGS: paths, extra_paths
FILTER_UNINSTALL_DIRS = $(call FOLD_LEFT,FILTER_UNINSTALL_DIRS_1,$(1) $(2),$(2))
FILTER_UNINSTALL_DIRS_1 = $(call REMOVE_DUPES,$(foreach x,$(1),$(if $(call WILDCARD_PATH_MATCH,$(2),$(x)),$(2),$(x))))

INSTALL_DIR_RECIPES   := $(if $(strip $(INSTALL_DIRS)),$(NL_TAB)$$(INSTALL_DIR) $(foreach x,$(call REMOVE_PREFIXES,$(patsubst %,%/,$(call REMOVE_DUPES,$(INSTALL_DIRS)))),$$(DESTDIR_2)$(x))$(NEWLINE))
UNINSTALL_DIR_RECIPES := $(foreach x,$(call LIST_REVERSE,$(call FILTER_UNINSTALL_DIRS,$(call REMOVE_DUPES,$(UNINSTALL_DIRS)),$(call REMOVE_DUPES,$(EXTRA_UNINSTALL_DIRS)))),$(NL_TAB)-rmdir $$(DESTDIR_2)$(x)/$(NEWLINE))

define INSTALL_RULES
install-only/local:$(INSTALL_DIR_RECIPES)$(INSTALL_RECIPES)
uninstall/local:$(UNINSTALL_RECIPES)$(UNINSTALL_DIR_RECIPES)
endef

ifeq ($(ENABLE_NOINST_BUILD),)
$(eval $(INSTALL_RULES))
endif


# TESTING (A.K.A CHECKING)

define CHECK_RULES

check/local: $(TARGETS_CHECK)
$(foreach x,$(TARGETS_CHECK_PROG_OPTIM),$(NL_TAB)./$(x)$(NEWLINE))

check-debug/local: $(TARGETS_CHECK_DEBUG)
$(foreach x,$(TARGETS_CHECK_PROG_DEBUG),$(NL_TAB)./$(x)$(NEWLINE))

memcheck/local: $(TARGETS_CHECK)
$(foreach x,$(TARGETS_CHECK_PROG_OPTIM),$(NL_TAB)$$(VALGRIND) $$(VALGRIND_FLAGS) --error-exitcode=1 ./$(x) --no-error-exitcode$(NEWLINE))

memcheck-debug/local: $(TARGETS_CHECK_DEBUG)
$(foreach x,$(TARGETS_CHECK_PROG_DEBUG),$(NL_TAB)$$(VALGRIND) $$(VALGRIND_FLAGS) --error-exitcode=1 ./$(x) --no-error-exitcode$(NEWLINE))

ifneq ($(strip $(or $(SOURCE_DIRS),$(TARGETS_CHECK_COVER))),)
check-cover/local: $(TARGETS_CHECK_COVER)
$(if $(SOURCE_DIRS),$(NL_TAB)$$(RM) $(foreach x,$(SOURCE_DIRS),$(patsubst ./%,%,$(x))*.gcda))
$(foreach x,$(TARGETS_CHECK_PROG_COVER),$(NL_TAB)-./$(x)$(NEWLINE))
endif

endef

$(eval $(CHECK_RULES))



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

MANGLE_LIBREF = $(subst /,_s,$(subst .,_d,$(subst -,_e,$(subst _,_u,$(1)))))

# Expand the contents of the `target_LIBS` variable for the specified
# target. The target must either be a program or an installed
# library. Relative paths in the output will be expressed relative to
# the directory holding the local `Makefile`.
#
# Output for each convenience library `x/y/libfoo.a`:
#
#     noinst:x/y/libfoo libdeps:x/y/libfoo.libdeps
#     ldflag-opt:flag... ldflag-dbg:flag... ldflag-cov:flag...
#
# For each installed library `x/y/libfoo.a` referenced directly or in
# two steps via a convenience library:
#
#     inst:x/y/libfoo libdeps:x/y/libfoo.libdeps dir:x/y lib:foo
#
# For each installed library `x/y/libfoo.a` referenced directly or
# indirectly in any number of steps, and installed as
# `/foo/bar/libfoo.so`:
#
#     rpath:/foo/bar rpath-noinst:x/y
#
# ARGS: abstract_target
EXPAND_INST_LIB_LIBREFS = $(call EXPAND_LIBREFS,$(1),rpath:$(call GET_INSTALL_DIR_FOR_LIB_TARGET,$(1)) rpath-noinst:$(patsubst %/,%,$(dir $(1))))
# ARGS: abstract_target, initial_elems
EXPAND_LIBREFS = $(call REMOVE_DUPES,$(2) $(foreach x,$($(call FOLD_TARGET,$(1))_LIBS),$(call EXPAND_LIBREF,$(x))))
# ARGS: libref
EXPAND_LIBREF = $(call EXPAND_LIBREF_1,$(1),$(call MANGLE_LIBREF,$(1)))
EXPAND_LIBREF_1 = $(if $(GMK_CELR_$(2)),,$(eval GMK_ELR_$(2) := $$(call EXPAND_LIBREF_2,$(1))$(NEWLINE)GMK_CELR_$(2) = x))$(GMK_ELR_$(2))
EXPAND_LIBREF_2 = $(call EXPAND_LIBREF_3,$(call GET_LIBRARY_STEM,$(x)),$(call READ_LIBDEPS,$(x)))
# ARGS: libref_stem, libref_libdeps_contents
EXPAND_LIBREF_3 = $(if $(filter noinst,$(2)),$(call EXPAND_LIBREF_NOINST,$(1),$(2)),$(call EXPAND_LIBREF_INST,$(1),$(2)))
EXPAND_LIBREF_NOINST = $(call EXPAND_LIBREF_4,noinst:$(1) libdeps:$(1)$(LIB_SUFFIX_LIBDEPS) $(filter-out noinst,$(2)))
EXPAND_LIBREF_INST   = $(call EXPAND_LIBREF_4,lib:$(1).a libdeps:$(1)$(LIB_SUFFIX_LIBDEPS) $(2))
# ARGS: partially_expanded_libdeps
EXPAND_LIBREF_4 = $(foreach x,$(1),$(if $(filter lib:%,$(x)),$(call EXPAND_LIBREF_5,$(call GET_LIBRARY_STEM,$(patsubst lib:%,%,$(x)))),$(x)))
# ARGS: nested_libref_stem
EXPAND_LIBREF_5 = $(call EXPAND_LIBREF_6,$(1),$(dir $(1)),$(notdir $(1)))
# ARGS: nested_libref_stem, dir_part, nondir_part
EXPAND_LIBREF_6 = inst:$(1) dir:$(patsubst %/,%,$(2)) $(patsubst lib%,lib:%,$(3))

# Read the contents of the `.libdeps` file for the specified library
# and translate relative paths such that they are expressed relative
# to the directory holding the local `Makefile`. For referenced
# libraries defined in the local `Makefile`, the contents needs to be
# computed "on the fly" because the `.libdeps` file may not yet be up
# to date.
#
# ARGS: abstract_libref
READ_LIBDEPS   = $(if $(call IS_LOCAL_NOINST_LIB,$(1)),$(call MAKE_NOINST_LIBDEPS,$(1)),$(if $(call IS_LOCAL_INST_LIB,$(1)),$(call MAKE_INST_LIBDEPS,$(1)),$(call READ_LIBDEPS_1,$(1))))
READ_LIBDEPS_1 = $(call PATTERN_UNPACK_MAP,READ_LIBDEPS_2,lib:% rpath-noinst:%,$(call CAT_OPT_FILE,$(call GET_LIBRARY_STEM,$(1))$(LIB_SUFFIX_LIBDEPS)),$(dir $(1)))
READ_LIBDEPS_2 = $(call MAKE_REL_PATH,$(2)$(1))
# Is the specified library one that is defined in the local Makefile?
IS_LOCAL_INST_LIB   = $(call FIND,IS_SAME_PATH_AS,$(INST_LIBRARIES),$(1))
IS_LOCAL_NOINST_LIB = $(call FIND,IS_SAME_PATH_AS,$(noinst_LIBRARIES) $(check_LIBRARIES),$(1))

# Quote elements for shell and translate relative paths such that they
# become relative to the specified target directory. It is assumed
# that the relative paths are currently relative to the current
# working directory.
#
# ARGS: libdeps_contents, target_dir
EXPORT_LIBDEPS = $(foreach x,$(call PATTERN_UNPACK_MAP,EXPORT_LIBDEPS_1,lib:% rpath-noinst:%,$(1),$(2)),$(call SHELL_ESCAPE,$(x)))
EXPORT_LIBDEPS_1 = $(call MAKE_REL_PATH,$(1),$(2))

# Compute what is almost the contents to be placed in the `.libdeps`
# file for the specified library. The only thing that sets it apart
# from what must ultimately be placed in the file, is that all
# relative paths in the output of this function will be expressed
# relative to the directory holding the local `Makefile`, and not
# relative to the directory holding the `.libdeps` file (in case they
# differ).
#
# ARGS: abstract_target
MAKE_INST_LIBDEPS     = $(call EXTRACT_INST_LIB_LIBDEPS,$(call EXPAND_INST_LIB_LIBREFS,$(1)))
MAKE_NOINST_LIBDEPS   = $(strip noinst $(call MAKE_NOINST_LIBDEPS_1,$(1)) $(call MAKE_NOINST_LIBDEPS_2,$(1)))
MAKE_NOINST_LIBDEPS_1 = $(foreach x,$($(call FOLD_TARGET,$(1))_LIBS),lib:$(x) $(call READ_LIBDEPS,$(x)))
MAKE_NOINST_LIBDEPS_2 = $(call MAKE_NOINST_LIBDEPS_3,$(1)) $(call MAKE_NOINST_LIBDEPS_4,$(1)) $(call MAKE_NOINST_LIBDEPS_5,$(1))
MAKE_NOINST_LIBDEPS_3 = $(foreach x,$(call GET_FLAGS,$(call FOLD_TARGET,$(1))_LDFLAGS,OPTIM),ldflag-opt:$(x))
MAKE_NOINST_LIBDEPS_4 = $(foreach x,$(call GET_FLAGS,$(call FOLD_TARGET,$(1))_LDFLAGS,DEBUG),ldflag-dbg:$(x))
MAKE_NOINST_LIBDEPS_5 = $(foreach x,$(call GET_FLAGS,$(call FOLD_TARGET,$(1))_LDFLAGS,COVER),ldflag-cov:$(x))

# ARGS: expanded_librefs
EXTRACT_INST_LIB_LIBDEPS = $(filter rpath:% rpath-noinst:%,$(1))

# Add library name qualification, and select the appropriate set of
# linker flags for the specified compilation mode.
#
# ARGS: expanded_librefs, compile_mode
FINALIZE_EXPANDED_LIBREFS   = $(call SELECT_LDFLAGS_$(2),$(call QUALIFY_LIBREFS,$(1),$(2)))
QUALIFY_LIBREFS = $(call QUALIFY_LIBREFS_1,$(1),$(SUFFIX_LIB_STATIC_$(2)),$(SUFFIX_LIB_SHARED_$(2)),$(BASE_DENOM_2)$(LIB_DENOM_$(2)))
QUALIFY_LIBREFS_1 = $(patsubst noinst:%,noinst:%$(2),$(patsubst inst:%,inst:%$(3),$(patsubst lib:%,lib:%$(4),$(1))))
SELECT_LDFLAGS_OPTIM = $(patsubst ldflag-opt:%,ldflag:%,$(filter-out ldflag-dbg:% ldflag-cov:%,$(1)))
SELECT_LDFLAGS_DEBUG = $(patsubst ldflag-dbg:%,ldflag:%,$(filter-out ldflag-opt:% ldflag-cov:%,$(1)))
SELECT_LDFLAGS_COVER = $(patsubst ldflag-cov:%,ldflag:%,$(filter-out ldflag-opt:% ldflag-dbg:%,$(1)))

# ARGS: abstract_target
GET_LIBREFS_DEP_INFO = $(call GET_LIBREFS_DEP_INFO_1,$(foreach x,$($(call FOLD_TARGET,$(1))_LIBS),$(call EXPAND_LIBREF,$(x))))
GET_LIBREFS_DEP_INFO_1 = $(filter noinst:% inst:% libdeps:%,$(1)) $(if $(filter rpath-noinst:%,$(1)),noinst_rpath)

# ARGS: librefs_dep_info, compile_mode
FINALIZE_LIBREFS_DEP_INFO = $(call FILTER_UNPACK,noinst:% inst:% libdeps:%,$(call QUALIFY_LIBREFS,$(1),$(2)))

# ARGS: finalized_expanded_librefs
LDFLAGS_FROM_LIBREFS = $(call FILTER_PATSUBST,noinst:%,%,$(1)) $(call FILTER_PATSUBST,lib:%,-l%,$(1)) $(call FILTER_PATSUBST,dir:%,-L%,$(1)) $(call FILTER_PATSUBST,ldflag:%,%,$(1))
RPATHS_FROM_LIBREFS = $(NOINST_RPATHS_FROM_LIBREFS)
ifeq ($(ENABLE_NOINST_BUILD),)
RPATHS_FROM_LIBREFS = $(foreach x,$(call FILTER_PATSUBST,rpath:%,%,$(1)),-Wl,-rpath,$(x))
endif
NOINST_RPATHS_FROM_LIBREFS = $(foreach x,$(call FILTER_PATSUBST,rpath-noinst:%,%,$(1)),-Wl,-rpath,\$$ORIGIN$(if $(call IS_EQUAL_TO,$(x),.),,/$(x)))
ifeq ($(OS),Darwin)
NOINST_RPATHS_FROM_LIBREFS = $(foreach x,$(call FILTER_PATSUBST,rpath-noinst:%,%,$(1)),-Wl,-rpath,@loader_path/$(x))
endif

# ARGS: target, objects, abstract_target, compile_mode
NOINST_PROG_RECIPE = $(call NOINST_PROG_RECIPE_1,$(1),$(2),$(3),$(4),$(call FINALIZE_EXPANDED_LIBREFS,$(call EXPAND_LIBREFS,$(3)),$(4)))
NOINST_PROG_RECIPE_1 = $(call LIST_CONCAT,$(strip $(LD_PROG_$(4)) $(2) $(call LDFLAGS_FROM_LIBREFS,$(5)) $(call GET_LDFLAGS_FOR_TARGET,$(3),$(4)) $(LDFLAGS_ARCH)),$(call NOINST_RPATHS_FROM_LIBREFS,$(5))) -o $(1)

INST_PROG_RECIPE = $(call INST_PROG_RECIPE_1,$(1),$(2),$(3),$(4),$(call FINALIZE_EXPANDED_LIBREFS,$(call EXPAND_LIBREFS,$(3)),$(4)))
INST_PROG_RECIPE_1 = $(strip $(LD_PROG_$(4)) $(2) $(call LDFLAGS_FROM_LIBREFS,$(5)) $(call GET_LDFLAGS_FOR_TARGET,$(3),$(4)) $(LDFLAGS_ARCH) $(call RPATHS_FROM_LIBREFS,$(5))) -o $(1)

# ARGS: target, objects, deps, abstract_target, compile_mode, has_noinst_rpaths
define NOINST_PROG_RULES
$(1): $(2) $(3)
	$$(call NOINST_PROG_RECIPE,$(1),$(2),$(4),$(5))
endef
define INST_PROG_RULES
ifeq ($(if $(ENABLE_NOINST_BUILD),,$(6)),)
$(1): $(2) $(3)
	$$(call INST_PROG_RECIPE,$(1),$(2),$(4),$(5))
else
$(1) $(1)-noinst: $(2) $(3)
	$$(call INST_PROG_RECIPE,$(1),$(2),$(4),$(5))
	$$(call NOINST_PROG_RECIPE,$(1)-noinst,$(2),$(4),$(5))
endif
endef

# ARGS: abstract_target, abstract_objects, librefs_dep_info, extra_deps, compile_mode, prog_type
EVAL_PROG_RULES_3 = $(eval $(call $(6)_PROG_RULES,$(1)$(SUFFIX_PROG_$(5)),$(patsubst %.o,%$(SUFFIX_OBJ_STATIC_$(5)),$(2)),$(call FINALIZE_LIBREFS_DEP_INFO,$(3),$(5)) $(call GET_DEPS_FOR_TARGET,$(1)),$(1),$(5),$(filter noinst_rpath,$(3))))

EVAL_PROG_RULES_2 = $(foreach x,OPTIM DEBUG COVER,$(call EVAL_PROG_RULES_3,$(1),$(2),$(3),$(4),$(x),$(5)))

EVAL_PROG_RULES_1 = $(call EVAL_PROG_RULES_2,$(1),$(call GET_OBJECTS_FOR_TARGET,$(1),.o),$(call GET_LIBREFS_DEP_INFO,$(1)),$(call GET_DEPS_FOR_TARGET,$(1)),$(2))

$(foreach x,$(noinst_PROGRAMS) $(check_PROGRAMS),$(call EVAL_PROG_RULES_1,$(x),NOINST))
$(foreach x,$(INST_PROGRAMS) $(DEV_PROGRAMS),$(call EVAL_PROG_RULES_1,$(x),INST))



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
# programs against `libinst.a`. The `rpath-noinst:` entries are
# similar, but they are used when linking programs that are not
# installed (i.e., those that can be executed before `libinst.a` is
# installed). While the paths specified by the `rpath:` entries are
# absolute, the paths specified by the `noninst-rpath:` entries are
# always relative to the directory containing the 'libdeps' file.
#
# First of all, `libinst.libdeps` contains an `rpath:` and a
# `rpath-noinst:` entry for itself. For instance:
#
#     rpath:/usr/local/lib rpath-noinst:.
#
# Further more, `libinst.libdeps` contains an `rpath:` and a
# `rpath-noinst:` entry for each installed library `libxxx.a`, that
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
#     rpath:/usr/local/lib rpath-noinst:. rpath-noinst:../xxx
#     rpath-noinst:../yyy
#
# Had they all been located in the same directory, `libinst.libdeps`
# would instead contain
#
#     rpath:/usr/local/lib rpath-noinst:.
#
#
# If `libconv.a` is a convenience library (not installed), then
# `libconv.libdeps` contains a `noinst` entry that identifies it as a
# convenience library from the point of view of `Makefile`s in other
# subdirectories. Apart from that, it contains a `lib:` entry for each
# installed project-local library that `libconv.a` directly depends
# on, and it contains the union of the contents of the 'libdeps' files
# associated with each of those `lib:` entries with relative paths
# transformed as necessary. Aa with `noninst-rpath:`, the paths
# specified by the `lib:` entries are always relative to the directory
# containing the 'libdeps' file. For example, if `libconv.a` depends
# on `libinst.a`, and `libconv.a` is located in the root directory of
# the project, and the installed libraries are located in distinct
# subdirectories as described in an example above, then
# `libconv.libdeps` will contain
#
#     noinst lib:inst/libinst.a rpath:/usr/local/lib rpath-noinst:inst
#     rpath-noinst:xxx rpath-noinst:yyy
#
# Note how the relative paths in the `rpath-noinst:` entries have been
# transformed such that they are now relative to the root directory.
#
# When extra linker flags are attached to a convenience library, those
# flags will also be carried in the 'libdeps' file. For example,
# `libconv.libdeps` might contain
#
#     ldflag-opt:-lmagic ldflag-opt:-L/opt/magic/lib
#     ldflag-dbg:-lmagic ldflag-dbg:-L/opt/magic-debug/lib
#     ldflag-cov:-lmagic ldflag-cov:-L/opt/magic-debug/lib
#
# The `ldflag-opt:` entries are used when compiling in optimized
# (default) mode, while the `ldflag-dbg:` and the `ldflag-cov:`
# entries are used when compiling in debug and coverage modes
# respectively.

# ARGS: target, objects, extra_deps
define STATIC_LIBRARY_RULE
$(1): $(2) $(3)
	$$(RM) $(1)
	$$(strip $$(AR) $$(ARFLAGS_GENERAL) $(1) $(2))
endef

# ARGS: real_local_path, objects, finalized_expanded_librefs, extra_deps, link_cmd, ldflags, lib_version
SHARED_LIBRARY_RULE_HELPER = $(call SHARED_LIBRARY_RULE,$(1),$(2) $(call FILTER_UNPACK,inst:% libdeps:%,$(3)) $(4),$(5) $(2) $(call LDFLAGS_FROM_LIBREFS,$(3)) $(6) $$(LDFLAGS_ARCH),$(if $(ENABLE_NOINST_BUILD),,$(7)))

# ARGS: qual_lib_name, deps, cmd, version
SHARED_LIBRARY_RULE = $(SHARED_LIBRARY_RULE_DEFAULT)
define SHARED_LIBRARY_RULE_DEFAULT
$(1): $(2)
	$$(strip $(3)) -o $(1)
endef

ifeq ($(OS),Linux)

# ARGS: qual_lib_name, deps, cmd, version
SHARED_LIBRARY_RULE = $(if $(4),$(call SHARED_LIBRARY_RULE_VER,$(1),$(2),$(3),$(call MAP_SHARED_LIB_VERSION,$(4))),$(SHARED_LIBRARY_RULE_DEFAULT))

# ARGS: qual_lib_name, deps, cmd, mapped_version
SHARED_LIBRARY_RULE_VER = $(call SHARED_LIBRARY_RULE_VER_2,$(1),$(2),$(3),$(word 1,$(4)),$(word 2,$(4)))

# ARGS: qual_lib_name, deps, cmd, major_version, full_version
define SHARED_LIBRARY_RULE_VER_2
$(1) $(1).$(4) $(1).$(5): $(2)
	$$(strip $(3) -Wl,-soname,$(notdir $(1).$(4))) -o $(1).$(5)
	ln -s -f $(notdir $(1).$(5)) $(1).$(4)
	ln -s -f $(notdir $(1).$(4)) $(1)
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
	$$(strip $(3) -install_name @rpath/$(notdir $(4)) -compatibility_version $(5) -current_version $(6)) -o $(4)
	ln -s -f $(notdir $(4)) $(1)
endef

endif

# ARGS: target_stem_path, contents, deps
define LIBDEPS_RULE
$(1)$$(LIB_SUFFIX_LIBDEPS): $(3) $$(DEP_MAKEFILES)
	echo $$(call EXPORT_LIBDEPS,$(2),$(dir $(1))) >$(1)$$(LIB_SUFFIX_LIBDEPS)
endef

# ARGS: abstract_target, extra_deps
define NOINST_LIB_RULES
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_STATIC_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_STATIC_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_STATIC_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(3))
$(call LIBDEPS_RULE,$(call GET_LIBRARY_STEM,$(1)),$(call MAKE_NOINST_LIBDEPS,$(1)),$(foreach x,$($(call FOLD_TARGET,$(1))_LIBS),$(call GET_LIBRARY_STEM,$(x))$(LIB_SUFFIX_LIBDEPS)))
endef

# ARGS: abstract_target, expanded_librefs, extra_deps
define INST_LIB_RULES
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_STATIC_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_OPTIM)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_STATIC_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_DEBUG)),$(3))
$(call STATIC_LIBRARY_RULE,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_STATIC_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_STATIC_COVER)),$(3))
$(call SHARED_LIBRARY_RULE_HELPER,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_SHARED_OPTIM),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_OPTIM)),$(call FINALIZE_EXPANDED_LIBREFS,$(2),OPTIM),$(3),$$(LD_LIB_OPTIM),$(call GET_LDFLAGS_FOR_TARGET,$(1),OPTIM),$(call GET_LIBRARY_VERSION,$(1)))
$(call SHARED_LIBRARY_RULE_HELPER,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_SHARED_DEBUG),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_DEBUG)),$(call FINALIZE_EXPANDED_LIBREFS,$(2),DEBUG),$(3),$$(LD_LIB_DEBUG),$(call GET_LDFLAGS_FOR_TARGET,$(1),DEBUG),$(call GET_LIBRARY_VERSION,$(1)))
$(call SHARED_LIBRARY_RULE_HELPER,$(call GET_LIBRARY_STEM,$(1))$(SUFFIX_LIB_SHARED_COVER),$(call GET_OBJECTS_FOR_TARGET,$(1),$(SUFFIX_OBJ_SHARED_COVER)),$(call FINALIZE_EXPANDED_LIBREFS,$(2),COVER),$(3),$$(LD_LIB_COVER),$(call GET_LDFLAGS_FOR_TARGET,$(1),COVER),$(call GET_LIBRARY_VERSION,$(1)))
$(call LIBDEPS_RULE,$(call GET_LIBRARY_STEM,$(1)),$(call EXTRACT_INST_LIB_LIBDEPS,$(2)),$(call FILTER_PATSUBST,libdeps:%,%,$(2)))
endef

define LIBRARY_RULES
$(foreach x,$(noinst_LIBRARIES) $(check_LIBRARIES),$(NEWLINE)$(call NOINST_LIB_RULES,$(x),$(call GET_DEPS_FOR_TARGET,$(x)))$(NEWLINE))
$(foreach x,$(INST_LIBRARIES),$(NEWLINE)$(call INST_LIB_RULES,$(x),$(call EXPAND_INST_LIB_LIBREFS,$(x)),$(call GET_DEPS_FOR_TARGET,$(x)))$(NEWLINE))
endef

$(eval $(LIBRARY_RULES))



# FLEX AND BISON

%.flex.cpp %.flex.hpp: %.flex $(DEP_MAKEFILES)
	flex --outfile=$*.flex.cpp --header-file=$*.flex.hpp $<

%.bison.cpp %.bison.hpp: %.bison $(DEP_MAKEFILES)
	bison --output=$*.bison.cpp --defines=$*.bison.hpp $<



# COMPILING + AUTOMATIC DEPENDENCIES

$(foreach x,$(LIBRARIES) $(PROGRAMS),$(foreach y,$(call GET_OBJECTS_FOR_TARGET,$(x),.o),$(eval GMK_TARGETS_$(call FOLD_TARGET,$(y)) += $(x))))

GET_CFLAGS_FOR_TARGET = $(foreach x,PROJECT DIR $(foreach y,$(GMK_TARGETS_$(call FOLD_TARGET,$(1))) $(1),$(call FOLD_TARGET,$(y))),$(call GET_FLAGS,$(x)_CFLAGS,$(2)))

%$(SUFFIX_OBJ_STATIC_OPTIM): %.c
	$(strip $(CC_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_OPTIM): %.cpp
	$(strip $(CXX_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.c
	$(strip $(CC_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.cpp
	$(strip $(CXX_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_DEBUG): %.c
	$(strip $(CC_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_DEBUG): %.cpp
	$(strip $(CXX_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.c
	$(strip $(CC_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.cpp
	$(strip $(CXX_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_COVER): %.c
	$(strip $(CC_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_STATIC_COVER): %.cpp
	$(strip $(CXX_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.c
	$(strip $(CC_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.cpp
	$(strip $(CXX_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)



%$(SUFFIX_OBJ_STATIC_OPTIM): %.m
	$(strip $(OCC_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_OPTIM): %.mm
	$(strip $(OCXX_STATIC_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.m
	$(strip $(OCC_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_OPTIM): %.mm
	$(strip $(OCXX_SHARED_OPTIM) $(call GET_CFLAGS_FOR_TARGET,$*.o,OPTIM) $(CFLAGS_OTHER)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_DEBUG): %.m
	$(strip $(OCC_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_STATIC_DEBUG): %.mm
	$(strip $(OCXX_STATIC_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.m
	$(strip $(OCC_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@

%$(SUFFIX_OBJ_SHARED_DEBUG): %.mm
	$(strip $(OCXX_SHARED_DEBUG) $(call GET_CFLAGS_FOR_TARGET,$*.o,DEBUG) $(CFLAGS_OTHER)) -c $< -o $@


%$(SUFFIX_OBJ_STATIC_COVER): %.m
	$(strip $(OCC_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_STATIC_COVER): %.mm
	$(strip $(OCXX_STATIC_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.m
	$(strip $(OCC_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)

%$(SUFFIX_OBJ_SHARED_COVER): %.mm
	$(strip $(OCXX_SHARED_COVER) $(call GET_CFLAGS_FOR_TARGET,$*.o,COVER) $(CFLAGS_OTHER)) -c $(abspath $<) -o $(abspath $@)


-include $(OBJECTS:.o=.d)
