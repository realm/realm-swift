//
//  ConformanceTests.m
//  Realm
//
//  Created by Realm on 7/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "RLMHandoverable_Private.hpp"

@interface ConformanceTests : XCTestCase

@property (nonatomic, readonly) unsigned int count;
@property (nonatomic, readonly) Class *classList;

@end

static BOOL classOrSuperclass_conformsToProtocol(Class cls, Protocol *protocol) {
    if (cls == nil) return NO;
    else if (class_conformsToProtocol(cls, protocol)) return YES;
    else return classOrSuperclass_conformsToProtocol(class_getSuperclass(cls), protocol);
}

@implementation ConformanceTests

- (void)setUp {
    [super setUp];

    _classList = objc_copyClassList(&_count);
}

- (void)tearDown {
    free(_classList);
}

- (void)testHandoverablePrivateConformance {
    // Ensure that conformance to `RLMHandoverable` implies conformance to `RLMHandoverable_Private`
    Protocol *publicProtocol = @protocol(RLMHandoverable);
    Protocol *privateProtocol = @protocol(RLMHandoverable_Private);
    for (Class *c = self.classList; c < self.classList + self.count; c++) {
        if (classOrSuperclass_conformsToProtocol(*c, publicProtocol)) {
            XCTAssertTrue(classOrSuperclass_conformsToProtocol(*c, privateProtocol),
                          "%@ conforms to `RLMHandoverable` but not `RLMHandoverable_Private`", *c);
        }
    }
}

@end
