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

@interface RLMSyncPermission ()
- (RLMSyncPermission *)tildeExpandedSyncPermissionForUser:(RLMSyncUser *)user;
@end
@interface RLMSyncUser ()
- (void)invalidate;
@end

#define APPLY_PERMISSION(ma_permission, ma_user) \
    APPLY_PERMISSION_WITH_MESSAGE(ma_permission, ma_user, ma_user, @"Setting a permission should work")


#define APPLY_PERMISSION_WITH_MESSAGE(ma_permission, ma_user, ma_target_user, ma_message) do {                         \
    APPLY_PERMISSION_UNCHECKED(ma_permission, ma_user, ma_message);                                                    \
    CHECK_PERMISSION_PRESENT([self getPermissionResultsFor:ma_target_user], ma_permission, ma_user);                   \
} while (0)

#define APPLY_PERMISSION_UNCHECKED(ma_permission, ma_user, ma_message) do {                                            \
    XCTestExpectation *ex = [self expectationWithDescription:ma_message];                                              \
    [ma_user applyPermission:ma_permission callback:^(NSError *err) {                                                  \
        XCTAssertNil(err, @"Received an error when applying permission: %@", err);                                     \
        [ex fulfill];                                                                                                  \
    }];                                                                                                                \
    [self waitForExpectations:@[ex] timeout:2.0];                                                                      \
} while (0)

#define REVOKE_PERMISSION(ma_permission, ma_user) do {                                                                 \
    XCTestExpectation *ex = [self expectationWithDescription:@"revoke permission"];                                    \
    [ma_user applyPermission:ma_permission callback:^(NSError *err) {                                                  \
        XCTAssertNil(err, @"Received an error when applying permission: %@", err);                                     \
        [ex fulfill];                                                                                                  \
    }];                                                                                                                \
    [self waitForExpectations:@[ex] timeout:2.0];                                                                      \
    CHECK_PERMISSION_ABSENT([self getPermissionResultsFor:ma_user], ma_permission, ma_user);                           \
} while (0)

#define CHECK_COUNT_PENDING_DOWNLOAD(expected_count, m_type, m_realm) \
    CHECK_COUNT_PENDING_DOWNLOAD_CUSTOM_EXPECTATION(expected_count, m_type, m_realm, nil)

/// This macro tries ten times to wait for downloads and then check for object count.
/// If the object count does not match, it waits 0.1 second before trying again.
/// It is most useful in cases where the test ROS might be expected to take some
/// non-negligible amount of time performing an operation whose completion is required
/// for the test on the client side to proceed.
#define CHECK_COUNT_PENDING_DOWNLOAD_CUSTOM_EXPECTATION(expected_count, m_type, m_realm, m_exp) do {                   \
    RLMSyncConfiguration *m_config = m_realm.configuration.syncConfiguration;                                          \
    XCTAssertNotNil(m_config, @"Realm passed to CHECK_COUNT_PENDING_DOWNLOAD() doesn't have a sync config!");          \
    RLMSyncUser *m_user = m_config.user;                                                                               \
    NSURL *m_url = m_config.realmURL;                                                                                  \
    for (int i=0; i<10; i++) {                                                                                         \
        [self waitForDownloadsForUser:m_user url:m_url expectation:m_exp error:nil];                                   \
        if (expected_count == [m_type allObjectsInRealm:m_realm].count) { break; }                                     \
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];                           \
    }                                                                                                                  \
    CHECK_COUNT(expected_count, m_type, m_realm);                                                                      \
} while (0)


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

    RLMSyncManager.sharedManager.errorHandler = ^(NSError *error, __unused RLMSyncSession *session) {
        XCTFail(@"Error handler should not be called unless explicitly expected. Error: %@", error);
    };
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

#define CHECK_PERMISSION_PRESENT(ma_results, ma_permission, ma_user) \
    XCTAssertNotEqual([ma_results indexOfObject:[ma_permission tildeExpandedSyncPermissionForUser:ma_user]], NSNotFound)

#define CHECK_PERMISSION_ABSENT(ma_results, ma_permission, ma_user) \
    XCTAssertEqual([ma_results indexOfObject:[ma_permission tildeExpandedSyncPermissionForUser:ma_user]], NSNotFound)

#define CHECK_PERMISSION_COUNT_AT_LEAST(ma_results, ma_count) \
    XCTAssertGreaterThanOrEqual(ma_results.count, ma_count)

#define CHECK_PERMISSION_COUNT(ma_results, ma_count) \
    XCTAssertEqual(ma_results.count, ma_count)

#pragma mark - Helper methods

- (NSArray<RLMSyncPermission *> *)getPermissionResultsFor:(RLMSyncUser *)user {
    return [self getPermissionResultsFor:user message:@"Get permission results"];
}

- (NSArray<RLMSyncPermission *> *)getPermissionResultsFor:(RLMSyncUser *)user message:(NSString *)message {
    // Get a reference to the permission results.
    XCTestExpectation *ex = [self expectationWithDescription:message];
    __block NSArray<RLMSyncPermission *> *results = nil;
    [user retrievePermissionsWithCallback:^(NSArray<RLMSyncPermission *> *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(results, @"getPermissionResultsFor: failed for user %@. No results.", user.identity);
    return results;
}

- (void)testErrorHandlingForInvalidUser {
    [self.userA invalidate];
    RLMSyncPermission *p;
    NSURL *url;

    __block bool called = false;
    void (^checkError)(NSError *) = ^(NSError *err) {
        XCTAssertNotNil(err);
        XCTAssertEqual(err.code, RLMSyncAuthErrorInvalidParameters);
        called = true;
    };

    [self.userA retrievePermissionsWithCallback:^(id permissions, NSError *err) {
        XCTAssertNil(permissions);
        checkError(err);
    }];
    XCTAssertTrue(called);

    called = false;
    [self.userA applyPermission:p callback:^(NSError *err) {
        checkError(err);
    }];
    XCTAssertTrue(called);

    called = false;
    [self.userA createOfferForRealmAtURL:url accessLevel:RLMSyncAccessLevelWrite expiration:nil callback:^(NSString *token, NSError *err) {
        XCTAssertNil(token);
        checkError(err);
    }];
    XCTAssertTrue(called);

    called = false;
    [self.userA acceptOfferForToken:@"" callback:^(NSURL *url, NSError *err) {
        XCTAssertNil(url);
        checkError(err);
    }];
    XCTAssertTrue(called);

    called = false;
    [self.userA invalidateOfferForToken:@"" callback:^(NSError *err) {
        checkError(err);
    }];
    XCTAssertTrue(called);
}

#pragma mark - Permissions

/// If user A grants user B read access to a Realm, user B should be able to read from it.
- (void)testReadAccess {
    NSString *testName = NSStringFromSelector(_cmd);
    // Open a Realm for user A.
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealm *userARealm = [self openRealmForURL:userAURL user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:userARealm];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B read permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[userAURL path]
                                                               identity:self.userB.identity
                                                            accessLevel:RLMSyncAccessLevelRead];
    // Set the read permission.
    APPLY_PERMISSION(p, self.userA);

    // Open the same Realm for user B.
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealmConfiguration *userBConfig = [self.userB configurationWithURL:userBURL fullSynchronization:YES];
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
    RLMSyncManager.sharedManager.errorHandler = ^(NSError *err, __unused RLMSyncSession *session) {
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
    NSString *testName = NSStringFromSelector(_cmd);
    // Open a Realm for user A.
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealm *userARealm = [self openRealmForURL:userAURL user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:userARealm];
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
    [self waitForUploadsForRealm:userBRealm];
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
    NSString *testName = NSStringFromSelector(_cmd);
    // Unresolved URL: ~/testManageAccess
    NSURL *userAURLUnresolved = makeTestURL(testName, nil);
    // Resolved URL: <User A ID>/testManageAccess
    NSURL *userAURLResolved = makeTestURL(testName, self.userA);

    // Open a Realm for user A.
    RLMRealm *userARealm = [self openRealmForURL:userAURLUnresolved user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:userARealm];
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
    [self waitForUploadsForRealm:userBRealm];
    CHECK_COUNT(5, SyncObject, userBRealm);
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userARealm);

    // User B should be able to give user C write permissions to user A's Realm.
    RLMSyncPermission *p2 = [[RLMSyncPermission alloc] initWithRealmPath:[userAURLResolved path]
                                                                identity:self.userC.identity
                                                             accessLevel:RLMSyncAccessLevelWrite];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userB, self.userC,
                                  @"User B should be able to give C write permissions to A's Realm.");

    // User C should be able to write to the Realm.
    RLMRealm *userCRealm = [self openRealmForURL:userAURLResolved user:self.userC];
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userCRealm);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-6", @"child-7", @"child-8"]];
    [self waitForUploadsForRealm:userCRealm];
    CHECK_COUNT(8, SyncObject, userCRealm);
    CHECK_COUNT_PENDING_DOWNLOAD(8, SyncObject, userARealm);
    CHECK_COUNT_PENDING_DOWNLOAD(8, SyncObject, userBRealm);
}

/// If user A grants user B write access to a Realm via username, user B should be able to write to it.
- (void)testWriteAccessViaUsername {
    NSString *testName = NSStringFromSelector(_cmd);
    // Open a Realm for user A.
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealm *userARealm = [self openRealmForURL:userAURL user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:userARealm];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B write permissions to that Realm via user B's username.
    NSString *userAFullPath = [makeTildeSubstitutedURL(userAURL, self.userA) path];
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:userAURL.path
                                                               username:self.userBUsername
                                                            accessLevel:RLMSyncAccessLevelWrite];
    // Set the permission.
    APPLY_PERMISSION_UNCHECKED(p, self.userA, @"Grant permission via email");

    RLMSyncPermission *expected = [[RLMSyncPermission alloc] initWithRealmPath:userAFullPath
                                                                      identity:self.userB.identity
                                                                   accessLevel:RLMSyncAccessLevelWrite];
    CHECK_PERMISSION_PRESENT([self getPermissionResultsFor:self.userB], expected, self.userB);

    // Open the Realm for user B. Since user B has write privileges, they should be able to open it 'normally'.
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealm *userBRealm = [self openRealmForURL:userBURL user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);

    // Add some objects using user B.
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForRealm:userBRealm];
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
    [self waitForUploadsForRealm:userARealm];
    CHECK_COUNT(3, SyncObject, userARealm);

    // User B should be able to write to the Realm.
    RLMRealm *userBRealm = [self openRealmForURL:guestURL user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForRealm:userBRealm];
    CHECK_COUNT(5, SyncObject, userBRealm);

    // User C should be able to write to the Realm.
    RLMRealm *userCRealm = [self openRealmForURL:guestURL user:self.userC];
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userCRealm);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-6", @"child-7", @"child-8", @"child-9"]];
    [self waitForUploadsForRealm:userCRealm];
    CHECK_COUNT(9, SyncObject, userCRealm);

    p = [[RLMSyncPermission alloc] initWithRealmPath:[ownerURL path]
                                            identity:@"*"
                                         accessLevel:RLMSyncAccessLevelNone];
    REVOKE_PERMISSION(p, self.userA);
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
    APPLY_PERMISSION_WITH_MESSAGE(p, admin, self.userA, @"Setting wildcard permission should work.");

    // Have the admin user write a few objects first.
    [self addSyncObjectsToRealm:adminUserRealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:adminUserRealm];
    CHECK_COUNT(3, SyncObject, adminUserRealm);

    // User B should be able to read from the Realm.
    __block RLMRealm *userBRealm = nil;
    RLMRealmConfiguration *userBConfig = [self.userB configurationWithURL:globalRealmURL fullSynchronization:YES];
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
    RLMRealmConfiguration *userCConfig = [self.userC configurationWithURL:globalRealmURL fullSynchronization:YES];
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

    p = [[RLMSyncPermission alloc] initWithRealmPath:[globalRealmURL path]
                                            identity:@"*"
                                         accessLevel:RLMSyncAccessLevelNone];
    REVOKE_PERMISSION(p, admin);
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
    APPLY_PERMISSION_WITH_MESSAGE(p, admin, self.userA, @"Should grant access to all users");

    // Have the admin user write a few objects first.
    [self addSyncObjectsToRealm:adminUserRealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:adminUserRealm];
    CHECK_COUNT(3, SyncObject, adminUserRealm);

    // User B should be able to write to the Realm.
    RLMRealm *userBRealm = [self openRealmForURL:globalRealmURL user:self.userB];
    CHECK_COUNT_PENDING_DOWNLOAD(3, SyncObject, userBRealm);
    [self addSyncObjectsToRealm:userBRealm descriptions:@[@"child-4", @"child-5"]];
    [self waitForUploadsForRealm:userBRealm];
    CHECK_COUNT(5, SyncObject, userBRealm);

    // User C should be able to write to the Realm.
    RLMRealm *userCRealm = [self openRealmForURL:globalRealmURL user:self.userC];
    CHECK_COUNT_PENDING_DOWNLOAD(5, SyncObject, userCRealm);
    [self addSyncObjectsToRealm:userCRealm descriptions:@[@"child-6", @"child-7", @"child-8", @"child-9"]];
    [self waitForUploadsForRealm:userCRealm];
    CHECK_COUNT(9, SyncObject, userCRealm);

    p = [[RLMSyncPermission alloc] initWithRealmPath:[globalRealmURL path]
                                            identity:@"*"
                                         accessLevel:RLMSyncAccessLevelNone];
    REVOKE_PERMISSION(p, admin);
}

- (void)testReadAccessWithClassSuperset {
    NSString *testName = NSStringFromSelector(_cmd);

    // Create a Realm with only a single object type
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealmConfiguration *userAConfig = [self.userA configurationWithURL:userAURL fullSynchronization:YES];
    userAConfig.objectClasses = @[SyncObject.self];
    RLMRealm *userARealm = [self asyncOpenRealmWithConfiguration:userAConfig];
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:userARealm];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B read-only permissions to that Realm so that it can't add new object types
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[userAURL path]
                                                               identity:self.userB.identity
                                                            accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION(p, self.userA);

    // Open the same Realm s user B without limiting the set of object classes
    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealmConfiguration *userBConfig = [self.userB configurationWithURL:userBURL fullSynchronization:YES];
    userBConfig.readOnly = YES;
    RLMRealm *userBRealm = [self asyncOpenRealmWithConfiguration:userBConfig];
    CHECK_COUNT(3, SyncObject, userBRealm);

    // Verify that syncing is actually working and new objects written by A show up in B's Realm
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-4"]];
    CHECK_COUNT_PENDING_DOWNLOAD(4, SyncObject, userBRealm);
}

#pragma mark - Permission change API

/// Setting a permission should work, and then that permission should be able to be retrieved.
- (void)testSettingPermission {
    // First, there should be no permissions.
    NSArray<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userA];
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
    CHECK_PERMISSION_PRESENT(results, p, self.userA);

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
    NSArray<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB
                                                                  message:@"Setting new permission."];
    CHECK_PERMISSION_PRESENT(results, p, self.userA);

    // Delete the permission.
    RLMSyncPermission *p2 = [[RLMSyncPermission alloc] initWithRealmPath:url.path
                                                                identity:self.userB.identity
                                                             accessLevel:RLMSyncAccessLevelNone];
    REVOKE_PERMISSION(p2, self.userA);

    // Make sure the permission deletion is properly reflected.
    results = [self getPermissionResultsFor:self.userB message:@"Setting new permission."];
    CHECK_PERMISSION_COUNT(results, 0);
}

/// KVC getting and setting should work properly for `NSArray<RLMSyncPermission>`.
- (void)testKVCWithPermissionsResults {
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
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, self.userA, @"Setting r1 permission for user B should work.");
    NSString *path2 = [makeTildeSubstitutedURL(url2, self.userA) path];
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:path2
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, self.userA, @"Setting r2 permission for user B should work.");

    // Wait for all the permissions to show up.
    NSArray<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];
    CHECK_PERMISSION_PRESENT(results, p1, self.userA);
    CHECK_PERMISSION_PRESENT(results, p2, self.userA);

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
    // Open two Realms
    NSURL *url1 = CUSTOM_REALM_URL(@"r1");
    NSURL *url2 = CUSTOM_REALM_URL(@"r2");
    NSURL *url3 = CUSTOM_REALM_URL(@"r3");
    __attribute__((objc_precise_lifetime)) RLMRealm *r1 = [self openRealmForURL:url1 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r2 = [self openRealmForURL:url2 user:self.userA];
    __attribute__((objc_precise_lifetime)) RLMRealm *r3 = [self openRealmForURL:url3 user:self.userA];
    NSString *uB = self.userB.identity;

    // Give user B permissions to realms r1, r2, and r3.
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:url1.path
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, self.userA, @"Setting r1 permission for user B should work.");
    NSString *finalPath = [makeTildeSubstitutedURL(url2, self.userA) path];
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:finalPath
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, self.userA, @"Setting r2 permission for user B should work.");
    id p3 = [[RLMSyncPermission alloc] initWithRealmPath:url3.path
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p3, self.userA, self.userA, @"Setting r3 permission for user B should work.");

    // Wait for all the permissions to show up.
    NSArray<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];
    CHECK_PERMISSION_PRESENT(results, p1, self.userA);
    CHECK_PERMISSION_PRESENT(results, p2, self.userA);
    CHECK_PERMISSION_PRESENT(results, p3, self.userA);

    // Now make a filter.
    NSArray<RLMSyncPermission *> *filtered = [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path == %@", finalPath]];
    CHECK_PERMISSION_ABSENT(filtered, p1, self.userA);
    CHECK_PERMISSION_PRESENT(filtered, p2, self.userA);
    CHECK_PERMISSION_ABSENT(filtered, p3, self.userA);
}

- (void)testSortingPermissionsOnUserID {
    NSURL *url = REALM_URL();
    __attribute__((objc_precise_lifetime)) RLMRealm *r = [self openRealmForURL:url user:self.userA];

    // Give users B and C access to my Realm.
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                identity:self.userB.identity
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, self.userA, @"Setting r permission for user B should work.");
    id p2 = [[RLMSyncPermission alloc] initWithRealmPath:[makeTildeSubstitutedURL(url, self.userA) path]
                                                identity:self.userC.identity
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p2, self.userA, self.userA, @"Setting r permission for user C should work.");

    // Now sort on user ID.
    NSArray<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userA];
    NSArray<RLMSyncPermission *> *sorted = [results sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identity" ascending:YES]]];
    CHECK_PERMISSION_COUNT(sorted, 3);
    NSArray *sortedIDs = [sorted valueForKey:@"identity"];
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

- (void)testPermissionResultsIndexOfObject {
    NSString *uB = self.userB.identity;

    // Have A open a Realm and grant a permission to B.
    NSURL *url = REALM_URL();
    NSString *tildeSubstitutedPath = [makeTildeSubstitutedURL(url, self.userA) path];
    __attribute__((objc_precise_lifetime)) RLMRealm *r = [self openRealmForURL:url user:self.userA];
    id p1 = [[RLMSyncPermission alloc] initWithRealmPath:tildeSubstitutedPath
                                                identity:uB
                                             accessLevel:RLMSyncAccessLevelRead];
    APPLY_PERMISSION_WITH_MESSAGE(p1, self.userA, self.userA,
                                  @"Setting read permission for user B should work.");

    // Wait for the permission to show up.
    NSArray<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB];
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
        XCTAssertEqual(error.domain, RLMSyncAuthErrorDomain);
        XCTAssertEqual(error.code, RLMSyncAuthErrorAccessDeniedOrInvalidPath);
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Now retrieve the permissions again and make sure the new permission was not set.
    NSArray<RLMSyncPermission *> *results = [self getPermissionResultsFor:self.userB
                                                                  message:@"Retrieving the results should work."];
    CHECK_PERMISSION_ABSENT(results, p, self.userA);
}

#pragma mark - Permission offer/response

- (NSString *)createOfferForRealmAtURL:(NSURL *)url
                                  user:(RLMSyncUser *)user
                           accessLevel:(RLMSyncAccessLevel)level
                            expiration:(NSDate *)expiration {
    __block NSString *token;
    XCTestExpectation *ex = [self expectationWithDescription:@"Should get a token when making an offer."];
    [user createOfferForRealmAtURL:url
                       accessLevel:level
                        expiration:expiration
                          callback:^(NSString *t, NSError *error) {
        XCTAssertNil(error);
        token = t;
        XCTAssertNotNil(token);
        XCTAssertGreaterThan(token.length, 0);
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:10.0];
    return token;
}

/// Get a token which can be used to offer the permissions as defined
- (void)testPermissionOffer {
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:self.userA];
    [self createOfferForRealmAtURL:url user:self.userA accessLevel:RLMSyncAccessLevelWrite expiration:nil];
}

/// Failed to process a permission offer object due to the offer expired
- (void)testPermissionOfferIsExpired {
    NSURL *url = REALM_URL();
    // Create the Realm
    [self openRealmForURL:url user:self.userA];

    XCTestExpectation *ex = [self expectationWithDescription:@"Server should process the permission offer."];
    [self.userA createOfferForRealmAtURL:url
                             accessLevel:RLMSyncAccessLevelWrite
                              expiration:[NSDate dateWithTimeIntervalSinceNow:-30 * 24 * 60 * 60]
                                callback:^(NSString *token, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(token);
        XCTAssertEqual(error.code, RLMSyncAuthErrorExpiredPermissionOffer);
        XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], @"The permission offer is expired.");
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:10.0];
}

/// Get a permission offer token, then permission offer response will be processed, then open another user's Realm file
- (void)testPermissionOfferResponse {
    NSURL *url = REALM_URL();
    // Create the Realm
    [self openRealmForURL:url user:self.userA];

    NSString *token = [self createOfferForRealmAtURL:url user:self.userA
                                         accessLevel:RLMSyncAccessLevelWrite expiration:nil];

    // Accept the offer.
    __block NSURL *realmURL = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Server should process offer acceptance."];
    [self.userB acceptOfferForToken:token callback:^(NSURL *returnedURL, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(returnedURL);
        realmURL = returnedURL;
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:20.0];
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
    XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidParameters);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey],
                          @"Your request parameters did not validate. token: Invalid parameter 'token'!;");
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
    XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidParameters);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey],
                          @"Your request parameters did not validate. token: Invalid parameter 'token'!;");
}

- (void)testInvalidatePermissionOffer {
    NSURL *url = REALM_URL();
    // Create the Realm
    [self openRealmForURL:url user:self.userA];

    // Create an offer
    NSString *token = [self createOfferForRealmAtURL:url user:self.userA
                                         accessLevel:RLMSyncAccessLevelWrite expiration:nil];

    // Invalidate it
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Should invalidate a offer token."];
    [self.userA invalidateOfferForToken:token callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex2 fulfill];
    }];
    [self waitForExpectations:@[ex2] timeout:10.0];

    // Fail to accept the offer
    XCTestExpectation *ex3 = [self expectationWithDescription:@"Server should reject invalidated offer"];
    [self.userB acceptOfferForToken:token callback:^(NSURL *returnedURL, NSError *error) {
        XCTAssertNil(returnedURL);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, RLMSyncAuthErrorExpiredPermissionOffer);
        XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], @"The permission offer is expired.");
        [ex3 fulfill];
    }];
    [self waitForExpectations:@[ex3] timeout:20.0];
}

- (void)testRetrievePermissionOffers {
    NSURL *url = REALM_URL();
    NSURL *expandedURL = makeTildeSubstitutedURL(url, self.userA);
    // Create the Realm
    [self openRealmForURL:url user:self.userA];

    NSDate *createdAt = [NSDate date];
    NSDate *expiresAt = [NSDate dateWithTimeIntervalSinceNow:100.0];
    // Create two offers
    NSString *token1 = [self createOfferForRealmAtURL:url user:self.userA
                                          accessLevel:RLMSyncAccessLevelRead expiration:expiresAt];
    NSString *token2 = [self createOfferForRealmAtURL:url user:self.userA
                                          accessLevel:RLMSyncAccessLevelWrite expiration:nil];

    id ex1 = [self expectationWithDescription:@"Retrieve offers"];
    [self.userA retrievePermissionOffersWithCallback:^(NSArray<RLMSyncPermissionOffer *> *offers, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(offers.count, 2U);
        for (RLMSyncPermissionOffer *offer in offers) {
            bool isFirst = [offer.token isEqualToString:token1];
            XCTAssertEqualObjects(offer.realmPath, expandedURL.path);
            XCTAssertGreaterThan(offer.createdAt.timeIntervalSince1970, createdAt.timeIntervalSince1970);
            if (isFirst) {
                XCTAssertEqualObjects(offer.token, token1);
                // May be up to a half ms off due to rounding
                XCTAssertLessThan(fabs([offer.expiresAt timeIntervalSinceDate:expiresAt]), 0.001);
                XCTAssertEqual(offer.accessLevel, RLMSyncAccessLevelRead);
            }
            else {
                XCTAssertEqualObjects(offer.token, token2);
                XCTAssertNil(offer.expiresAt);
                XCTAssertEqual(offer.accessLevel, RLMSyncAccessLevelWrite);
            }
        }
        [ex1 fulfill];
    }];
    [self waitForExpectations:@[ex1] timeout:10.0];

    // Invalidate one of the offers
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Should invalidate a offer token."];
    [self.userA invalidateOfferForToken:token1 callback:^(NSError *error) {
        XCTAssertNil(error);
        [ex2 fulfill];
    }];
    [self waitForExpectations:@[ex2] timeout:10.0];

    // Verify that we only get non-invalidated offers
    id ex3 = [self expectationWithDescription:@"Retrieve offers"];
    [self.userA retrievePermissionOffersWithCallback:^(NSArray<RLMSyncPermissionOffer *> *offers, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(offers.count, 1U);
        RLMSyncPermissionOffer *offer = offers[0];
        XCTAssertEqualObjects(offer.realmPath, expandedURL.path);
        XCTAssertGreaterThan(offer.createdAt.timeIntervalSince1970, createdAt.timeIntervalSince1970);
        XCTAssertEqualObjects(offer.token, token2);
        XCTAssertNil(offer.expiresAt);
        XCTAssertEqual(offer.accessLevel, RLMSyncAccessLevelWrite);
        [ex3 fulfill];
    }];
    [self waitForExpectations:@[ex3] timeout:10.0];
}

#pragma mark - Delete Realm upon permission denied

/// A Realm which is opened improperly should report an error allowing the app to recover.
- (void)testDeleteRealmUponPermissionDenied {
    NSString *testName = NSStringFromSelector(_cmd);
    // Open a Realm for user A.
    NSURL *userAURL = makeTestURL(testName, nil);
    RLMRealm *userARealm = [self openRealmForURL:userAURL user:self.userA];

    // Have user A add some items to the Realm.
    [self addSyncObjectsToRealm:userARealm descriptions:@[@"child-1", @"child-2", @"child-3"]];
    [self waitForUploadsForRealm:userARealm];
    CHECK_COUNT(3, SyncObject, userARealm);

    // Give user B read permissions to that Realm.
    RLMSyncPermission *p = [[RLMSyncPermission alloc] initWithRealmPath:[userAURL path]
                                                               identity:self.userB.identity
                                                            accessLevel:RLMSyncAccessLevelRead];
    // Set the read permission.
    APPLY_PERMISSION(p, self.userA);

    NSURL *userBURL = makeTestURL(testName, self.userA);
    RLMRealmConfiguration *userBConfig = [self.userB configurationWithURL:userBURL fullSynchronization:YES];
    __block NSError *theError = nil;

    // Incorrectly open the Realm for user B.
    NSURL *onDiskPath;
    @autoreleasepool {
        NSString *sessionName = NSStringFromSelector(_cmd);
        XCTestExpectation *ex2 = [self expectationWithDescription:@"We should get a permission denied error."];
        RLMSyncManager.sharedManager.errorHandler = ^(NSError *err, RLMSyncSession *session) {
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
