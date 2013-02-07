TEST_PROGRAMS = unit-tests

XCODE_HOME = $(shell xcode-select --print-path)

unit_tests_SOURCES = data_type.mm table.m group.m group_misc_2.m table_delete_all.m tutorial.m enumerator.m get_subtable.m subtable.m mixed.m shared_group.m
unit_tests_CFLAGS  = -Wno-comment -fobjc-arc -fobjc-abi-version=2 -F$(XCODE_HOME)/Library/Frameworks
unit_tests_LDFLAGS = -bundle -fobjc-link-runtime -F$(XCODE_HOME)/Library/Frameworks -framework Cocoa -framework SenTestingKit
unit_tests_LIBS    = ../libtightdb-objc.a

include ../../../../generic.mk
