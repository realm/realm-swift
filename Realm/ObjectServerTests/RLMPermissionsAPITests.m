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

#define CHECK_PERMISSION_COUNT_PREDICATE(ma_results, ma_count, ma_op) {                                                \
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking permission count"];                            \
    __weak typeof(ma_results) weakResults = ma_results;                                                                \
    __attribute__((objc_precise_lifetime))id token = [ma_results addNotificationBlock:^(NSError *err) {                \
        XCTAssertNil(err);                                                                                             \
        if (weakResults.count ma_op ma_count) {                                                                        \
            [ex fulfill];                                                                                              \
        }                                                                                                              \
    }];                                                                                                                \
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *err) {                                                \
        if (err) {                                                                                                     \
            NSLog(@"Checking permission count failed!\nError: %@\nResults: %@\nResults count: %@",                     \
                  err, weakResults, @([weakResults count]));                                                           \
        }                                                                                                              \
    }];                                                                                                                \
}

#define CHECK_PERMISSION_COUNT(ma_results, ma_count) CHECK_PERMISSION_COUNT_PREDICATE(ma_results, ma_count, ==)

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

#define APPLY_PERMISSION(ma_permission, ma_user)                                                                       \
APPLY_PERMISSION_WITH_MESSAGE(ma_permission, ma_user, @"Setting a permission should work")

#define APPLY_PERMISSION_WITH_MESSAGE(ma_permission, ma_user, ma_message) {                                            \
    XCTestExpectation *ex = [self expectationWithDescription:ma_message];                                              \
    [ma_user applyPermission:ma_permission callback:^(NSError *err) {                                                  \
        XCTAssertNil(err, @"Received an error when applying permission: %@", err);                                     \
        [ex fulfill];                                                                                                  \
    }];                                                                                                                \
    [self waitForExpectationsWithTimeout:10.0 handler:nil];                                                            \
}                                                                                                                      \

static NSURL *makeTestURL(NSString *name, RLMSyncUser *owner) {
    NSString *userID = [owner identity] ?: @"~";
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"realm://localhost:9080/%@/%@", userID, name]];
}

static NSURL *makeTestGlobalURL(NSString *name) {
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"realm://localhost:9080/%@", name]];
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

@property (nonatomic, strong) NSString *currentUsernameBase;

@property (nonatomic, strong) RLMSyncUser *userA;
@property (nonatomic, strong) RLMSyncUser *userB;
@property (nonatomic, strong) RLMSyncUser *userC;

@end

@implementation RLMPermissionsAPITests

- (void)setUp {
    [super setUp];
    NSString *accountNameBase = [[NSUUID UUID] UUIDString];
    self.currentUsernameBase = accountNameBase;
    NSString *userNameA = [accountNameBase stringByAppendingString:@"_A@example.org"];
    self.userA = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameA register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameB = [accountNameBase stringByAppendingString:@"_B@example.org"];
    self.userB = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameB register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameC = [accountNameBase stringByAppendingString:@"_C@example.org"];
    self.userC = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameC register:YES]
                                        server:[RLMSyncTestCase authServerURL]];
}

- (void)tearDown {
    self.currentUsernameBase = nil;
    [self.userA logOut];
    [self.userB logOut];
    [self.userC logOut];
    [super tearDown];
}

#pragma mark - Helper methods

- (RLMSyncPermissionResults *)getPermissionResultsFor:(RLMSyncUser *)user {
    return [self getPermissionResultsFor:user message:@"Get permission results"];
}

- (RLMSyncPermissionResults *)getPermissionResultsFor:(RLMSyncUser *)user message:(NSString *)message {
    // Get a reference to the permission results.
    XCTestExpectation *ex = [self expectationWithDescription:message];
    __block RLMSyncPermissionResults *results = nil;
    [user retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(results, @"getPermissionResultsFor: failed for user %@. No results.", user.identity);
    return results;
}

#pragma mark - Permissions

/// If user A grants user B read access to a Realm, user B should be able to read to it.
- (void)testReadAccess {
    __block void(^errorBlock)(NSError *) = nil;
    [[RLMSyncManager sharedManager] setErrorHandler:^(NSError *error, __unused RLMSyncSession *session) {
        if (errorBlock) {
            errorBlock(error);
            errorBlock = nil;
        } else {
            XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", error);
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
    APPLY_PERMISSION(p, self.userA);

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
    errorBlock = ^(NSError *err) {
        // Expect an error from the global error handler.
        XCTAssertNotNil(err);
        XCTAssertEqual(err.code, RLMSyncErrorPermissionDeniedError);
        [deniedEx fulfill];
    };
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5", @"child-6"]];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    // TODO: if we can get the session itself we can check to see if it's been errored out (as expected).

    // Perhaps obviously, there should be no new objects.
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userARealm);

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
    __block void(^errorBlock)(NSError *) = nil;
    [[RLMSyncManager sharedManager] setErrorHandler:^(NSError *error, __unused RLMSyncSession *session) {
        if (errorBlock) {
            errorBlock(error);
            errorBlock = nil;
        } else {
            XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", error);
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
    APPLY_PERMISSION(p, self.userA);

    // Open the Realm for user B. Since user B has write privileges, they should be able to open it 'normally'.
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealm *userBRealm = [self openRealmForURL:userBURL user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);

    // Add some objects using user B.
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForUser:self.userB url:userBURL];
    CHECK_COUNT(5, SyncObject, userBRealm);
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userARealm);

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
    __block void(^errorBlock)(NSError *) = nil;
    [[RLMSyncManager sharedManager] setErrorHandler:^(NSError *error, __unused RLMSyncSession *session) {
        if (errorBlock) {
            errorBlock(error);
            errorBlock = nil;
        } else {
            XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", error);
        }
    }];

    NSString *testName = NSStringFromSelector(_cmd);
    // Unresolved URL: ~/testManageAccess
    NSURL *userAURLUnresolved = makeTestURL(testName, nil);
    // Resolved URL: <User A ID>/testManageAccess
    NSURL *userAURLResolved = makeTestURL(testName, self.userA);

    // Open a Realm for user A.
    RLMRealm *userARealm = [self openRealmForURL:userAURLUnresolved user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForUser:self.userA url:userAURLUnresolved];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B admin permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userAURLUnresolved path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelAdmin];
    // Set the permission.
    APPLY_PERMISSION(p, self.userA);

    // Open the Realm for user B. Since user B has admin privileges, they should be able to open it 'normally'.
    RLMRealm *userBRealm = [self openRealmForURL:userAURLResolved user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);

    // Add some objects using user B.
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForUser:self.userB url:userAURLResolved];
    CHECK_COUNT(5, SyncObject, userBRealm);
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userARealm);

    // User B should be able to give user C write permissions to user A's Realm.
    RLMSyncPermissionValue *p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userAURLResolved path]
                                                                            userID:self.userC.identity
                                                                       accessLevel:RLMSyncAccessLevelWrite];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userB, @"User B should be able to give C write permissions to A's Realm.");

    // User C should be able to write to the Realm.
    RLMRealm *userCRealm = [self openRealmForURL:userAURLResolved user:self.userC];
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userCRealm);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-6", @"child-7", @"child-8"]];
    [self waitForUploadsForUser:self.userC url:userAURLResolved];
    CHECK_COUNT(8, SyncObject, userCRealm);
    CHECK_COUNT_PENDING_DOWNLOAD(8, SyncObject, userARealm);
    CHECK_COUNT_PENDING_DOWNLOAD(8, SyncObject, userBRealm);
}

/// If user A grants user B write access to a Realm via username, user B should be able to write to it.
- (void)testWriteAccessViaUsername {
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

    // Give user B write permissions to that Realm via user B's username.
    NSString *userBUsername = [NSString stringWithFormat:@"%@_B@example.org", self.currentUsernameBase];
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[userAURL path]
                                                                         username:userBUsername
                                                                      accessLevel:RLMSyncAccessLevelWrite];
    // Set the permission.
    APPLY_PERMISSION(p, self.userA);

    // Open the Realm for user B. Since user B has write privileges, they should be able to open it 'normally'.
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealm *userBRealm = [self openRealmForURL:userBURL user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);

    // Add some objects using user B.
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForUser:self.userB url:userBURL];
    CHECK_COUNT(5, SyncObject, userBRealm);
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userARealm);
}

/// Setting a permission for all users should work.
- (void)testWildcardWriteAccess {
    // Open a Realm for user A.
    NSString *testName = NSStringFromSelector(_cmd);
    NSURL *ownerURL = makeTestURL(testName, nil);
    NSURL *guestURL = makeTestURL(testName, self.userA);
    RLMRealm *userARealm = [self openRealmForURL:ownerURL user:self.userA];

    // Give all users write permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[ownerURL path]
                                                                           userID:@"*"
                                                                      accessLevel:RLMSyncAccessLevelWrite];

    // Set the permission.
    APPLY_PERMISSION(p, self.userA);

    // Have user A write a few objects first.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForUser:self.userA url:ownerURL];
    CHECK_COUNT(3, SyncObject, userARealm);

    // User B should be able to write to the Realm.
    RLMRealm *userBRealm = [self openRealmForURL:guestURL user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForUser:self.userB url:guestURL];
    CHECK_COUNT(5, SyncObject, userBRealm);

    // User C should be able to write to the Realm.
    RLMRealm *userCRealm = [self openRealmForURL:guestURL user:self.userC];
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userCRealm);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-6", @"child-7", @"child-8", @"child-9"]];
    [self waitForUploadsForUser:self.userC url:guestURL];
    CHECK_COUNT(9, SyncObject, userCRealm);
}

/// It should be possible to grant read-only access to a global Realm.
- (void)testWildcardGlobalRealmReadAccess {
    RLMSyncUser *admin = [self makeAdminUser:[[NSUUID UUID] UUIDString]
                                    password:@"password"
                                      server:[RLMSyncTestCase authServerURL]];

    // Open a Realm for the admin user.
    NSString *testName = NSStringFromSelector(_cmd);
    NSURL *globalRealmURL = makeTestGlobalURL(testName);
    RLMRealm *adminUserRealm = [self openRealmForURL:globalRealmURL user:admin];

    // Give all users read permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[globalRealmURL path]
                                                                           userID:@"*"
                                                                      accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    APPLY_PERMISSION_WITH_MESSAGE(p, admin, @"Setting wildcard permission should work.");

    // Have the admin user write a few objects first.
    [self addSyncObjectsToRealm:adminUserRealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForUser:admin url:globalRealmURL];
    CHECK_COUNT(3, SyncObject, adminUserRealm);

    // User B should be able to read from the Realm.
    __block RLMRealm *userBRealm = nil;
    RLMRealmConfiguration *userBConfig = [RLMRealmConfiguration defaultConfiguration];
    userBConfig.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:self.userB realmURL:globalRealmURL];
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

    // User C should be able to read from the Realm.
    __block RLMRealm *userCRealm = nil;
    RLMRealmConfiguration *userCConfig = [RLMRealmConfiguration defaultConfiguration];
    userCConfig.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:self.userC realmURL:globalRealmURL];
    XCTestExpectation *asyncOpenEx2 = [self expectationWithDescription:@"Should asynchronously open a Realm"];
    [RLMRealm asyncOpenWithConfiguration:userCConfig
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *err){
                                    XCTAssertNil(err);
                                    XCTAssertNotNil(realm);
                                    userCRealm = realm;
                                    [asyncOpenEx2 fulfill];
                                }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    CHECK_COUNT(3, SyncObject, userCRealm);
}

/// Setting a permission for all users on a global Realm (no `~`) should work.
- (void)testWildcardGlobalRealmWriteAccess {
    RLMSyncUser *admin = [self makeAdminUser:[[NSUUID UUID] UUIDString]
                                    password:@"password"
                                      server:[RLMSyncTestCase authServerURL]];

    // Open a Realm for the admin user.
    NSString *testName = NSStringFromSelector(_cmd);
    NSURL *globalRealmURL = makeTestGlobalURL(testName);
    RLMRealm *adminUserRealm = [self openRealmForURL:globalRealmURL user:admin];

    // Give all users write permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[globalRealmURL path]
                                                                           userID:@"*"
                                                                      accessLevel:RLMSyncAccessLevelWrite];

    // Set the permission.
    APPLY_PERMISSION(p, admin);

    // Have the admin user write a few objects first.
    [self addSyncObjectsToRealm:adminUserRealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForUser:admin url:globalRealmURL];
    CHECK_COUNT(3, SyncObject, adminUserRealm);

    // User B should be able to write to the Realm.
    RLMRealm *userBRealm = [self openRealmForURL:globalRealmURL user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForUser:self.userB url:globalRealmURL];
    CHECK_COUNT(5, SyncObject, userBRealm);

    // User C should be able to write to the Realm.
    RLMRealm *userCRealm = [self openRealmForURL:globalRealmURL user:self.userC];
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userCRealm);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-6", @"child-7", @"child-8", @"child-9"]];
    [self waitForUploadsForUser:self.userC url:globalRealmURL];
    CHECK_COUNT(9, SyncObject, userCRealm);
}

#pragma mark - Permission change API

/// Setting a permission should work, and then that permission should be able to be retrieved.
- (void)testSettingPermission {
    // First, there should be no permissions.
    RLMSyncPermissionResults *results = [self getPermissionResultsFor:self.userA];
    CHECK_PERMISSION_COUNT(results, 0);

    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Give user B read permissions to that Realm.
    RLMSyncPermissionValue *p = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url path]
                                                                           userID:self.userB.identity
                                                                      accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    APPLY_PERMISSION(p, self.userA);

    // Now retrieve the permissions again and make sure the new permission is properly set.
    results = [self getPermissionResultsFor:self.userA message:@"One permission after setting the permission."];

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
    APPLY_PERMISSION(p, self.userA);

    // Now retrieve the permissions again and make sure the new permission is properly set.
    results = [self getPermissionResultsFor:self.userA message:@"One permission after setting the permission."];
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
    results = [self getPermissionResultsFor:self.userA message:@"No permissions after deleting the permission."];
    CHECK_PERMISSION_ABSENT(results, expectedPermission);
}


/// Observing permission changes should work.
- (void)testObservingPermission {
    // Get a reference to the permission results.
    RLMSyncPermissionResults *results = [self getPermissionResultsFor:self.userA];

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
    APPLY_PERMISSION(p, self.userA);

    // Wait for the notification to be fired.
    [self waitForExpectations:@[noteEx] timeout:2.0];
    [token stop];
    id expectedPermission = makeExpectedPermission(p, self.userA, NSStringFromSelector(_cmd));
    CHECK_PERMISSION_PRESENT(results, expectedPermission);
}

/// Filtering permissions results should work.
- (void)testFilteringPermissions {
    // Get a reference to the permission results.
    RLMSyncPermissionResults *results = [self getPermissionResultsFor:self.userA];

    // Open two Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    NSString *uB = self.userB.identity;
    NSString *uC = self.userC.identity;

    // Give user B and C read permissions to r1, and user B read permissions for r2.
    id p1 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url1 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r1 permission for user B should work.");
    id p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url1 path] userID:uC accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r1 permission for user C should work.");
    id p3 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url2 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p3, self.userA, @"Setting r2 permission for user B should work.");

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

- (void)testSortingPermissionsOnPath {
    // Get a reference to the permission results.
    RLMSyncPermissionResults *results = [self getPermissionResultsFor:self.userA];

    // Open three Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    NSURL *url3 = CUSTOM_REALM_URL(@"r3");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r3 = [self openRealmForURL:url3 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B read permissions for all three Realms.
    id p1 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url1 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r1 permission for user B should work.");
    id p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url2 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r2 permission for user B should work.");
    id p3 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url3 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p3, self.userA, @"Setting r3 permission for user B should work.");

    // Now sort on Realm URL.
    id exp1 = makeExpectedPermission(p1, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r1"]);
    id exp2 = makeExpectedPermission(p2, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r2"]);
    id exp3 = makeExpectedPermission(p3, self.userA,
                                     [NSString stringWithFormat:@"%@%@", NSStringFromSelector(_cmd), @"r3"]);
    RLMSyncPermissionResults *filtered = [results objectsWithPredicate:[NSPredicate predicateWithFormat:@"userId == %@",
                                                                        uB]];
    RLMSyncPermissionResults *sorted = [filtered sortedResultsUsingProperty:RLMSyncPermissionResultsSortPropertyPath
                                                                  ascending:YES];
    // Wait for changes to propagate
    CHECK_PERMISSION_COUNT(sorted, 3);

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

- (void)testSortingPermissionsOnUserId {
    // Get a reference to the permission results.
    RLMSyncPermissionResults *results = [self getPermissionResultsFor:self.userA];

    // Open a Realm
    NSURL *url = REALM_URL();
    __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForURL:url user:self.userA];
    NSString *uB = self.userB.identity;
    NSString *uC = self.userC.identity;

    // Give users B and C read permission for the Realm.
    id p1 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r1 permission for user B should work.");
    id p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url path] userID:uC accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r1 permission for user C should work.");

    // Now sort on user ID.
    RLMSyncPermissionResults *sorted = [results sortedResultsUsingProperty:RLMSyncPermissionResultsSortPropertyUserID
                                                                 ascending:YES];

    // Wait for changes to propagate, then check them.
    BOOL seenUserBPermission = NO;
    BOOL seenUserCPermission = NO;
    CHECK_PERMISSION_COUNT_PREDICATE(sorted, 3, >=);
    for (int i=0; i<sorted.count - 1; i++) {
        NSString *thisID = [sorted objectAtIndex:i].userId;
        NSString *nextID = [sorted objectAtIndex:i + 1].userId;
        seenUserBPermission |= ([thisID isEqualToString:uB] || [nextID isEqualToString:uB]);
        seenUserCPermission |= ([thisID isEqualToString:uC] || [nextID isEqualToString:uC]);
        // Make sure permissions are in ascending order.
        NSComparisonResult result = [thisID compare:nextID];
        XCTAssertTrue(result == NSOrderedAscending || result == NSOrderedSame);
    }
    XCTAssertTrue(seenUserBPermission);
    XCTAssertTrue(seenUserCPermission);
}

- (void)testSortingPermissionsOnDate {
    // Get a reference to the permission results.
    RLMSyncPermissionResults *results = [self getPermissionResultsFor:self.userA];

    // Open three Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"-r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"-r2");
    NSURL *url3 = CUSTOM_REALM_URL(@"-r3");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r3 = [self openRealmForURL:url3 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B read permissions for all three Realms.
    id p1 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url3 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r3 permission for user B should work.");
    id p2 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url1 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r1 permission for user B should work.");
    id p3 = [[RLMSyncPermissionValue alloc] initWithRealmPath:[url2 path] userID:uB accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p3, self.userA, @"Setting r2 permission for user B should work.");

    // Now sort on date. (Note that we only want the results for the user B permissions.)
    RLMSyncPermissionResults *filtered = [results objectsWithPredicate:[NSPredicate predicateWithFormat:@"userId == %@",
                                                                        uB]];
    RLMSyncPermissionResults *sorted = [filtered sortedResultsUsingProperty:RLMSyncPermissionResultsSortDateUpdated
                                                                  ascending:YES];

    // Wait for changes to propagate
    CHECK_PERMISSION_COUNT(sorted, 3);
    RLMSyncPermissionValue *n1 = [sorted objectAtIndex:0];
    RLMSyncPermissionValue *n2 = [sorted objectAtIndex:1];
    RLMSyncPermissionValue *n3 = [sorted objectAtIndex:2];

    XCTAssertTrue([n1.path containsString:@"r3"]);
    XCTAssertTrue([n2.path containsString:@"r1"]);
    XCTAssertTrue([n3.path containsString:@"r2"]);

    // Make sure they are actually in ascending order.
    XCTAssertLessThan([n1.updatedAt timeIntervalSinceReferenceDate], [n2.updatedAt timeIntervalSinceReferenceDate]);
    XCTAssertLessThan([n2.updatedAt timeIntervalSinceReferenceDate], [n3.updatedAt timeIntervalSinceReferenceDate]);
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
    results = [self getPermissionResultsFor:self.userB message:@"Retrieving the results should work."];
    id expectedPermission = makeExpectedPermission(p, self.userA, NSStringFromSelector(_cmd));
    CHECK_PERMISSION_ABSENT(results, expectedPermission);
}

#pragma mark - Delete Realm upon permission denied

/// A Realm which is opened improperly should report an error allowing the app to recover.
- (void)testDeleteRealmUponPermissionDenied {
    __block void(^errorBlock)(NSError *, RLMSyncSession *session) = nil;
    [[RLMSyncManager sharedManager] setErrorHandler:^(NSError *error, RLMSyncSession *session) {
        if (errorBlock) {
            errorBlock(error, session);
            errorBlock = nil;
        } else {
            XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", error);
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
    APPLY_PERMISSION(p, self.userA);

    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealmConfiguration *userBConfig = [RLMRealmConfiguration defaultConfiguration];
    userBConfig.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:self.userB realmURL:userBURL];
    __block NSError *theError = nil;

    // Incorrectly open the Realm for user B.
    NSURL *onDiskPath;
    @autoreleasepool {
        NSString *sessionName = NSStringFromSelector(_cmd);
        XCTestExpectation *ex2 = [self expectationWithDescription:@"We should get a permission denied error."];
        errorBlock = ^(NSError *err, RLMSyncSession *session) {
            // Make sure we're actually looking at the right session.
            XCTAssertTrue([[session.realmURL absoluteString] containsString:sessionName]);
            theError = err;
            [ex2 fulfill];
        };
        __attribute__((objc_precise_lifetime)) RLMRealm *bad = [RLMRealm realmWithConfiguration:userBConfig error:nil];
        [self waitForExpectationsWithTimeout:10.0 handler:nil];
        onDiskPath = [RLMSyncTestCase onDiskPathForSyncedRealm:bad];
    }
    XCTAssertNotNil(onDiskPath);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[onDiskPath path]]);

    // Check the error and perform the Realm deletion.
    XCTAssertNotNil(theError);
    XCTAssertNotNil([theError rlmSync_deleteRealmBlock]);
    [theError rlmSync_deleteRealmBlock]();

    // Ensure the file is no longer on disk.
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[onDiskPath path]]);

    // Correctly open the same Realm for user B.
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
}

@end
