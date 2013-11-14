TEST_PROGRAMS = unit-tests

unit_tests_SOURCES = \
tutorial.m 

#unit_tests_SOURCES = functional.m

unit_tests_CFLAGS  = -Wno-comment -fobjc-arc -fobjc-abi-version=2 -F$(XCODE_HOME)/Library/Frameworks
unit_tests_LDFLAGS = -fobjc-link-runtime -F$(XCODE_HOME)/Library/Frameworks
unit_tests_LIBS    = ../src/tightdb/objc/libtightdb-objc.a

include ../src/generic.mk
