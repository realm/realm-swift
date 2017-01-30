////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncTestCase.h"
#import "RLMTestUtils.h"
#import "RLMSyncSessionRefreshHandle+ObjectServerTests.h"
#import "RLMSyncUser+ObjectServerTests.h"
#import "RLMSyncUtil_Private.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealmUtil.hpp"
#import "RLMRealm_Dynamic.h"

@interface RLMObjectServerTests : RLMSyncTestCase
@end

@implementation RLMObjectServerTests

#pragma mark - Authentication and Tokens

/// Valid username/password credentials should be able to log in a user. Using the same credentials should return the
/// same user object.
- (void)testUsernamePasswordAuthentication {
    RLMSyncUser *firstUser = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                                    server:[RLMSyncTestCase authServerURL]];
    RLMSyncUser *secondUser = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                             register:NO]
                                                     server:[RLMSyncTestCase authServerURL]];
    // Two users created with the same credential should resolve to the same actual user.
    XCTAssertTrue([firstUser.identity isEqualToString:secondUser.identity]);
    // Authentication server property should be properly set.
    XCTAssertEqualObjects(firstUser.authenticationServer, [RLMSyncTestCase authServerURL]);
    XCTAssertFalse(firstUser.isAdmin);
}

/// A valid admin token should be able to log in a user.
- (void)testAdminTokenAuthentication {
    NSURL *adminTokenFileURL = [[RLMSyncTestCase rootRealmCocoaURL] URLByAppendingPathComponent:@"sync/admin_token.base64"];
    NSString *adminToken = [NSString stringWithContentsOfURL:adminTokenFileURL encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotNil(adminToken);
    RLMSyncCredentials *credentials = [RLMSyncCredentials credentialsWithAccessToken:adminToken identity:@"test"];
    XCTAssertNotNil(credentials);

    RLMSyncUser *user = [self logInUserForCredentials:credentials server:[RLMObjectServerTests authServerURL]];
    XCTAssertTrue(user.isAdmin);
}

/// An invalid username/password credential should not be able to log in a user and a corresponding error should be generated.
- (void)testInvalidPasswordAuthentication {
    [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd) register:YES]
                          server:[RLMSyncTestCase authServerURL]];

    RLMSyncCredentials *credentials = [RLMSyncCredentials credentialsWithUsername:NSStringFromSelector(_cmd)
                                                                         password:@"INVALID_PASSWORD"
                                                                         register:NO];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser logInWithCredentials:credentials
                        authServerURL:[RLMObjectServerTests authServerURL]
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.domain, RLMSyncAuthErrorDomain);
        XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidCredential);
        XCTAssertNotNil(error.localizedDescription);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// A non-existsing user should not be able to log in and a corresponding error should be generated.
- (void)testNonExistingUsernameAuthentication {
    RLMSyncCredentials *credentials = [RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                       register:NO];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser logInWithCredentials:credentials
                        authServerURL:[RLMObjectServerTests authServerURL]
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.domain, RLMSyncAuthErrorDomain);
        XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidCredential);
        XCTAssertNotNil(error.localizedDescription);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Registering a user with existing username should return corresponding error.
- (void)testExistingUsernameRegistration {
    RLMSyncCredentials *credentials = [RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                            register:YES];

    [self logInUserForCredentials:credentials server:[RLMSyncTestCase authServerURL]];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser logInWithCredentials:credentials
                        authServerURL:[RLMObjectServerTests authServerURL]
                        onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.domain, RLMSyncAuthErrorDomain);
        XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidCredential);
        XCTAssertNotNil(error.localizedDescription);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Errors reported in RLMSyncManager.errorHandler shouldn't contain sync error domain errors as underlying error
- (void)testSyncErrorHandlerErrorDomain {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    XCTAssertNotNil(user);

    NSURL *realmURL = [NSURL URLWithString:@"realm://localhost:9080/THE_PATH_USER_DONT_HAVE_ACCESS_TO/test"];

    RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
    c.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:realmURL];

    NSError *error = nil;
    __attribute__((objc_precise_lifetime)) RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(realm.isEmpty);

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncManager sharedManager].errorHandler = ^(__unused NSError *error,
                                                    __unused RLMSyncSession *session) {
        XCTAssertTrue([error.domain isEqualToString:RLMSyncErrorDomain]);
        XCTAssertFalse([[error.userInfo[kRLMSyncUnderlyingErrorKey] domain] isEqualToString:RLMSyncErrorDomain]);
        [expectation fulfill];
    };

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// The pre-emptive token refresh subsystem should function, and properly refresh the token.
- (void)testPreemptiveTokenRefresh {
    // Prepare the test.
    __block NSInteger refreshCount = 0;
    __block NSInteger errorCount = 0;
    [RLMSyncManager sharedManager].errorHandler = ^(__unused NSError *error,
                                                    __unused RLMSyncSession *session) {
        errorCount++;
    };

    __block XCTestExpectation *ex;
    [RLMSyncSessionRefreshHandle calculateFireDateUsingTestLogic:YES
                                        blockOnRefreshCompletion:^(BOOL success) {
                                            XCTAssertTrue(success);
                                            refreshCount++;
                                            [ex fulfill];
                                        }];
    // Open the Realm.
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:true]
                                               server:[RLMObjectServerTests authServerURL]];
    __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForURL:url user:user];
    ex = [self expectationWithDescription:@"Timer fired"];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue(errorCount == 0);
    XCTAssertTrue(refreshCount > 0);
}

#pragma mark - Users

/// `[RLMSyncUser all]` should be updated once a user is logged in.
- (void)testBasicUserPersistence {
    XCTAssertNil([RLMSyncUser currentUser]);
    XCTAssertEqual([[RLMSyncUser allUsers] count], 0U);
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    XCTAssertNotNil(user);
    XCTAssertEqual([[RLMSyncUser allUsers] count], 1U);
    XCTAssertEqualObjects([RLMSyncUser allUsers], @{user.identity: user});
    XCTAssertEqualObjects([RLMSyncUser currentUser], user);

    RLMSyncUser *user2 = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:[NSStringFromSelector(_cmd) stringByAppendingString:@"2"]
                                                                                             register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    XCTAssertEqual([[RLMSyncUser allUsers] count], 2U);
    NSDictionary *dict2 = @{user.identity: user, user2.identity: user2};
    XCTAssertEqualObjects([RLMSyncUser allUsers], dict2);
    RLMAssertThrowsWithReasonMatching([RLMSyncUser currentUser], @"currentUser cannot be called if more that one valid, logged-in user exists");
}

/// `[RLMSyncUser currentUser]` should become nil if the user is logged out.
- (void)testCurrentUserLogout {
    XCTAssertNil([RLMSyncUser currentUser]);
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    XCTAssertNotNil(user);
    XCTAssertEqualObjects([RLMSyncUser currentUser], user);
    [user logOut];
    XCTAssertNil([RLMSyncUser currentUser]);
}

/// A sync user should return a session when asked for it based on the path.
- (void)testUserGetSessionForValidURL {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    NSURL *url = REALM_URL();
    [self openRealmForURL:url user:user immediatelyBlock:^{
        RLMSyncSession *session = [user sessionForURL:url];
        XCTAssertNotNil(session);
    }];
    // Check session existence after binding.
    RLMSyncSession *session = [user sessionForURL:url];
    XCTAssertNotNil(session);
}

/// A sync user should return nil when asked for a URL that doesn't exist.
- (void)testUserGetSessionForInvalidURL {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMSyncSession *badSession = [user sessionForURL:[NSURL URLWithString:@"realm://localhost:9080/noSuchRealm"]];
    XCTAssertNil(badSession);
}

/// A sync user should be able to successfully change their own password.
- (void)testUserChangePassword {
    NSString *userName = NSStringFromSelector(_cmd);
    NSString *firstPassword = @"a";
    NSString *secondPassword = @"b";
    // Successfully create user, change its password, log out,
    // then fail to change password again due to being logged out.
    {
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:userName password:firstPassword
                                                                       register:YES];
        RLMSyncUser *user = [self logInUserForCredentials:creds
                                                   server:[RLMObjectServerTests authServerURL]];
        XCTestExpectation *ex = [self expectationWithDescription:@"change password callback invoked"];
        [user changePassword:secondPassword completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [ex fulfill];
        }];
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
        [user logOut];
        ex = [self expectationWithDescription:@"change password callback invoked"];
        [user changePassword:@"fail" completion:^(NSError * _Nullable error) {
            XCTAssertNotNil(error);
            [ex fulfill];
        }];
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    }
    // Fail to log in with original password.
    {
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:userName password:firstPassword
                                                                       register:NO];

        XCTestExpectation *ex = [self expectationWithDescription:@"login callback invoked"];
        [RLMSyncUser logInWithCredentials:creds
                            authServerURL:[RLMObjectServerTests authServerURL]
                             onCompletion:^(RLMSyncUser *user, NSError *error) {
            XCTAssertNil(user);
            XCTAssertNotNil(error);
            XCTAssertEqual(error.domain, RLMSyncAuthErrorDomain);
            XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidCredential);
            XCTAssertNotNil(error.localizedDescription);

            [ex fulfill];
        }];
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    }
    // Successfully log in with new password.
    {
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:userName password:secondPassword
                                                                       register:NO];
        RLMSyncUser *user = [self logInUserForCredentials:creds server:[RLMObjectServerTests authServerURL]];
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(RLMSyncUser.currentUser, user);
        [user logOut];
        XCTAssertNil(RLMSyncUser.currentUser);
    }
}

/// A sync user should be able to successfully change their own password.
- (void)testOtherUserChangePassword {
    // Create admin user.
    NSString *adminUsername = [[NSUUID UUID] UUIDString];
    {
        NSURL *url = [RLMObjectServerTests authServerURL];
        RLMSyncUser *adminUser = [self makeAdminUser:adminUsername password:@"admin" server:url];
        [adminUser logOut];

        // Confirm that admin user has admin privileges.
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:adminUsername
                                                                       password:@"admin"
                                                                       register:NO];
        adminUser = [self logInUserForCredentials:creds server:url];
        XCTAssertTrue(adminUser.isAdmin);
        [adminUser logOut];
    }

    NSString *username = NSStringFromSelector(_cmd);
    NSString *firstPassword = @"a";
    NSString *secondPassword = @"b";
    NSString *userID = nil;
    // Successfully create user.
    {
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:username password:firstPassword
                                                                       register:YES];
        RLMSyncUser *user = [self logInUserForCredentials:creds server:[RLMObjectServerTests authServerURL]];
        userID = user.identity;
        [user logOut];
    }
    // Attempt change password from regular user.
    {
        NSString *regularUsername = [[NSUUID UUID] UUIDString];
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:regularUsername
                                                                       password:@"password"
                                                                       register:YES];
        RLMSyncUser *user = [self logInUserForCredentials:creds server:[RLMObjectServerTests authServerURL]];
        XCTestExpectation *ex = [self expectationWithDescription:@"change password callback invoked"];
        [user changePassword:secondPassword forUserID:userID completion:^(NSError * _Nullable error) {
            XCTAssertNotNil(error);
            [ex fulfill];
        }];
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
        [user logOut];
    }
    // Change password from admin user.
    {
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:adminUsername
                                                                       password:@"admin"
                                                                       register:NO];
        RLMSyncUser *user = [self logInUserForCredentials:creds server:[RLMObjectServerTests authServerURL]];
        XCTestExpectation *ex = [self expectationWithDescription:@"change password callback invoked"];
        [user changePassword:secondPassword forUserID:userID completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [ex fulfill];
        }];
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
        [user logOut];
    }
    // Fail to log in with original password.
    {
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:username
                                                                       password:firstPassword
                                                                       register:NO];

        XCTestExpectation *ex = [self expectationWithDescription:@"login callback invoked"];
        [RLMSyncUser logInWithCredentials:creds
                            authServerURL:[RLMObjectServerTests authServerURL]
                             onCompletion:^(RLMSyncUser *user, NSError *error) {
            XCTAssertNil(user);
            XCTAssertNotNil(error);
            XCTAssertEqual(error.domain, RLMSyncAuthErrorDomain);
            XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidCredential);
            XCTAssertNotNil(error.localizedDescription);

            [ex fulfill];
        }];
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    }
    // Successfully log in with new password.
    {
        RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:username password:secondPassword
                                                                       register:NO];
        RLMSyncUser *user = [self logInUserForCredentials:creds server:[RLMObjectServerTests authServerURL]];
        XCTAssertNotNil(user);
        [user logOut];
    }
}

/// A sync admin user should be able to retrieve information about other users.
- (void)testRetrieveUserInfo {
    NSString *nonAdminUsername = @"meela@realm.example.org";
    NSString *adminUsername = @"jyaku@realm.example.org";
    NSString *pw = @"p";
    NSURL *server = [RLMObjectServerTests authServerURL];

    // Create a non-admin user.
    RLMSyncCredentials *c1 = [RLMSyncCredentials credentialsWithUsername:nonAdminUsername password:pw register:YES];
    RLMSyncUser *nonAdminUser = [self logInUserForCredentials:c1 server:server];

    // Create an admin user.
    __unused RLMSyncUser *adminUser = [self makeAdminUser:adminUsername password:pw server:server];

    // Create another admin user.
    RLMSyncUser *userDoingLookups = [self makeAdminUser:[[NSUUID UUID] UUIDString] password:pw server:server];

    // Get the non-admin user's info.
    XCTestExpectation *ex1 = [self expectationWithDescription:@"should be able to get info about non-admin user"];
    [userDoingLookups retrieveInfoForUser:nonAdminUsername
                         identityProvider:RLMIdentityProviderUsernamePassword
                               completion:^(RLMSyncUserInfo *info, NSError *err) {
                                   XCTAssertNil(err);
                                   XCTAssertNotNil(info);
                                   XCTAssertEqualObjects(info.provider, RLMIdentityProviderUsernamePassword);
                                   XCTAssertEqualObjects(info.providerUserIdentity, nonAdminUsername);
                                   XCTAssertFalse(info.isAdmin);
                                   [ex1 fulfill];
                               }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    // Get the admin user's info.
    XCTestExpectation *ex2 = [self expectationWithDescription:@"should be able to get info about admin user"];
    [userDoingLookups retrieveInfoForUser:adminUsername
                         identityProvider:RLMIdentityProviderUsernamePassword
                               completion:^(RLMSyncUserInfo *info, NSError *err) {
                                   XCTAssertNil(err);
                                   XCTAssertNotNil(info);
                                   XCTAssertEqualObjects(info.provider, RLMIdentityProviderUsernamePassword);
                                   XCTAssertEqualObjects(info.providerUserIdentity, adminUsername);
                                   XCTAssertTrue(info.isAdmin);
                                   [ex2 fulfill];
                               }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    // Get invalid user's info.
    XCTestExpectation *ex3 = [self expectationWithDescription:@"should fail for non-existent user"];
    [userDoingLookups retrieveInfoForUser:@"invalid_user@realm.example.org"
                         identityProvider:RLMIdentityProviderUsernamePassword
                               completion:^(RLMSyncUserInfo *info, NSError *err) {
                                   XCTAssertNotNil(err);
                                   XCTAssertEqualObjects(err.domain, RLMSyncAuthErrorDomain);
                                   XCTAssertEqual(err.code, RLMSyncAuthErrorHTTPStatusCodeError);
                                   XCTAssertEqualObjects([err.userInfo objectForKey:@"statusCode"], @404);
                                   XCTAssertNil(info);
                                   [ex3 fulfill];
                               }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    // Get info using user without admin privileges.
    XCTestExpectation *ex4 = [self expectationWithDescription:@"should fail for user without admin privileges"];
    [nonAdminUser retrieveInfoForUser:adminUsername
                     identityProvider:RLMIdentityProviderUsernamePassword
                           completion:^(RLMSyncUserInfo *info, NSError *err) {
                               XCTAssertNotNil(err);
                               XCTAssertEqualObjects(err.domain, RLMSyncAuthErrorDomain);
                               XCTAssertEqual(err.code, RLMSyncAuthErrorHTTPStatusCodeError);
                               XCTAssertEqualObjects([err.userInfo objectForKey:@"statusCode"], @401);
                               XCTAssertNil(info);
                               [ex4 fulfill];
                           }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testUserExpirationCallback {
    NSString *username = NSStringFromSelector(_cmd);
    RLMSyncCredentials *credentials = [RLMSyncCredentials credentialsWithUsername:username
                                                                         password:@"a"
                                                                         register:YES];
    RLMSyncUser *user = [self logInUserForCredentials:credentials
                                               server:[RLMObjectServerTests authServerURL]];

    XCTestExpectation *ex = [self expectationWithDescription:@"callback should fire"];
    // Set a callback on the user
    __weak RLMSyncUser *weakUser = user;
    __block BOOL invoked = NO;
    user.errorHandler = ^(RLMSyncUser *u, NSError *error) {
        XCTAssertEqualObjects(u.identity, weakUser.identity);
        // Make sure we get the right error.
        XCTAssertEqualObjects(error.domain, RLMSyncAuthErrorDomain);
        XCTAssertEqual(error.code, RLMSyncAuthErrorInvalidCredential);
        invoked = YES;
        [ex fulfill];
    };

    // Screw up the token on the user using a debug API
    [self manuallySetRefreshTokenForUser:user value:@"not_a_real_refresh_token"];

    // Try to log in a Realm; this will cause our errorHandler block defined above to be fired.
    __attribute__((objc_precise_lifetime)) RLMRealm *r = [self immediatelyOpenRealmForURL:REALM_URL() user:user];
    if (!invoked) {
        [self waitForExpectationsWithTimeout:10.0 handler:nil];
    }
    XCTAssertTrue(user.state == RLMSyncUserStateLoggedOut);
}

#pragma mark - Basic Sync

/// It should be possible to successfully open a Realm configured for sync with an access token.
- (void)testOpenRealmWithAdminToken {
    // FIXME (tests): opening a Realm with the access token, then opening a Realm at the same virtual path
    // with normal credentials, causes Realms to fail to bind with a "bad virtual path" error.
    NSURL *adminTokenFileURL = [[RLMSyncTestCase rootRealmCocoaURL] URLByAppendingPathComponent:@"sync/admin_token.base64"];
    NSString *adminToken = [NSString stringWithContentsOfURL:adminTokenFileURL encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotNil(adminToken);
    RLMSyncCredentials *credentials = [RLMSyncCredentials credentialsWithAccessToken:adminToken identity:@"test"];
    XCTAssertNotNil(credentials);
    RLMSyncUser *user = [self logInUserForCredentials:credentials
                                               server:[RLMObjectServerTests authServerURL]];
    NSURL *url = [NSURL URLWithString:@"realm://localhost:9080/testSyncWithAdminToken"];
    RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
    c.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(realm.isEmpty);
}

/// It should be possible to successfully open a Realm configured for sync with a normal user.
- (void)testOpenRealmWithNormalCredentials {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    NSURL *url = REALM_URL();
    RLMRealm *realm = [self openRealmForURL:url user:user];
    XCTAssertTrue(realm.isEmpty);
}

/// If client B adds objects to a synced Realm, client A should see those objects.
- (void)testAddObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        CHECK_COUNT(0, SyncObject, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user realms:@[realm] realmURLs:@[url] expectedCounts:@[@3]];
    } else {
        // Add objects.
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// If client B deletes objects from a synced Realm, client A should see the effects of that deletion.
- (void)testDeleteObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        // Add objects.
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1", @"parent-2", @"parent-3"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(0, SyncObject, realm);
    } else {
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(0, SyncObject, realm);
    }
}

#pragma mark - Encryption

/// If client B encrypts its synced Realm, client A should be able to access that Realm with a different encryption key.
- (void)testEncryptedSyncedRealm {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    NSData *key = RLMGenerateKey();
    RLMRealm *realm = [self openRealmForURL:url user:user encryptionKey:key
                                 stopPolicy:RLMSyncStopPolicyAfterChangesUploaded immediatelyBlock:nil];
    if (self.isParent) {
        CHECK_COUNT(0, SyncObject, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user realms:@[realm] realmURLs:@[url] expectedCounts:@[@3]];
    } else {
        // Add objects.
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// If an encrypted synced Realm is re-opened with the wrong key, throw an exception.
- (void)testEncryptedSyncedRealmWrongKey {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    if (self.isParent) {
        NSString *path;
        @autoreleasepool {
            RLMRealm *realm = [self openRealmForURL:url user:user encryptionKey:RLMGenerateKey()
                                         stopPolicy:RLMSyncStopPolicyImmediately immediatelyBlock:nil];
            path = realm.configuration.pathOnDisk;
            CHECK_COUNT(0, SyncObject, realm);
            RLMRunChildAndWait();
            [self waitForDownloadsForUser:user realms:@[realm] realmURLs:@[url] expectedCounts:@[@3]];
        }
        RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
        c.fileURL = [NSURL fileURLWithPath:path];
        RLMAssertThrowsWithError([RLMRealm realmWithConfiguration:c error:nil],
                                 @"Unable to open a realm at path",
                                 RLMErrorFileAccess,
                                 @"not a realm file");
        c.encryptionKey = RLMGenerateKey();
        RLMAssertThrowsWithError([RLMRealm realmWithConfiguration:c error:nil],
                                 @"Unable to open a realm at path",
                                 RLMErrorFileAccess,
                                 @"Realm file decryption failed");
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user encryptionKey:RLMGenerateKey()
                                     stopPolicy:RLMSyncStopPolicyImmediately immediatelyBlock:nil];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    }
}

#pragma mark - Multiple Realm Sync

/// If a client opens multiple Realms, there should be one session object for each Realm that was opened.
- (void)testMultipleRealmsSessions {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    NSURL *urlC = CUSTOM_REALM_URL(@"c");
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    // Open three Realms.
    __attribute__((objc_precise_lifetime)) RLMRealm *realmealmA = [self openRealmForURL:urlA user:user];
    __attribute__((objc_precise_lifetime)) RLMRealm *realmealmB = [self openRealmForURL:urlB user:user];
    __attribute__((objc_precise_lifetime)) RLMRealm *realmealmC = [self openRealmForURL:urlC user:user];
    // Make sure there are three active sessions for the user.
    XCTAssert(user.allSessions.count == 3, @"Expected 3 sessions, but didn't get 3 sessions");
    XCTAssertNotNil([user sessionForURL:urlA], @"Expected to get a session for URL A");
    XCTAssertNotNil([user sessionForURL:urlB], @"Expected to get a session for URL B");
    XCTAssertNotNil([user sessionForURL:urlC], @"Expected to get a session for URL C");
    XCTAssertTrue([user sessionForURL:urlA].state == RLMSyncSessionStateActive, @"Expected active session for URL A");
    XCTAssertTrue([user sessionForURL:urlB].state == RLMSyncSessionStateActive, @"Expected active session for URL B");
    XCTAssertTrue([user sessionForURL:urlC].state == RLMSyncSessionStateActive, @"Expected active session for URL C");
}

/// A client should be able to open multiple Realms and add objects to each of them.
- (void)testMultipleRealmsAddObjects {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    NSURL *urlC = CUSTOM_REALM_URL(@"c");
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realmA = [self openRealmForURL:urlA user:user];
    RLMRealm *realmB = [self openRealmForURL:urlB user:user];
    RLMRealm *realmC = [self openRealmForURL:urlC user:user];
    if (self.isParent) {
        [self waitForDownloadsForUser:user url:urlA];
        [self waitForDownloadsForUser:user url:urlB];
        [self waitForDownloadsForUser:user url:urlC];
        CHECK_COUNT(0, SyncObject, realmA);
        CHECK_COUNT(0, SyncObject, realmB);
        CHECK_COUNT(0, SyncObject, realmC);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user
                               realms:@[realmA, realmB, realmC]
                            realmURLs:@[urlA, urlB, urlC]
                       expectedCounts:@[@3, @2, @5]];
    } else {
        // Add objects.
        [self addSyncObjectsToRealm:realmA
                       descriptions:@[@"child-A1", @"child-A2", @"child-A3"]];
        [self addSyncObjectsToRealm:realmB
                       descriptions:@[@"child-B1", @"child-B2"]];
        [self addSyncObjectsToRealm:realmC
                       descriptions:@[@"child-C1", @"child-C2", @"child-C3", @"child-C4", @"child-C5"]];
        [self waitForUploadsForUser:user url:urlA];
        [self waitForUploadsForUser:user url:urlB];
        [self waitForUploadsForUser:user url:urlC];
        CHECK_COUNT(3, SyncObject, realmA);
        CHECK_COUNT(2, SyncObject, realmB);
        CHECK_COUNT(5, SyncObject, realmC);
    }
}

/// A client should be able to open multiple Realms and delete objects from each of them.
- (void)testMultipleRealmsDeleteObjects {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    NSURL *urlC = CUSTOM_REALM_URL(@"c");
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realmA = [self openRealmForURL:urlA user:user];
    RLMRealm *realmB = [self openRealmForURL:urlB user:user];
    RLMRealm *realmC = [self openRealmForURL:urlC user:user];
    if (self.isParent) {
        [self waitForDownloadsForUser:user url:urlA];
        [self waitForDownloadsForUser:user url:urlB];
        [self waitForDownloadsForUser:user url:urlC];
        // Add objects.
        [self addSyncObjectsToRealm:realmA
                       descriptions:@[@"parent-A1", @"parent-A2", @"parent-A3", @"parent-A4"]];
        [self addSyncObjectsToRealm:realmB
                       descriptions:@[@"parent-B1", @"parent-B2", @"parent-B3", @"parent-B4", @"parent-B5"]];
        [self addSyncObjectsToRealm:realmC
                       descriptions:@[@"parent-C1", @"parent-C2"]];
        [self waitForUploadsForUser:user url:urlA];
        [self waitForUploadsForUser:user url:urlB];
        [self waitForUploadsForUser:user url:urlC];
        CHECK_COUNT(4, SyncObject, realmA);
        CHECK_COUNT(5, SyncObject, realmB);
        CHECK_COUNT(2, SyncObject, realmC);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user
                               realms:@[realmA, realmB, realmC]
                            realmURLs:@[urlA, urlB, urlC]
                       expectedCounts:@[@0, @0, @0]];
    } else {
        // Delete all the objects from the Realms.
        [self waitForDownloadsForUser:user url:urlA];
        [self waitForDownloadsForUser:user url:urlB];
        [self waitForDownloadsForUser:user url:urlC];
        CHECK_COUNT(4, SyncObject, realmA);
        CHECK_COUNT(5, SyncObject, realmB);
        CHECK_COUNT(2, SyncObject, realmC);
        [realmA beginWriteTransaction];
        [realmA deleteAllObjects];
        [realmA commitWriteTransaction];
        [realmB beginWriteTransaction];
        [realmB deleteAllObjects];
        [realmB commitWriteTransaction];
        [realmC beginWriteTransaction];
        [realmC deleteAllObjects];
        [realmC commitWriteTransaction];
        [self waitForUploadsForUser:user url:urlA];
        [self waitForUploadsForUser:user url:urlB];
        [self waitForUploadsForUser:user url:urlC];
        CHECK_COUNT(0, SyncObject, realmA);
        CHECK_COUNT(0, SyncObject, realmB);
        CHECK_COUNT(0, SyncObject, realmC);
    }
}

#pragma mark - Session Lifetime

/// When a session opened by a Realm goes out of scope, it should stay alive long enough to finish any waiting uploads.
- (void)testUploadChangesWhenRealmOutOfScope {
    const NSInteger OBJECT_COUNT = 10000;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    if (self.isParent) {
        // Open the Realm in an autorelease pool so that it is destroyed as soon as possible.
        @autoreleasepool {
            RLMRealm *realm = [self openRealmForURL:url user:user];
            [realm beginWriteTransaction];
            for (NSInteger i=0; i<OBJECT_COUNT; i++) {
                [realm addObject:[[SyncObject alloc] initWithValue:@[[NSString stringWithFormat:@"parent-%@", @(i+1)]]]];
            }
            [realm commitWriteTransaction];
            CHECK_COUNT(OBJECT_COUNT, SyncObject, realm);
        }
        // Run the sub-test. (Give the upload a bit of time to start.)
        // NOTE: This sleep should be fine because:
        // - There is currently no API that allows asynchronous coordination for waiting for an upload to begin.
        // - A delay longer than the specified one will not affect the outcome of the test.
        sleep(2);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Wait for download to complete.
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(OBJECT_COUNT, SyncObject, realm);
    }
}

#pragma mark - Logging Back In

/// A Realm that was opened before a user logged out should be able to resume uploading if the user logs back in.
- (void)testLogBackInSameRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];

    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, realm);
        [self waitForUploadsForUser:user url:url];
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-2", @"parent-3"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// A Realm that was opened before a user logged out should be able to resume downloading if the user logs back in.
- (void)testLogBackInSameRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];

    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, realm);
        [self waitForUploadsForUser:user url:url];
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    } else {
        [self waitForDownloadsForUser:user url:url];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// A Realm that was opened while a user was logged out should be able to start uploading if the user logs back in.
- (void)testLogBackInDeferredRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    if (self.isParent) {
        // Semaphore for knowing when the Realm is successfully opened for sync.
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
        [user logOut];
        // Open a Realm after the user's been logged out.
        [self primeSyncManagerWithSemaphore:sema];
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, realm);
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Wait for the Realm's session to be bound.
        WAIT_FOR_SEMAPHORE(sema, 30);
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-2", @"parent-3"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// A Realm that was opened while a user was logged out should be able to start downloading if the user logs back in.
- (void)testLogBackInDeferredRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    if (self.isParent) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        RLMRunChildAndWait();
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
        [user logOut];
        // Open a Realm after the user's been logged out.
        [self primeSyncManagerWithSemaphore:sema];
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, realm);
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Wait for the Realm's session to be bound.
        WAIT_FOR_SEMAPHORE(sema, 30);
        [self waitForDownloadsForUser:user realms:@[realm] realmURLs:@[url] expectedCounts:@[@4]];
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly upload changes.
- (void)testLogBackInOpenFirstTimePathUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForURL:url user:user];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(2, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Add objects.
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(2, SyncObject, realm);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly download changes.
- (void)testLogBackInOpenFirstTimePathDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Run the sub-test.
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(2, SyncObject, realm);
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Add objects.
        [self waitForDownloadsForUser:user url:url];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(2, SyncObject, realm);
    }
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly upload changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(1, SyncObject, realm);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Open the Realm again.
        realm = [self immediatelyOpenRealmForURL:url user:user];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        CHECK_COUNT(5, SyncObject, realm);
        [self waitForUploadsForUser:user url:url];
        RLMRunChildAndWait();
    } else {
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(5, SyncObject, realm);
    }
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly download changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        [self waitForUploadsForUser:user url:url];
        XCTAssert([SyncObject allObjectsInRealm:realm].count == 1, @"Expected 1 item");
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Run the sub-test.
        RLMRunChildAndWait();
        // Open the Realm again and get the items.
        realm = [self immediatelyOpenRealmForURL:url user:user];
        [self waitForDownloadsForUser:user realms:@[realm] realmURLs:@[url] expectedCounts:@[@5]];
    } else {
        // Add objects.
        [self waitForDownloadsForUser:user url:url];
        CHECK_COUNT(1, SyncObject, realm);
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(5, SyncObject, realm);
    }
}

#pragma mark - Client reset

/// Ensure that a client reset error is propagated up to the binding successfully.
- (void)testClientReset {
    NSURL *url = REALM_URL();
    NSString *sessionName = NSStringFromSelector(_cmd);
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:sessionName
                                                                                            register:true]
                                               server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForURL:url user:user];

    __block NSError *theError = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Waiting for error handler to be called..."];
    [RLMSyncManager sharedManager].errorHandler = ^void(NSError *error, RLMSyncSession *session) {
        // Make sure we're actually looking at the right session.
        XCTAssertTrue([[session.realmURL absoluteString] containsString:sessionName]);
        theError = error;
        [ex fulfill];
    };
    [user simulateClientResetErrorForSession:url];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertNotNil(theError);
    XCTAssertTrue(theError.code == RLMSyncErrorClientResetError);
    NSString *pathValue = [theError rlmSync_clientResetBackedUpRealmPath];
    XCTAssertNotNil(pathValue);
    // Sanity check the recovery path.
    XCTAssertTrue([pathValue containsString:@"io.realm.object-server-recovered-realms/recovered_realm"]);
    XCTAssertNotNil([theError rlmSync_clientResetBlock]);
}

/// Test manually initiating client reset.
- (void)testClientResetManualInitiation {
    NSURL *url = REALM_URL();
    NSString *sessionName = NSStringFromSelector(_cmd);
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:sessionName
                                                                                            register:true]
                                               server:[RLMObjectServerTests authServerURL]];
    __block NSError *theError = nil;
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForURL:url user:user];
        XCTestExpectation *ex = [self expectationWithDescription:@"Waiting for error handler to be called..."];
        [RLMSyncManager sharedManager].errorHandler = ^void(NSError *error, RLMSyncSession *session) {
            // Make sure we're actually looking at the right session.
            XCTAssertTrue([[session.realmURL absoluteString] containsString:sessionName]);
            theError = error;
            [ex fulfill];
        };
        [user simulateClientResetErrorForSession:url];
        [self waitForExpectationsWithTimeout:10 handler:nil];
        XCTAssertNotNil(theError);
    }
    // At this point the Realm should be invalidated and client reset should be possible.
    NSString *pathValue = [theError rlmSync_clientResetBackedUpRealmPath];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:pathValue]);
    [theError rlmSync_clientResetBlock]();
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:pathValue]);
}

#pragma mark - Progress Notifications

- (void)testStreamingDownloadNotifier {
    const NSInteger NUMBER_OF_BIG_OBJECTS = 2;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    __block NSInteger callCount = 0;
    __block NSUInteger transferred = 0;
    __block NSUInteger transferrable = 0;
    // Open the Realm
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        __block BOOL hasBeenFulfilled = NO;
        // Register a notifier.
        RLMSyncSession *session = [user sessionForURL:url];
        XCTAssertNotNil(session);
        XCTestExpectation *ex = [self expectationWithDescription:@"streaming-download-notifier"];
        RLMProgressNotificationToken *token = [session addProgressNotificationForDirection:RLMSyncProgressDirectionDownload
                                                                                      mode:RLMSyncProgressReportIndefinitely
                                                                                     block:^(NSUInteger xfr, NSUInteger xfb) {
            // Make sure the values are increasing, and update our stored copies.
            XCTAssert(xfr >= transferred);
            XCTAssert(xfb >= transferrable);
            transferred = xfr;
            transferrable = xfb;
            callCount++;
            if (transferrable > 0 && transferred >= transferrable && !hasBeenFulfilled) {
                [ex fulfill];
                hasBeenFulfilled = YES;
            }
        }];
        // Wait for the child process to upload everything.
        RLMRunChildAndWait();
        [self waitForExpectationsWithTimeout:10.0 handler:nil];
        [token stop];
        // The notifier should have been called at least twice: once at the beginning and at least once
        // to report progress.
        XCTAssert(callCount > 1);
        XCTAssert(transferred >= transferrable,
                  @"Transferred (%@) needs to be greater than or equal to transferrable (%@)",
                  @(transferred), @(transferrable));
    } else {
        // Write lots of data to the Realm, then wait for it to be uploaded.
        [realm beginWriteTransaction];
        for (NSInteger i=0; i<NUMBER_OF_BIG_OBJECTS; i++) {
            [realm addObject:[HugeSyncObject object]];
        }
        [realm commitWriteTransaction];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
    }
}

- (void)testStreamingUploadNotifier {
    const NSInteger NUMBER_OF_BIG_OBJECTS = 2;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    __block NSInteger callCount = 0;
    __block NSUInteger transferred = 0;
    __block NSUInteger transferrable = 0;
    __block BOOL hasBeenFulfilled = NO;
    // Open the Realm
    RLMRealm *realm = [self openRealmForURL:url user:user];

    // Register a notifier.
    RLMSyncSession *session = [user sessionForURL:url];
    XCTAssertNotNil(session);
    XCTestExpectation *ex = [self expectationWithDescription:@"streaming-upload-expectation"];
    RLMProgressNotificationToken *token = [session addProgressNotificationForDirection:RLMSyncProgressDirectionUpload
                                                                                  mode:RLMSyncProgressReportIndefinitely
                                                                                 block:^(NSUInteger xfr, NSUInteger xfb) {
                                                                                     // Make sure the values are
                                                                                     // increasing, and update our
                                                                                     // stored copies.
                                                                                     XCTAssert(xfr >= transferred);
                                                                                     XCTAssert(xfb >= transferrable);
                                                                                     transferred = xfr;
                                                                                     transferrable = xfb;
                                                                                     callCount++;
                                                                                     if (transferred > 0
                                                                                         && transferred >= transferrable
                                                                                         && !hasBeenFulfilled) {
                                                                                         [ex fulfill];
                                                                                         hasBeenFulfilled = YES;
                                                                                     }
                                                                                 }];
    // Upload lots of data
    [realm beginWriteTransaction];
    for (NSInteger i=0; i<NUMBER_OF_BIG_OBJECTS; i++) {
        [realm addObject:[HugeSyncObject object]];
    }
    [realm commitWriteTransaction];
    // Wait for upload to begin and finish
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [token stop];
    // The notifier should have been called at least twice: once at the beginning and at least once
    // to report progress.
    XCTAssert(callCount > 1);
    XCTAssert(transferred >= transferrable,
              @"Transferred (%@) needs to be greater than or equal to transferrable (%@)",
              @(transferred), @(transferrable));
}

#pragma mark - Download Realm

- (void)testDownloadRealm {
    const NSInteger NUMBER_OF_BIG_OBJECTS = 2;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (self.isParent) {
        // Wait for the child process to upload everything.
        RLMRunChildAndWait();
        XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
        RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
        RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
        c.syncConfiguration = syncConfig;
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:c.pathOnDisk isDirectory:nil]);
        [RLMRealm asyncOpenWithConfiguration:c
                               callbackQueue:dispatch_get_main_queue()
                                    callback:^(RLMRealm * _Nullable realm, NSError * _Nullable error) {
            XCTAssertNil(error);
            CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
            [ex fulfill];
        }];
        NSUInteger (^fileSize)(NSString *) = ^NSUInteger(NSString *path) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            if (attributes)
                return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];

            return 0;
        };
        NSUInteger sizeBefore = fileSize(c.pathOnDisk);
        @autoreleasepool {
            // We have partial transaction logs but no data
            XCTAssertGreaterThan(sizeBefore, 0U);
            XCTAssertTrue([[RLMRealm realmWithConfiguration:c error:nil] isEmpty]);
        }
        XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
        [self waitForExpectationsWithTimeout:10.0 handler:nil];
        XCTAssertGreaterThan(fileSize(c.pathOnDisk), sizeBefore);
        XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Write lots of data to the Realm, then wait for it to be uploaded.
        [realm beginWriteTransaction];
        for (NSInteger i=0; i<NUMBER_OF_BIG_OBJECTS; i++) {
            [realm addObject:[HugeSyncObject object]];
        }
        [realm commitWriteTransaction];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
    }
}

- (void)testDownloadAlreadyOpenRealm {
    const NSInteger NUMBER_OF_BIG_OBJECTS = 2;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (self.isParent) {
        // Wait for the child process to upload everything.
        RLMRunChildAndWait();
        XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
        XCTestExpectation *ex2 = [self expectationWithDescription:@"wait for downloads after asyncOpen"];
        RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
        RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
        c.syncConfiguration = syncConfig;
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:c.pathOnDisk isDirectory:nil]);
        RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];
        CHECK_COUNT(0, HugeSyncObject, realm);
        [RLMRealm asyncOpenWithConfiguration:c
                               callbackQueue:dispatch_get_main_queue()
                                    callback:^(RLMRealm * _Nullable realm, NSError * _Nullable error) {
            XCTAssertNil(error);
            // The big objects might take some time for the server to process,
            // so we may need to ask it a few times before it's ready.
            CHECK_COUNT_PENDING_DOWNLOAD_CUSTOM_EXPECTATION(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm, ex2);
            [ex fulfill];
        }];
        NSUInteger (^fileSize)(NSString *) = ^NSUInteger(NSString *path) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            if (attributes)
                return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];

            return 0;
        };
        NSUInteger sizeBefore = fileSize(c.pathOnDisk);
        XCTAssertGreaterThan(sizeBefore, 0U);
        XCTAssertNotNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
        [self waitForExpectationsWithTimeout:10.0 handler:nil];
        XCTAssertGreaterThan(fileSize(c.pathOnDisk), sizeBefore);
        XCTAssertNotNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Write lots of data to the Realm, then wait for it to be uploaded.
        [realm beginWriteTransaction];
        for (NSInteger i=0; i<NUMBER_OF_BIG_OBJECTS; i++) {
            [realm addObject:[HugeSyncObject object]];
        }
        [realm commitWriteTransaction];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
    }
}

- (void)testDownloadWhileOpeningRealm {
    const NSInteger NUMBER_OF_BIG_OBJECTS = 2;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (self.isParent) {
        // Wait for the child process to upload everything.
        RLMRunChildAndWait();
        XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
        RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
        RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
        c.syncConfiguration = syncConfig;
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:c.pathOnDisk isDirectory:nil]);
        [RLMRealm asyncOpenWithConfiguration:c
                               callbackQueue:dispatch_get_main_queue()
                                    callback:^(RLMRealm * _Nullable realm, NSError * _Nullable error) {
            XCTAssertNil(error);
            CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
            [ex fulfill];
        }];
        RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];
        CHECK_COUNT(0, HugeSyncObject, realm);
        XCTAssertNotNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
        [self waitForExpectationsWithTimeout:10.0 handler:nil];
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
        XCTAssertNotNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Write lots of data to the Realm, then wait for it to be uploaded.
        [realm beginWriteTransaction];
        for (NSInteger i=0; i<NUMBER_OF_BIG_OBJECTS; i++) {
            [realm addObject:[HugeSyncObject object]];
        }
        [realm commitWriteTransaction];
        [self waitForUploadsForUser:user url:url];
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
    }
}

#pragma mark - Permissions

/// Permission Realm reflects permissions for Realms
- (void)testPermission {
    NSString *userNameA = [NSStringFromSelector(_cmd) stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSString *userNameB = [NSStringFromSelector(_cmd) stringByAppendingString:@"_B"];
    RLMSyncUser *userB = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameB
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSError *error;
    RLMRealm *permissionRealm = [userA permissionRealmWithError:&error];
    XCTAssertNil(error, @"Error when opening permission Realm: %@", error);

    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission will be granted by the server"];
    RLMResults *r = [RLMSyncPermission objectsInRealm:permissionRealm where:@"userId = %@", userB.identity];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults *results,
                                                            __unused RLMCollectionChange *change,
                                                            __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermission *permission = results[0];
        XCTAssertEqualObjects(permission.userId, userB.identity);
        XCTAssertEqualObjects(permission.path, ([NSString stringWithFormat:@"/%@/%@", userA.identity, @"testPermission"]));
        XCTAssertEqual(permission.mayRead, YES);
        XCTAssertEqual(permission.mayWrite, NO);
        XCTAssertEqual(permission.mayManage, NO);

        [expectation fulfill];
    }];

    NSURL *url = REALM_URL();
    RLMRealm *realm = [self openRealmForURL:url user:userA];

    NSString *realmURL = realm.configuration.syncConfiguration.realmURL.absoluteString;
    RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange permissionChangeWithRealmURL:realmURL
                                                                                               userID:userB.identity
                                                                                                 read:@YES
                                                                                                write:@NO
                                                                                               manage:@NO];

    RLMRealm *managementRealm = [userA managementRealmWithError:&error];
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionChange];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission change object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
}

/// Grant/revoke access a user's Realm to another user. Another user has no access permission by default.
- (void)testPermissionChange {
    NSString *userNameA = [NSStringFromSelector(_cmd) stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    NSString *userNameB = [NSStringFromSelector(_cmd) stringByAppendingString:@"_B"];
    RLMSyncUser *userB = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameB
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSURL *url = REALM_URL();
    RLMRealm *realm = [self openRealmForURL:url user:userA];

    NSArray *administrativePermissions = @[
                                           @[@YES, @YES, @YES],
                                           @[@NO, @YES, @YES],
                                           @[@YES, @NO, @YES],
                                           @[@NO, @NO, @YES]
                                           ];
    NSArray *readWritePermissions = @[
                                      @[@YES, @YES, @NO]
                                      ];
    NSArray *readOnlyPermissions = @[
                                     @[@YES, @NO, @NO]
                                     ];
    NSArray *noAccessPermissions = @[
                                     @[@NO, @NO, @NO],
                                     @[[NSNull null], [NSNull null], [NSNull null]]
                                     ];

    NSArray *permissions = @[administrativePermissions,
                             readWritePermissions,
                             readOnlyPermissions,
                             noAccessPermissions];
    NSArray *statusMessages = @[@"administrative access",
                                @"read-write access",
                                @"read-only access",
                                @"no access"];

    [permissions enumerateObjectsUsingBlock:^(id  _Nonnull accessPermissions, NSUInteger idx, BOOL * _Nonnull stop __unused) {
        for (NSArray *permissions in accessPermissions) {
            NSNumber<RLMBool> *mayRead = permissions[0] == [NSNull null] ? nil : permissions[0];
            NSNumber<RLMBool> *mayWrite = permissions[1] == [NSNull null] ? nil : permissions[1];
            NSNumber<RLMBool> *mayManage = permissions[2] == [NSNull null] ? nil : permissions[2];
            NSString *realmURL = realm.configuration.syncConfiguration.realmURL.absoluteString;
            RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange permissionChangeWithRealmURL:realmURL
                                                                                                       userID:userB.identity
                                                                                                         read:mayRead
                                                                                                        write:mayWrite
                                                                                                      manage:mayManage];
            [self verifyChangePermission:permissionChange statusMessage:statusMessages[idx] owner:userA];
        }
    }];
}

/// Grant/revoke access a user's Realm to every users.
- (void)testPermissionChangeForRealm {
    NSString *userNameA = [NSStringFromSelector(_cmd) stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSURL *url = REALM_URL();
    RLMRealm *realm = [self openRealmForURL:url user:userA];

    NSArray *administrativePermissions = @[
                                           @[@YES, @YES, @YES],
                                           @[@NO, @YES, @YES],
                                           @[@YES, @NO, @YES],
                                           @[@NO, @NO, @YES]
                                           ];
    NSArray *readWritePermissions = @[
                                      @[@YES, @YES, @NO]
                                      ];
    NSArray *readOnlyPermissions = @[
                                     @[@YES, @NO, @NO]
                                     ];
    NSArray *noAccessPermissions = @[
                                     @[@NO, @NO, @NO],
                                     @[[NSNull null], [NSNull null], [NSNull null]]
                                     ];

    NSArray *permissions = @[administrativePermissions,
                             readWritePermissions,
                             readOnlyPermissions,
                             noAccessPermissions];
    NSArray *statusMessages = @[@"administrative access",
                                @"read-write access",
                                @"read-only access",
                                @"no access"];

    [permissions enumerateObjectsUsingBlock:^(id  _Nonnull accessPermissions, NSUInteger idx, BOOL * _Nonnull stop __unused) {
        for (NSArray *permissions in accessPermissions) {
            NSNumber<RLMBool> *mayRead = permissions[0] == [NSNull null] ? nil : permissions[0];
            NSNumber<RLMBool> *mayWrite = permissions[1] == [NSNull null] ? nil : permissions[1];
            NSNumber<RLMBool> *mayManage = permissions[2] == [NSNull null] ? nil : permissions[2];
            NSString *realmURL = realm.configuration.syncConfiguration.realmURL.absoluteString;
            RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange permissionChangeWithRealmURL:realmURL
                                                                                                   userID:@"*"
                                                                                                         read:mayRead
                                                                                                        write:mayWrite
                                                                                                       manage:mayManage];
            [self verifyChangePermission:permissionChange statusMessage:statusMessages[idx] owner:userA];
        }
    }];
}

/// Grant/revoke access user's all Realms to another user.
- (void)testPermissionChangeForUser {
    NSString *userNameA = [NSStringFromSelector(_cmd) stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSURL *url = REALM_URL();
    __unused RLMRealm *realm = [self openRealmForURL:url user:userA];

    NSString *userNameB = [NSStringFromSelector(_cmd) stringByAppendingString:@"_B"];
    RLMSyncUser *userB = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameB
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSArray *administrativePermissions = @[
                                           @[@YES, @YES, @YES],
                                           @[@NO, @YES, @YES],
                                           @[@YES, @NO, @YES],
                                           @[@NO, @NO, @YES]
                                           ];
    NSArray *readWritePermissions = @[
                                      @[@YES, @YES, @NO]
                                      ];
    NSArray *readOnlyPermissions = @[
                                     @[@YES, @NO, @NO]
                                     ];
    NSArray *noAccessPermissions = @[
                                     @[@NO, @NO, @NO],
                                     @[[NSNull null], [NSNull null], [NSNull null]]
                                     ];

    NSArray *permissions = @[administrativePermissions,
                             readWritePermissions,
                             readOnlyPermissions,
                             noAccessPermissions];
    NSArray *statusMessages = @[@"administrative access",
                                @"read-write access",
                                @"read-only access",
                                @"no access"];

    [permissions enumerateObjectsUsingBlock:^(id  _Nonnull accessPermissions, NSUInteger idx, BOOL * _Nonnull stop __unused) {
        for (NSArray *permissions in accessPermissions) {
            NSNumber<RLMBool> *mayRead = permissions[0] == [NSNull null] ? nil : permissions[0];
            NSNumber<RLMBool> *mayWrite = permissions[1] == [NSNull null] ? nil : permissions[1];
            NSNumber<RLMBool> *mayManage = permissions[2] == [NSNull null] ? nil : permissions[2];
            RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange permissionChangeWithRealmURL:@"*"
                                                                                                   userID:userB.identity
                                                                                                         read:mayRead
                                                                                                        write:mayWrite
                                                                                                       manage:mayManage];
            [self verifyChangePermission:permissionChange statusMessage:statusMessages[idx] owner:userA];
        }
    }];
}

- (void)waitForPermissionChange:(RLMSyncPermissionChange *)change inRealm:(RLMRealm *)realm
                validationBlock:(void (^)(RLMSyncPermissionChange *))block {
    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission will be granted by the server"];
    RLMResults *r = [RLMSyncPermissionChange objectsInRealm:realm where:@"id = %@", change.id];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults *results,
                                                            __unused RLMCollectionChange *change,
                                                            __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermissionChange *permissionChange = results[0];
        if (permissionChange.statusCode) {
            block(permissionChange);
            [expectation fulfill];
        }
    }];

    NSError *error = nil;
    [realm transactionWithBlock:^{
        [realm addObject:change];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission change object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
}

- (void)verifyChangePermission:(RLMSyncPermissionChange *)permissionChange statusMessage:(NSString *)message owner:(RLMSyncUser *)owner {
    RLMRealm *managementRealm = [owner managementRealmWithError:nil];
    [self waitForPermissionChange:permissionChange inRealm:managementRealm validationBlock:^(RLMSyncPermissionChange *change) {
        XCTAssertEqual(change.status, RLMSyncManagementObjectStatusSuccess);
        XCTAssertTrue([change.statusMessage rangeOfString:message].location != NSNotFound);
    }];
}

/// Changing unowned Realm permission should fail
- (void)testPermissionChangeErrorByUnownedRealm {
    NSString *userNameA = [NSStringFromSelector(_cmd) stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    NSString *userNameB = [NSStringFromSelector(_cmd) stringByAppendingString:@"_B"];
    RLMSyncUser *userB = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameB
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"realm://localhost:9080/~/%@", userNameB]];
    NSError *error = nil;
    RLMRealm *realm = [self openRealmForURL:url user:userB];

    RLMRealm *managementRealm = [userA managementRealmWithError:&error];
    XCTAssertNotNil(managementRealm);
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    NSString *realmURL = realm.configuration.syncConfiguration.realmURL.absoluteString;

    {
        RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange permissionChangeWithRealmURL:realmURL
                                                                                                   userID:userB.identity
                                                                                                     read:@YES
                                                                                                    write:@YES
                                                                                                   manage:@NO];
        [self waitForPermissionChange:permissionChange inRealm:managementRealm validationBlock:^(RLMSyncPermissionChange *change) {
            XCTAssertEqual(change.status, RLMSyncManagementObjectStatusError);
        }];
    }

    {
        RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange permissionChangeWithRealmURL:realmURL
                                                                                                   userID:@"*"
                                                                                                     read:@YES
                                                                                                    write:@YES
                                                                                                   manage:@NO];
        [self waitForPermissionChange:permissionChange inRealm:managementRealm validationBlock:^(RLMSyncPermissionChange *change) {
            XCTAssertEqual(change.status, RLMSyncManagementObjectStatusError);
        }];
    }
}

/// Get a token which can be used to offer the permissions as defined
- (void)testPermissionOffer {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];
    NSString *realmURL = realm.configuration.syncConfiguration.realmURL.absoluteString;

    RLMSyncPermissionOffer *permissionOffer = [RLMSyncPermissionOffer permissionOfferWithRealmURL:realmURL
                                                                                        expiresAt:[NSDate dateWithTimeIntervalSinceNow:30 * 24 * 60 * 60]
                                                                                             read:YES
                                                                                            write:YES
                                                                                           manage:NO];
    NSError *error = nil;
    RLMRealm *managementRealm = [user managementRealmWithError:&error];
    XCTAssertNotNil(managementRealm);
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission offer will be processed by the server"];
    RLMResults *r = [RLMSyncPermissionOffer objectsInRealm:managementRealm where:@"id = %@", permissionOffer.id];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults *results,
                                                            __unused RLMCollectionChange *change,
                                                            __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermissionOffer *permissionOffer = results[0];
        if (permissionOffer.statusCode) {
            XCTAssertEqual(permissionOffer.status, RLMSyncManagementObjectStatusSuccess);
            XCTAssertNotNil(permissionOffer.token);

            [expectation fulfill];
        }
    }];

    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionOffer];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission offer object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
}

/// Failed to process a permission offer object due to the offer expired
- (void)testPermissionOfferIsExpired {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];
    NSString *realmURL = realm.configuration.syncConfiguration.realmURL.absoluteString;

    RLMSyncPermissionOffer *permissionOffer = [RLMSyncPermissionOffer permissionOfferWithRealmURL:realmURL
                                                                                        expiresAt:[NSDate dateWithTimeIntervalSinceNow:-30 * 24 * 60 * 60]
                                                                                             read:YES
                                                                                            write:YES
                                                                                           manage:NO];
    NSError *error = nil;
    RLMRealm *managementRealm = [user managementRealmWithError:&error];
    XCTAssertNotNil(managementRealm);
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission offer will be processed by the server"];
    RLMResults *r = [RLMSyncPermissionOffer objectsInRealm:managementRealm where:@"id = %@", permissionOffer.id];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults *results,
                                                            __unused RLMCollectionChange *change,
                                                            __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermissionOffer *permissionOffer = results[0];
        if (permissionOffer.statusCode) {
            XCTAssertEqual(permissionOffer.status, RLMSyncManagementObjectStatusError);
            XCTAssertEqualObjects(permissionOffer.statusMessage, @"The permission offer is expired.");
            XCTAssertNil(permissionOffer.token);

            [expectation fulfill];
        }
    }];

    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionOffer];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission offer object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
}

/// Get a permission offer token, then permission offer response will be processed, then open another user's Realm file
- (void)testPermissionOfferResponse {
    NSString *userNameA = [NSStringFromSelector(_cmd) stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"realm://localhost:9080/~/%@", userNameA]];
    NSError *error = nil;
    RLMRealm *realm = [self openRealmForURL:url user:userA];

    RLMRealm *managementRealm = [userA managementRealmWithError:&error];
    XCTAssertNotNil(managementRealm);
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    NSString *realmURL = realm.configuration.syncConfiguration.realmURL.absoluteString;

    RLMSyncPermissionOffer *permissionOffer = [RLMSyncPermissionOffer permissionOfferWithRealmURL:realmURL
                                                                                        expiresAt:[NSDate dateWithTimeIntervalSinceNow:30 * 24 * 60 * 60]
                                                                                             read:YES
                                                                                            write:YES
                                                                                           manage:NO];
    __block NSString *permissionToken = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission offer will be processed by the server"];
    RLMResults *r = [RLMSyncPermissionOffer objectsInRealm:managementRealm where:@"id = %@", permissionOffer.id];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults *results,
                                                            __unused RLMCollectionChange *change,
                                                            __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermissionOffer *permissionOffer = results[0];
        if (permissionOffer.statusCode) {
            XCTAssertEqual(permissionOffer.status, RLMSyncManagementObjectStatusSuccess);
            XCTAssertNotNil(permissionOffer.token);

            permissionToken = permissionOffer.token;
            [expectation fulfill];
        }
    }];

    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionOffer];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission offer object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];

    NSString *userNameB = [NSStringFromSelector(_cmd) stringByAppendingString:@"_B"];
    RLMSyncUser *userB = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameB
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    managementRealm = [userB managementRealmWithError:&error];
    XCTAssertNotNil(managementRealm);
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    __block NSString *responseRealmUrl = nil;

    RLMSyncPermissionOfferResponse *permissionOfferResponse = [RLMSyncPermissionOfferResponse
                                                               permissionOfferResponseWithToken:permissionToken];

    expectation = [self expectationWithDescription:@"A new permission offer response will be processed by the server"];
    r = [RLMSyncPermissionOfferResponse objectsInRealm:managementRealm where:@"id = %@", permissionOfferResponse.id];
    token = [r addNotificationBlock:^(RLMResults *results,
                                      __unused RLMCollectionChange *change,
                                      __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermissionOfferResponse *permissionOfferResponse = results[0];
        if (permissionOfferResponse.statusCode) {
            XCTAssertEqual(permissionOfferResponse.status, RLMSyncManagementObjectStatusSuccess);
            XCTAssertEqualObjects((permissionOfferResponse.realmUrl),
                                  ([NSString stringWithFormat:@"realm://localhost:9080/%@/%@", userA.identity, userNameA]));

            responseRealmUrl = permissionOfferResponse.realmUrl;

            [expectation fulfill];
        }
    }];

    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionOfferResponse];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission offer response object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];

    XCTAssertNotNil([self openRealmForURL:[NSURL URLWithString:responseRealmUrl] user:userB]);
}

/// Failed to process a permission offer response object due to `token` is invalid
- (void)testPermissionOfferResponseInvalidToken {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    RLMSyncPermissionOfferResponse *permissionOfferResponse = [RLMSyncPermissionOfferResponse permissionOfferResponseWithToken:@"invalid token"];

    NSError *error = nil;
    RLMRealm *managementRealm = [user managementRealmWithError:&error];
    XCTAssertNotNil(managementRealm);
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission offer response will be processed by the server"];
    RLMResults *r = [RLMSyncPermissionOfferResponse objectsInRealm:managementRealm where:@"id = %@", permissionOfferResponse.id];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults *results,
                                                            __unused RLMCollectionChange *change,
                                                            __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermissionOffer *permissionOffer = results[0];
        if (permissionOffer.statusCode) {
            XCTAssertEqual(permissionOffer.status, RLMSyncManagementObjectStatusError);
            XCTAssertNil(permissionOffer.realmUrl);

            [expectation fulfill];
        }
    }];

    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionOfferResponse];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission offer response object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
}

/// Failed to process a permission offer response object due to `token` does not exist
- (void)testPermissionOfferResponseTokenNotExist {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    NSString *fakeToken = @"00000000000000000000000000000000:00000000-0000-0000-0000-000000000000";
    RLMSyncPermissionOfferResponse *permissionOfferResponse = [RLMSyncPermissionOfferResponse permissionOfferResponseWithToken:fakeToken];

    NSError *error = nil;
    RLMRealm *managementRealm = [user managementRealmWithError:&error];
    XCTAssertNotNil(managementRealm);
    XCTAssertNil(error, @"Error when opening management Realm: %@", error);

    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission offer response will be processed by the server"];
    RLMResults *r = [RLMSyncPermissionOfferResponse objectsInRealm:managementRealm where:@"id = %@", permissionOfferResponse.id];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults *results,
                                                            __unused RLMCollectionChange *change,
                                                            __unused NSError *error) {
        if (results.count == 0) {
            return;
        }

        RLMSyncPermissionOffer *permissionOffer = results[0];
        if (permissionOffer.statusCode) {
            XCTAssertEqual(permissionOffer.status, RLMSyncManagementObjectStatusError);
            XCTAssertNil(permissionOffer.realmUrl);

            [expectation fulfill];
        }
    }];

    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionOfferResponse];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission offer response object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
}

#pragma mark - Validation

- (void)testCompactOnLaunchCannotBeSet {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:REALM_URL()];

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.syncConfiguration = syncConfig;
    RLMAssertThrowsWithReasonMatching(configuration.shouldCompactOnLaunch = ^BOOL(NSUInteger, NSUInteger){ return NO; },
                                      @"Cannot set `shouldCompactOnLaunch` when `syncConfiguration` is set.");
}

@end
