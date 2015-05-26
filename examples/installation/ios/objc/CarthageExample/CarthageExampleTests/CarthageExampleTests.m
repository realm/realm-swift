//
//  CarthageExampleTests.m
//  CarthageExampleTests
//
//  Created by JP Simard on 5/11/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface CarthageExampleTests : XCTestCase
@end

@implementation CarthageExampleTests

- (void)testExample {
    XCTAssertTrue([MyModel isSubclassOfClass:[RLMObject class]]);
}

@end
