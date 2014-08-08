//
//  PerformanceTests.m
//  Realm-Xcode6
//
//  Created by Thomas Goyne on 8/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTestCase.h"

@interface PerformanceTests : RLMTestCase
@end

@implementation PerformanceTests

- (void)testArrayValidation {
    // Create all of the objects outside the timed loop to reduce noise
    NSMutableArray *arrays = [NSMutableArray arrayWithCapacity:10];
    for (int i = 0; i < 10; ++i) {
        NSMutableArray *subarray = [NSMutableArray arrayWithCapacity:1000];
        for (int j = 0; j < 1000; ++j) {
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

- (void)testInsertSingle {
    [self measureBlock:^{
        RLMRealm *realm = self.realmWithTestPath;
        for (int i = 0; i < 100; ++i) {
            [realm beginWriteTransaction];
            StringObject *obj = [[StringObject alloc] init];
            obj.stringCol = @"a";
            [realm addObject:obj];
            [realm commitWriteTransaction];
        }
        [self tearDown];
    }];
}

- (void)testInsertMultiple {
    [self measureBlock:^{
        RLMRealm *realm = self.realmWithTestPath;
        [realm beginWriteTransaction];
        for (int i = 0; i < 100; ++i) {
            StringObject *obj = [[StringObject alloc] init];
            obj.stringCol = @"a";
            [realm addObject:obj];
        }
        [realm commitWriteTransaction];
        [self tearDown];
    }];
}

- (void)testInsertSingleLiteral {
    [self measureBlock:^{
        RLMRealm *realm = self.realmWithTestPath;
        for (int i = 0; i < 100; ++i) {
            [realm beginWriteTransaction];
            [StringObject createInRealm:realm withObject:@[@"a"]];
            [realm commitWriteTransaction];
        }
        [self tearDown];
    }];
}

- (void)testInsertMultipleLiteral {
    [self measureBlock:^{
        RLMRealm *realm = self.realmWithTestPath;
        [realm beginWriteTransaction];
        for (int i = 0; i < 100; ++i) {
            [StringObject createInRealm:realm withObject:@[@"a"]];
        }
        [realm commitWriteTransaction];
        [self tearDown];
    }];
}

- (RLMRealm *)createStringObjects {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    for (int i = 0; i < 1000; ++i) {
        [StringObject createInRealm:realm withObject:@[@"a"]];
        [StringObject createInRealm:realm withObject:@[@"b"]];
    }
    [realm commitWriteTransaction];

    return realm;
}

- (void)testCountWhere {
    RLMRealm *realm = [self createStringObjects];
    [self measureBlock:^{
        [[StringObject objectsInRealm:realm where:@"stringCol = 'a'"] count];
    }];
}

- (void)testEnumerateAndAccessQuery {
    RLMRealm *realm = [self createStringObjects];

    [self measureBlock:^{
        for (StringObject *so in [StringObject objectsInRealm:realm where:@"stringCol = 'a'"]) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessAll {
    RLMRealm *realm = [self createStringObjects];

    [self measureBlock:^{
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessArrayProperty {
    RLMRealm *realm = [self createStringObjects];

    [realm beginWriteTransaction];
    ArrayPropertyObject *apo = [ArrayPropertyObject createInRealm:realm
                                                       withObject:@[@"name", [realm allObjects:StringObject.className], @[]]];
    [realm commitWriteTransaction];

    [self measureBlock:^{
        for (StringObject *so in apo.array) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndMutate {
    RLMRealm *realm = [self createStringObjects];

    [self measureBlock:^{
        [realm beginWriteTransaction];
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            so.stringCol = @"c";
        }
        [realm commitWriteTransaction];
    }];
}

@end
