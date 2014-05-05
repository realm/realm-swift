check_PROGRAMS = unit-tests

unit_tests_SOURCES = \
data_type.mm dynamic_table.mm enumerator.m err_handling.mm functional.m \
get_subtable.m group.m group_misc_2.m mixed.m query.m shared_group.m \
subtable.m table_delete_all.m table_view.m tutorial.m typed_table.m \
version.m RLMTestCase.m realm.m XCTestCase+AsyncTesting.h \
XCTestCase+AsyncTesting.m




#unit_tests_SOURCES = functional.m

unit_tests_CFLAGS  = -Wno-comment -fobjc-arc -fobjc-abi-version=2 -F$(XCODE_HOME)/Library/Frameworks
<<<<<<< HEAD:src/tightdb/objc/test/Makefile
unit_tests_LDFLAGS = -bundle -fobjc-link-runtime -F$(XCODE_HOME)/Library/Frameworks -framework Cocoa -framework SenTestingKit
unit_tests_LIBS    = ../libtightdb-objc.a
=======
unit_tests_LDFLAGS = -bundle -fobjc-link-runtime -F$(XCODE_HOME)/Library/Frameworks -framework Cocoa -framework XCTest
unit_tests_LIBS    = ../librealm-objc.a
>>>>>>> master:src/realm/objc/test/Makefile

include ../../../generic.mk
