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

#import "RLMSyncUser+ObjectServerTests.h"

#define ACCOUNT_NAME() NSStringFromSelector(_cmd)
#define CUSTOM_REALM_URL(realm_identifier) \
    [NSURL URLWithString:[NSString stringWithFormat:@"realm://localhost:9080/~/%@%@", ACCOUNT_NAME(), realm_identifier]]
#define REALM_URL() CUSTOM_REALM_URL(@"")

@interface RLMObjectServerTests : RLMSyncTestCase
@end

@implementation RLMObjectServerTests

#pragma mark - Authentication

/// Valid username/password credentials should be able to log in a user. Using the same credentials should return the
/// same user object.
- (void)testUsernamePasswordAuthentication {
    RLMSyncUser *firstUser = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:YES]
                                                    server:[RLMSyncTestCase authServerURL]];
    RLMSyncUser *secondUser = [self logInUserForCredentials:[RLMSyncTestCase basicCredentialsWithName:ACCOUNT_NAME()
                                                                                             register:NO]
                                                     server:[RLMSyncTestCase authServerURL]];
    // Two users created with the same credential should resolve to the same actual user.
    XCTAssertTrue([firstUser.identity isEqualToString:secondUser.identity]);
    // Authentication server property should be properly set.
    XCTAssertEqualObjects(firstUser.authenticationServer, [RLMSyncTestCase authServerURL]);

    // Trying to "create" a username/password account that already exists should cause an error.
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser logInWithCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME() register:YES]
                        authServerURL:[RLMObjectServerTests authServerURL]
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        // FIXME: Improve error message
        XCTAssertEqualObjects(error.localizedDescription,
                              @"The operation couldn’t be completed. (io.realm.sync error 3.)");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// A valid admin token should be able to log in a user.
- (void)testAdminTokenAuthentication {
    NSURL *adminTokenFileURL = [[RLMSyncTestCase rootRealmCocoaURL] URLByAppendingPathComponent:@"sync/admin_token.base64"];
    NSString *adminToken = [NSString stringWithContentsOfURL:adminTokenFileURL encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotNil(adminToken);
    RLMSyncCredentials *credentials = [RLMSyncCredentials credentialsWithAccessToken:adminToken identity:@"test"];
    XCTAssertNotNil(credentials);

    [self logInUserForCredentials:credentials server:[RLMObjectServerTests authServerURL]];
}

#pragma mark - User Persistence

/// `[RLMSyncUser all]` should be updated once a user is logged in.
- (void)testBasicUserPersistence {
    XCTAssertNil([RLMSyncUser currentUser]);
    XCTAssertEqual([[RLMSyncUser allUsers] count], 0U);
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    XCTAssertNotNil(user);
    XCTAssertEqual([[RLMSyncUser allUsers] count], 1U);
    XCTAssertEqualObjects([RLMSyncUser allUsers], @{user.identity: user});
    XCTAssertEqualObjects([RLMSyncUser currentUser], user);

    RLMSyncUser *user2 = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:[ACCOUNT_NAME() stringByAppendingString:@"2"]
                                                                                             register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    XCTAssertEqual([[RLMSyncUser allUsers] count], 2U);
    NSDictionary *dict2 = @{user.identity: user, user2.identity: user2};
    XCTAssertEqualObjects([RLMSyncUser allUsers], dict2);
    RLMAssertThrowsWithReasonMatching([RLMSyncUser currentUser], @"currentUser cannot be called if more that one valid, logged-in user exists");
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
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:YES]
                                               server:[RLMObjectServerTests authServerURL]];
    NSURL *url = REALM_URL();
    RLMRealm *realm = [self openRealmForURL:url user:user];
    XCTAssertTrue(realm.isEmpty);
}

/// If client B adds objects to a synced Realm, client A should see those objects.
- (void)testAddObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
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
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// If client B deletes objects from a synced Realm, client A should see the effects of that deletion.
- (void)testDeleteObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        // Add objects.
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1", @"parent-2", @"parent-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(0, SyncObject, realm);
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(0, SyncObject, realm);
    }
}

#pragma mark - Multiple Realm Sync

/// If a client opens multiple Realms, there should be one session object for each Realm that was opened.
- (void)testMultipleRealmsSessions {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    NSURL *urlC = CUSTOM_REALM_URL(@"c");
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
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

// FIXME: get these tests working reliably on CI
/// A client should be able to open multiple Realms and add objects to each of them.
- (void)testMultipleRealmsAddObjects {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    NSURL *urlC = CUSTOM_REALM_URL(@"c");
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realmA = [self openRealmForURL:urlA user:user];
    RLMRealm *realmB = [self openRealmForURL:urlB user:user];
    RLMRealm *realmC = [self openRealmForURL:urlC user:user];
    if (self.isParent) {
        WAIT_FOR_DOWNLOAD(user, urlA);
        WAIT_FOR_DOWNLOAD(user, urlC);
        WAIT_FOR_DOWNLOAD(user, urlB);
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
        WAIT_FOR_UPLOAD(user, urlA);
        WAIT_FOR_UPLOAD(user, urlB);
        WAIT_FOR_UPLOAD(user, urlC);
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
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realmA = [self openRealmForURL:urlA user:user];
    RLMRealm *realmB = [self openRealmForURL:urlB user:user];
    RLMRealm *realmC = [self openRealmForURL:urlC user:user];
    if (self.isParent) {
        WAIT_FOR_DOWNLOAD(user, urlA);
        WAIT_FOR_DOWNLOAD(user, urlB);
        WAIT_FOR_DOWNLOAD(user, urlC);
        // Add objects.
        [self addSyncObjectsToRealm:realmA
                       descriptions:@[@"parent-A1", @"parent-A2", @"parent-A3", @"parent-A4"]];
        [self addSyncObjectsToRealm:realmB
                       descriptions:@[@"parent-B1", @"parent-B2", @"parent-B3", @"parent-B4", @"parent-B5"]];
        [self addSyncObjectsToRealm:realmC
                       descriptions:@[@"parent-C1", @"parent-C2"]];
        WAIT_FOR_UPLOAD(user, urlA);
        WAIT_FOR_UPLOAD(user, urlB);
        WAIT_FOR_UPLOAD(user, urlC);
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
        WAIT_FOR_DOWNLOAD(user, urlA);
        WAIT_FOR_DOWNLOAD(user, urlB);
        WAIT_FOR_DOWNLOAD(user, urlC);
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
        WAIT_FOR_UPLOAD(user, urlA);
        WAIT_FOR_UPLOAD(user, urlB);
        WAIT_FOR_UPLOAD(user, urlC);
        CHECK_COUNT(0, SyncObject, realmA);
        CHECK_COUNT(0, SyncObject, realmB);
        CHECK_COUNT(0, SyncObject, realmC);
    }
}

#pragma mark - Session Lifetime

// FIXME: figure out how to get this test to reliably pass.
/// When a session opened by a Realm goes out of scope, it should stay alive long enough to finish any waiting uploads.
- (void)testUploadChangesWhenRealmOutOfScope {
    const NSInteger OBJECT_COUNT = 10000;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
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
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(OBJECT_COUNT, SyncObject, realm);
    }
}

#pragma mark - Logging Back In

/// A Realm that was opened before a user logged out should be able to resume uploading if the user logs back in.
- (void)testLogBackInSameRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];

    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, realm);
        WAIT_FOR_UPLOAD(user, url);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-2", @"parent-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// A Realm that was opened before a user logged out should be able to resume downloading if the user logs back in.
- (void)testLogBackInSameRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    RLMRealm *realm = [self openRealmForURL:url user:user];

    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, realm);
        WAIT_FOR_UPLOAD(user, url);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        RLMRunChildAndWait();
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// A Realm that was opened while a user was logged out should be able to start uploading if the user logs back in.
- (void)testLogBackInDeferredRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
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
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Wait for the Realm's session to be bound.
        WAIT_FOR_SEMAPHORE(sema, 30);
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-2", @"parent-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// A Realm that was opened while a user was logged out should be able to start downloading if the user logs back in.
- (void)testLogBackInDeferredRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
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
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Wait for the Realm's session to be bound.
        WAIT_FOR_SEMAPHORE(sema, 30);
        [self waitForDownloadsForUser:user realms:@[realm] realmURLs:@[url] expectedCounts:@[@4]];
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, realm);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly upload changes.
- (void)testLogBackInOpenFirstTimePathUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForURL:url user:user];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(2, SyncObject, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Add objects.
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(2, SyncObject, realm);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly download changes.
- (void)testLogBackInOpenFirstTimePathDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Run the sub-test.
        RLMRunChildAndWait();
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(2, SyncObject, realm);
    } else {
        RLMRealm *realm = [self openRealmForURL:url user:user];
        // Add objects.
        WAIT_FOR_DOWNLOAD(user, url);
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(2, SyncObject, realm);
    }
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly upload changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(1, SyncObject, realm);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Open the Realm again.
        realm = [self immediatelyOpenRealmForURL:url user:user];
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        CHECK_COUNT(5, SyncObject, realm);
        WAIT_FOR_UPLOAD(user, url);
        RLMRunChildAndWait();
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(5, SyncObject, realm);
    }
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly download changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                            register:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    RLMRealm *realm = [self openRealmForURL:url user:user];
    if (self.isParent) {
        [self addSyncObjectsToRealm:realm descriptions:@[@"parent-1"]];
        WAIT_FOR_UPLOAD(user, url);
        XCTAssert([SyncObject allObjectsInRealm:realm].count == 1, @"Expected 1 item");
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:ACCOUNT_NAME()
                                                                                   register:NO]
                                      server:[RLMObjectServerTests authServerURL]];
        // Run the sub-test.
        RLMRunChildAndWait();
        // Open the Realm again and get the items.
        realm = [self immediatelyOpenRealmForURL:url user:user];
        [self waitForDownloadsForUser:user realms:@[realm] realmURLs:@[url] expectedCounts:@[@5]];
    } else {
        // Add objects.
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(1, SyncObject, realm);
        [self addSyncObjectsToRealm:realm descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(5, SyncObject, realm);
    }
}

#pragma mark - Permissions

/// Grant/revoke access a user's Realm to another user. Another user has no access permission by default.
- (void)testPermissionChange {
    NSString *userNameA = [ACCOUNT_NAME() stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    NSString *userNameB = [ACCOUNT_NAME() stringByAppendingString:@"_B"];
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
    NSString *userNameA = [ACCOUNT_NAME() stringByAppendingString:@"_A"];
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
    NSString *userNameA = [ACCOUNT_NAME() stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                                server:[RLMObjectServerTests authServerURL]];

    NSString *userNameB = [ACCOUNT_NAME() stringByAppendingString:@"_B"];
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

- (void)verifyChangePermission:(RLMSyncPermissionChange *)permissionChange statusMessage:(NSString *)message owner:(RLMSyncUser *)owner {
    RLMRealm *managementRealm = [self managementRealmForUser:owner];

    XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission will be granted by the server"];

    RLMResults<RLMSyncPermissionChange *> *r = [RLMSyncPermissionChange objectsInRealm:managementRealm
                                                                                 where:@"id = %@", permissionChange.id];
    RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults * _Nullable results,
                                                            RLMCollectionChange * _Nullable change __unused,
                                                            NSError * _Nullable error __unused) {
        RLMSyncPermissionChange *permissionChange = results[0];
        if (permissionChange.statusCode) {
            XCTAssertEqual(permissionChange.status, RLMSyncManagementObjectStatusSuccess);
            XCTAssertTrue([permissionChange.statusMessage rangeOfString:message].location != NSNotFound);
            [expectation fulfill];
        }
    }];

    NSError *error = nil;
    [managementRealm transactionWithBlock:^{
        [managementRealm addObject:permissionChange];
    } error:&error];
    XCTAssertNil(error, @"Error when writing permission change object: %@", error);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
}

/// Changing unowned Realm permission should fail
- (void)testPermissionChangeErrorByUnownedRealm {
    NSString *userNameA = [ACCOUNT_NAME() stringByAppendingString:@"_A"];
    RLMSyncUser *userA = [self logInUserForCredentials:[RLMObjectServerTests basicCredentialsWithName:userNameA
                                                                                             register:self.isParent]
                                               server:[RLMObjectServerTests authServerURL]];

    NSString *userNameB = [ACCOUNT_NAME() stringByAppendingString:@"_B"];
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

        XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission will be granted by the server"];
        RLMResults<RLMSyncPermissionChange *> *r = [RLMSyncPermissionChange objectsInRealm:managementRealm
                                                                                     where:@"id = %@", permissionChange.id];
        RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change __unused, NSError * _Nullable error __unused) {
            RLMSyncPermissionChange *permissionChange = results[0];
            if (permissionChange.statusCode) {
                XCTAssertEqual(permissionChange.status, RLMSyncManagementObjectStatusError);
                [expectation fulfill];
            }
        }];

        [managementRealm transactionWithBlock:^{
            [managementRealm addObject:permissionChange];
        } error:&error];
        XCTAssertNil(error, @"Error when writing permission change object: %@", error);

        [self waitForExpectationsWithTimeout:2.0 handler:nil];
        [token stop];
    }

    {
        RLMSyncPermissionChange *permissionChange = [RLMSyncPermissionChange permissionChangeWithRealmURL:realmURL
                                                                                               userID:@"*"
                                                                                                     read:@YES
                                                                                                    write:@YES
                                                                                                   manage:@NO];

        XCTestExpectation *expectation = [self expectationWithDescription:@"A new permission will be granted by the server"];
        RLMResults<RLMSyncPermissionChange *> *r = [RLMSyncPermissionChange objectsInRealm:managementRealm
                                                                                     where:@"id = %@", permissionChange.id];
        RLMNotificationToken *token = [r addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change __unused, NSError * _Nullable error __unused) {
            RLMSyncPermissionChange *permissionChange = results[0];
            if (permissionChange.statusCode) {
                XCTAssertEqual(permissionChange.status, RLMSyncManagementObjectStatusError);
                [expectation fulfill];
            }
        }];

        [managementRealm transactionWithBlock:^{
            [managementRealm addObject:permissionChange];
        } error:&error];
        XCTAssertNil(error, @"Error when writing permission change object: %@", error);

        [self waitForExpectationsWithTimeout:2.0 handler:nil];
        [token stop];
    }
}

@end
