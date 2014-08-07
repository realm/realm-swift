//
//  PerformanceTests.m
//  Realm-Xcode6
//
//  Created by Thomas Goyne on 8/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTestCase.h"

@interface RLMSchema (Private)
+ (void)enumerateRLMObjectSubclasses:(void (^)(Class))block;
@end

@interface PerformanceTests : RLMTestCase
@end

@implementation PerformanceTests

- (void)testClassEnumeration {
    [self measureBlock:^{
        for (int i = 0; i < 1000; ++i) {
            [RLMSchema enumerateRLMObjectSubclasses:^(Class _) { }];
        }
    }];
}

- (void)testArrayValidation {
    // Create all of the objects outside the timed loop to reduce noise
    NSMutableArray *arrays = [NSMutableArray arrayWithCapacity:10];
    for (int i = 0; i < 10; ++i) {
        NSMutableArray *subarray = [NSMutableArray arrayWithCapacity:10000];
        for (int j = 0; j < 10000; ++j) {
            StringObject *obj = [[StringObject alloc] init];
            obj.stringCol = @"a";
            [subarray addObject:obj];
        }
        [arrays addObject:subarray];
    }

    [self measureBlock:^{
        ArrayPropertyObject *arrObj = [[ArrayPropertyObject alloc] init];
        arrObj[@"array"] = [arrays lastObject];
        [arrays removeLastObject];
    }];
}

@end
