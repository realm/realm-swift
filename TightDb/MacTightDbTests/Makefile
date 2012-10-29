TEST_PROGRAMS = unit-tests

XCODE_HOME = $(shell xcode-select --print-path)

unit_tests_SOURCES = MacTightDbTests.m MACtestTable.m MACTestGroup.m MACTestGroupMisc2.m MACTestTableDeleteAll.m MACTestTutorial.m MACTestEnumerator.m
unit_tests_CFLAGS  = -fobjc-arc -fobjc-abi-version=2 -Wno-comment -Wno-variadic-macros -F$(XCODE_HOME)/Library/Frameworks -I../../Deliv
unit_tests_LDFLAGS = -bundle -fobjc-link-runtime -F$(XCODE_HOME)/Library/Frameworks -framework SenTestingKit
unit_tests_LIBS    = ../TightDb/libtightdb-objc.a

include ../../generic.mk
