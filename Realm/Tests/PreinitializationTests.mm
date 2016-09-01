//
//  PreinitializationTests.m
//  Realm
//
//  Created by Realm on 8/31/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "RLMRealm.h"
#import "RLMUtil.hpp"
#import "RLMAssertions.h"
#import "RLMTestObjects.h"
#import "RLMSchema_Private.h"

@interface PreinitializationTests : XCTestCase {
    IMP originalImplementation;
}

@end

@implementation PreinitializationTests

- (void)setUp {
    Method constructor = class_getClassMethod(RLMRealm.class, @selector(realmWithConfiguration:error:));
    originalImplementation = method_setImplementation(constructor,
        imp_implementationWithBlock(^(__unsafe_unretained __unused RLMRealmConfiguration *config,
                                      __unsafe_unretained __unused NSError ** error) {
        @throw RLMException(@"Illegal to initialize a Realm in this test case.");
    }));
}

- (void)tearDown {
    Method constructor = class_getClassMethod(RLMRealm.class, @selector(realmWithConfiguration:error:));
    method_setImplementation(constructor, originalImplementation);
}

- (void)invokeTest {
    // Prevents global schema state changes in one test case from affecting other test cases
    RLMUnsafeResetSchema();
    @autoreleasepool {
        [super invokeTest];
    }
}

- (void)testDisallowRealmConstruction {
    RLMAssertThrowsWithReasonMatching(RLMRealm.defaultRealm, @"Illegal to initialize a Realm in this test case.");
}

- (void)testCreateUnmanagedObject {
    XCTAssertNoThrow([[IntObject alloc] initWithValue:@[@0]]);
}

- (void)testCreateUnmanagedObjectWithNestedObject {
    id value = @[@0, @[@[@0]]]; // on separate line due to parsing bug
    XCTAssertNoThrow([[IntegerArrayPropertyObject alloc] initWithValue:value]);
}

@end
