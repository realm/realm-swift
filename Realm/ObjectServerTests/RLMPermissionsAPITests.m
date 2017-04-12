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

#define CHECK_PERMISSION_COUNT(ma_results, ma_count) {                                                  \
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking permission count"];             \
    id token = [ma_results addNotificationBlock:^(NSError *err) {                                       \
        XCTAssertNil(err);                                                                              \
        if (ma_results.count == ma_count) {                                                             \
            [ex fulfill];                                                                               \
        }                                                                                               \
    }];                                                                                                 \
    [self waitForExpectationsWithTimeout:2.0 handler:nil];                                              \
}

#define CHECK_PERMISSION_PRESENT(ma_results, ma_permission) {                                           \
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking permission presence"];          \
    id token = [ma_results addNotificationBlock:^(NSError *err) {                                       \
        XCTAssertNil(err);                                                                              \
        for (NSInteger i=0; i<ma_results.count; i++) {                                                  \
            if ([[ma_results permissionAtIndex:i] isEqual:ma_permission]) {                             \
                [ex fulfill];                                                                           \
                break;                                                                                  \
            }                                                                                           \
        }                                                                                               \
    }];                                                                                                 \
    [self waitForExpectationsWithTimeout:2.0 handler:nil];                                              \
}

#define CHECK_PERMISSION_ABSENT(ma_results, ma_permission) {                                            \
    XCTestExpectation *ex = [self expectationWithDescription:@"Checking permission absence"];           \
    id token = [ma_results addNotificationBlock:^(NSError *err) {                                       \
        XCTAssertNil(err);                                                                              \
        BOOL isPresent = NO;                                                                            \
        for (NSInteger i=0; i<ma_results.count; i++) {                                                  \
            if ([[ma_results permissionAtIndex:i] isEqual:ma_permission]) {                             \
                isPresent = YES;                                                                        \
                break;                                                                                  \
            }                                                                                           \
        }                                                                                               \
        if (!isPresent) {                                                                               \
            [ex fulfill];                                                                               \
        }                                                                                               \
    }];                                                                                                 \
    [self waitForExpectationsWithTimeout:2.0 handler:nil];                                              \
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
    id expectedPermission = [[RLMSyncPermissionValue alloc] initWithRealmPath:[NSString stringWithFormat:@"/%@/%@",
                                                                               self.userA.identity,
                                                                               NSStringFromSelector(_cmd)]
                                                                       userID:self.userB.identity
                                                                  accessLevel:RLMSyncAccessLevelRead];
    CHECK_PERMISSION_PRESENT(results, expectedPermission);
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
    id expectedPermission = [[RLMSyncPermissionValue alloc] initWithRealmPath:[NSString stringWithFormat:@"/%@/%@",
                                                                               self.userA.identity,
                                                                               NSStringFromSelector(_cmd)]
                                                                       userID:self.userB.identity
                                                                  accessLevel:RLMSyncAccessLevelRead];
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
    id expectedPermission = [[RLMSyncPermissionValue alloc] initWithRealmPath:[NSString stringWithFormat:@"/%@/%@",
                                                                               self.userA.identity,
                                                                               NSStringFromSelector(_cmd)]
                                                                       userID:self.userB.identity
                                                                  accessLevel:RLMSyncAccessLevelRead];
    CHECK_PERMISSION_PRESENT(results, expectedPermission);
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
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Setting a permission should work."];
    [self.userB applyPermission:p callback:^(NSError *error) {
        XCTAssertNotNil(error);
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Now retrieve the permissions again and make sure the new permission was not set.
    XCTestExpectation *ex3 = [self expectationWithDescription:@"One permission after setting the permission."];
    [self.userB retrievePermissionsWithCallback:^(RLMSyncPermissionResults *r, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(r);
        results = r;
        [ex3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    id expectedPermission = [[RLMSyncPermissionValue alloc] initWithRealmPath:[NSString stringWithFormat:@"/%@/%@",
                                                                               self.userA.identity,
                                                                               NSStringFromSelector(_cmd)]
                                                                       userID:self.userC.identity
                                                                  accessLevel:RLMSyncAccessLevelRead];
    CHECK_PERMISSION_ABSENT(results, expectedPermission);
}

@end
