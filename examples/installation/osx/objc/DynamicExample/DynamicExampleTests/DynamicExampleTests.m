//
//  DynamicExampleTests.m
//  DynamicExampleTests
//
//  Created by JP Simard on 5/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface DynamicExampleTests : XCTestCase
@end

@implementation DynamicExampleTests

- (void)testExample {
    XCTAssertTrue([MyModel isSubclassOfClass:[RLMObject class]]);
}

@end
