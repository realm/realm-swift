////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"

#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.h"

#if !DEBUG && TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR

@interface PerformanceTests : RLMTestCase
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) dispatch_semaphore_t sema;
@end

static RLMRealm *s_smallRealm, *s_mediumRealm, *s_largeRealm;

@implementation PerformanceTests

+ (void)setUp {
    [super setUp];

    s_smallRealm = [self createStringObjects:1];
    s_mediumRealm = [self createStringObjects:5];
    s_largeRealm = [self createStringObjects:50];
}

+ (void)tearDown {
    s_smallRealm = s_mediumRealm = s_largeRealm = nil;
    [RLMRealm resetRealmState];
    [super tearDown];
}

- (void)resetRealmState {
    // Do nothing, as we need to keep our in-memory realms around between tests
}

- (void)measureBlock:(void (^)(void))block {
    [super measureBlock:^{
        @autoreleasepool {
            block();
        }
    }];
}

- (void)measureMetrics:(NSArray *)metrics automaticallyStartMeasuring:(BOOL)automaticallyStartMeasuring forBlock:(void (^)(void))block {
    [super measureMetrics:metrics automaticallyStartMeasuring:automaticallyStartMeasuring forBlock:^{
        @autoreleasepool {
            block();
        }
    }];
}

+ (RLMRealm *)createStringObjects:(int)factor {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.inMemoryIdentifier = @(factor).stringValue;

    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    [realm beginWriteTransaction];
    for (int i = 0; i < 1000 * factor; ++i) {
        [StringObject createInRealm:realm withValue:@[@"a"]];
        [StringObject createInRealm:realm withValue:@[@"b"]];
    }
    [realm commitWriteTransaction];

    return realm;
}

- (RLMRealm *)testRealm {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.inMemoryIdentifier = @"test";
    return [RLMRealm realmWithConfiguration:config error:nil];
}

- (void)testInsertMultiple {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = self.realmWithTestPath;
        [self startMeasuring];
        [realm beginWriteTransaction];
        for (int i = 0; i < 5000; ++i) {
            StringObject *obj = [[StringObject alloc] init];
            obj.stringCol = @"a";
            [realm addObject:obj];
        }
        [realm commitWriteTransaction];
        [self stopMeasuring];
        [self tearDown];
    }];
}

- (void)testInsertSingleLiteral {
    [self measureBlock:^{
        RLMRealm *realm = self.realmWithTestPath;
        for (int i = 0; i < 50; ++i) {
            [realm beginWriteTransaction];
            [StringObject createInRealm:realm withValue:@[@"a"]];
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
            [StringObject createInRealm:realm withValue:@[@"a"]];
        }
        [realm commitWriteTransaction];
        [self tearDown];
    }];
}

- (RLMRealm *)getStringObjects:(int)factor {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.inMemoryIdentifier = @(factor).stringValue;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    [NSFileManager.defaultManager removeItemAtPath:RLMTestRealmPath() error:nil];
    [realm writeCopyToPath:RLMTestRealmPath() error:nil];
    return [self realmWithTestPath];
}

- (void)testCountWhereQuery {
    RLMRealm *realm = [self getStringObjects:50];
    [self measureBlock:^{
        for (int i = 0; i < 50; ++i) {
            RLMResults *array = [StringObject objectsInRealm:realm where:@"stringCol = 'a'"];
            [array count];
        }
    }];
}

- (void)testCountWhereTableView {
    RLMRealm *realm = [self getStringObjects:50];
    [self measureBlock:^{
        for (int i = 0; i < 10; ++i) {
            RLMResults *array = [StringObject objectsInRealm:realm where:@"stringCol = 'a'"];
            [array firstObject]; // Force materialization of backing table view
            [array count];
        }
    }];
}

- (void)testEnumerateAndAccessQuery {
    RLMRealm *realm = [self getStringObjects:5];

    [self measureBlock:^{
        for (StringObject *so in [StringObject objectsInRealm:realm where:@"stringCol = 'a'"]) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessAll {
    RLMRealm *realm = [self getStringObjects:5];

    [self measureBlock:^{
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessAllSlow {
    RLMRealm *realm = [self getStringObjects:5];

    [self measureBlock:^{
        RLMResults *all = [StringObject allObjectsInRealm:realm];
        for (NSUInteger i = 0; i < all.count; ++i) {
            (void)[all[i] stringCol];

        }
    }];
}

- (void)testEnumerateAndAccessArrayProperty {
    RLMRealm *realm = [self getStringObjects:5];

    [realm beginWriteTransaction];
    ArrayPropertyObject *apo = [ArrayPropertyObject createInRealm:realm
                                                       withValue:@[@"name", [StringObject allObjectsInRealm:realm], @[]]];
    [realm commitWriteTransaction];

    [self measureBlock:^{
        for (StringObject *so in apo.array) {
            (void)[so stringCol];
        }
    }];
}

- (void)testEnumerateAndAccessArrayPropertySlow {
    RLMRealm *realm = [self getStringObjects:5];

    [realm beginWriteTransaction];
    ArrayPropertyObject *apo = [ArrayPropertyObject createInRealm:realm
                                                       withValue:@[@"name", [StringObject allObjectsInRealm:realm], @[]]];
    [realm commitWriteTransaction];

    [self measureBlock:^{
        RLMArray *array = apo.array;
        for (NSUInteger i = 0; i < array.count; ++i) {
            (void)[array[i] stringCol];
        }
    }];
}

- (void)testEnumerateAndMutateAll {
    RLMRealm *realm = [self getStringObjects:5];

    [self measureBlock:^{
        [realm beginWriteTransaction];
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            so.stringCol = @"c";
        }
        [realm commitWriteTransaction];
    }];
}

- (void)testEnumerateAndMutateQuery {
    RLMRealm *realm = [self getStringObjects:1];

    [self measureBlock:^{
        [realm beginWriteTransaction];
        for (StringObject *so in [StringObject objectsInRealm:realm where:@"stringCol != 'b'"]) {
            so.stringCol = @"c";
        }
        [realm commitWriteTransaction];
    }];
}

- (void)testQueryConstruction {
    RLMRealm *realm = self.realmWithTestPath;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"boolCol = false and (intCol = 5 or floatCol = 1.0) and objectCol = nil and longCol != 7 and stringCol IN {'a', 'b', 'c'}"];

    [self measureBlock:^{
        for (int i = 0; i < 500; ++i) {
            [AllTypesObject objectsInRealm:realm withPredicate:predicate];
        }
    }];
}

- (void)testDeleteAll {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = [self getStringObjects:50];

        [self startMeasuring];
        [realm beginWriteTransaction];
        [realm deleteObjects:[StringObject allObjectsInRealm:realm]];
        [realm commitWriteTransaction];
        [self stopMeasuring];
    }];
}

- (void)testQueryDeletion {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = [self getStringObjects:5];

        [self startMeasuring];
        [realm beginWriteTransaction];
        [realm deleteObjects:[StringObject objectsInRealm:realm where:@"stringCol = 'a' OR stringCol = 'b'"]];
        [realm commitWriteTransaction];
        [self stopMeasuring];
    }];
}

- (void)testManualDeletion {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = [self getStringObjects:5];

        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:10000];
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
        [StringObject createInRealm:realm withValue:@[@(i).stringValue]];
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
        [IndexedStringObject createInRealm:realm withValue:@[@(i).stringValue]];
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
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:3000];
    for (int i = 0; i < 3000; ++i) {
        [IntObject createInRealm:realm withValue:@[@(i)]];
        if (i % 2) {
            [ids addObject:@(i)];
        }
    }
    [realm commitWriteTransaction];

    [self measureBlock:^{
        (void)[[IntObject objectsInRealm:realm where:@"intCol IN %@", ids] firstObject];
    }];
}

- (void)testSortingAllObjects {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    for (int i = 0; i < 3000; ++i) {
        [IntObject createInRealm:realm withValue:@[@(arc4random())]];
    }
    [realm commitWriteTransaction];

    [self measureBlock:^{
        (void)[[IntObject allObjectsInRealm:realm] sortedResultsUsingProperty:@"intCol" ascending:YES].lastObject;
    }];
}

- (void)testRealmCreationCached {
    __block RLMRealm *realm;
    [self dispatchAsyncAndWait:^{
        realm = [self realmWithTestPath]; // ensure a cached realm for the path
    }];

    [self measureBlock:^{
        for (int i = 0; i < 250; ++i) {
            @autoreleasepool {
                [self realmWithTestPath];
            }
        }
    }];
    [realm path];
}

- (void)testRealmCreationUncached {
    [self measureBlock:^{
        for (int i = 0; i < 50; ++i) {
            @autoreleasepool {
                [self realmWithTestPath];
            }
        }
    }];
}

- (void)testRealmFileCreation {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    __block int measurement = 0;
    const int iterations = 10;
    [self measureBlock:^{
        for (int i = 0; i < iterations; ++i) {
            @autoreleasepool {
                config.inMemoryIdentifier = @(measurement * iterations + i).stringValue;
                [RLMRealm realmWithConfiguration:config error:nil];
            }
        }
        ++measurement;
    }];
}

- (void)testCommitWriteTransaction {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = self.testRealm;
        [realm beginWriteTransaction];
        IntObject *obj = [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];

        [self startMeasuring];
        while (obj.intCol < 100) {
            [realm transactionWithBlock:^{
                obj.intCol++;
            }];
        }
        [self stopMeasuring];
    }];
}

- (void)testCommitWriteTransactionWithLocalNotification {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = self.testRealm;
        [realm beginWriteTransaction];
        IntObject *obj = [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];

        RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, __unused RLMRealm *realm) { }];
        [self startMeasuring];
        while (obj.intCol < 500) {
            [realm transactionWithBlock:^{
                obj.intCol++;
            }];
        }
        [self stopMeasuring];
        [token stop];
    }];
}

- (void)testCommitWriteTransactionWithCrossThreadNotification {
    const int stopValue = 500;

    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = self.testRealm;
        [realm beginWriteTransaction];
        IntObject *obj = [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];

        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self dispatchAsync:^{
            RLMRealm *realm = self.testRealm;
            IntObject *obj = [[IntObject allObjectsInRealm:realm] firstObject];
            __block RLMNotificationToken *token;

            CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
                token = [realm addNotificationBlock:^(__unused NSString *note, __unused RLMRealm *realm) {
                    if (obj.intCol == stopValue) {
                        CFRunLoopStop(CFRunLoopGetCurrent());
                    }
                }];
                dispatch_semaphore_signal(sema);
            });
            CFRunLoopRun();

            [token stop];
        }];

        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        [self startMeasuring];
        while (obj.intCol < stopValue) {
            [realm transactionWithBlock:^{
                obj.intCol++;
            }];
        }

        [self dispatchAsyncAndWait:^{}];
        [self stopMeasuring];
    }];
}

- (void)testCrossThreadSyncLatency {
    const int stopValue = 500;

    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = self.testRealm;
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        IntObject *obj = [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];

        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self dispatchAsync:^{
            RLMRealm *realm = self.testRealm;
            IntObject *obj = [[IntObject allObjectsInRealm:realm] firstObject];
            __block RLMNotificationToken *token;

            CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
                token = [realm addNotificationBlock:^(__unused NSString *note, __unused RLMRealm *realm) {
                    if (obj.intCol == stopValue) {
                        CFRunLoopStop(CFRunLoopGetCurrent());
                    }
                    else if (obj.intCol % 2 == 0) {
                        [realm transactionWithBlock:^{
                            obj.intCol++;
                        }];
                    }
                }];

                dispatch_semaphore_signal(sema);
            });
            CFRunLoopRun();

            [token stop];
        }];

        RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, __unused RLMRealm *realm) {
            if (obj.intCol % 2 == 1 && obj.intCol < stopValue) {
                [realm transactionWithBlock:^{
                    obj.intCol++;
                }];
            }
        }];

        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        [self startMeasuring];
        [realm transactionWithBlock:^{
            obj.intCol++;
        }];
        while (obj.intCol < stopValue) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }

        [self dispatchAsyncAndWait:^{}];
        [self stopMeasuring];

        [token stop];
    }];
}

- (void)testArrayKVOIndexHandlingRemoveForward {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = [self getStringObjects:50];
        [realm beginWriteTransaction];
        ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withValue:@[@"", [StringObject allObjectsInRealm:realm], @[]]];
        [realm commitWriteTransaction];

        const NSUInteger initial = obj.array.count;
        [self observeObject:obj keyPath:@"array"
                      until:^(id obj) { return [obj array].count < initial; }];

        [self startMeasuring];
        [realm beginWriteTransaction];
        for (NSUInteger i = 0; i < obj.array.count; i += 10) {
            [obj.array removeObjectAtIndex:i];
        }
        [realm commitWriteTransaction];
        dispatch_sync(_queue, ^{});
    }];
}

- (void)testArrayKVOIndexHandlingRemoveBackwards {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = [self getStringObjects:50];
        [realm beginWriteTransaction];
        ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withValue:@[@"", [StringObject allObjectsInRealm:realm], @[]]];
        [realm commitWriteTransaction];

        const NSUInteger initial = obj.array.count;
        [self observeObject:obj keyPath:@"array"
                      until:^(id obj) { return [obj array].count < initial; }];

        [self startMeasuring];
        [realm beginWriteTransaction];
        for (NSUInteger i = obj.array.count; i > 0; i -= i > 10 ? 10 : i) {
            [obj.array removeObjectAtIndex:i - 1];
        }
        [realm commitWriteTransaction];
        dispatch_sync(_queue, ^{});
    }];
}

- (void)testArrayKVOIndexHandlingInsertCompact {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = [self getStringObjects:50];
        [realm beginWriteTransaction];
        ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[]]];
        [realm commitWriteTransaction];

        const NSUInteger count = [StringObject allObjectsInRealm:realm].count / 8;
        const NSUInteger factor = count / 10;

        [self observeObject:obj keyPath:@"array"
                      until:^(id obj) { return [obj array].count >= count; }];

        [self startMeasuring];
        [realm beginWriteTransaction];
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            [obj.array addObject:so];
            if (obj.array.count % factor == 0) {
                [realm commitWriteTransaction];
                dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
                [realm beginWriteTransaction];
            }
            if (obj.array.count > count) {
                break;
            }
        }
        [realm commitWriteTransaction];

        dispatch_sync(_queue, ^{});
    }];
}

- (void)testArrayKVOIndexHandlingInsertSparse {
    [self measureMetrics:self.class.defaultPerformanceMetrics automaticallyStartMeasuring:NO forBlock:^{
        RLMRealm *realm = [self getStringObjects:50];
        [realm beginWriteTransaction];
        ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[]]];
        [realm commitWriteTransaction];

        const NSUInteger count = [StringObject allObjectsInRealm:realm].count / 8;
        const NSUInteger factor = count / 10;

        [self observeObject:obj keyPath:@"array"
                      until:^(id obj) { return [obj array].count >= count; }];

        [self startMeasuring];
        [realm beginWriteTransaction];
        for (StringObject *so in [StringObject allObjectsInRealm:realm]) {
            NSUInteger index = obj.array.count;
            if (obj.array.count > factor) {
                index = index * 3 % factor;
            }
            [obj.array insertObject:so atIndex:index];

            if (obj.array.count % factor == 0) {
                [realm commitWriteTransaction];
                dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
                [realm beginWriteTransaction];
            }
            if (obj.array.count > count) {
                break;
            }
        }
        [realm commitWriteTransaction];

        dispatch_sync(_queue, ^{});
    }];
}

- (void)observeObject:(RLMObject *)object keyPath:(NSString *)keyPath until:(int (^)(id))block {
    self.sema = dispatch_semaphore_create(0);
    self.queue = dispatch_queue_create("bg", 0);

    RLMRealmConfiguration *config = object.realm.configuration;
    NSString *className = [object.class className];
    dispatch_async(_queue, ^{
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        id obj = [[realm allObjects:className] firstObject];
        [obj addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptions)0 context:(__bridge void *)_sema];

        dispatch_semaphore_signal(_sema);
        while (!block(obj)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }

        [obj removeObserver:self forKeyPath:keyPath context:(__bridge void *)_sema];
    });
    dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
}

- (void)observeValueForKeyPath:(__unused NSString *)keyPath
                      ofObject:(__unused id)object
                        change:(__unused NSDictionary *)change
                       context:(void *)context {
    dispatch_semaphore_signal((__bridge dispatch_semaphore_t)context);
}

@end

#endif
