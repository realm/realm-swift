TEST_PROGRAMS = unit-tests

XCODE_HOME = $(shell xcode-select --print-path)

unit_tests_SOURCES = table.m group.m group_misc_2.m table_delete_all.m tutorial.m enumerator.m
unit_tests_CFLAGS  = -fobjc-arc -fobjc-abi-version=2 -Wno-comment -Wno-variadic-macros -F$(XCODE_HOME)/Library/Frameworks
unit_tests_LDFLAGS = -bundle -fobjc-link-runtime -F$(XCODE_HOME)/Library/Frameworks -framework Cocoa -framework SenTestingKit
unit_tests_LIBS    = ../libtightdb-objc.a

include ../../../../generic.mk
