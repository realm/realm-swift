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

// FIXME: Many permission tests appears to fail with the ROS 3.0.0 alpha releases.

#import "RLMSyncTestCase.h"

#import "RLMTestUtils.h"

#define APPLY_PERMISSION(ma_permission, ma_user) \
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
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"realm://127.0.0.1:9080/%@/%@", userID, name]];
}

static NSURL *makeTestGlobalURL(NSString *name) {
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"realm://127.0.0.1:9080/%@", name]];
}

static NSURL *makeTildeSubstitutedURL(NSURL *url, RLMSyncUser *user) {
    return [NSURL URLWithString:[[url absoluteString] stringByReplacingOccurrencesOfString:@"~" withString:user.identity]];
}

@interface RLMPermissionsAPITests : RLMSyncTestCase

@property (nonatomic, strong) NSString *currentUsernameBase;

@property (nonatomic, strong) RLMSyncUser *userA;
@property (nonatomic, strong) RLMSyncUser *userB;
@property (nonatomic, strong) RLMSyncUser *userC;

@property (nonatomic, strong) NSString *userBUsername;

@end

@implementation RLMPermissionsAPITests

- (void)setUp {
    [super setUp];
    NSString *accountNameBase = [[NSUUID UUID] UUIDString];
    self.currentUsernameBase = accountNameBase;
    NSString *userNameA = [accountNameBase stringByAppendingString:@"a"];
    self.userA = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameA register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameB = [accountNameBase stringByAppendingString:@"b"];
    self.userBUsername = userNameB;
    self.userB = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameB register:YES]
                                        server:[RLMSyncTestCase authServerURL]];

    NSString *userNameC = [accountNameBase stringByAppendingString:@"c"];
    self.userC = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:userNameC register:YES]
                                        server:[RLMSyncTestCase authServerURL]];
}

- (void)tearDown {
    self.currentUsernameBase = nil;
    [self.userA logOut];
    [self.userB logOut];
    [self.userC logOut];
    self.userBUsername = nil;
    [super tearDown];
}

#pragma mark - Permission validation methods

// This macro is only used for the validation methods below.
#define RECORD_FAILURE(ma_msg) [self recordFailureWithDescription:ma_msg inFile:file atLine:line expected:YES]

#define CHECK_PERMISSION_PRESENT(ma_results, ma_permission) \
    [self checkPresenceOfPermission:ma_permission inResults:ma_results line:__LINE__ file:@(__FILE__)]

/// Check that the targeted permission is present in, or eventually appears in the results.
- (void)checkPresenceOfPermission:(RLMSyncPermission *)permission
                        inResults:(RLMResults<RLMSyncPermission *> *)results
                             line:(NSUInteger)line
                             file:(NSString *)file {
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking presence of permission..."];
    RLMNotificationToken *token = [results addNotificationBlock:^(RLMResults *r, __unused id c, NSError *err) {
        if (err) {
            RECORD_FAILURE(@"Failed to retrieve permissions.");
            [ex fulfill];
            return;
        }
        if ([r indexOfObject:permission] != NSNotFound) {
            [ex fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timed out. The final state of the permissions is %@; the desired permission was %@",
                  results, permission);
        }
    }];
    [token invalidate];
}

#define CHECK_PERMISSION_ABSENT(ma_results, ma_permission) \
    [self checkAbsenceOfPermission:ma_permission inResults:ma_results line:__LINE__ file:@(__FILE__)]

/// Check that the targeted permission is absent from, or eventually disappears from the results.
- (void)checkAbsenceOfPermission:(RLMSyncPermission *)permission
                        inResults:(RLMResults<RLMSyncPermission *> *)results
                             line:(NSUInteger)line
                             file:(NSString *)file {
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking absence of permission..."];
    RLMNotificationToken *token = [results addNotificationBlock:^(RLMResults *r, __unused id c, NSError *err) {
        if (err) {
            RECORD_FAILURE(@"Failed to retrieve permissions.");
            [ex fulfill];
            return;
        }
        if ([r indexOfObject:permission] == NSNotFound) {
            [ex fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timed out. The final state of the permissions is %@; the permission to check for %@",
                  results, permission);
        }
    }];
    [token invalidate];
}

#define CHECK_PERMISSION_COUNT_AT_LEAST(ma_results, ma_count) \
    [self checkPermissionCountOfResults:ma_results atLeast:ma_count exact:NO line:__LINE__ file:@(__FILE__)];

#define CHECK_PERMISSION_COUNT(ma_results, ma_count) \
    [self checkPermissionCountOfResults:ma_results atLeast:ma_count exact:YES line:__LINE__ file:@(__FILE__)];

- (void)checkPermissionCountOfResults:(RLMResults<RLMSyncPermission *> *)results
                              atLeast:(NSInteger)count
                                exact:(BOOL)exact
                                 line:(NSUInteger)line
                                 file:(NSString *)file {
    // Check first.
    if ((NSInteger)results.count == count || (!exact && (NSInteger)results.count > count)) {
        return;
    }
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking presence of permission..."];
    RLMNotificationToken *token = [results addNotificationBlock:^(RLMResults *r, __unused id c, NSError *err) {
        if (err) {
            RECORD_FAILURE(@"Failed to retrieve permissions.");
            [ex fulfill];
            return;
        }
        NSInteger actualCount = (NSInteger)r.count;
        if (actualCount == count || (!exact && actualCount > count)) {
            [ex fulfill];
            return;
        }
    }];
    [self waitForExpectations:@[ex] timeout:20.0];
    [token invalidate];
}

#undef RECORD_FAILURE

#pragma mark - Helper methods

- (RLMResults<RLMSyncPermission *> *)getPermissionResultsFor:(RLMSyncUser *)user {
    return [self getPermissionResultsFor:user message:@"Get permission results"];
}

- (RLMResults<RLMSyncPermission *> *)getPermissionResultsFor:(RLMSyncUser *)user message:(NSString *)message {
    // Get a reference to the permission results.
    XCTestExpectation *ex = [self expectationWithDescription:message];
    __block RLMResults<RLMSyncPermission *> *results = nil;
    [user retrievePermissionsWithCallback:^(RLMResults<RLMSyncPermission *> *r, NSError *error) {
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

// FIXME ROS 2.0: works when ROS is manually provided, not when ROS is run as part of tests
/// If user A grants user B read access to a Realm, user B should be able to read from it.
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
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[userAURL path]
                                                               identity:self.userB.identity
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
    [self waitForExpectations:@[deniedEx] timeout:20.0];

    // TODO: if we can get the session itself we can check to see if it's been errored out (as expected).

    // Perhaps obviously, there should be no new objects.
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userARealm);

    // Administering the Realm should fail.
    RLMSyncPermission *p2 = [[RLMSyncPermission alloc] initWithRealmPath:[userBURL path]
                                                                identity:self.userC.identity
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
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[userAURL path]
                                                               identity:self.userB.identity
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
    RLMSyncPermission *p2 = [[RLMSyncPermission alloc] initWithRealmPath:[userBURL path]
                                                                identity:self.userC.identity
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
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[userAURLUnresolved path]
                                                               identity:self.userB.identity
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
    RLMSyncPermission *p2 = [[RLMSyncPermission alloc] initWithRealmPath:[userAURLResolved path]
                                                                identity:self.userC.identity
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
    NSString *userAFullPath = [makeTildeSubstitutedURL(userAURL, self.userA) path];
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:userAFullPath
                                                               username:self.userBUsername
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
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[ownerURL path]
                                                               identity:@"*"
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
    RLMSyncUser *admin = [self createAdminUserForURL:[RLMSyncTestCase authServerURL]
                                            username:[[NSUUID UUID] UUIDString]];

    // Open a Realm for the admin user.
    NSString *testName = NSStringFromSelector(_cmd);
    NSURL *globalRealmURL = makeTestGlobalURL(testName);
    RLMRealm *adminUserRealm = [self openRealmForURL:globalRealmURL user:admin];

    // Give all users read permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[globalRealmURL path]
                                                               identity:@"*"
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
    RLMSyncUser *admin = [self createAdminUserForURL:[RLMSyncTestCase authServerURL]
                                            username:[[NSUUID UUID] UUIDString]];

    // Open a Realm for the admin user.
    NSString *testName = NSStringFromSelector(_cmd);
    NSURL *globalRealmURL = makeTestGlobalURL(testName);
    RLMRealm *adminUserRealm = [self openRealmForURL:globalRealmURL user:admin];

    // Give all users write permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[globalRealmURL path]
                                                               identity:@"*"
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
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userA];
    CHECK_PERMISSION_COUNT(results, 0);

    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Give user B read permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                               identity:self.userB.identity
                                                            accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    APPLY_PERMISSION(p, self.userA);
    
    // Now retrieve the permissions again and make sure the new permission is properly set.
    results = [self getPermissionResultsFor:self.userB message:@"One permission after setting the permission."];

    // Expected permission: applies to user B, but for user A's Realm.
    CHECK_PERMISSION_PRESENT(results, p);

    // Check getting permission by its index.
    NSUInteger index = [results indexOfObject:p];
    XCTAssertNotEqual(index, NSNotFound);
    XCTAssertEqualObjects(p, [results objectAtIndex:index]);
}

/// Deleting a permission should work.
- (void)testDeletingPermission {
    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Give user B read permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                               identity:self.userB.identity
                                                            accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    APPLY_PERMISSION(p, self.userA);

    // Now retrieve the permissions again and make sure the new permission is properly set.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB
                                                                     message:@"Setting new permission."];
    CHECK_PERMISSION_PRESENT(results, p);

    // Delete the permission.
    XCTestExpectation *ex3 = [self expectationWithDescription:@"Deleting a permission should work."];
    [self.userA revokePermission:p callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Make sure the permission deletion is properly reflected.
    CHECK_PERMISSION_COUNT(results, 0);
}

/// Observing permission changes should work.
- (void)testObservingPermission {
    // Get a reference to the permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];

    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Register notifications.
    XCTestExpectation *noteEx = [self expectationWithDescription:@"Notification should fire."];
    RLMNotificationToken *token = [results addNotificationBlock:^(__unused id r, __unused id c, NSError *error) {
        XCTAssertNil(error);
        if (results.count > 0) {
            [noteEx fulfill];
        }
    }];

    // Give user B read permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                               identity:self.userB.identity
                                                            accessLevel:RLMSyncAccessLevelRead];

    // Set the permission.
    APPLY_PERMISSION(p, self.userA);

    // Wait for the notification to be fired.
    [self waitForExpectations:@[noteEx] timeout:2.0];
    [token invalidate];
    CHECK_PERMISSION_PRESENT(results, p);
}

/// KVC getting and setting should work properly for `RLMResults<RLMSyncPermission>`.
- (void)testKVCWithPermissionsResults {
    // Get a reference to the permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];

    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B read permissions to r1 and r2.
    NSString *path1 = [makeTildeSubstitutedURL(url1, self.userA) path];
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:path1
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r1 permission for user B should work.");
    NSString *path2 = [makeTildeSubstitutedURL(url2, self.userA) path];
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:path2
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r2 permission for user B should work.");

    // Wait for all the permissions to show up.
    CHECK_PERMISSION_PRESENT(results, p1);
    CHECK_PERMISSION_PRESENT(results, p2);

    // Now use `valueForKey`
    NSArray *selfValues = [results valueForKey:@"self"];
    XCTAssert(selfValues.count == results.count);
    for (id object in selfValues) {
        XCTAssert([object isKindOfClass:[RLMSyncPermission class]]);
    }

    NSArray *identityValues = [results valueForKey:@"path"];
    XCTAssert(identityValues.count == results.count);
    XCTAssert([identityValues containsObject:path1]);
    XCTAssert([identityValues containsObject:path2]);

    // Since `RLMSyncPermission`s are read-only, KVC setting should fail.
    RLMAssertThrows([results setValue:@"foobar" forKey:@"path"]);
}

/// Filtering permissions results should work.
- (void)testFilteringPermissions {
    // Get a reference to the permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];

    // Open two Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    NSURL *url3 = CUSTOM_REALM_URL(@"r3");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r3 = [self openRealmForURL:url3 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B permissions to realms r1, r2, and r3.
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url1, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r1 permission for user B should work.");
    NSString *finalPath = [makeTildeSubstitutedURL(url2, self.userA) path];
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:finalPath
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r2 permission for user B should work.");
    id p3 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url3, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p3, self.userA, @"Setting r3 permission for user B should work.");

    // Wait for all the permissions to show up.
    CHECK_PERMISSION_PRESENT(results, p1);
    CHECK_PERMISSION_PRESENT(results, p2);
    CHECK_PERMISSION_PRESENT(results, p3);

    // Now make a filter.
    RLMResults<RLMSyncPermission *> *filtered = [results objectsWithPredicate:[NSPredicate predicateWithFormat:@"%K == %@",
                                                                               RLMSyncPermissionSortPropertyPath,
                                                                               finalPath]];
    CHECK_PERMISSION_ABSENT(filtered, p1);
    CHECK_PERMISSION_PRESENT(filtered, p2);
    CHECK_PERMISSION_ABSENT(filtered, p3);
}

- (void)testSortingPermissionsOnUserID {
    // Get a reference to my own permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userA];

    // Open my Realm.
    NSURL *url = REALM_URL();
    __attribute__((objc_precise_lifetime)) RLMRealm *r = [self openRealmForURL:url user:self.userA];

    // Give users B and C access to my Realm.
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                identity:self.userB.identity
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r permission for user B should work.");
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                identity:self.userC.identity
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r permission for user C should work.");

    // Now sort on user ID.
    RLMResults<RLMSyncPermission *> *sorted = [results sortedResultsUsingKeyPath:RLMSyncPermissionSortPropertyUserID
                                                                       ascending:YES];
    // Wait for changes to propagate
    CHECK_PERMISSION_COUNT(sorted, 3);
    NSMutableArray *sortedIDs = [NSMutableArray array];
    for (NSUInteger i = 0; i < sorted.count; i++) {
        [sortedIDs addObject:[sorted objectAtIndex:i].identity];
    }
    // Make sure the IDs in sortedIDs are actually sorted.
    for (NSUInteger i = 0; i < sorted.count - 1; i++) {
        XCTAssertEqual([sortedIDs[i] compare:sortedIDs[i + 1]], NSOrderedAscending);
    }
    // Make sure the IDs in sortedIDs contain all 3 users' IDs.
    NSSet *sortedIDSet = [NSSet setWithArray:sortedIDs];
    XCTAssertTrue([sortedIDSet containsObject:self.userA.identity]);
    XCTAssertTrue([sortedIDSet containsObject:self.userB.identity]);
    XCTAssertTrue([sortedIDSet containsObject:self.userC.identity]);
}

- (void)testSortingPermissionsOnPath {
    // Get a reference to the permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];

    // Open three Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    NSURL *url3 = CUSTOM_REALM_URL(@"r3");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r3 = [self openRealmForURL:url3 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B read permissions for all three Realms.
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url1, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r1 permission for user B should work.");
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url2, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r2 permission for user B should work.");
    id p3 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url3, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p3, self.userA, @"Setting r3 permission for user B should work.");

    // Now sort on Realm URL.
    RLMResults<RLMSyncPermission *> *sorted = [results sortedResultsUsingKeyPath:RLMSyncPermissionSortPropertyPath
                                                                        ascending:YES];
    // Wait for changes to propagate
    CHECK_PERMISSION_COUNT(sorted, 3);

    CHECK_PERMISSION_PRESENT(sorted, p1);
    CHECK_PERMISSION_PRESENT(sorted, p2);
    CHECK_PERMISSION_PRESENT(sorted, p3);
    NSUInteger idx1 = [sorted indexOfObject:p1];
    NSUInteger idx2 = [sorted indexOfObject:p2];
    NSUInteger idx3 = [sorted indexOfObject:p3];
    // Make sure they are actually in ascending order.
    XCTAssertNotEqual(idx1, NSNotFound);
    XCTAssertNotEqual(idx2, NSNotFound);
    XCTAssertNotEqual(idx3, NSNotFound);
    XCTAssertLessThan(idx1, idx2);
    XCTAssertLessThan(idx2, idx3);
}

- (void)testSortingPermissionsOnDate {
    // Get a reference to the permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];

    // Open three Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"-r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"-r2");
    NSURL *url3 = CUSTOM_REALM_URL(@"-r3");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r3 = [self openRealmForURL:url3 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B read permissions for all three Realms.
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url3, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r3 permission for user B should work.");
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url1, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, @"Setting r1 permission for user B should work.");
    id p3 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url2, self.userA) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p3, self.userA, @"Setting r2 permission for user B should work.");

    // Now sort on date.
    RLMResults<RLMSyncPermission *> *sorted = [results sortedResultsUsingKeyPath:RLMSyncPermissionSortPropertyUpdated
                                                                       ascending:YES];

    // Wait for changes to propagate
    CHECK_PERMISSION_COUNT(sorted, 3);
    RLMSyncPermission *n1 = [sorted objectAtIndex:0];
    RLMSyncPermission *n2 = [sorted objectAtIndex:1];
    RLMSyncPermission *n3 = [sorted objectAtIndex:2];

    XCTAssertTrue([n1.path rangeOfString:@"r3"].location != NSNotFound);
    XCTAssertTrue([n2.path rangeOfString:@"r1"].location != NSNotFound);
    XCTAssertTrue([n3.path rangeOfString:@"r2"].location != NSNotFound);

    // Make sure they are actually in ascending order.
    XCTAssertLessThan([n1.updatedAt timeIntervalSinceReferenceDate], [n2.updatedAt timeIntervalSinceReferenceDate]);
    XCTAssertLessThan([n2.updatedAt timeIntervalSinceReferenceDate], [n3.updatedAt timeIntervalSinceReferenceDate]);
}

- (void)testPermissionResultsIndexOfObject {
    // Get a reference to the permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];

    NSString *uB = self.userB.identity;

    // Have A open a Realm and grant a permission to B.
    NSURL *url = REALM_URL();
    NSString *tildeSubstitutedPath = [makeTildeSubstitutedURL(url, self.userA) path];
    __attribute__((objc_precise_lifetime)) RLMRealm *r = [self openRealmForURL:url user:self.userA];
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:tildeSubstitutedPath
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, @"Setting r permission for user B should work.");

    // Wait for the permission to show up.
    CHECK_PERMISSION_COUNT(results, 1);
    // Should be able to get the permission based on the actual permission.
    XCTAssertEqual(((NSInteger)[results indexOfObject:p1]), 0);
    // A permission with a differing access level should not match.
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:tildeSubstitutedPath
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelAdmin];
    XCTAssertEqual([results indexOfObject:p2], NSNotFound);
    // A permission with a differing identity should not match.
    id p3 = [[RLMSyncPermission alloc] initWithRealmPath:tildeSubstitutedPath
                                                identity:self.userA.identity
                                             accessLevel:RLMSyncAccessLevelRead];
    XCTAssertEqual([results indexOfObject:p3], NSNotFound);
    // A permission with a differing path should not match.
    id p4 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userB) path]
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    XCTAssertEqual([results indexOfObject:p4], NSNotFound);
}

- (void)testPermissionResultsIndexOfObjectWithPredicate {
    // Get a reference to the permission results.
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];

    NSString *uB = self.userB.identity;
    // Open a Realm
    {
        NSURL *url = CUSTOM_REALM_URL(@"r1");
        __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForURL:url user:self.userA];

        // Give user B read permission for the Realm.
        RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                                   identity:uB
                                                                accessLevel:RLMSyncAccessLevelRead];
        APPLY_PERMISSION_WITH_MESSAGE(p, self.userA, @"Setting r1 permission for user B should work.");
    }

    NSString *finalPath;
    {
        // Do this again so there's more than one permission in the permission Realm.
        NSURL *url = CUSTOM_REALM_URL(@"r2");
        __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForURL:url user:self.userA];

        // Give user B read permission for the Realm.
        finalPath = [makeTildeSubstitutedURL(url, self.userA) path];
        RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:finalPath
                                                                   identity:uB
                                                                accessLevel:RLMSyncAccessLevelRead];
        APPLY_PERMISSION_WITH_MESSAGE(p, self.userA, @"Setting r2 permission for user B should work.");
    }

    // Wait for changes to propagate
    CHECK_PERMISSION_COUNT_AT_LEAST(results, 2);

    // Create the predicate and retrieve the index of the object.
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K == %@", RLMSyncPermissionSortPropertyPath, finalPath];
    NSUInteger index = [results indexOfObjectWithPredicate:pred];
    XCTAssertNotEqual(index, NSNotFound);
    if (index == NSNotFound) {
        return;
    }
    RLMSyncPermission *target = [results objectAtIndex:index];
    XCTAssertEqualObjects(target.path, finalPath);
}

/// User should not be able to change a permission for a Realm they don't own.
- (void)testSettingUnownedRealmPermission {
    // Open a Realm for user A.
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];

    // Try to have user B give user C permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                               identity:self.userC.identity
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
    RLMResults<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB
                                                                     message:@"Retrieving the results should work."];
    CHECK_PERMISSION_ABSENT(results, p);
}

- (void)testRetrievingPermissionsChecksThreadHasRunLoop {
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReason([self.userA retrievePermissionsWithCallback:^(__unused RLMResults *r, __unused NSError *e) {
            XCTFail(@"callback should not have been invoked");
        }], @"Can only access or modify permissions from a thread which has a run loop");
    }];
}

#pragma mark - Permission offer/response

/// Get a token which can be used to offer the permissions as defined
- (void)testPermissionOffer {
    NSURL *url = REALM_URL();
    // Open the Realm.
    __unused RLMRealm *realm = [self openRealmForURL:url user:self.userA];

    // Create the offer.
    __block NSString *token = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Should get a token when making an offer."];
    [self.userA createOfferForRealmAtURL:url
                             accessLevel:RLMSyncAccessLevelWrite
                              expiration:[NSDate dateWithTimeIntervalSinceNow:30 * 24 * 60 * 60]
                                callback:^(NSString *t, NSError *error) {
                                    XCTAssertNil(error);
                                    XCTAssertNotNil(t);
                                    token = t;
                                    [ex fulfill];
                                }];
    [self waitForExpectations:@[ex] timeout:10.0];
    XCTAssertTrue([token length] > 0);
}

/// Failed to process a permission offer object due to the offer expired
- (void)testPermissionOfferIsExpired {
    NSURL *url = REALM_URL();
    // Open the Realm.
    __unused RLMRealm *realm = [self openRealmForURL:url user:self.userA];

    // Create the offer.
    __block NSError *error = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Server should process the permission offer."];
    [self.userA createOfferForRealmAtURL:url
                             accessLevel:RLMSyncAccessLevelWrite
                              expiration:[NSDate dateWithTimeIntervalSinceNow:-30 * 24 * 60 * 60]
                                callback:^(NSString *token, NSError *err) {
                                    XCTAssertNotNil(err);
                                    XCTAssertNil(token);
                                    error = err;
                                    [ex fulfill];
                                }];
    [self waitForExpectations:@[ex] timeout:10.0];
    XCTAssertEqual(error.code, RLMSyncPermissionErrorOfferFailed);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], @"The permission offer is expired.");
}

/// Get a permission offer token, then permission offer response will be processed, then open another user's Realm file
- (void)testPermissionOfferResponse {
    NSURL *url = REALM_URL();
    // Open the Realm.
    __unused RLMRealm *realm = [self openRealmForURL:url user:self.userA];

    // Create the offer.
    __block NSString *token = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Should get a token when making an offer."];
    [self.userA createOfferForRealmAtURL:url
                             accessLevel:RLMSyncAccessLevelWrite
                              expiration:[NSDate dateWithTimeIntervalSinceNow:30 * 24 * 60 * 60]
                                callback:^(NSString *t, NSError *error) {
                                    XCTAssertNil(error);
                                    XCTAssertNotNil(t);
                                    token = t;
                                    [ex fulfill];
                                }];
    [self waitForExpectations:@[ex] timeout:10.0];
    XCTAssertTrue([token length] > 0);

    // Accept the offer.
    __block NSURL *realmURL = nil;
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Server should process offer acceptance."];
    [self.userB acceptOfferForToken:token callback:^(NSURL *returnedURL, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(returnedURL);
        realmURL = returnedURL;
        [ex2 fulfill];
    }];
    [self waitForExpectations:@[ex2] timeout:20.0];
    XCTAssertEqualObjects([realmURL path], [makeTildeSubstitutedURL(url, self.userA) path]);

    // Open the Realm.
    XCTAssertNotNil([self openRealmForURL:realmURL user:self.userB]);
}

/// Failed to process a permission offer response object due to `token` is invalid
- (void)testPermissionOfferResponseInvalidToken {
    NSString *badToken = @"invalid token";

    // Expect an error.
    __block NSError *error = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Server should process offer acceptance."];
    [self.userA acceptOfferForToken:badToken callback:^(NSURL *returnedURL, NSError *err) {
        XCTAssertNil(returnedURL);
        XCTAssertNotNil(err);
        error = err;
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:20.0];
    XCTAssertEqual(error.code, RLMSyncPermissionErrorAcceptOfferFailed);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], @"Your request parameters did not validate.");
}

/// Failed to process a permission offer response object due to `token` represents a Realm that does not exist
- (void)testPermissionOfferResponseTokenNotExist {
    NSString *fakeToken = @"00000000000000000000000000000000:00000000-0000-0000-0000-000000000000";

    // Expect an error.
    __block NSError *error = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Server should process offer acceptance."];
    [self.userA acceptOfferForToken:fakeToken callback:^(NSURL *returnedURL, NSError *err) {
        XCTAssertNil(returnedURL);
        XCTAssertNotNil(err);
        error = err;
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:20.0];
    XCTAssertEqual(error.code, RLMSyncPermissionErrorAcceptOfferFailed);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], @"Your request parameters did not validate.");
}

#pragma mark - Delete Realm upon permission denied

// FIXME ROS 2.0: works when ROS is manually provided, not when ROS is run as part of tests
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
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[userAURL path]
                                                               identity:self.userB.identity
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
            XCTAssertTrue([[session.realmURL absoluteString] rangeOfString:sessionName].location != NSNotFound);
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
    RLMSyncErrorActionToken *errorToken = [theError rlmSync_errorActionToken];
    XCTAssertNotNil(errorToken);
    [RLMSyncSession immediatelyHandleError:errorToken];

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
