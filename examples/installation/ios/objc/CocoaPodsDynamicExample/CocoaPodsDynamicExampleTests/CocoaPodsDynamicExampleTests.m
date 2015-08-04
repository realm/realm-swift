//
//  CocoaPodsDynamicExampleTests.m
//  CocoaPodsDynamicExampleTests
//
//  Created by JP Simard on 5/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface CocoaPodsDynamicExampleTests : XCTestCase
@end

@implementation CocoaPodsDynamicExampleTests

- (void)testExample {
    XCTAssertTrue([MyModel isSubclassOfClass:[RLMObject class]]);
}

@end
