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

#import "RLMRealm+Sync.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealmUtil.hpp"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSyncUtil_Private.h"
#import "shared_realm.hpp"
#import "RLMApp_Private.hpp"
#import "RLMAppCredentials.h"

#pragma mark - Test objects

@interface PartialSyncObjectA : RLMObject
@property NSInteger number;
@property NSString *string;
+ (instancetype)objectWithNumber:(NSInteger)number string:(NSString *)string;
@end

@interface PartialSyncObjectB : RLMObject
@property NSInteger number;
@property NSString *firstString;
@property NSString *secondString;
+ (instancetype)objectWithNumber:(NSInteger)number firstString:(NSString *)first secondString:(NSString *)second;
@end

@implementation PartialSyncObjectA
+ (instancetype)objectWithNumber:(NSInteger)number string:(NSString *)string {
    PartialSyncObjectA *object = [[PartialSyncObjectA alloc] init];
    object.number = number;
    object.string = string;
    return object;
}
@end

@implementation PartialSyncObjectB
+ (instancetype)objectWithNumber:(NSInteger)number firstString:(NSString *)first secondString:(NSString *)second {
    PartialSyncObjectB *object = [[PartialSyncObjectB alloc] init];
    object.number = number;
    object.firstString = first;
    object.secondString = second;
    return object;
}
@end

@interface RLMObjectServerTests : RLMSyncTestCase
@end

@implementation RLMObjectServerTests

#pragma mark - App Tests

- (void)testAppInit {
    RLMAppConfiguration *config = [[RLMAppConfiguration alloc] initWithBaseURL:@"base_url"
                                                                     transport:nil
                                                                  localAppName:@"app_name"
                                                               localAppVersion:@"app_version"
                                                       defaultRequestTimeoutMS:42.0];

    RLMApp *app = [RLMApp app:@"<app-id>" configuration:config];

    // TODO: Get config and compare values
}

#pragma mark - Authentication and Tokens


- (void)testAnonymousAuthentication {
    RLMApp *app = [RLMApp app:@"translate-utwuv" configuration:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"should login anonymously"];
    __block RLMSyncUser *syncUser;
    [app loginWithCredential:[RLMAppCredentials anonymousCredentials] completionHandler:^(RLMSyncUser * _Nullable user, NSError * _Nullable error) {
        XCTAssert(!error);
        XCTAssert(user);
        syncUser = user;
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    // TODO: Fix test. Current User is not actually being set in OS
//    RLMSyncUser *currentUser = [app currentUser];
//    XCTAssert([currentUser.identity isEqualTo: syncUser.identity]);
//    XCTAssert([currentUser.refreshToken isEqualTo: syncUser.refreshToken]);
//    XCTAssert([currentUser.accessToken isEqualTo: syncUser.accessToken]);
}

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
}

/// An invalid username/password credential should not be able to log in a user and a corresponding error should be generated.
- (void)testInvalidPasswordAuthentication {
    [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd) register:YES]
                          server:[RLMSyncTestCase authServerURL]];

    RLMAppCredentials *credentials = [RLMAppCredentials credentialsWithUsername:NSStringFromSelector(_cmd)
                                                                       password:@"INVALID_PASSWORD"];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// A non-existsing user should not be able to log in and a corresponding error should be generated.
- (void)testNonExistingUsernameAuthentication {
    RLMAppCredentials *credentials = [RLMAppCredentials credentialsWithUsername:@"INVALID_USERNAME"
                                                                       password:@"INVALID_PASSWORD"];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Registering a user with existing username should return corresponding error.
- (void)testExistingUsernameRegistration {
    RLMAppCredentials *credentials = [RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                           register:YES];

    [self logInUserForCredentials:credentials server:[RLMSyncTestCase authServerURL]];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Errors reported in RLMSyncManager.errorHandler shouldn't contain sync error domain errors as underlying error
- (void)testSyncErrorHandlerErrorDomain {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    XCTAssertNotNil(user);

    NSURL *realmURL = [NSURL URLWithString:@"realm://127.0.0.1:9080/THE_PATH_USER_DONT_HAVE_ACCESS_TO/test"];

    RLMRealmConfiguration *c = [user configurationWithURL:realmURL];

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
        if (refreshCount++ == 3) { // arbitrary choice; refreshes every second
            [ex fulfill];
        }
    }];
    // Open the Realm.
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests
                                                       basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                       register:true]
                                               server:[RLMObjectServerTests authServerURL]];
    __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForURL:url user:user];
    ex = [self expectationWithDescription:@"Timer fired"];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue(errorCount == 0);
    XCTAssertTrue(refreshCount >= 4);
}

- (void)testLoginConnectionTimeoutFromManager {
    // First create the user, talking directly to ROS
    NSString *userName = NSStringFromSelector(_cmd);
    @autoreleasepool {
        RLMAppCredentials *credentials = [RLMObjectServerTests basicCredentialsWithName:userName
                                                                               register:YES];
        RLMSyncUser *user = [self logInUserForCredentials:credentials
                                                   server:[NSURL URLWithString:@"http://127.0.0.1:9080"]];
        // FIXME: [realmapp] This should use the new logout
    }

    RLMSyncTimeoutOptions *timeoutOptions = [RLMSyncTimeoutOptions new];

    // 9082 is a proxy which delays responding to requests
    NSURL *authURL = [NSURL URLWithString:@"http://127.0.0.1:9082"];

    // Login attempt should time out
    timeoutOptions.connectTimeout = 1000.0;
    RLMSyncManager.sharedManager.timeoutOptions = timeoutOptions;

    RLMAppCredentials *credentials = [RLMObjectServerTests basicCredentialsWithName:userName
                                                                           register:NO];
    XCTestExpectation *ex = [self expectationWithDescription:@"Login should time out"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Login attempt should succeeed
    timeoutOptions.connectTimeout = 3000.0;
    RLMSyncManager.sharedManager.timeoutOptions = timeoutOptions;

    ex = [self expectationWithDescription:@"Login should succeed"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testLoginConnectionTimeoutDirect {
    // First create the user, talking directly to ROS
    NSString *userName = NSStringFromSelector(_cmd);
    @autoreleasepool {
        RLMAppCredentials *credentials = [RLMObjectServerTests basicCredentialsWithName:userName
                                                                               register:YES];
        RLMSyncUser *user = [self logInUserForCredentials:credentials
                                                   server:[NSURL URLWithString:@"http://127.0.0.1:9080"]];
        // FIXME: [realmapp] This should use the new logout
    }

    // 9082 is a proxy which delays responding to requests
    NSURL *authURL = [NSURL URLWithString:@"http://127.0.0.1:9082"];

    // Login attempt should time out
    RLMAppCredentials *credentials = [RLMObjectServerTests basicCredentialsWithName:userName
                                                                           register:NO];
    XCTestExpectation *ex = [self expectationWithDescription:@"Login should time out"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Login attempt should succeeed
    ex = [self expectationWithDescription:@"Login should succeed"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Users

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
    RLMSyncSession *badSession = [user sessionForURL:[NSURL URLWithString:@"realm://127.0.0.1:9080/noSuchRealm"]];
    XCTAssertNil(badSession);
}

/// The login queue argument should be respected.
- (void)testLoginQueueForSuccessfulLogin {
    // Make global queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    RLMAppCredentials *c1 = [RLMAppCredentials credentialsWithUsername:[[NSUUID UUID] UUIDString]
                                                                password:@"p"];
    XCTestExpectation *ex1 = [self expectationWithDescription:@"User logs in successfully on background queue"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    RLMAppCredentials *c2 = [RLMAppCredentials credentialsWithUsername:[[NSUUID UUID] UUIDString]
                                                                password:@"p"];
    XCTestExpectation *ex2 = [self expectationWithDescription:@"User logs in successfully on main queue"];

    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// The login queue argument should be respected.
- (void)testLoginQueueForFailedLogin {
    // Make global queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    RLMAppCredentials *c1 = [RLMAppCredentials credentialsWithUsername:[[NSUUID UUID] UUIDString]
                                                                password:@"p"];
    XCTestExpectation *ex1 = [self expectationWithDescription:@"Error returned on background queue"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    RLMAppCredentials *c2 = [RLMAppCredentials credentialsWithUsername:[[NSUUID UUID] UUIDString]
                                                                password:@"p"];
    XCTestExpectation *ex2 = [self expectationWithDescription:@"Error returned on main queue"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testUserExpirationCallback {
    NSString *username = NSStringFromSelector(_cmd);
    RLMAppCredentials *credentials = [RLMAppCredentials credentialsWithUsername:username
                                                                         password:@"a"];
    RLMSyncUser *user = [self logInUserForCredentials:credentials
                                               server:[RLMObjectServerTests authServerURL]];

    XCTestExpectation *ex = [self expectationWithDescription:@"callback should fire"];
    // Set a callback on the user
    __weak RLMSyncUser *weakUser = user;
    user.errorHandler = ^(RLMSyncUser *u, NSError *error) {
        XCTAssertEqualObjects(u.identity, weakUser.identity);
        // Make sure we get the right error.
        XCTAssertEqualObjects(error.domain, RLMSyncAuthErrorDomain);
        XCTAssertEqual(error.code, RLMSyncAuthErrorAccessDeniedOrInvalidPath);
        [ex fulfill];
    };

    // Screw up the token on the user using a debug API
    [self manuallySetRefreshTokenForUser:user value:@"not_a_real_refresh_token"];

    // Try to log in a Realm; this will cause our errorHandler block defined above to be fired.
    __attribute__((objc_precise_lifetime)) RLMRealm *r = [self immediatelyOpenRealmForURL:REALM_URL() user:user];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue(user.state == RLMSyncUserStateLoggedOut);
}

#pragma mark - Basic Sync

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
        [self waitForUploadsForRealm:realm];
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
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(0, SyncObject, realm);
    } else {
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(3, SyncObject, realm);
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
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
        [self waitForUploadsForRealm:realm];
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
                                 @"invalid mnemonic");
        c.encryptionKey = RLMGenerateKey();
        RLMAssertThrowsWithError([RLMRealm realmWithConfiguration:c error:nil],
                                 @"Unable to open a realm at path",
                                 RLMErrorFileAccess,
                                 @"Realm file decryption failed");
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user encryptionKey:RLMGenerateKey()
                                     stopPolicy:RLMSyncStopPolicyImmediately immediatelyBlock:nil];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3"]];
        [self waitForUploadsForRealm:realm];
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
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
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
        [self waitForUploadsForRealm:realmA];
        [self waitForUploadsForRealm:realmB];
        [self waitForUploadsForRealm:realmC];
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
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
        // Add objects.
        [self addSyncObjectsToRealm:realmA
                       descriptions:@[@"parent-A1", @"parent-A2", @"parent-A3", @"parent-A4"]];
        [self addSyncObjectsToRealm:realmB
                       descriptions:@[@"parent-B1", @"parent-B2", @"parent-B3", @"parent-B4", @"parent-B5"]];
        [self addSyncObjectsToRealm:realmC
                       descriptions:@[@"parent-C1", @"parent-C2"]];
        [self waitForUploadsForRealm:realmA];
        [self waitForUploadsForRealm:realmB];
        [self waitForUploadsForRealm:realmC];
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
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
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
        [self waitForUploadsForRealm:realmA];
        [self waitForUploadsForRealm:realmB];
        [self waitForUploadsForRealm:realmC];
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
        [self waitForDownloadsForRealm:realm];
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
        [self waitForUploadsForRealm:realm];
        // Log out the user.
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-2", @"parent-3"]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        [self waitForDownloadsForRealm:realm];
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
        [self waitForUploadsForRealm:realm];
        // Log out the user.
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(3, SyncObject, realm);
    } else {
        [self waitForDownloadsForRealm:realm];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        [self waitForUploadsForRealm:realm];
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
        RLMRealmConfiguration *config = [user configurationWithURL:url];
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
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
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self waitForDownloadsForRealm:realm];
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
        RLMRealmConfiguration *config = [user configurationWithURL:url];
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
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
        [self waitForUploadsForRealm:realm];
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
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForURL:url user:user];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(2, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Add objects.
        [self waitForDownloadsForRealm:realm];
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
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Run the sub-test.
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(2, SyncObject, realm);
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Add objects.
        [self waitForDownloadsForRealm:realm];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        [self waitForUploadsForRealm:realm];
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
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, SyncObject, realm);
        // Log out the user.
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Open the Realm again.
        realm = [self immediatelyOpenRealmForURL:url user:user];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        CHECK_COUNT(5, SyncObject, realm);
        [self waitForUploadsForRealm:realm];
        RLMRunChildAndWait();
    } else {
        [self waitForDownloadsForRealm:realm];
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
        [self waitForUploadsForRealm:realm];
        XCTAssert([SyncObject allObjectsInRealm:realm].count == 1, @"Expected 1 item");
        // Log out the user.
        // FIXME: [realmapp] Use new logout
        REALM_UNREACHABLE();
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
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(1, SyncObject, realm);
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(5, SyncObject, realm);
    }
}

#pragma mark - Session suspend and resume

- (void)testSuspendAndResume {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realmA = [self openRealmForURL:urlA user:user];
    RLMRealm *realmB = [self openRealmForURL:urlB user:user];
    if (self.isParent) {
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        CHECK_COUNT(0, SyncObject, realmA);
        CHECK_COUNT(0, SyncObject, realmB);

        // Suspend the session for realm A and then add an object to each Realm
        RLMSyncSession *sessionA = [RLMSyncSession sessionForRealm:realmA];
        [sessionA suspend];

        [self addSyncObjectsToRealm:realmA descriptions:@[@"child-A1"]];
        [self addSyncObjectsToRealm:realmB descriptions:@[@"child-B1"]];
        [self waitForUploadsForRealm:realmB];

        RLMRunChildAndWait();

        // A should still be 1 since it's suspended. If it wasn't suspended, it
        // should have downloaded before B due to the ordering in the child.
        [self waitForDownloadsForRealm:realmB];
        CHECK_COUNT(1, SyncObject, realmA);
        CHECK_COUNT(3, SyncObject, realmB);

        // A should see the other two from the child after resuming
        [sessionA resume];
        [self waitForDownloadsForRealm:realmA];
        CHECK_COUNT(3, SyncObject, realmA);
    } else {
        // Child shouldn't see the object in A
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        CHECK_COUNT(0, SyncObject, realmA);
        CHECK_COUNT(1, SyncObject, realmB);

        [self addSyncObjectsToRealm:realmA descriptions:@[@"child-A2", @"child-A3"]];
        [self waitForUploadsForRealm:realmA];
        [self addSyncObjectsToRealm:realmB descriptions:@[@"child-B2", @"child-B3"]];
        [self waitForUploadsForRealm:realmB];
        CHECK_COUNT(2, SyncObject, realmA);
        CHECK_COUNT(3, SyncObject, realmB);
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
        XCTAssertTrue([[session.realmURL absoluteString] rangeOfString:sessionName].location != NSNotFound);
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
    NSString *recoveryPath = @"io.realm.object-server-recovered-realms/recovered_realm";
    XCTAssertTrue([pathValue rangeOfString:recoveryPath].location != NSNotFound);
    XCTAssertNotNil([theError rlmSync_errorActionToken]);
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
            XCTAssertTrue([[session.realmURL absoluteString] rangeOfString:sessionName].location != NSNotFound);
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
    [RLMSyncSession immediatelyHandleError:[theError rlmSync_errorActionToken]];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:pathValue]);
}

#pragma mark - Progress Notifications

static const NSInteger NUMBER_OF_BIG_OBJECTS = 2;

- (void)populateDataForUser:(RLMSyncUser *)user url:(NSURL *)url {
    RLMRealm *realm = [self openRealmForURL:url user:user];
    [realm beginWriteTransaction];
    for (NSInteger i=0; i<NUMBER_OF_BIG_OBJECTS; i++) {
        [realm addObject:[HugeSyncObject object]];
    }
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
}

- (void)testStreamingDownloadNotifier {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (!self.isParent) {
        [self populateDataForUser:user url:url];
        return;
    }

    __block NSInteger callCount = 0;
    __block NSUInteger transferred = 0;
    __block NSUInteger transferrable = 0;
    __block BOOL hasBeenFulfilled = NO;
    // Register a notifier.
    [self openRealmForURL:url user:user];
    RLMSyncSession *session = [user sessionForURL:url];
    XCTAssertNotNil(session);
    XCTestExpectation *ex = [self expectationWithDescription:@"streaming-download-notifier"];
    id token = [session addProgressNotificationForDirection:RLMSyncProgressDirectionDownload
                                                       mode:RLMSyncProgressModeReportIndefinitely
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
    [token invalidate];
    // The notifier should have been called at least twice: once at the beginning and at least once
    // to report progress.
    XCTAssert(callCount > 1);
    XCTAssert(transferred >= transferrable,
              @"Transferred (%@) needs to be greater than or equal to transferrable (%@)",
              @(transferred), @(transferrable));
}

- (void)testStreamingUploadNotifier {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    __block NSInteger callCount = 0;
    __block NSUInteger transferred = 0;
    __block NSUInteger transferrable = 0;
    // Open the Realm
    RLMRealm *realm = [self openRealmForURL:url user:user];

    // Register a notifier.
    RLMSyncSession *session = [user sessionForURL:url];
    XCTAssertNotNil(session);
    XCTestExpectation *ex = [self expectationWithDescription:@"streaming-upload-expectation"];
    auto token = [session addProgressNotificationForDirection:RLMSyncProgressDirectionUpload
                                                         mode:RLMSyncProgressModeReportIndefinitely
                                                        block:^(NSUInteger xfr, NSUInteger xfb) {
                                                            // Make sure the values are
                                                            // increasing, and update our
                                                            // stored copies.
                                                            XCTAssert(xfr >= transferred);
                                                            XCTAssert(xfb >= transferrable);
                                                            transferred = xfr;
                                                            transferrable = xfb;
                                                            callCount++;
                                                            if (transferred > 0 && transferred >= transferrable && transferrable > 1000000 * NUMBER_OF_BIG_OBJECTS) {
                                                                [ex fulfill];
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
    [token invalidate];
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
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (!self.isParent) {
        [self populateDataForUser:user url:url];
        return;
    }

    // Wait for the child process to upload everything.
    RLMRunChildAndWait();

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [user configurationWithURL:url];
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
    XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertGreaterThan(fileSize(c.pathOnDisk), 0U);
    XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
}

- (void)testDownloadAlreadyOpenRealm {
    const NSInteger NUMBER_OF_BIG_OBJECTS = 2;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (!self.isParent) {
        [self populateDataForUser:user url:url];
        return;
    }

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [user configurationWithURL:url];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:c.pathOnDisk isDirectory:nil]);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];
    CHECK_COUNT(0, HugeSyncObject, realm);
    [realm.syncSession suspend];

    // Wait for the child process to upload everything.
    RLMRunChildAndWait();

    auto fileSize = ^NSUInteger(NSString *path) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];
    };
    NSUInteger sizeBefore = fileSize(c.pathOnDisk);
    XCTAssertGreaterThan(sizeBefore, 0U);
    XCTAssertNotNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));

    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm * _Nullable realm, NSError * _Nullable error) {
        XCTAssertNil(error);
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
        [ex fulfill];
    }];
    [realm.syncSession resume];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertGreaterThan(fileSize(c.pathOnDisk), sizeBefore);
    XCTAssertNotNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
    CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);

    (void)[realm configuration];
}

- (void)testDownloadCancelsOnAuthError {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    auto c = [user configurationWithURL:[NSURL URLWithString:@"realm://127.0.0.1:9080/invalid"]];
    auto ex = [self expectationWithDescription:@"async open"];
    [RLMRealm asyncOpenWithConfiguration:c callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
                                    XCTAssertNil(realm);
                                    XCTAssertNotNil(error);
                                    [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testCancelDownload {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (!self.isParent) {
        [self populateDataForUser:user url:url];
        return;
    }

    // Wait for the child process to upload everything.
    RLMRunChildAndWait();

    // Use a serial queue for asyncOpen to ensure that the first one adds
    // the completion block before the second one cancels it
    RLMSetAsyncOpenQueue(dispatch_queue_create("io.realm.asyncOpen", 0));

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [user configurationWithURL:url];

    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
                                    XCTAssertNil(realm);
                                    XCTAssertNotNil(error);
                                    [ex fulfill];
                                }];
    [[RLMRealm asyncOpenWithConfiguration:c
                            callbackQueue:dispatch_get_main_queue()
                                 callback:^(RLMRealm *, NSError *) {
                                     XCTFail(@"Cancelled callback got called");
                                 }] cancel];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testAsyncOpenProgressNotifications {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    if (!self.isParent) {
        [self populateDataForUser:user url:url];
        return;
    }

    RLMRunChildAndWait();

    XCTestExpectation *ex1 = [self expectationWithDescription:@"async open"];
    XCTestExpectation *ex2 = [self expectationWithDescription:@"download progress complete"];
    RLMRealmConfiguration *c = [user configurationWithURL:url];

    auto task = [RLMRealm asyncOpenWithConfiguration:c
                                       callbackQueue:dispatch_get_main_queue()
                                            callback:^(RLMRealm *realm, NSError *error) {
                                                XCTAssertNil(error);
                                                XCTAssertNotNil(realm);
                                                [ex1 fulfill];
                                            }];
    [task addProgressNotificationBlock:^(NSUInteger transferredBytes, NSUInteger transferrableBytes) {
        if (transferrableBytes > 0 && transferredBytes == transferrableBytes) {
            [ex2 fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testAsyncOpenConnectionTimeout {
    NSString *userName = NSStringFromSelector(_cmd);
    // 9083 is a proxy which delays responding to requests
    NSURL *authURL = [NSURL URLWithString:@"http://127.0.0.1:9083"];
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userName register:YES]
                                               server:authURL];
    RLMRealmConfiguration *c = [user configuration];
    RLMSyncConfiguration *syncConfig = c.syncConfiguration;
    syncConfig.cancelAsyncOpenOnNonFatalErrors = true;
    c.syncConfiguration = syncConfig;

    RLMSyncTimeoutOptions *timeoutOptions = [RLMSyncTimeoutOptions new];
    timeoutOptions.connectTimeout = 1000.0;
    RLMSyncManager.sharedManager.timeoutOptions = timeoutOptions;

    XCTestExpectation *ex = [self expectationWithDescription:@"async open"];
    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, ETIMEDOUT);
        XCTAssertEqual(error.domain, NSPOSIXErrorDomain);
        XCTAssertNil(realm);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - Compact on Launch

- (void)testCompactOnLaunch {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];

    NSString *path;
    // Create a large object and then delete it in the next transaction so that
    // the file is bloated
    @autoreleasepool {
        auto realm = [self openRealmForURL:url user:user];
        [realm beginWriteTransaction];
        [realm addObject:[HugeSyncObject object]];
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];

        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
        [self waitForDownloadsForRealm:realm];

        path = realm.configuration.pathOnDisk;
    }

    auto fileManager = NSFileManager.defaultManager;
    auto initialSize = [[fileManager attributesOfItemAtPath:path error:nil][NSFileSize] unsignedLongLongValue];

    // Reopen the file with a shouldCompactOnLaunch block and verify that it is
    // actually compacted
    auto config = [user configurationWithURL:url];
    __block bool blockCalled = false;
    __block NSUInteger usedSize = 0;
    config.shouldCompactOnLaunch = ^(NSUInteger, NSUInteger used) {
        usedSize = used;
        blockCalled = true;
        return YES;
    };

    @autoreleasepool {
        [RLMRealm realmWithConfiguration:config error:nil];
    }
    XCTAssertTrue(blockCalled);

    auto finalSize = [[fileManager attributesOfItemAtPath:path error:nil][NSFileSize] unsignedLongLongValue];
    XCTAssertLessThan(finalSize, initialSize);
    XCTAssertLessThanOrEqual(finalSize, usedSize + 4096U);
}

#pragma mark - Certificate pinning

- (void)attemptLoginWithUsername:(NSString *)userName callback:(void (^)(RLMSyncUser *, NSError *))callback {
    NSURL *url = [RLMObjectServerTests secureAuthServerURL];
    RLMAppCredentials *creds = [RLMObjectServerTests basicCredentialsWithName:userName register:YES];

    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP login"];
    // FIXME: [realmapp] This should use the new login
    REALM_UNREACHABLE();
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testHTTPSLoginFailsWithoutCertificate {
    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, NSURLErrorDomain);
        XCTAssertEqual(error.code, NSURLErrorServerCertificateUntrusted);
    }];
}

static NSURL *certificateURL(NSString *filename) {
    return [NSURL fileURLWithPath:[[[@(__FILE__) stringByDeletingLastPathComponent]
                                    stringByAppendingPathComponent:@"certificates"]
                                   stringByAppendingPathComponent:filename]];
}

- (void)testHTTPSLoginFailsWithIncorrectCertificate {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"not-localhost.cer")};
    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, NSURLErrorDomain);
        XCTAssertEqual(error.code, NSURLErrorServerCertificateUntrusted);
    }];
}

- (void)testHTTPSLoginFailsWithInvalidPathToCertificate {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"nonexistent.pem")};
    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, NSCocoaErrorDomain);
        XCTAssertEqual(error.code, NSFileReadNoSuchFileError);
    }];
}

- (void)testHTTPSLoginFailsWithDifferentValidCert {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"localhost-other.cer")};
    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, NSURLErrorDomain);
        XCTAssertEqual(error.code, NSURLErrorServerCertificateUntrusted);
    }];
}

- (void)testHTTPSLoginFailsWithFileThatIsNotACert {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"../test-ros-server.js")};
    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, NSOSStatusErrorDomain);
        XCTAssertEqual(error.code, errSecUnknownFormat);
    }];
}

- (void)testHTTPSLoginDoesNotUseCertificateForDifferentDomain {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"example.com": certificateURL(@"localhost.cer")};
    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, NSURLErrorDomain);
        XCTAssertEqual(error.code, NSURLErrorServerCertificateUntrusted);
    }];
}

- (void)testHTTPSLoginSucceedsWithValidSelfSignedCertificate {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"localhost.cer")};

    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNotNil(user);
        XCTAssertNil(error);
    }];
}

- (void)testConfigurationFromUserAutomaticallyUsesCert {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"localhost.cer")};

    __block RLMSyncUser *user;
    [self attemptLoginWithUsername:NSStringFromSelector(_cmd) callback:^(RLMSyncUser *u, NSError *error) {
        XCTAssertNotNil(u);
        XCTAssertNil(error);
        user = u;
    }];

    RLMRealmConfiguration *config = [user configuration];
    XCTAssertEqualObjects(config.syncConfiguration.realmURL.scheme, @"realms");
    XCTAssertEqualObjects(config.syncConfiguration.pinnedCertificateURL, certificateURL(@"localhost.cer"));

    // Verify that we can actually open the Realm
    auto realm = [self openRealmWithConfiguration:config];
    NSError *error;
    [self waitForUploadsForRealm:realm error:&error];
    XCTAssertNil(error);
}

- (void)verifyOpenSucceeds:(RLMRealmConfiguration *)config {
    auto realm = [self openRealmWithConfiguration:config];
    NSError *error;
    [self waitForUploadsForRealm:realm error:&error];
    XCTAssertNil(error);
}

- (void)verifyOpenFails:(RLMRealmConfiguration *)config {
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait for error"];
    RLMSyncManager.sharedManager.errorHandler = ^(NSError *error, __unused RLMSyncSession *session) {
        XCTAssertTrue([error.domain isEqualToString:RLMSyncErrorDomain]);
        XCTAssertFalse([[error.userInfo[kRLMSyncUnderlyingErrorKey] domain] isEqualToString:RLMSyncErrorDomain]);
        [expectation fulfill];
    };

    [self openRealmWithConfiguration:config];
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testConfigurationFromInsecureUserAutomaticallyUsesCert {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"localhost.cer")};

    RLMSyncUser *user = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                       register:YES]
                                               server:[RLMSyncTestCase authServerURL]];

    RLMRealmConfiguration *config = [user configurationWithURL:[NSURL URLWithString:@"realms://localhost:9443/~/default"]];
    XCTAssertEqualObjects(config.syncConfiguration.realmURL.scheme, @"realms");
    XCTAssertEqualObjects(config.syncConfiguration.pinnedCertificateURL, certificateURL(@"localhost.cer"));

    [self verifyOpenSucceeds:config];
}

- (void)testOpenSecureRealmWithNoCert {
    RLMSyncUser *user = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                       register:YES]
                                               server:[RLMSyncTestCase authServerURL]];
    [self verifyOpenFails:[user configurationWithURL:[NSURL URLWithString:@"realms://localhost:9443/~/default"]]];
}

- (void)testOpenSecureRealmWithIncorrectCert {
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"not-localhost.cer")};

    RLMSyncUser *user = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                       register:YES]
                                               server:[RLMSyncTestCase authServerURL]];
    [self verifyOpenFails:[user configurationWithURL:[NSURL URLWithString:@"realms://localhost:9443/~/default"]]];
}

- (void)DISABLE_testOpenSecureRealmWithMissingCertFile {
    // FIXME: this currently crashes inside the sync library
    RLMSyncManager.sharedManager.pinnedCertificatePaths = @{@"localhost": certificateURL(@"nonexistent.pem")};

    RLMSyncUser *user = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                                       register:YES]
                                               server:[RLMSyncTestCase authServerURL]];
    [self verifyOpenFails:[user configurationWithURL:[NSURL URLWithString:@"realms://localhost:9443/~/default"]]];
}

@end
