////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import <XCTest/XCTest.h>

#import "RLMSyncTestCase.h"

#import "RLMTestUtils.h"

#define CHECK_PERMISSION_COUNT(ma_results, ma_count) {                                                                 \
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking permission count"];                            \
    __weak typeof(ma_results) weakResults = ma_results;                                                                \
    __attribute__((objc_precise_lifetime))id token = [ma_results addNotificationBlock:^(NSError *err) {                \
        XCTAssertNil(err);                                                                                             \
        if (weakResults.count == ma_count) {                                                                           \
            [ex fulfill];                                                                                              \
        }                                                                                                              \
    }];                                                                                                                \
    [self waitForExpectationsWithTimeout:2.0 handler:nil];                                                             \
}

#define CHECK_PERMISSION_PRESENT(ma_results, ma_permission) {                                                          \
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking permission presence"];                         \
    __weak typeof(ma_results) weakResults = ma_results;                                                                \
    __attribute__((objc_precise_lifetime)) id token = [ma_results addNotificationBlock:^(NSError *err) {               \
        XCTAssertNil(err);                                                                                             \
        for (NSInteger i=0; i<weakResults.count; i++) {                                                                \
            if ([[weakResults objectAtIndex:i] isEqual:ma_permission]) {                                               \
                [ex fulfill];                                                                                          \
                break;                                                                                                 \
            }                                                                                                          \
        }                                                                                                              \
    }];                                                                                                                \
    [self waitForExpectationsWithTimeout:10.0 handler:nil];                                                            \
}

/// Check whether a permission disappears or is absent from a results.
/// This macro is intended to be used to check that a permission is
/// immediately absent, or eventually disappears, from a results.
#define CHECK_PERMISSION_ABSENT(ma_results, ma_permission) {                                                           \
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking permission absence"];                          \
    __weak typeof(ma_results) weakResults = ma_results;                                                                \
    __attribute__((objc_precise_lifetime)) id token = [ma_results addNotificationBlock:^(NSError *err) {               \
        XCTAssertNil(err);                                                                                             \
        BOOL isPresent = NO;                                                                                           \
        for (NSInteger i=0; i<weakResults.count; i++) {                                                                \
            if ([[weakResults objectAtIndex:i] isEqual:ma_permission]) {                                               \
                isPresent = YES;                                                                                       \
                break;                                                                                                 \
            }                                                                                                          \
        }                                                                                                              \
        if (!isPresent) {                                                                                              \
            [ex fulfill];                                                                                              \
        }                                                                                                              \
    }];                                                                                                                \
    [self waitForExpectationsWithTimeout:10.0 handler:nil];                                                            \
}

#define GET_PERMISSION(ma_results, ma_permission, ma_destination) {                                                    \
    XCTestExpectation *ex = [self expectationWithDescription:@"Retrieving permission..."];                             \
    __block RLMSyncPermissionValue *value = nil;                                                                       \
    __weak typeof(ma_results) weakResults = ma_results;                                                                \
    __attribute__((objc_precise_lifetime)) id token = [ma_results addNotificationBlock:^(NSError *err) {               \
        XCTAssertNil(err);                                                                                             \
        for (NSInteger i=0; i<weakResults.count; i++) {                                                                \
            if ([[weakResults objectAtIndex:i] isEqual:ma_permission]) {                                               \
                value = [weakResults objectAtIndex:i];                                                                 \
                [ex fulfill];                                                                                          \
                return;                                                                                                \
            }                                                                                                          \
        }                                                                                                              \
    }];                                                                                                                \
    [self waitForExpectationsWithTimeout:10.0 handler:nil];                                                            \
    ma_destination = value;                                                                                            \
}

static NSURL *makeTestURL(NSString *name, RLMSyncUser *owner) {
    NSString *userID = [owner identity] ?: @"~";
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"realm://localhost:9080/%@/%@", userID, name]];
}

static RLMSyncPermissionValue *makeExpectedPermission(RLMSyncPermissionValue *original,
                                                      RLMSyncUser *owner,
                                                      NSString *realmName) {
    return [[RLMSyncPermissionValue alloc] initWithRealmPath:[NSString stringWithFormat:@"/%@/%@",
                                                              owner.identity,
                                                              realmName]
                                                      userID:original.userId
                                                 accessLevel:original.accessLevel];
}

@interface RLMPermissionsAPITests : RLMSyncTestCase

@property (nonatomic, strong) RLMSyncUser *userA;
@property (nonatomic, strong) RLMSyncUser *userB;
@property (nonatomic, strong) RLMSyncUser *userC;

@end

@implementation RLMPermissionsAPITests

- (void)setUp {
    [super setUp];
    NSString *accountNameBase = [[NSUUID UUID] UUIDString];
    NSString *userNameA = [accountNameBase stringByAppendingString:@"_A"];
    self.userA = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameA register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameB = [accountNameBase stringByAppendingString:@"_B"];
    self.userB = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameB register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameC = [accountNameBase stringByAppendingString:@"_C"];
    self.userC = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameC register:YES]
                                        server:[RLMSyncTestCase authServerURL]];
}

- (void)tearDown {
    [self.userA logOut];
    [self.userB logOut];
    [self.userC logOut];
    [super tearDown];
}

#pragma mark - Permissions

/// If user A grants user B read access to a Realm, user B should be able to read to it.
- (void)testReadAccess {
    __block void(^workBlock)(NSError *) = ^(NSError *err) {
        XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", err);
    };
    [[RLMSyncManager sharedManager] setErrorHandler:^(NSError *error, __unused RLMSyncSession *session) {
        if (workBlock) {
            workBlock(error);
        }
    }];

    NSString *testName = NSStringFromSelector(_cmd);
    // Open a Realm for user A.
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealm *userARealm = [self openRealmForURL:userAURL user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForUser:self.userA url:userAURL];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B read permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userAURL path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelRead];
    // Set the read permission.
    XCTestExpectation *ex = [self expectationWithDescription:@"Setting a permission should work."];
    [self.userA applyPermission:p callback:^(NSError *err) {
        XCTAssert(!err);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Open the same Realm for user B.
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealmConfiguration *userBConfig = [RLMRealmConfiguration defaultConfiguration];
    userBConfig.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:self.userB realmURL:userBURL];
    __block RLMRealm *userBRealm = nil;
    XCTestExpectation *asyncOpenEx = [self expectationWithDescription:@"Should asynchronously open a Realm"];
    [RLMRealm asyncOpenWithConfiguration:userBConfig
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *err){
                                    XCTAssertNil(err);
                                    XCTAssertNotNil(realm);
                                    userBRealm = realm;
                                    [asyncOpenEx fulfill];
    }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    CHECK_COUNT(3, SyncObject, userBRealm);


    // Ensure user B can't actually write to the Realm.
    // Run this portion of the test on a background queue, since the error handler is dispatched onto the main queue.
    XCTestExpectation *deniedEx = [self expectationWithDescription:@"Expect a permission denied error."];
    workBlock = ^(NSError *err) {
        // Expect an error from the global error handler.
        XCTAssertNotNil(err);
        XCTAssertEqual(err.code, RLMSyncErrorClientSessionError);
        // 206 is a permission error. TODO: don't hardcode the literal.
        XCTAssertEqual([err.userInfo[kRLMSyncErrorStatusCodeKey] integerValue], 206);
        [deniedEx fulfill];
    };
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    // TODO: if we can get the session itself we can check to see if it's been errored out (as expected).

    // Perhaps obviously, there should be no new objects.
    [self waitForDownloadsForUser:self.userA url:userAURL];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Administering the Realm should fail.
    RLMSyncPermissionValue *p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userBURL path]
                                                                            userID:self.userC.identity
                                                                       accessLevel:RLMSyncAccessLevelRead];
    XCTestExpectation *manageEx = [self expectationWithDescription:@"Managing a Realm you can't manage should fail."];
    [self.userB applyPermission:p2 callback:^(NSError *error) {
        XCTAssertNotNil(error);
        [manageEx fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// If user A grants user B write access to a Realm, user B should be able to write to it.
- (void)testWriteAccess {
    __block void(^workBlock)(NSError *) = ^(NSError *err) {
        XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", err);
    };
    [[RLMSyncManager sharedManager] setErrorHandler:^(NSError *error, __unused RLMSyncSession *session) {
        if (workBlock) {
            workBlock(error);
        }
    }];

    NSString *testName = NSStringFromSelector(_cmd);
    // Open a Realm for user A.
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealm *userARealm = [self openRealmForURL:userAURL user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForUser:self.userA url:userAURL];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B write permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userAURL path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelWrite];
    // Set the permission.
    XCTestExpectation *ex = [self expectationWithDescription:@"Setting a permission should work."];
    [self.userA applyPermission:p callback:^(NSError *err) {
        XCTAssert(!err);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Open the Realm for user B. Since user B has write privileges, they should be able to open it 'normally'.
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealm *userBRealm = [self openRealmForURL:userBURL user:self.userB];
    [self waitForDownloadsForUser:self.userB url:userBURL];
    CHECK_COUNT(3, SyncObject, userBRealm);

    // Add some objects using user B.
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForUser:self.userB url:userBURL];
    CHECK_COUNT(5, SyncObject, userBRealm);
    [self waitForUploadsForUser:self.userA url:userAURL];
    CHECK_COUNT(5, SyncObject, userARealm);

    // Administering the Realm should fail.
    RLMSyncPermissionValue *p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userBURL path]
                                                                            userID:self.userC.identity
                                                                       accessLevel:RLMSyncAccessLevelRead];
    XCTestExpectation *manageEx = [self expectationWithDescription:@"Managing a Realm you can't manage should fail."];
    [self.userB applyPermission:p2 callback:^(NSError *error) {
        XCTAssertNotNil(error);
        [manageEx fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// If user A grants user B manage access to a Realm, user B should be able to set a permission for user C.
- (void)testManageAccess {
    __block void(^workBlock)(NSError *) = ^(NSError *err) {
        XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", err);
    };
    [[RLMSyncManager sharedManager] setErrorHandler:^(NSError *error, __unused RLMSyncSession *session) {
        if (workBlock) {
            workBlock(error);
        }
    }];

    NSString *testName = NSStringFromSelector(_cmd);
    // Open a Realm for user A.
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealm *userARealm = [self openRealmForURL:userAURL user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForUser:self.userA url:userAURL];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B admin permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userAURL path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelAdmin];
    // Set the permission.
    XCTestExpectation *ex = [self expectationWithDescription:@"Setting a permission should work."];
    [self.userA applyPermission:p callback:^(NSError *err) {
        XCTAssert(!err);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Open the Realm for user B. Since user B has admin privileges, they should be able to open it 'normally'.
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealm *userBRealm = [self openRealmForURL:userBURL user:self.userB];
    [self waitForDownloadsForUser:self.userB url:userBURL];
    CHECK_COUNT(3, SyncObject, userBRealm);

    // Add some objects using user B.
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForUser:self.userB url:userBURL];
    CHECK_COUNT(5, SyncObject, userBRealm);
    [self waitForDownloadsForUser:self.userA url:userAURL];
    CHECK_COUNT(5, SyncObject, userARealm);

    // User B should be able to give user C write permissions to user A's Realm.
    RLMSyncPermissionValue *p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userBURL path]
                                                                            userID:self.userC.identity
                                                                       accessLevel:RLMSyncAccessLevelWrite];
    XCTestExpectation *manageEx = [self expectationWithDescription:@"Managing a Realm you can't manage should fail."];
    [self.userB applyPermission:p2 callback:^(NSError *error) {
        XCTAssertNil(error);
        [manageEx fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // User C should be able to write to the Realm.
    NSURL *userCURL = makeTestURL(testName, self.userC);
    RLMRealm *userCRealm = [self openRealmForURL:userCURL user:self.userC];
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-6", @"child-7", @"child-8"]];
    [self waitForUploadsForUser:self.userC url:userCURL];
    CHECK_COUNT(8, SyncObject, userBRealm);
    [self waitForDownloadsForUser:self.userA url:userAURL];
    CHECK_COUNT(8, SyncObject, userARealm);
    [self waitForDownloadsForUser:self.userB url:userBURL];
    CHECK_COUNT(8, SyncObject, userBRealm);
}

#pragma mark - Permission change API

/// Setting a permission should work, and then that permission should be able to be retrieved.
- (void)testSettingPermission {
    // First, there should be no permissions.
    XCTestExpectation *ex = [self expectationWithDescription:@"No permissions for newly created user."];
    __block RLMSyncPermissionResults *results;
    [self.userA retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    CHECK_PERMISSION_COUNT(results, 0);

    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Give user B read permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Setting a permission should work."];
    [self.userA applyPermission:p callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Now retrieve the permissions again and make sure the new permission is properly set.
    XCTestExpectation *ex3 = [self expectationWithDescription:@"One permission after setting the permission."];
    [self.userA retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    // Expected permission: applies to user B, but for user A's Realm.
    id expectedPermission = makeExpectedPermission(p, self.userA, NSStringFromSelector(_cmd));
    RLMSyncPermissionValue *final = nil;
    GET_PERMISSION(results, expectedPermission, final);
    XCTAssertNotNil(final, @"Did not find the permission %@", expectedPermission);

    // Check getting permission by its index.
    NSUInteger index = [results indexOfObject:expectedPermission];
    XCTAssertNotEqual(index, NSNotFound);
    XCTAssertEqualObjects(expectedPermission, [results objectAtIndex:index]);
}

/// Deleting a permission should work.
- (void)testDeletingPermission {
    __block RLMSyncPermissionResults *results;

    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Give user B read permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    XCTestExpectation *ex = [self expectationWithDescription:@"Setting a permission should work."];
    [self.userA applyPermission:p callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Now retrieve the permissions again and make sure the new permission is properly set.
    XCTestExpectation *ex2 = [self expectationWithDescription:@"One permission after setting the permission."];
    [self.userA retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    id expectedPermission = makeExpectedPermission(p, self.userA, NSStringFromSelector(_cmd));
    CHECK_PERMISSION_PRESENT(results, expectedPermission);

    // Delete the permission.
    XCTestExpectation *ex3 = [self expectationWithDescription:@"Deleting a permission should work."];
    [self.userA revokePermission:p callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Make sure the permission deletion is properly reflected.
    XCTestExpectation *ex4 = [self expectationWithDescription:@"No permissions after deleting the permission."];
    [self.userA retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex4 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    CHECK_PERMISSION_ABSENT(results, expectedPermission);
}


/// Observing permission changes should work.
- (void)testObservingPermission {
    // Get a reference to the permission results.
    XCTestExpectation *ex = [self expectationWithDescription:@"Get permission results."];
    __block RLMSyncPermissionResults *results = nil;
    [self.userA retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Register notifications.
    XCTestExpectation *noteEx = [self expectationWithDescription:@"Notification should fire."];
    RLMNotificationToken *token = [results addNotificationBlock:^(NSError *error) {
        XCTAssertNil(error);
        if (results.count > 0) {
            [noteEx fulfill];
        }
    }];

    // Give user B read permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Setting a permission should work."];
    [self.userA applyPermission:p callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex2 fulfill];
    }];
    [self waitForExpectations:@[ex2] timeout:2.0];

    // Wait for the notification to be fired.
    [self waitForExpectations:@[noteEx] timeout:2.0];
    [token stop];
    id expectedPermission = makeExpectedPermission(p, self.userA, NSStringFromSelector(_cmd));
    CHECK_PERMISSION_PRESENT(results, expectedPermission);
}

/// Filtering permissions results should work.
- (void)testFilteringPermissions {
    // Get a reference to the permission results.
    XCTestExpectation *ex = [self expectationWithDescription:@"Get permission results."];
    __block RLMSyncPermissionResults *results = nil;
    [self.userA retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Open two Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    NSString *uB = self.userB.identity;
    NSString *uC = self.userC.identity;

    // Give user B and C read permissions to r1, and user B read permissions for r2.
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Setting r1 permission for user B should work."];
    id p1 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url1 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    [self.userA applyPermission:p1 callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTestExpectation *ex3 = [self expectationWithDescription:@"Setting r1 permission for user C should work."];
    id p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url1 path] userID:uC accessLevel:RLMSyncAccessLevelRead];
    [self.userA applyPermission:p2 callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTestExpectation *ex4 = [self expectationWithDescription:@"Setting r2 permission for user B should work."];
    id p3 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url2 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    [self.userA applyPermission:p3 callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex4 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Wait for all the permissions to show up.
    id exp1 = makeExpectedPermission(p1, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r1"]);
    id exp2 = makeExpectedPermission(p2, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r1"]);
    id exp3 = makeExpectedPermission(p3, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r2"]);
    CHECK_PERMISSION_PRESENT(results, exp1);
    CHECK_PERMISSION_PRESENT(results, exp2);
    CHECK_PERMISSION_PRESENT(results, exp3);

    // Now make a filter.
    RLMSyncPermissionResults *filtered = [results objectsWithPredicate:[NSPredicate predicateWithFormat:@"userId == %@",
                                                                        self.userB.identity]];
    CHECK_PERMISSION_PRESENT(filtered, exp1);
    CHECK_PERMISSION_ABSENT(filtered, exp2);
    CHECK_PERMISSION_PRESENT(filtered, exp3);
}

- (void)testSortingPermissions {
    // Get a reference to the permission results.
    XCTestExpectation *ex = [self expectationWithDescription:@"Get permission results."];
    __block RLMSyncPermissionResults *results = nil;
    [self.userA retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Open three Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    NSURL *url3 = CUSTOM_REALM_URL(@"r3");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r3 = [self openRealmForURL:url3 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B read permissions for all three Realms.
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Setting r1 permission for user B should work."];
    id p1 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url1 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    [self.userA applyPermission:p1 callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTestExpectation *ex3 = [self expectationWithDescription:@"Setting r2 permission for user B should work."];
    id p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url2 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    [self.userA applyPermission:p2 callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTestExpectation *ex4 = [self expectationWithDescription:@"Setting r3 permission for user C should work."];
    id p3 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url3 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    [self.userA applyPermission:p3 callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex4 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Now sort on Realm URL.
    id exp1 = makeExpectedPermission(p1, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r1"]);
    id exp2 = makeExpectedPermission(p2, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r2"]);
    id exp3 = makeExpectedPermission(p3, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r3"]);
    RLMSyncPermissionResults *sorted = [results sortedResultsUsingProperty:RLMSyncPermissionResultsSortPropertyPath
                                                                 ascending:YES];
    RLMSyncPermissionValue *n1 = nil;
    RLMSyncPermissionValue *n2 = nil;
    RLMSyncPermissionValue *n3 = nil;
    GET_PERMISSION(sorted, exp1, n1);
    GET_PERMISSION(sorted, exp2, n2);
    GET_PERMISSION(sorted, exp3, n3);
    NSUInteger idx1 = [sorted indexOfObject:n1];
    NSUInteger idx2 = [sorted indexOfObject:n2];
    NSUInteger idx3 = [sorted indexOfObject:n3];
    // Make sure they are actually in ascending order.
    XCTAssertNotEqual(idx1, NSNotFound);
    XCTAssertNotEqual(idx2, NSNotFound);
    XCTAssertNotEqual(idx3, NSNotFound);
    XCTAssertLessThan(idx1, idx2);
    XCTAssertLessThan(idx2, idx3);
}

/// User should not be able to change a permission for a Realm they don't own.
- (void)testSettingUnownedRealmPermission {
    __block RLMSyncPermissionResults *results;

    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Try to have user B give user C permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url path]
                                                                           userID:self.userC.identity
                                                                      accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Setting an invalid permission should fail."];
    [self.userB applyPermission:p callback:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.domain, RLMSyncPermissionErrorDomain);
        XCTAssertEqual(error.code, RLMSyncPermissionErrorChangeFailed);
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Now retrieve the permissions again and make sure the new permission was not set.
    XCTestExpectation *ex3 = [self expectationWithDescription:@"Retrieving the results should work."];
    [self.userB retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    id expectedPermission = makeExpectedPermission(p, self.userA, NSStringFromSelector(_cmd));
    CHECK_PERMISSION_ABSENT(results, expectedPermission);
}

@end
