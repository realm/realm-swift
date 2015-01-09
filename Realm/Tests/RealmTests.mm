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

#import "RLMObjectSchema_Private.hpp"
#import "RLMRealm_Dynamic.h"

#import <libkern/OSAtomic.h>

@interface RLMRealm ()
+ (BOOL)isCoreDebug;
@end

@interface RLMObjectSchema (Private)
+ (instancetype)schemaForObjectClass:(Class)objectClass;

@property (nonatomic, readwrite, assign) Class objectClass;
@end

@interface RLMSchema (Private)
@property (nonatomic, readwrite, copy) NSArray *objectSchema;
@end

@interface RealmTests : RLMTestCase
@end

@implementation RealmTests

#pragma mark - Tests

- (void)testCoreDebug {
#if DEBUG
    XCTAssertTrue([RLMRealm isCoreDebug], @"Debug version of Realm should use libtightdb{-ios}-dbg");
#else
    XCTAssertFalse([RLMRealm isCoreDebug], @"Release version of Realm should use libtightdb{-ios}");
#endif
}

- (void)testRealmFailure
{
    XCTAssertThrows([RLMRealm realmWithPath:@"/dev/null"], @"Shouldn't exist");
}

- (void)testDefaultRealmPath
{
    NSString *defaultPath = [[RLMRealm defaultRealm] path];
    @autoreleasepool {
        XCTAssertEqualObjects(defaultPath, [RLMRealm defaultRealmPath], @"Default Realm path should be correct.");
    }

    NSString *newPath = [defaultPath stringByAppendingPathExtension:@"new"];
    [RLMRealm setDefaultRealmPath:newPath];
    XCTAssertEqualObjects(newPath, [RLMRealm defaultRealmPath], @"Default Realm path should be correct.");

    // we have to clean-up since dispatch_once isn't run for each test case
    [RLMRealm setDefaultRealmPath:defaultPath];
}

- (void)testRealmPath
{
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    XCTAssertEqualObjects(defaultRealm.path, RLMDefaultRealmPath(), @"Default path");
    RLMRealm *testRealm = [self realmWithTestPath];
    XCTAssertEqualObjects(testRealm.path, RLMTestRealmPath(), @"Test path");
}

- (void)testRealmAddAndRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:@[@"a"]];
    [StringObject createInRealm:realm withObject:@[@"b"]];
    [StringObject createInRealm:realm withObject:@[@"c"]];
    XCTAssertEqual([StringObject objectsInRealm:realm withPredicate:nil].count, 3U, @"Expecting 3 objects");
    [realm commitWriteTransaction];

    // test again after write transaction
    RLMResults *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, 3U, @"Expecting 3 objects");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"a", @"Expecting column to be 'a'");

    [realm beginWriteTransaction];
    [realm deleteObject:objects[2]];
    [realm deleteObject:objects[0]];
    XCTAssertEqual([StringObject objectsInRealm:realm withPredicate:nil].count, 1U, @"Expecting 1 object");
    [realm commitWriteTransaction];

    objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, 1U, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}

- (void)testRemoveNonpersistedObject {
    RLMRealm *realm = [self realmWithTestPath];
    StringObject *obj = [[StringObject alloc] initWithObject:@[@"a"]];

    [realm beginWriteTransaction];
    XCTAssertThrows([realm deleteObject:obj]);
    obj = [StringObject createInRealm:realm withObject:@[@"b"]];
    [realm commitWriteTransaction];

    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        RLMObject *obj = [[StringObject allObjectsInRealm:realm] firstObject];
        [realm beginWriteTransaction];
        [realm deleteObject:obj];
        XCTAssertThrows([realm deleteObject:obj]);
        [realm commitWriteTransaction];
    }];

    [realm beginWriteTransaction];
    [realm deleteObject:obj];
    [realm commitWriteTransaction];
}

- (void)testRealmBatchRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    StringObject *strObj = [StringObject createInRealm:realm withObject:@[@"a"]];
    [StringObject createInRealm:realm withObject:@[@"b"]];
    [StringObject createInRealm:realm withObject:@[@"c"]];
    [realm commitWriteTransaction];

    // delete objects
    RLMResults *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, 3U, @"Expecting 3 objects");
    [realm beginWriteTransaction];
    [realm deleteObjects:[StringObject objectsInRealm:realm where:@"stringCol != 'a'"]];
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], 1U, @"Expecting 0 objects");
    [realm deleteObjects:objects];
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], 0U, @"Expecting 0 objects");
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], 0U, @"Expecting 0 objects");
    XCTAssertThrows(strObj.stringCol, @"Object should be invalidated");

    // add objects to linkView
    [realm beginWriteTransaction];
    ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withObject:@[@"name", @[@[@"a"], @[@"b"], @[@"c"]], @[]]];
    [StringObject createInRealm:realm withObject:@[@"d"]];
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], 4U, @"Expecting 4 objects");

    // remove from linkView
    [realm beginWriteTransaction];
    [realm deleteObjects:obj.array];
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], 1U, @"Expecting 1 object");
    XCTAssertEqual(obj.array.count, 0U, @"Expecting 0 objects");

    // remove NSArray
    NSArray *arrayOfLastObject = @[[[StringObject allObjectsInRealm:realm] lastObject]];
    [realm beginWriteTransaction];
    [realm deleteObjects:arrayOfLastObject];
    [realm commitWriteTransaction];
    XCTAssertEqual(objects.count, 0U, @"Expecting 0 objects");

    // add objects to linkView
    [realm beginWriteTransaction];
    [obj.array addObject:[StringObject createInRealm:realm withObject:@[@"a"]]];
    [obj.array addObject:[[StringObject alloc] initWithObject:@[@"b"]]];
    [realm commitWriteTransaction];

    // remove objects from realm
    XCTAssertEqual(obj.array.count, 2U, @"Expecting 2 objects");
    [realm beginWriteTransaction];
    [realm deleteObjects:[StringObject allObjectsInRealm:realm]];
    [realm commitWriteTransaction];
    XCTAssertEqual(obj.array.count, 0U, @"Expecting 0 objects");
}

- (void)testAddPersistedObjectToOtherRealm {
    RLMRealm *realm1 = [self realmWithTestPath];
    RLMRealm *realm2 = [RLMRealm defaultRealm];

    CircleObject *co1 = [[CircleObject alloc] init];
    co1.data = @"1";

    CircleObject *co2 = [[CircleObject alloc] init];
    co2.data = @"2";
    co2.next = co1;

    CircleArrayObject *cao = [[CircleArrayObject alloc] init];
    [cao.circles addObject:co1];

    [realm1 transactionWithBlock:^{ [realm1 addObject:co1]; }];

    [realm2 beginWriteTransaction];
    XCTAssertThrows([realm2 addObject:co1], @"should reject already-persisted object");
    XCTAssertThrows([realm2 addObject:co2], @"should reject linked persisted object");
    XCTAssertThrows([realm2 addObject:cao], @"should reject array containing persisted object");
    [realm2 commitWriteTransaction];

    // The objects are left in an odd state if validation fails (since the
    // exception isn't supposed to be recoverable), so make new objects
    co2 = [[CircleObject alloc] init];
    co2.data = @"2";
    co2.next = co1;

    cao = [[CircleArrayObject alloc] init];
    [cao.circles addObject:co1];

    [realm1 beginWriteTransaction];
    XCTAssertNoThrow([realm1 addObject:co2], @"should be able to add object which links to object persisted in target realm");
    XCTAssertNoThrow([realm1 addObject:cao], @"should be able to add object with an array containing an object persisted in target realm");
    [realm1 commitWriteTransaction];
}

- (void)testCopyObjectsBetweenRealms {
    RLMRealm *realm1 = [self realmWithTestPath];
    RLMRealm *realm2 = [RLMRealm defaultRealm];

    StringObject *so = [[StringObject alloc] init];
    so.stringCol = @"value";

    [realm1 beginWriteTransaction];
    [realm1 addObject:so];
    [realm1 commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm1].count);
    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm2].count);
    XCTAssertEqualObjects(so.stringCol, @"value");

    [realm2 beginWriteTransaction];
    StringObject *so2 = [StringObject createInRealm:realm2 withObject:so];
    [realm2 commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm1].count);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm2].count);
    XCTAssertEqualObjects(so2.stringCol, @"value");
}

- (void)testCopyArrayPropertyBetweenRealms {
    RLMRealm *realm1 = [self realmWithTestPath];
    RLMRealm *realm2 = [RLMRealm defaultRealm];

    EmployeeObject *eo = [[EmployeeObject alloc] init];
    eo.name = @"name";
    eo.age = 50;
    eo.hired = YES;

    CompanyObject *co = [[CompanyObject alloc] init];
    co.name = @"company name";
    [co.employees addObject:eo];

    [realm1 beginWriteTransaction];
    [realm1 addObject:co];
    [realm1 commitWriteTransaction];

    XCTAssertEqual(1U, [EmployeeObject allObjectsInRealm:realm1].count);
    XCTAssertEqual(1U, [CompanyObject allObjectsInRealm:realm1].count);

    [realm2 beginWriteTransaction];
    CompanyObject *co2 = [CompanyObject createInRealm:realm2 withObject:co];
    [realm2 commitWriteTransaction];

    XCTAssertEqual(1U, [EmployeeObject allObjectsInRealm:realm1].count);
    XCTAssertEqual(1U, [CompanyObject allObjectsInRealm:realm1].count);
    XCTAssertEqual(1U, [EmployeeObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(1U, [CompanyObject allObjectsInRealm:realm2].count);

    XCTAssertEqualObjects(@"name", [co2.employees.firstObject name]);
}

- (void)testCopyLinksBetweenRealms {
    RLMRealm *realm1 = [self realmWithTestPath];
    RLMRealm *realm2 = [RLMRealm defaultRealm];

    CircleObject *c = [[CircleObject alloc] init];
    c.data = @"1";
    c.next = [[CircleObject alloc] init];
    c.next.data = @"2";

    [realm1 beginWriteTransaction];
    [realm1 addObject:c];
    [realm1 commitWriteTransaction];

    XCTAssertEqual(realm1, c.realm);
    XCTAssertEqual(realm1, c.next.realm);
    XCTAssertEqual(2U, [CircleObject allObjectsInRealm:realm1].count);

    [realm2 beginWriteTransaction];
    CircleObject *c2 = [CircleObject createInRealm:realm2 withObject:c];
    [realm2 commitWriteTransaction];

    XCTAssertEqualObjects(c2.data, @"1");
    XCTAssertEqualObjects(c2.next.data, @"2");

    XCTAssertEqual(2U, [CircleObject allObjectsInRealm:realm1].count);
    XCTAssertEqual(2U, [CircleObject allObjectsInRealm:realm2].count);
}

- (void)testCopyObjectsInArrayLiteral {
    RLMRealm *realm1 = [self realmWithTestPath];
    RLMRealm *realm2 = [RLMRealm defaultRealm];

    CircleObject *c = [[CircleObject alloc] init];
    c.data = @"1";

    [realm1 beginWriteTransaction];
    [realm1 addObject:c];
    [realm1 commitWriteTransaction];

    [realm2 beginWriteTransaction];
    CircleObject *c2 = [CircleObject createInRealm:realm2 withObject:@[@"3", @[@"2", c]]];
    [realm2 commitWriteTransaction];

    XCTAssertEqual(1U, [CircleObject allObjectsInRealm:realm1].count);
    XCTAssertEqual(3U, [CircleObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(realm1, c.realm);
    XCTAssertEqual(realm2, c2.realm);

    XCTAssertEqualObjects(@"1", c.data);
    XCTAssertEqualObjects(@"3", c2.data);
    XCTAssertEqualObjects(@"2", c2.next.data);
    XCTAssertEqualObjects(@"1", c2.next.next.data);
}

- (void)testRealmTransactionBlock {
    RLMRealm *realm = [self realmWithTestPath];
    [realm transactionWithBlock:^{
        [StringObject createInRealm:realm withObject:@[@"b"]];
    }];
    RLMResults *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, 1U, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}

- (void)waitForNotification:(NSString *)expectedNote realm:(RLMRealm *)realm block:(dispatch_block_t)block {
    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm *realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        if (note == expectedNote) {
            [notificationFired fulfill];
        }
    }];

    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, block);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // wait for queue to finish
    dispatch_sync(queue, ^{});

    [realm removeNotification:token];
}

- (void)testAutorefreshAfterBackgroundUpdate {
    RLMRealm *realm = [self realmWithTestPath];

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];
    }];

    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
}

- (void)testBackgroundUpdateWithoutAutorefresh {
    RLMRealm *realm = [self realmWithTestPath];
    realm.autorefresh = NO;

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];

        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
    }];

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    [realm refresh];
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
}

- (void)testBackgroundRealmIsNotified {
    RLMRealm *realm = [self realmWithTestPath];

    XCTestExpectation *bgReady = [self expectationWithDescription:@"background queue waiting for commit"];
    __block XCTestExpectation *bgDone = nil;

    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [self realmWithTestPath];
        __block bool fulfilled = false;
        RLMNotificationToken *token = [realm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
            XCTAssertNotNil(realm, @"Realm should not be nil");
            XCTAssertEqual(note, RLMRealmDidChangeNotification);
            XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
            fulfilled = true;
        }];

        // notify main thread that we're ready for it to commit
        [bgReady fulfill];

        // run for two seconds or until we recieve notification
        NSDate *end = [NSDate dateWithTimeIntervalSinceNow:5.0];
        while (!fulfilled) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:end];
        }
        XCTAssertTrue(fulfilled, @"Notification should have been received");

        [realm removeNotification:token];
        [bgDone fulfill];
    });

    // wait for background realm to be created
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    bgDone = [self expectationWithDescription:@"background queue done"];;

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:@[@"string"]];
    [realm commitWriteTransaction];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // wait for queue to finish
    dispatch_sync(queue, ^{});
}

- (void)testBeginWriteTransactionsNotifiesWithUpdatedObjects {
    RLMRealm *realm = [self realmWithTestPath];
    realm.autorefresh = NO;

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    // Create an object in a background thread and wait for that to complete,
    // without refreshing the main thread realm
    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];

        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
    }];

    // Verify that the main thread realm still doesn't have any objects
    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    // Verify that the local notification sent by the beginWriteTransaction
    // below when it advances the realm to the latest version occurs *after*
    // the advance
    __block bool notificationFired = false;
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm *realm) {
        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
        notificationFired = true;
    }];

    [realm beginWriteTransaction];
    [realm commitWriteTransaction];

    [realm removeNotification:token];
    XCTAssertTrue(notificationFired);
}

- (void)testInMemoryRealm
{
    RLMRealm *inMemoryRealm = [RLMRealm inMemoryRealmWithIdentifier:@"identifier"];

    [self waitForNotification:RLMRealmDidChangeNotification realm:inMemoryRealm block:^{
        RLMRealm *inMemoryRealm = [RLMRealm inMemoryRealmWithIdentifier:@"identifier"];
        [inMemoryRealm beginWriteTransaction];
        [StringObject createInRealm:inMemoryRealm withObject:@[@"a"]];
        [StringObject createInRealm:inMemoryRealm withObject:@[@"b"]];
        [StringObject createInRealm:inMemoryRealm withObject:@[@"c"]];
        XCTAssertEqual(3U, [StringObject allObjectsInRealm:inMemoryRealm].count);
        [inMemoryRealm commitWriteTransaction];
    }];

    XCTAssertEqual(3U, [StringObject allObjectsInRealm:inMemoryRealm].count);

    // make sure we can have another
    RLMRealm *anotherInMemoryRealm = [RLMRealm inMemoryRealmWithIdentifier:@"identifier2"];
    XCTAssertEqual(0U, [StringObject allObjectsInRealm:anotherInMemoryRealm].count);

    // make sure we can't open disk-realm at same path
    XCTAssertThrows([RLMRealm realmWithPath:anotherInMemoryRealm.path], @"Should throw");
}

- (void)testRealmFileAccess
{
    XCTAssertThrows([RLMRealm realmWithPath:nil], @"nil path");
    XCTAssertThrows([RLMRealm realmWithPath:@""], @"empty path");

    NSString *content = @"Some content";
    NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filePath = RLMRealmPathForFile(@"filename.realm");
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];

    NSError *error;
    XCTAssertNil([RLMRealm realmWithPath:filePath readOnly:NO error:&error], @"Invalid database");
    XCTAssertNotNil(error, @"Should populate error object");
}

- (void)testCrossThreadAccess
{
    RLMRealm *realm = RLMRealm.defaultRealm;

    // Using dispatch_async to ensure it actually lands on another thread
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&spinlock);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertThrows([realm beginWriteTransaction]);
        XCTAssertThrows([IntObject allObjectsInRealm:realm]);
        XCTAssertThrows([IntObject objectsInRealm:realm where:@"intCol = 0"]);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);
}

- (void)testReadOnlyFile
{
    @autoreleasepool {
        RLMRealm *realm = self.realmWithTestPath;
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"a"]];
        [realm commitWriteTransaction];
    }

    [NSFileManager.defaultManager setAttributes:@{NSFileImmutable: @YES} ofItemAtPath:RLMTestRealmPath() error:nil];

    // Should not be able to open read-write
    XCTAssertThrows([self realmWithTestPath]);

    RLMRealm *realm;
    XCTAssertNoThrow(realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil]);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);

    [NSFileManager.defaultManager setAttributes:@{NSFileImmutable: @NO} ofItemAtPath:RLMTestRealmPath() error:nil];
}

- (void)testReadOnlyRealmMustExist
{
   XCTAssertThrows([RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil]);
}

- (void)testReadOnlyRealmIsImmutable
{
    @autoreleasepool { [self realmWithTestPath]; }

    RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil];
    XCTAssertThrows([realm beginWriteTransaction]);
    XCTAssertThrows([realm refresh]);
}

- (void)testCannotHaveReadOnlyAndReadWriteRealmsAtSamePathAtSameTime
{
    @autoreleasepool {
        XCTAssertNoThrow([self realmWithTestPath]);
        XCTAssertThrows([RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil]);
    }

    @autoreleasepool {
        XCTAssertNoThrow([RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil]);
        XCTAssertThrows([self realmWithTestPath]);
    }
}

- (void)testReadOnlyRealmWithMissingTables
{
    // create a realm with only a StringObject table
    @autoreleasepool {
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
        objectSchema.objectClass = RLMObject.class;

        RLMSchema *schema = [[RLMSchema alloc] init];
        schema.objectSchema = @[objectSchema];
        RLMRealm *realm = [self realmWithTestPathAndSchema:schema];

        [realm beginWriteTransaction];
        [realm createObject:StringObject.className withObject:@[@"a"]];
        [realm commitWriteTransaction];
    }

    RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil];
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);

    // verify that reading a missing table gives an empty array rather than
    // crashing
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
}

- (void)testReadOnlyRealmWithMissingColumns
{
    // create a realm with only a zero-column StringObject table
    @autoreleasepool {
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
        objectSchema.objectClass = RLMObject.class;
        objectSchema.properties = @[];

        RLMSchema *schema = [[RLMSchema alloc] init];
        schema.objectSchema = @[objectSchema];
        RLMRealm *realm = [self realmWithTestPathAndSchema:schema];

        [realm beginWriteTransaction];
        [realm createObject:StringObject.className withObject:@[]];
        [realm commitWriteTransaction];
    }

    XCTAssertThrows([RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil],
                    @"should reject table missing column");
}

- (void)testMultipleRealms
{
    // Create one StringObject in two different realms
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    RLMRealm *testRealm = self.realmWithTestPath;
    [defaultRealm beginWriteTransaction];
    [testRealm beginWriteTransaction];
    [StringObject createInRealm:defaultRealm withObject:@[@"a"]];
    [StringObject createInRealm:testRealm withObject:@[@"b"]];
    [testRealm commitWriteTransaction];
    [defaultRealm commitWriteTransaction];

    // Confirm that objects were added to the correct realms
    RLMResults *defaultObjects = [StringObject allObjectsInRealm:defaultRealm];
    RLMResults *testObjects = [StringObject allObjectsInRealm:testRealm];
    XCTAssertEqual(defaultObjects.count, 1U, @"Expecting 1 object");
    XCTAssertEqual(testObjects.count, 1U, @"Expecting 1 object");
    XCTAssertEqualObjects([defaultObjects.firstObject stringCol], @"a", @"Expecting column to be 'a'");
    XCTAssertEqualObjects([testObjects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}

- (void)testAddOrUpdate {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    PrimaryStringObject *obj = [[PrimaryStringObject alloc] initWithObject:@[@"string", @1]];
    [realm addOrUpdateObject:obj];
    RLMResults *objects = [PrimaryStringObject allObjects];
    XCTAssertEqual([objects count], 1U, @"Should have 1 object");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 1, @"Value should be 1");

    PrimaryStringObject *obj2 = [[PrimaryStringObject alloc] initWithObject:@[@"string2", @2]];
    [realm addOrUpdateObject:obj2];
    XCTAssertEqual([objects count], 2U, @"Should have 2 objects");

    // upsert with new secondary property
    PrimaryStringObject *obj3 = [[PrimaryStringObject alloc] initWithObject:@[@"string", @3]];
    [realm addOrUpdateObject:obj3];
    XCTAssertEqual([objects count], 2U, @"Should have 2 objects");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 3, @"Value should be 3");

    // upsert on non-primary key object should throw
    XCTAssertThrows([realm addOrUpdateObject:[[StringObject alloc] initWithObject:@[@"string"]]]);

    [realm commitWriteTransaction];
}

- (void)testDeleteAllObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    OwnerObject *obj = [OwnerObject createInDefaultRealmWithObject:@[@"deeter", @[@"barney", @2]]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, OwnerObject.allObjects.count);
    XCTAssertEqual(1U, DogObject.allObjects.count);
    XCTAssertEqual(NO, obj.invalidated);

    XCTAssertThrows([realm deleteAllObjects]);

    [realm transactionWithBlock:^{
        [realm deleteAllObjects];
        XCTAssertEqual(YES, obj.invalidated);
    }];

    XCTAssertEqual(0U, OwnerObject.allObjects.count);
    XCTAssertEqual(0U, DogObject.allObjects.count);
}

- (void)testRollbackInsert
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    IntObject *createdObject = [IntObject createInRealm:realm withObject:@[@0]];
    [realm cancelWriteTransaction];

    XCTAssertTrue(createdObject.isInvalidated);
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
}

- (void)testRollbackDelete
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    IntObject *objectToDelete = [IntObject createInRealm:realm withObject:@[@0]];
    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    [realm deleteObject:objectToDelete];
    [realm cancelWriteTransaction];

    XCTAssertTrue(objectToDelete.isInvalidated);
    XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
}

- (void)testRollbackModify
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    IntObject *objectToModify = [IntObject createInRealm:realm withObject:@[@0]];
    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    objectToModify.intCol = 1;
    [realm cancelWriteTransaction];

    XCTAssertEqual(0, objectToModify.intCol);
}

- (void)testRollbackLink
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    CircleObject *obj1 = [CircleObject createInRealm:realm withObject:@[@"1", NSNull.null]];
    CircleObject *obj2 = [CircleObject createInRealm:realm withObject:@[@"2", NSNull.null]];
    [realm commitWriteTransaction];

    // Link to existing persisted
    [realm beginWriteTransaction];
    obj1.next = obj2;
    [realm cancelWriteTransaction];

    XCTAssertNil(obj1.next);

    // Link to standalone
    [realm beginWriteTransaction];
    CircleObject *obj3 = [[CircleObject alloc] init];
    obj3.data = @"3";
    obj1.next = obj3;
    [realm cancelWriteTransaction];

    XCTAssertNil(obj1.next);
    XCTAssertEqual(2U, [CircleObject allObjectsInRealm:realm].count);

    // Remove link
    [realm beginWriteTransaction];
    obj1.next = obj2;
    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    obj1.next = nil;
    [realm cancelWriteTransaction];

    XCTAssertTrue([obj1.next isEqualToObject:obj2]);

    // Modify link
    [realm beginWriteTransaction];
    CircleObject *obj4 = [CircleObject createInRealm:realm withObject:@[@"4", NSNull.null]];
    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    obj1.next = obj4;
    [realm cancelWriteTransaction];

    XCTAssertTrue([obj1.next isEqualToObject:obj2]);
}

- (void)testRollbackLinkList
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    IntObject *obj1 = [IntObject createInRealm:realm withObject:@[@0]];
    IntObject *obj2 = [IntObject createInRealm:realm withObject:@[@1]];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withObject:@[@"", @[], @[obj1]]];
    [realm commitWriteTransaction];

    // Add existing persisted
    [realm beginWriteTransaction];
    [array.intArray addObject:obj2];
    [realm cancelWriteTransaction];

    XCTAssertEqual(1U, array.intArray.count);

    // Add standalone
    [realm beginWriteTransaction];
    [array.intArray addObject:[[IntObject alloc] init]];
    [realm cancelWriteTransaction];

    XCTAssertEqual(1U, array.intArray.count);
    XCTAssertEqual(2U, [IntObject allObjectsInRealm:realm].count);

    // Remove
    [realm beginWriteTransaction];
    [array.intArray removeObjectAtIndex:0];
    [realm cancelWriteTransaction];

    XCTAssertEqual(1U, array.intArray.count);

    // Modify
    [realm beginWriteTransaction];
    array.intArray[0] = obj2;
    [realm cancelWriteTransaction];

    XCTAssertEqual(1U, array.intArray.count);
    XCTAssertTrue([array.intArray[0] isEqualToObject:obj1]);
}

- (void)testRollbackTransactionWithBlock
{
    RLMRealm *realm = [self realmWithTestPath];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withObject:@[@0]];
        [realm cancelWriteTransaction];
    }];

    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
}

- (void)testRollbackTransactionWithoutExplicitCommitOrCancel
{
    @autoreleasepool {
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withObject:@[@0]];
    }

    XCTAssertEqual(0U, [IntObject allObjectsInRealm:[self realmWithTestPath]].count);
}

- (void)testAddObjectsFromArray
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    XCTAssertThrows(([realm addObjects:@[@[@"Rex", @10]]]),
                    @"should reject non-RLMObject in array");

    DogObject *dog = [DogObject new];
    dog.dogName = @"Rex";
    dog.age = 10;
    XCTAssertNoThrow([realm addObjects:@[dog]], @"should allow RLMObject in array");
    XCTAssertEqual(1U, [[DogObject allObjectsInRealm:realm] count]);
}

- (void)testWriteCopyOfRealm
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withObject:@[@0]];
    }];

    NSError *writeError;
    XCTAssertTrue([realm writeCopyToPath:RLMTestRealmPath() error:&writeError]);
    XCTAssertNil(writeError);
    RLMRealm *copy = [self realmWithTestPath];
    XCTAssertEqual(1U, [IntObject allObjectsInRealm:copy].count);
}

- (void)testCannotOverwriteWithWriteCopy
{
    RLMRealm *realm = [self realmWithTestPath];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withObject:@[@0]];
    }];

    NSError *writeError;
    XCTAssertFalse([realm writeCopyToPath:RLMTestRealmPath() error:&writeError]);
    XCTAssertNotNil(writeError);
}

- (void)testWritingCopyUsesWriteTransactionInProgress
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withObject:@[@0]];

        NSError *writeError;
        XCTAssertTrue([realm writeCopyToPath:RLMTestRealmPath() error:&writeError]);
        XCTAssertNil(writeError);
        RLMRealm *copy = [self realmWithTestPath];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:copy].count);
    }];
}

- (void)testCanRestartReadTransactionAfterInvalidate
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withObject:@[@1]];
    }];

    [realm invalidate];
    IntObject *obj = [IntObject allObjectsInRealm:realm].firstObject;
    XCTAssertEqual(obj.intCol, 1);
}

- (void)testInvalidateDetachesAccessors
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    __block IntObject *obj;
    [realm transactionWithBlock:^{
        obj = [IntObject createInRealm:realm withObject:@[@0]];
    }];

    [realm invalidate];
    XCTAssertTrue(obj.isInvalidated);
    XCTAssertThrows([obj intCol]);
}

- (void)testInvalidateInvalidatesResults
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withObject:@[@1]];
    }];

    RLMResults *results = [IntObject objectsInRealm:realm where:@"intCol = 1"];
    XCTAssertEqual([results.firstObject intCol], 1);

    [realm invalidate];
    XCTAssertThrows([results count]);
    XCTAssertThrows([results firstObject]);
}

- (void)testInvalidateInvalidatesArrays
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    __block ArrayPropertyObject *arrayObject;
    [realm transactionWithBlock:^{
        arrayObject = [ArrayPropertyObject createInRealm:realm withObject:@[@"", @[], @[@[@1]]]];
    }];

    RLMArray *array = arrayObject.intArray;
    XCTAssertEqual(1U, array.count);

    [realm invalidate];
    XCTAssertThrows([array count]);
}

- (void)testInvalidteOnReadOnlyRealmIsError
{
    @autoreleasepool {
        // Create the file
        [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];
    }
    RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil];
    XCTAssertThrows([realm invalidate]);
}

- (void)testInvalidateBeforeReadDoesNotAssert
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm invalidate];
}

- (void)testInvalidateDuringWriteRollsBack
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    @autoreleasepool {
        [IntObject createInRealm:realm withObject:@[@1]];
    }
    [realm invalidate];

    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
}

- (void)testRefreshCreatesAReadTransaction
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_group_t group = dispatch_group_create();

    dispatch_group_async(group, queue, ^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithObject:@[@1]];
        }];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    XCTAssertTrue([realm refresh]);

    dispatch_group_async(group, queue, ^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithObject:@[@1]];
        }];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    // refresh above should have created a read transaction, so realm should
    // still only see one object
    XCTAssertEqual(1U, [IntObject allObjects].count);

    // Just a sanity check
    XCTAssertTrue([realm refresh]);
    XCTAssertEqual(2U, [IntObject allObjects].count);
}

- (void)testBadEncryptionKeys
{
    XCTAssertThrows([RLMRealm realmWithPath:RLMRealm.defaultRealmPath encryptionKey:nil readOnly:NO error:nil]);
    XCTAssertThrows([RLMRealm realmWithPath:RLMRealm.defaultRealmPath encryptionKey:[NSData data] readOnly:NO error:nil]);
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMRealm.defaultRealmPath encryptionKey:nil]);
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMRealm.defaultRealmPath encryptionKey:[NSData data]]);
    XCTAssertThrows([RLMRealm setEncryptionKey:[NSData data] forRealmsAtPath:RLMRealm.defaultRealmPath]);
}

- (void)testValidEncryptionKeys
{
    XCTAssertNoThrow([RLMRealm setEncryptionKey:[[NSMutableData alloc] initWithLength:64]
                                forRealmsAtPath:RLMRealm.defaultRealmPath]);
    XCTAssertNoThrow([RLMRealm setEncryptionKey:nil forRealmsAtPath:RLMRealm.defaultRealmPath]);

}
@end
