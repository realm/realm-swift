check_PROGRAMS = unit-tests

unit_tests_SOURCES = DynamicTests.m ObjectTests.m RLMTestObjects.m \
LinkTests.m QueryTests.m RealmTests.m MixedTests.m RLMTestCase.m \
XCTestCase+AsyncTesting.m

unit_tests_CFLAGS  = -I../.. -Wno-comment -fobjc-arc -fobjc-abi-version=2 -F$(XCODE_HOME)/Library/Frameworks
unit_tests_LDFLAGS = -bundle -fobjc-link-runtime -F$(XCODE_HOME)/Library/Frameworks -framework Cocoa -framework XCTest
unit_tests_LIBS    = ../librealm-objc.a

include ../generic.mk
