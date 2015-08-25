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

extern "C" {
#import "RLMSchema_Private.h"
}

@interface RLMRealm ()
+ (BOOL)isCoreDebug;
- (BOOL)compact;
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

- (void)deleteFiles
{
    [super deleteFiles];

    for (NSString *realmPath in self.pathsFor100Realms) {
        [self deleteRealmFileAtPath:realmPath];
    }
}

#pragma mark - Tests

- (void)testCoreDebug {
#if DEBUG
    XCTAssertTrue([RLMRealm isCoreDebug], @"Debug version of Realm should use librealm{-ios}-dbg");
#else
    XCTAssertFalse([RLMRealm isCoreDebug], @"Release version of Realm should use librealm{-ios}");
#endif
}

- (void)testRealmFailure
{
    XCTAssertThrows([RLMRealm realmWithPath:@"/dev/null"], @"Shouldn't exist");
}

- (void)testDefaultRealmPath
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *defaultPath = [[RLMRealm defaultRealm] path];
    @autoreleasepool {
        XCTAssertEqualObjects(defaultPath, [RLMRealm defaultRealmPath], @"Default Realm path should be correct.");
    }

    NSString *newPath = [defaultPath stringByAppendingPathExtension:@"new"];
    [RLMRealm setDefaultRealmPath:newPath];
    XCTAssertEqualObjects(newPath, [RLMRealm defaultRealmPath], @"Default Realm path should be correct.");

    // we have to clean-up since dispatch_once isn't run for each test case
    [RLMRealm setDefaultRealmPath:defaultPath];
#pragma clang diagnostic pop
}

- (void)testRealmPath
{
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    XCTAssertEqualObjects(defaultRealm.path, RLMDefaultRealmPath(), @"Default path");
    RLMRealm *testRealm = [self realmWithTestPath];
    XCTAssertEqualObjects(testRealm.path, RLMTestRealmPath(), @"Test path");
}

- (void)testRealmConfiguration {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMRealmConfiguration *configuration = realm.configuration;
    XCTAssertEqual(realm, [RLMRealm realmWithConfiguration:configuration error:nil]);
}

- (void)testRealmAddAndRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withValue:@[@"a"]];
    [StringObject createInRealm:realm withValue:@[@"b"]];
    [StringObject createInRealm:realm withValue:@[@"c"]];
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
    StringObject *obj = [[StringObject alloc] initWithValue:@[@"a"]];

    [realm beginWriteTransaction];
    XCTAssertThrows([realm deleteObject:obj]);
    obj = [StringObject createInRealm:realm withValue:@[@"b"]];
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
    StringObject *strObj = [StringObject createInRealm:realm withValue:@[@"a"]];
    [StringObject createInRealm:realm withValue:@[@"b"]];
    [StringObject createInRealm:realm withValue:@[@"c"]];
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
    ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withValue:@[@"name", @[@[@"a"], @[@"b"], @[@"c"]], @[]]];
    [StringObject createInRealm:realm withValue:@[@"d"]];
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
    [obj.array addObject:[StringObject createInRealm:realm withValue:@[@"a"]]];
    [obj.array addObject:[[StringObject alloc] initWithValue:@[@"b"]]];
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
    StringObject *so2 = [StringObject createInRealm:realm2 withValue:so];
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
    CompanyObject *co2 = [CompanyObject createInRealm:realm2 withValue:co];
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
    CircleObject *c2 = [CircleObject createInRealm:realm2 withValue:c];
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
    CircleObject *c2 = [CircleObject createInRealm:realm2 withValue:@[@"3", @[@"2", c]]];
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
        [StringObject createInRealm:realm withValue:@[@"b"]];
    }];
    RLMResults *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, 1U, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}

- (void)testInWriteTransaction {
    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertFalse(realm.inWriteTransaction);
    [realm beginWriteTransaction];
    XCTAssertTrue(realm.inWriteTransaction);
    [realm cancelWriteTransaction];
    [realm transactionWithBlock:^{
        XCTAssertTrue(realm.inWriteTransaction);
        [realm cancelWriteTransaction];
        XCTAssertFalse(realm.inWriteTransaction);
    }];

    [realm beginWriteTransaction];
    [realm invalidate];
    XCTAssertFalse(realm.inWriteTransaction);
}

- (void)testAutorefreshAfterBackgroundUpdate {
    RLMRealm *realm = [self realmWithTestPath];

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withValue:@[@"string"]];
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
        [StringObject createInRealm:realm withValue:@[@"string"]];
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

    [self dispatchAsync:^{
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

        // run for two seconds or until we receive notification
        NSDate *end = [NSDate dateWithTimeIntervalSinceNow:5.0];
        while (!fulfilled) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:end];
        }
        XCTAssertTrue(fulfilled, @"Notification should have been received");

        [realm removeNotification:token];
        [bgDone fulfill];
    }];

    // wait for background realm to be created
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    bgDone = [self expectationWithDescription:@"background queue done"];;

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withValue:@[@"string"]];
    [realm commitWriteTransaction];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
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
        [StringObject createInRealm:realm withValue:@[@"string"]];
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

- (void)testBeginWriteTransactionsRefreshesRealm {
    // auto refresh on by default
    RLMRealm *realm = [self realmWithTestPath];

    // Set up notification which will be triggered when calling beginWriteTransaction
    __block bool notificationFired = false;
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm *realm) {
        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
        XCTAssertThrows([realm beginWriteTransaction], @"We should already be in a write transaction");
        notificationFired = true;
    }];

    // dispatch to background syncronously
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withValue:@[@"string"]];
        [realm commitWriteTransaction];
    }];

    // notification shouldnt have fired
    XCTAssertFalse(notificationFired);

    [realm beginWriteTransaction];

    // notification should have fired
    XCTAssertTrue(notificationFired);

    [realm cancelWriteTransaction];
    [realm removeNotification:token];
}

- (void)testInMemoryRealm
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    RLMRealm *inMemoryRealm = [RLMRealm inMemoryRealmWithIdentifier:@"identifier"];
#pragma clang diagnostic pop

    // verify that the realm's path is in the temporary directory
    XCTAssertEqualObjects(NSTemporaryDirectory(), [inMemoryRealm.path.stringByDeletingLastPathComponent stringByAppendingString:@"/"]);

    [self waitForNotification:RLMRealmDidChangeNotification realm:inMemoryRealm block:^{
        RLMRealm *inMemoryRealm = [self inMemoryRealmWithIdentifier:@"identifier"];
        [inMemoryRealm beginWriteTransaction];
        [StringObject createInRealm:inMemoryRealm withValue:@[@"a"]];
        [StringObject createInRealm:inMemoryRealm withValue:@[@"b"]];
        [StringObject createInRealm:inMemoryRealm withValue:@[@"c"]];
        XCTAssertEqual(3U, [StringObject allObjectsInRealm:inMemoryRealm].count);
        [inMemoryRealm commitWriteTransaction];
    }];

    XCTAssertEqual(3U, [StringObject allObjectsInRealm:inMemoryRealm].count);

    // make sure we can have another
    RLMRealm *anotherInMemoryRealm = [self inMemoryRealmWithIdentifier:@"identifier2"];
    XCTAssertEqual(0U, [StringObject allObjectsInRealm:anotherInMemoryRealm].count);

    // make sure we can't open disk-realm at same path
    XCTAssertThrows([RLMRealm realmWithPath:anotherInMemoryRealm.path], @"Should throw");
}

- (void)testRealmFileAccess
{
    XCTAssertThrows([RLMRealm realmWithPath:self.nonLiteralNil], @"nil path");
    XCTAssertThrows([RLMRealm realmWithPath:@""], @"empty path");

    NSString *content = @"Some content";
    NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filePath = RLMRealmPathForFile(@"filename.realm");
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];

    NSError *error;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertNil([RLMRealm realmWithPath:filePath readOnly:NO error:&error], @"Invalid database");
    XCTAssertNotNil(error, @"Should populate error object");
#pragma clang diagnostic pop
    error = nil;
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.path = filePath;
    XCTAssertNil([RLMRealm realmWithConfiguration:configuration error:&error], @"Invalid database");
    XCTAssertNotNil(error, @"Should populate error object");
}

- (void)testCrossThreadAccess
{
    RLMRealm *realm = RLMRealm.defaultRealm;

    [self dispatchAsyncAndWait:^{
        XCTAssertThrows([realm beginWriteTransaction]);
        XCTAssertThrows([IntObject allObjectsInRealm:realm]);
        XCTAssertThrows([IntObject objectsInRealm:realm where:@"intCol = 0"]);
    }];
}

- (void)testReadOnlyFile
{
    @autoreleasepool {
        RLMRealm *realm = self.realmWithTestPath;
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withValue:@[@"a"]];
        [realm commitWriteTransaction];
    }

    [NSFileManager.defaultManager setAttributes:@{NSFileImmutable: @YES} ofItemAtPath:RLMTestRealmPath() error:nil];

    // Should not be able to open read-write
    XCTAssertThrows([self realmWithTestPath]);

    RLMRealm *realm;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertNoThrow(realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil]);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
#pragma clang diagnostic pop
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.path = RLMTestRealmPath();
    configuration.readOnly = true;
    realm = nil;
    XCTAssertNoThrow(realm = [RLMRealm realmWithConfiguration:configuration error:nil]);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);

    [NSFileManager.defaultManager setAttributes:@{NSFileImmutable: @NO} ofItemAtPath:RLMTestRealmPath() error:nil];
}

- (void)testReadOnlyRealmMustExist
{
   XCTAssertThrows([self readOnlyRealmWithPath:RLMTestRealmPath() error:nil]);
}

- (void)testReadOnlyRealmIsImmutable
{
    @autoreleasepool { [self realmWithTestPath]; }

    RLMRealm *realm = [self readOnlyRealmWithPath:RLMTestRealmPath() error:nil];
    XCTAssertThrows([realm beginWriteTransaction]);
    XCTAssertThrows([realm refresh]);
}

- (void)testCannotHaveReadOnlyAndReadWriteRealmsAtSamePathAtSameTime
{
    @autoreleasepool {
        XCTAssertNoThrow([self realmWithTestPath]);
        XCTAssertThrows([self readOnlyRealmWithPath:RLMTestRealmPath() error:nil]);
    }

    @autoreleasepool {
        XCTAssertNoThrow([self readOnlyRealmWithPath:RLMTestRealmPath() error:nil]);
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
        [realm createObject:StringObject.className withValue:@[@"a"]];
        [realm commitWriteTransaction];
    }

    RLMRealm *realm = [self readOnlyRealmWithPath:RLMTestRealmPath() error:nil];
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);

    // verify that reading a missing table gives an empty array rather than
    // crashing
    RLMResults *results = [IntObject allObjectsInRealm:realm];
    XCTAssertEqual(0U, results.count);
    XCTAssertEqual(results, [results objectsWhere:@"intCol = 5"]);
    XCTAssertEqual(results, [results sortedResultsUsingProperty:@"intCol" ascending:YES]);
    XCTAssertThrows([results objectAtIndex:0]);
    XCTAssertEqual(NSNotFound, [results indexOfObject:self.nonLiteralNil]);
    XCTAssertNoThrow([realm deleteObjects:results]);
    for (__unused id obj in results) {
        XCTFail(@"Got an item in empty results");
    }
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
        [realm createObject:StringObject.className withValue:@[]];
        [realm commitWriteTransaction];
    }

    XCTAssertThrows([self readOnlyRealmWithPath:RLMTestRealmPath() error:nil],
                    @"should reject table missing column");
}

- (void)testMultipleRealms
{
    // Create one StringObject in two different realms
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    RLMRealm *testRealm = self.realmWithTestPath;
    [defaultRealm beginWriteTransaction];
    [testRealm beginWriteTransaction];
    [StringObject createInRealm:defaultRealm withValue:@[@"a"]];
    [StringObject createInRealm:testRealm withValue:@[@"b"]];
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

    PrimaryStringObject *obj = [[PrimaryStringObject alloc] initWithValue:@[@"string", @1]];
    [realm addOrUpdateObject:obj];
    RLMResults *objects = [PrimaryStringObject allObjects];
    XCTAssertEqual([objects count], 1U, @"Should have 1 object");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 1, @"Value should be 1");

    PrimaryStringObject *obj2 = [[PrimaryStringObject alloc] initWithValue:@[@"string2", @2]];
    [realm addOrUpdateObject:obj2];
    XCTAssertEqual([objects count], 2U, @"Should have 2 objects");

    // upsert with new secondary property
    PrimaryStringObject *obj3 = [[PrimaryStringObject alloc] initWithValue:@[@"string", @3]];
    [realm addOrUpdateObject:obj3];
    XCTAssertEqual([objects count], 2U, @"Should have 2 objects");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 3, @"Value should be 3");

    // upsert on non-primary key object should throw
    XCTAssertThrows([realm addOrUpdateObject:[[StringObject alloc] initWithValue:@[@"string"]]]);

    [realm commitWriteTransaction];
}

- (void)testAddOrUpdateObjectsFromArray {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    PrimaryStringObject *obj = [[PrimaryStringObject alloc] initWithValue:@[@"string1", @1]];
    [realm addObject:obj];

    PrimaryStringObject *obj2 = [[PrimaryStringObject alloc] initWithValue:@[@"string2", @2]];
    [realm addObject:obj2];

    PrimaryStringObject *obj3 = [[PrimaryStringObject alloc] initWithValue:@[@"string3", @3]];
    [realm addObject:obj3];

    RLMResults *objects = [PrimaryStringObject allObjects];
    XCTAssertEqual([objects count], 3U, @"Should have 3 object");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 1, @"Value should be 1");
    XCTAssertEqual([(PrimaryStringObject *)objects[1] intCol], 2, @"Value should be 2");
    XCTAssertEqual([(PrimaryStringObject *)objects[2] intCol], 3, @"Value should be 3");

    // upsert with array of 2 objects. One is to update the existing value, another is added
    NSArray *array = @[[[PrimaryStringObject alloc] initWithValue:@[@"string2", @4]],
                       [[PrimaryStringObject alloc] initWithValue:@[@"string4", @5]]];
    [realm addOrUpdateObjectsFromArray:array];
    XCTAssertEqual([objects count], 4U, @"Should have 4 objects");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 1, @"Value should be 1");
    XCTAssertEqual([(PrimaryStringObject *)objects[1] intCol], 4, @"Value should be 4");
    XCTAssertEqual([(PrimaryStringObject *)objects[2] intCol], 3, @"Value should be 3");
    XCTAssertEqual([(PrimaryStringObject *)objects[3] intCol], 5, @"Value should be 5");

    [realm commitWriteTransaction];
}

- (void)testDelete {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    OwnerObject *obj = [OwnerObject createInDefaultRealmWithValue:@[@"deeter", @[@"barney", @2]]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, OwnerObject.allObjects.count);
    XCTAssertEqual(NO, obj.invalidated);

    XCTAssertThrows([realm deleteObject:obj]);

    RLMRealm *testRealm = [self realmWithTestPath];
    [testRealm transactionWithBlock:^{
        XCTAssertThrows([testRealm deleteObject:[[OwnerObject alloc] init]]);
        [realm transactionWithBlock:^{
            XCTAssertThrows([testRealm deleteObject:obj]);
        }];
    }];

    [realm transactionWithBlock:^{
        [realm deleteObject:obj];
        XCTAssertEqual(YES, obj.invalidated);
    }];

    XCTAssertEqual(0U, OwnerObject.allObjects.count);
}

- (void)testDeleteObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    CompanyObject *obj = [CompanyObject createInDefaultRealmWithValue:@[@"deeter", @[@[@"barney", @2, @YES]]]];
    NSArray *objects = @[obj];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, CompanyObject.allObjects.count);

    XCTAssertThrows([realm deleteObjects:objects]);
    XCTAssertThrows([realm deleteObjects:[CompanyObject allObjectsInRealm:realm]]);
    XCTAssertThrows([realm deleteObjects:obj.employees]);

    RLMRealm *testRealm = [self realmWithTestPath];
    [testRealm transactionWithBlock:^{
        [realm transactionWithBlock:^{
            XCTAssertThrows([testRealm deleteObjects:objects]);
            XCTAssertThrows([testRealm deleteObjects:[CompanyObject allObjectsInRealm:realm]]);
            XCTAssertThrows([testRealm deleteObjects:obj.employees]);
        }];
    }];

    XCTAssertEqual(1U, CompanyObject.allObjects.count);
}

- (void)testDeleteAllObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    OwnerObject *obj = [OwnerObject createInDefaultRealmWithValue:@[@"deeter", @[@"barney", @2]]];
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
    IntObject *createdObject = [IntObject createInRealm:realm withValue:@[@0]];
    [realm cancelWriteTransaction];

    XCTAssertTrue(createdObject.isInvalidated);
    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
}

- (void)testRollbackDelete
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    IntObject *objectToDelete = [IntObject createInRealm:realm withValue:@[@0]];
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
    IntObject *objectToModify = [IntObject createInRealm:realm withValue:@[@0]];
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
    CircleObject *obj1 = [CircleObject createInRealm:realm withValue:@[@"1", NSNull.null]];
    CircleObject *obj2 = [CircleObject createInRealm:realm withValue:@[@"2", NSNull.null]];
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
    CircleObject *obj4 = [CircleObject createInRealm:realm withValue:@[@"4", NSNull.null]];
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
    IntObject *obj1 = [IntObject createInRealm:realm withValue:@[@0]];
    IntObject *obj2 = [IntObject createInRealm:realm withValue:@[@1]];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[obj1]]];
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
        [IntObject createInRealm:realm withValue:@[@0]];
        [realm cancelWriteTransaction];
    }];

    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
}

- (void)testRollbackTransactionWithoutExplicitCommitOrCancel
{
    @autoreleasepool {
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@0]];
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
    [realm cancelWriteTransaction];
}

- (void)testWriteCopyOfRealm
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withValue:@[@0]];
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
        [IntObject createInRealm:realm withValue:@[@0]];
    }];

    NSError *writeError;
    XCTAssertFalse([realm writeCopyToPath:RLMTestRealmPath() error:&writeError]);
    XCTAssertNotNil(writeError);
}

- (void)testWritingCopyUsesWriteTransactionInProgress
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withValue:@[@0]];

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
        [IntObject createInRealm:realm withValue:@[@1]];
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
        obj = [IntObject createInRealm:realm withValue:@[@0]];
    }];

    [realm invalidate];
    XCTAssertTrue(obj.isInvalidated);
    XCTAssertThrows([obj intCol]);
}

- (void)testInvalidateInvalidatesResults
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withValue:@[@1]];
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
        arrayObject = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[@[@1]]]];
    }];

    RLMArray *array = arrayObject.intArray;
    XCTAssertEqual(1U, array.count);

    [realm invalidate];
    XCTAssertThrows([array count]);
}

- (void)testInvalidateOnReadOnlyRealmIsError
{
    @autoreleasepool {
        // Create the file
        [self realmWithTestPath];
    }
    RLMRealm *realm = [self readOnlyRealmWithPath:RLMTestRealmPath() error:nil];
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
        [IntObject createInRealm:realm withValue:@[@1]];
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
            [IntObject createInDefaultRealmWithValue:@[@1]];
        }];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    XCTAssertTrue([realm refresh]);

    dispatch_group_async(group, queue, ^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@1]];
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

- (void)testInvalidLockFile
{
    // Create the realm file and lock file
    @autoreleasepool { [RLMRealm defaultRealm]; }

    int fd = open([RLMRealmConfiguration.defaultConfiguration.path stringByAppendingString:@".lock"].UTF8String, O_RDWR);
    XCTAssertNotEqual(-1, fd);

    // Change the value of the mutex size field in the shared info header
    uint8_t value = 255;
    pwrite(fd, &value, 1, 1);

    // Ensure that SharedGroup can't get an exclusive lock on the lock file so
    // that it can't just recreate it
    int ret = flock(fd, LOCK_SH);
    XCTAssertEqual(0, ret);

    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:RLMRealmConfiguration.defaultConfiguration error:&error];
    XCTAssertNil(realm);
    XCTAssertNotNil(error);
    XCTAssertEqual(RLMErrorIncompatibleLockFile, error.code);

    flock(fd, LOCK_UN);
    close(fd);
}

- (void)testCannotSetSchemaVersionWhenRealmIsOpen {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    RLMRealm *realm = [self realmWithTestPath];
    NSString *path = realm.path;

    XCTAssertThrows([RLMRealm setSchemaVersion:1 forRealmAtPath:path withMigrationBlock:nil]);
    XCTAssertNoThrow([RLMRealm setSchemaVersion:[RLMRealm schemaVersionAtPath:path error:nil] forRealmAtPath:path withMigrationBlock:nil]);
#pragma clang diagnostic pop
}

- (void)testCannotMigrateRealmWhenRealmIsOpen {
    RLMRealm *realm = [self realmWithTestPath];
    NSString *path = realm.path;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertThrows([RLMRealm migrateRealmAtPath:path]);
    XCTAssertThrows([RLMRealm migrateRealmAtPath:path encryptionKey:[[NSMutableData alloc] initWithLength:64]]);
#pragma clang diagnostic pop
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.path = path;
    XCTAssertThrows([RLMRealm migrateRealm:configuration]);
}

- (void)testNotificationPipeBufferOverfull {
    RLMRealm *realm = [self inMemoryRealmWithIdentifier:@"test"];
    // pipes have a 8 KB buffer on OS X, so verify we don't block after 8192 commits
    for (int i = 0; i < 9000; ++i) {
        [realm transactionWithBlock:^{}];
    }
}

- (void)testHoldRealmAfterSourceThreadIsDestroyed {
    __block RLMRealm *realm;

    // Using an NSThread to ensure the thread (and thus runloop) is actually destroyed
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runBlock:) object:^{
        realm = [RLMRealm defaultRealm];
    }];
    [thread start];
    while (!thread.isFinished)
        usleep(100);

    [realm path]; // ensure ARC releases the object after the thread has finished
}

- (void)testCompact
{
    RLMRealm *realm = self.realmWithTestPath;
    [realm transactionWithBlock:^{
        [StringObject createInRealm:realm withValue:@[@"A"]];
        [StringObject createInRealm:realm withValue:@[@"A"]];
    }];
    auto fileSize = ^(NSString *path) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];
    };
    unsigned long long fileSizeBefore = fileSize(realm.path);
    XCTAssertTrue([realm compact]);
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], 2U);
    unsigned long long fileSizeAfter = fileSize(realm.path);
    XCTAssertGreaterThan(fileSizeBefore, fileSizeAfter);
}

- (NSArray *)pathsFor100Realms
{
    NSMutableArray *paths = [NSMutableArray array];
    for (int i = 0; i < 100; ++i) {
        NSString *realmFileName = [NSString stringWithFormat:@"test.%d.realm", i];
        [paths addObject:RLMRealmPathForFile(realmFileName)];
    }
    return paths;
}

- (void)testCanCreate100RealmsWithoutBreakingGCD
{
    NSMutableArray *realms = [NSMutableArray array];
    for (NSString *realmPath in self.pathsFor100Realms) {
        [realms addObject:[RLMRealm realmWithPath:realmPath]];
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"Block dispatched to concurrent queue should be executed"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)runBlock:(void (^)())block {
    block();
}

@end
