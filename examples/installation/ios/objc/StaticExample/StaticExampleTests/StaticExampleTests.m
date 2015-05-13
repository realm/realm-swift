//
//  StaticExampleTests.m
//  StaticExampleTests
//
//  Created by JP Simard on 5/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface StaticExampleTests : XCTestCase
@end

@implementation StaticExampleTests

- (void)testExample {
    XCTAssertTrue([MyModel isSubclassOfClass:[RLMObject class]]);
}

@end
