//
//  PerformanceTests.m
//  Realm-Xcode6
//
//  Created by Thomas Goyne on 8/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTestCase.h"

@interface IndexedStringObject : RLMObject
@property NSString *stringCol;
@end

@implementation IndexedStringObject
+ (RLMPropertyAttributes)attributesForProperty:(__unused NSString *)propertyName
{
    return RLMPropertyAttributeIndexed;
}
@end

@interface PerformanceTests : RLMTestCase
@end

@implementation PerformanceTests

- (void)testInsertMultiple {
    [self measureBlock:^{
        RLMRealm *realm = self.realmWithTestPath;
        [realm beginWriteTransaction];
        for (int i = 0; i < 5000; ++i) {
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
        for (int i = 0; i < 500; ++i) {
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
        for (int i = 0; i < 5000; ++i) {
            [StringObject createInRealm:realm withObject:@[@"a"]];
        }
        [realm commitWriteTransaction];
        [self tearDown];
    }];
}

- (RLMRealm *)createStringObjects:(int)factor {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    for (int i = 0; i < 1000 * factor; ++i) {
        [StringObject createInRealm:realm withObject:@[@"a"]];
        [StringObject createInRealm:realm withObject:@[@"b"]];
    }
    [realm commitWriteTransaction];

    return realm;
}

- (void)testCountWhereQuery {
    RLMRealm *realm = [self createStringObjects:50];
    [self measureBlock:^{
        RLMResults *array = [StringObject objectsInRealm:realm where:@"stringCol = 'a'"];
        [array count];
    }];
}

- (void)testCountWhereTableView {
    RLMRealm *realm = [self createStringObjects:50];
    [self measureBlock:^{
        RLMResults *array = [StringObject objectsInRealm:realm where:@"stringCol = 'a'"];
        [array firstObject]; // Force materialization of backing table view
        [array count];
    }];
}

- (void)testEnumerateAndAccessQuery {
    RLMRealm *realm = [self createStringObjects:5];

    [self measureBlock:^{
        for (StringObject *so in [StringObject objectsInRealm:realm where:@"stringCol = 'a'"]) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessAll {
    RLMRealm *realm = [self createStringObjects:5];

    [self measureBlock:^{
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessAllSlow {
    RLMRealm *realm = [self createStringObjects:5];

    [self measureBlock:^{
        RLMResults *all = [StringObject allObjectsInRealm:realm];
        for (NSUInteger i = 0; i < all.count; ++i) {
            (void)[all[i] stringCol];

        }
    }];
}

- (void)testEnumerateAndAccessArrayProperty {
    RLMRealm *realm = [self createStringObjects:5];

    [realm beginWriteTransaction];
    ArrayPropertyObject *apo = [ArrayPropertyObject createInRealm:realm
                                                       withObject:@[@"name", [StringObject allObjectsInRealm:realm], @[]]];
    [realm commitWriteTransaction];

    [self measureBlock:^{
        for (StringObject *so in apo.array) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessArrayPropertySlow {
    RLMRealm *realm = [self createStringObjects:5];

    [realm beginWriteTransaction];
    ArrayPropertyObject *apo = [ArrayPropertyObject createInRealm:realm
                                                       withObject:@[@"name", [StringObject allObjectsInRealm:realm], @[]]];
    [realm commitWriteTransaction];

    [self measureBlock:^{
        RLMArray *array = apo.array;
        for (NSUInteger i = 0; i < array.count; ++i) {
            (void)[array[i] stringCol];
        }
    }];
}

- (void)testEnumerateAndMutate {
    RLMRealm *realm = [self createStringObjects:1];

    [self measureBlock:^{
        [realm beginWriteTransaction];
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            so.stringCol = @"c";
        }
        [realm commitWriteTransaction];
    }];
}

- (void)testQueryConstruction {
    RLMRealm *realm = self.realmWithTestPath;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"boolCol = false and (intCol = 5 or floatCol = 1.0) and objectCol = nil and longCol != 7 and stringCol IN {'a', 'b', 'c'}"];

    [self measureBlock:^{
        for (int i = 0; i < 100; ++i) {
            [AllTypesObject objectsInRealm:realm withPredicate:predicate];
        }
    }];
}

- (void)testQueryDeletion {
    RLMRealm *realm = self.realmWithTestPath;

    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        [realm beginWriteTransaction];
        for (int i = 0; i < 5000; ++i) {
            [StringObject createInRealm:realm withObject:@[@"a"]];
        }
        [realm commitWriteTransaction];

        [self startMeasuring];
        [realm beginWriteTransaction];
        [realm deleteObjects:[StringObject allObjectsInRealm:realm]];
        [realm commitWriteTransaction];
        [self stopMeasuring];
    }];
}

- (void)testManualDeletion {
    RLMRealm *realm = self.realmWithTestPath;

    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        [realm beginWriteTransaction];
        for (int i = 0; i < 5000; ++i) {
            [StringObject createInRealm:realm withObject:@[@"a"]];
        }
        [realm commitWriteTransaction];

        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:5000];
        for (StringObject *obj in [StringObject allObjectsInRealm:realm]) {
            [objects addObject:obj];
        }

        [self startMeasuring];
        [realm beginWriteTransaction];
        [realm deleteObjects:objects];
        [realm commitWriteTransaction];
        [self stopMeasuring];
    }];
}

- (void)testUnIndexedStringLookup {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    for (int i = 0; i < 1000; ++i) {
        [StringObject createInRealm:realm withObject:@[@(i).stringValue]];
    }
    [realm commitWriteTransaction];

    [self measureBlock:^{
        for (int i = 0; i < 1000; ++i) {
            [[StringObject objectsInRealm:realm where:@"stringCol = %@", @(i).stringValue] firstObject];
        }
    }];
}

- (void)testIndexedStringLookup {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    for (int i = 0; i < 1000; ++i) {
        [IndexedStringObject createInRealm:realm withObject:@[@(i).stringValue]];
    }
    [realm commitWriteTransaction];

    [self measureBlock:^{
        for (int i = 0; i < 1000; ++i) {
            [[IndexedStringObject objectsInRealm:realm where:@"stringCol = %@", @(i).stringValue] firstObject];
        }
    }];
}

- (void)testLargeINQuery {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:1000];
    for (int i = 0; i < 2000; ++i) {
        [IntObject createInRealm:realm withObject:@[@(i)]];
        if (i % 2) {
            [ids addObject:@(i)];
        }
    }
    [realm commitWriteTransaction];

    [self measureBlock:^{
        (void)[[IntObject objectsInRealm:realm where:@"intCol IN %@", ids] firstObject];
    }];
}

- (void)testRealmCreation {
    [self realmWithTestPath]; // ensure a cached realm for the path

    dispatch_queue_t queue = dispatch_queue_create("test queue", 0);
    [self measureBlock:^{
        for (int i = 0; i < 250; ++i) {
            dispatch_async(queue, ^{
                @autoreleasepool {
                    [self realmWithTestPath];
                }
            });
        }

        dispatch_sync(queue, ^{});
    }];
}

@end
