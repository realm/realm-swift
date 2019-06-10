////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMMultiProcessTestCase.h"

#import "RLMConstants.h"

@interface InterprocessTest : RLMMultiProcessTestCase
@end

@implementation InterprocessTest
- (void)setUp {
    [super setUp];

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.objectClasses = @[IntObject.class, DoubleObject.class];
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

- (void)testCreateInitialRealmInChild {
    if (self.isParent) {
        RLMRunChildAndWait();
        RLMRealm *realm = [RLMRealm defaultRealm];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
    else {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
    }
}

- (void)testCreateInitialRealmInParent {
    RLMRealm *realm = [RLMRealm defaultRealm];
    if (self.isParent) {
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];

        RLMRunChildAndWait();
    }
    else {
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

- (void)testCompactOnLaunchSuccessful {
    if (self.isParent) {
        @autoreleasepool {
            RLMRealm *realm = RLMRealm.defaultRealm;
            [realm transactionWithBlock:^{
                for (int i = 0; i < 1000; ++i) {
                    [IntObject createInRealm:realm withValue:@[@(i)]];
                }
            }];
            [realm transactionWithBlock:^{
                [realm deleteAllObjects];
            }];
        }
        RLMRunChildAndWait(); // runs the event loop
    } else {
        unsigned long long (^fileSize)(NSString *) = ^unsigned long long(NSString *path) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];
        };

        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.shouldCompactOnLaunch = ^BOOL(__unused NSUInteger totalBytes, __unused NSUInteger usedBytes){
            return YES;
        };
        unsigned long long sizeBefore = fileSize(config.fileURL.path);
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        unsigned long long sizeAfter = fileSize(config.fileURL.path);
        XCTAssertGreaterThan(sizeBefore, sizeAfter);
        XCTAssertTrue(realm.isEmpty);
    }
}

- (void)testCompactOnLaunchBeginWriteFailed {
    if (self.isParent) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        RLMRunChildAndWait(); // runs the event loop
        [realm cancelWriteTransaction];
    } else {
        unsigned long long (^fileSize)(NSString *) = ^unsigned long long(NSString *path) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];
        };

        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.shouldCompactOnLaunch = ^BOOL(__unused NSUInteger totalBytes, __unused NSUInteger usedBytes){
            return YES;
        };
        unsigned long long sizeBefore = fileSize(config.fileURL.path);
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        unsigned long long sizeAfter = fileSize(config.fileURL.path);
        XCTAssertEqual(sizeBefore, sizeAfter);
        XCTAssertTrue(realm.isEmpty);
    }
}

- (void)testCompactOnLaunchFailSilently {
    if (self.isParent) {
        RLMRealm *realm  = [RLMRealm defaultRealm];
        RLMRunChildAndWait(); // runs the event loop
        (void)[realm configuration]; // ensure the Realm stays open while the child process runs
    } else {
        unsigned long long (^fileSize)(NSString *) = ^unsigned long long(NSString *path) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];
        };

        __block BOOL blockCalled = NO;

        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.shouldCompactOnLaunch = ^BOOL(__unused NSUInteger totalBytes, __unused NSUInteger usedBytes){
            blockCalled = YES;
            return YES;
        };
        unsigned long long sizeBefore = fileSize(config.fileURL.path);
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        unsigned long long sizeAfter = fileSize(config.fileURL.path);
        XCTAssertLessThanOrEqual(sizeBefore, sizeAfter);
        XCTAssertTrue(realm.isEmpty);
        XCTAssertTrue(blockCalled);
    }
}

- (void)testOpenInParentThenAddObjectInChild {
    RLMRealm *realm = [RLMRealm defaultRealm];
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);

    if (self.isParent) {
        RLMRunChildAndWait(); // runs the event loop
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
    else {
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
    }
}

- (void)testOpenInParentThenAddObjectInChildWithoutAutorefresh {
    RLMRealm *realm = [RLMRealm defaultRealm];
    realm.autorefresh = NO;
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);

    if (self.isParent) {
        RLMRunChildAndWait();
        XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
        [realm refresh];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
    else {
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
    }
}

- (void)testOpenInParentThenAddObjectInChildWithNoChanceToAutorefresh {
    RLMRealm *realm = [RLMRealm defaultRealm];
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);

    if (self.isParent) {
        // Wait on a different thread so that this thread doesn't get the chance
        // to autorefresh
        [self dispatchAsyncAndWait:^{
            RLMRunChildAndWait();
        }];

        XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
        [realm refresh];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
    else {
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
    }
}

- (void)testChangeInChildTriggersNotificationInParent {
    RLMRealm *realm = [RLMRealm defaultRealm];
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);

    if (self.isParent) {
        [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
            RLMRunChildAndWait();
        }];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
    else {
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
    }
}

- (void)testBackgroundProcessDoesNotTriggerSpuriousNotifications {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused RLMNotification notification, __unused RLMRealm *realm) {
        XCTFail(@"Notification should not have been triggered");
    }];

    if (self.isParent) {
        RLMRunChildAndWait();
    }
    else {
        // Just a meaningless thing that reads from the realm
        XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
    }

    [token invalidate];
}

// FIXME: Re-enable this test when it can be made to pass reliably.
- (void)DISABLED_testShareInMemoryRealm {
    RLMRealm *realm = [self inMemoryRealmWithIdentifier:@"test"];
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);

    if (self.isParent) {
        [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
            RLMRunChildAndWait();
        }];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
    else {
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
    }
}

- (void)testBidirectionalCommunication {
    const int stopValue = 100;

    RLMRealm *realm = [self inMemoryRealmWithIdentifier:@"test"];
    [realm beginWriteTransaction];
    IntObject *obj = [IntObject allObjectsInRealm:realm].firstObject;
    if (!obj) {
        obj = [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
    }
    else {
        [realm cancelWriteTransaction];
    }

    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, __unused RLMRealm *realm) {
        if (obj.intCol % 2 == self.isParent && obj.intCol < stopValue) {
            [realm transactionWithBlock:^{
                obj.intCol++;
            }];
        }
    }];

    if (self.isParent) {
        dispatch_queue_t queue = dispatch_queue_create("background", 0);
        dispatch_async(queue, ^{ RLMRunChildAndWait(); });
        while (obj.intCol < stopValue) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        dispatch_sync(queue, ^{});
    }
    else {
        [realm transactionWithBlock:^{
            obj.intCol++;
        }];
        while (obj.intCol < stopValue) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }

    [token invalidate];
}

- (void)testManyWriters {
    const int stopValue = 100;
    const int workers = 10;
    const RLMRealm *realm = RLMRealm.defaultRealm;

    if (self.isParent) {
        [realm beginWriteTransaction];
        IntObject *obj = [IntObject createInDefaultRealmWithValue:@[@(-workers)]];
        [realm commitWriteTransaction];

        dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
        for (int i = 0; i < workers; ++i) {
            dispatch_async(queue, ^{ RLMRunChildAndWait(); });
        }
        dispatch_barrier_sync(queue, ^{});

        [realm refresh];
        XCTAssertEqual(stopValue, obj.intCol);
        XCTAssertEqual(stopValue, [DoubleObject allObjects].count);
        XCTAssertEqual(stopValue / 2 + 1, [[DoubleObject.allObjects minOfProperty:@"doubleCol"] intValue]);
        return;
    }

    // Run the run loop until someone else makes a commit
    dispatch_block_t waitForExternalChange = ^{
        RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, __unused RLMRealm *realm) {
            CFRunLoopStop(CFRunLoopGetCurrent());
        }];
        CFRunLoopRun();
        [token invalidate];
    };

    IntObject *obj = [IntObject allObjects].firstObject;
    int nextRun = -1;

    // Wait for all of the workers to start up
    while (obj.intCol < 0) {
        if (nextRun == -1) {
            [realm beginWriteTransaction];
            ++obj.intCol;
            [realm commitWriteTransaction];
            nextRun = 0;
        }
        waitForExternalChange();
    }

    while (true) {
        // Wait for someone else to run if it's not our turn yet
        if (obj.intCol < nextRun && nextRun < 100) {
            waitForExternalChange();
            continue;
        }

        [realm beginWriteTransaction];
        if (obj.intCol == stopValue) {
            [realm commitWriteTransaction];
            break;
        }

        ++obj.intCol;

        // Do some stuff
        [DoubleObject createInDefaultRealmWithValue:@[@(obj.intCol)]];
        [DoubleObject createInDefaultRealmWithValue:@[@(obj.intCol)]];
        RLMResults *min = [DoubleObject objectsWhere:@"doubleCol = %@", [DoubleObject.allObjects minOfProperty:@"doubleCol"]];
        [realm deleteObject:min.firstObject];
        [realm commitWriteTransaction];

        // Wait for a random number of other workers to do some work to avoid
        // having a strict order that processes run in and to avoid having a
        // single process do everything
        nextRun = obj.intCol + arc4random() % 10;
    }
}

- (void)testRecoverAfterCrash {
    if (self.isParent) {
        [self runChildAndWait];
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
        XCTAssertEqual(1U, [IntObject allObjects].count);
    }
    else {
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        _Exit(1);
    }
}

- (void)testRecoverAfterCrashWithFileAlreadyOpen {
    if (self.isParent) {
        RLMRealm *realm = RLMRealm.defaultRealm;
        [self runChildAndWait];
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm commitWriteTransaction];
        XCTAssertEqual(1U, [IntObject allObjects].count);
    }
    else {
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        _Exit(1);
    }
}

- (void)testCanOpenAndReadWhileOtherProcessHoldsWriteLock {
    RLMRealm *realm = RLMRealm.defaultRealm;
    if (self.isParent) {
        [realm beginWriteTransaction];
        RLMRunChildAndWait();
        [realm commitWriteTransaction];
    }
    else {
        XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
    }
}

@end
