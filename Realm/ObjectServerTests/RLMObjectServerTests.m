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

static NSURL *makeRealmURL(const char *function, NSString *identifier) {
    // 'function' is expected to be an Objective-C method name: "[MyClass fooBarBaz]"
    NSString *functionAsString = @(function);
    NSString *reduced = [functionAsString substringWithRange:NSMakeRange(1, [functionAsString length] - 2)];
    NSString *methodName = [reduced componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]][1];
    return [NSURL URLWithString:[NSString stringWithFormat:@"realm://localhost:9080/~/%@%@",
                                 [methodName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]],
                                 identifier ?: @""]];
}

#define CUSTOM_REALM_URL(realm_identifier) makeRealmURL(__FUNCTION__, realm_identifier)

#define REALM_URL() CUSTOM_REALM_URL(@"")

@interface RLMObjectServerTests : RLMSyncTestCase
@end

@implementation RLMObjectServerTests

#pragma mark - Authentication

/// A valid username/password credential should be able to log in a user. Using the same credential should return the
/// same user object.
- (void)testUsernamePasswordAuthentication {
    RLMSyncUser *firstUser = [self logInUserForCredential:[RLMSyncTestCase basicCredential:YES]
                                                   server:[RLMSyncTestCase authServerURL]];
    RLMSyncUser *secondUser = [self logInUserForCredential:[RLMSyncTestCase basicCredential:NO]
                                                    server:[RLMSyncTestCase authServerURL]];
    // Logging in with equivalent credentials should return the same user object instance.
    XCTAssertEqual(firstUser, secondUser);
    // Authentication server property should be properly set.
    XCTAssertEqualObjects(firstUser.authenticationServer, [RLMSyncTestCase authServerURL]);

    // Trying to "create" a username/password account that already exists should cause an error.
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser authenticateWithCredential:[RLMObjectServerTests basicCredential:YES]
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
    RLMSyncCredential *credential = [RLMSyncCredential credentialWithAccessToken:adminToken identity:@"test"];
    XCTAssertNotNil(credential);

    [self logInUserForCredential:credential server:[RLMObjectServerTests authServerURL]];
}

#pragma mark - User Persistence

/// `[RLMSyncUser all]` should be updated once a user is logged in.
- (void)testBasicUserPersistence {
    XCTAssertEqual([[RLMSyncUser all] count], 0U);
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:YES]
                                              server:[RLMObjectServerTests authServerURL]];
    XCTAssertNotNil(user);
    XCTAssertEqual([[RLMSyncUser all] count], 1U);
    XCTAssertTrue([[RLMSyncUser all] containsObject:user]);
}

#pragma mark - Basic Sync

/// It should be possible to successfully open a Realm configured for sync with an access token.
- (void)testOpenRealmWithAdminToken {
    // FIXME (tests): opening a Realm with the access token, then opening a Realm at the same virtual path
    // with a normal credential, causes Realms to fail to bind with a "bad virtual path" error.
    NSURL *adminTokenFileURL = [[RLMSyncTestCase rootRealmCocoaURL] URLByAppendingPathComponent:@"sync/admin_token.base64"];
    NSString *adminToken = [NSString stringWithContentsOfURL:adminTokenFileURL encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotNil(adminToken);
    RLMSyncCredential *credential = [RLMSyncCredential credentialWithAccessToken:adminToken identity:@"test"];
    XCTAssertNotNil(credential);
    RLMSyncUser *user = [self logInUserForCredential:credential
                                              server:[RLMObjectServerTests authServerURL]];
    NSURL *url = [NSURL URLWithString:@"realm://localhost:9080/testSyncWithAdminToken"];
    RLMRealm *realm = [self openRealmForURL:url user:user];
    XCTAssertTrue(realm.isEmpty);
}

/// It should be possible to successfully open a Realm configured for sync with a normal user.
- (void)testOpenRealmWithNormalCredential {
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:YES]
                                              server:[RLMObjectServerTests authServerURL]];
    NSURL *url = REALM_URL();
    RLMRealm *realm = [self openRealmForURL:url user:user];
    XCTAssertTrue(realm.isEmpty);
}

/// If client B adds objects to a synced Realm, client A should see those objects.
- (void)testRemoteAddObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    RLMRealm *r = [self openRealmForURL:url user:user];
    if (self.isParent) {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(0, SyncObject, r);
        RLMRunChildAndWait();
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
    } else {
        // Add objects.
        [self addSyncObjectsToRealm:r descriptions:@[@"child-1", @"child-2", @"child-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
    }
}

/// If client B deletes objects from a synced Realm, client A should see the effects of that deletion.
- (void)testRemoteDeleteObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    RLMRealm *r = [self openRealmForURL:url user:user];
    if (self.isParent) {
        WAIT_FOR_DOWNLOAD(user, url);
        // Add objects.
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-1", @"parent-2", @"parent-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
        RLMRunChildAndWait();
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(0, SyncObject, r);
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
        [r beginWriteTransaction];
        [r deleteAllObjects];
        [r commitWriteTransaction];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(0, SyncObject, r);
    }
}

#pragma mark - Multiple Realm Sync

/// If a client opens multiple Realms, there should be one session object for each Realm that was opened.
- (void)testMultipleRealmsSessions {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    NSURL *urlC = CUSTOM_REALM_URL(@"c");
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open three Realms.
    __unused RLMRealm *realmA = [self openRealmForURL:urlA user:user];
    __unused RLMRealm *realmB = [self openRealmForURL:urlB user:user];
    __unused RLMRealm *realmC = [self openRealmForURL:urlC user:user];
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
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
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
- (void)testMultipleRealmsRemoveObjects {
    NSURL *urlA = CUSTOM_REALM_URL(@"a");
    NSURL *urlB = CUSTOM_REALM_URL(@"b");
    NSURL *urlC = CUSTOM_REALM_URL(@"c");
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
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

/// When a session opened by a Realm goes out of scope, it should stay alive long enough to finish any waiting uploads.
- (void)testUploadChangesWhenRealmOutOfScope {
    const NSInteger OBJECT_COUNT = 10000;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];

    if (self.isParent) {
        // Open the Realm in an autorelease pool so that it is destroyed as soon as possible.
        @autoreleasepool {
            RLMRealm *r = [self openRealmForURL:url user:user];
            [r beginWriteTransaction];
            for (NSInteger i=0; i<OBJECT_COUNT; i++) {
                [r addObject:[[SyncObject alloc] initWithValue:@[[NSString stringWithFormat:@"parent-%@", @(i+1)]]]];
            }
            [r commitWriteTransaction];
            CHECK_COUNT(OBJECT_COUNT, SyncObject, r);
        }
        // Run the sub-test. (Give the upload a bit of time to start.)
        usleep(50000);
        RLMRunChildAndWait();
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user];
        // Wait for download to complete.
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(OBJECT_COUNT, SyncObject, r);
    }
}

/// If a client logs out, the session should be immediately terminated.
- (void)testImmediateSessionTerminationWhenLoggingOut {
    const NSInteger OBJECT_COUNT = 10000;
    NSURL *url = [NSURL URLWithString:@"realm://localhost:9080/~/testBasicSync"];
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    RLMRealm *r = [self openRealmForURL:url user:user];
    if (self.isParent) {
        [r beginWriteTransaction];
        for (NSInteger i=0; i<OBJECT_COUNT; i++) {
            [r addObject:[[SyncObject alloc] initWithValue:@[[NSString stringWithFormat:@"parent-%@", @(i+1)]]]];
        }
        [r commitWriteTransaction];
        [user logOut];
        CHECK_COUNT(OBJECT_COUNT, SyncObject, r);
        usleep(50000);
        RLMRunChildAndWait();
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(0, SyncObject, r);
    }
}

#pragma mark - Logging Back In

/// A Realm that was opened before a user logged out should be able to resume uploading if the user logs back in.
- (void)testLogBackInSameRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    RLMRealm *r = [self openRealmForURL:url user:user];

    if (self.isParent) {
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, r);
        WAIT_FOR_UPLOAD(user, url);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        usleep(200000);
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-2", @"parent-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
        RLMRunChildAndWait();
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
    }
}

/// A Realm that was opened before a user logged out should be able to resume downloading if the user logs back in.
- (void)testLogBackInSameRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    RLMRealm *r = [self openRealmForURL:url user:user];

    if (self.isParent) {
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, r);
        WAIT_FOR_UPLOAD(user, url);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        usleep(200000);
        RLMRunChildAndWait();
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        [self addSyncObjectsToRealm:r descriptions:@[@"child-1", @"child-2"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
    }
}

/// A Realm that was opened while a user was logged out should be able to start uploading if the user logs back in.
- (void)testLogBackInDeferredRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    if (self.isParent) {
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
        [user logOut];
        // Open a Realm after the user's been logged out.
        RLMRealm *r = [RLMRealm realmWithConfiguration:config error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, r);
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        usleep(200000);
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-2", @"parent-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
        RLMRunChildAndWait();
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
    }
}

/// A Realm that was opened while a user was logged out should be able to start downloading if the user logs back in.
- (void)testLogBackInDeferredRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    if (self.isParent) {
        RLMRunChildAndWait();
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
        [user logOut];
        // Open a Realm after the user's been logged out.
        RLMRealm *r = [RLMRealm realmWithConfiguration:config error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-1"]];
        CHECK_COUNT(1, SyncObject, r);
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        usleep(200000);
        [self waitForDownloadsForUser:user realms:@[r] realmURLs:@[url] expectedCounts:@[@4]];
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addSyncObjectsToRealm:r descriptions:@[@"child-1", @"child-2", @"child-3"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(3, SyncObject, r);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly upload changes.
- (void)testLogBackInOpenFirstTimePathUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];

    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *r = [self openRealmForURL:url user:user];
        [self addSyncObjectsToRealm:r descriptions:@[@"child-1", @"child-2"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(2, SyncObject, r);
        RLMRunChildAndWait();
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user];
        // Add objects.
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(2, SyncObject, r);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly download changes.
- (void)testLogBackInOpenFirstTimePathDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];

    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Allow for asynchronous binding work.
        // FIXME: remove this once we get the new token system
        usleep(200000);
        // Open the Realm (for the first time).
        RLMRealm *r = [self openRealmForURL:url user:user];
        // Run the sub-test.
        RLMRunChildAndWait();
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(2, SyncObject, r);
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user];
        // Add objects.
        WAIT_FOR_DOWNLOAD(user, url);
        [self addSyncObjectsToRealm:r descriptions:@[@"child-1", @"child-2"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(2, SyncObject, r);
    }
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly upload changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    RLMRealm *r = [self openRealmForURL:url user:user];
    if (self.isParent) {
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-1"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(1, SyncObject, r);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Give the sessions time to asynchronously re-bind.
        usleep(200000);
        // Open the Realm again.
        r = [self immediatelyOpenRealmForURL:url user:user];
        [self addSyncObjectsToRealm:r descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        CHECK_COUNT(5, SyncObject, r);
        WAIT_FOR_UPLOAD(user, url);
        RLMRunChildAndWait();
    } else {
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(5, SyncObject, r);
    }
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly download changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    RLMRealm *r = [self openRealmForURL:url user:user];
    if (self.isParent) {
        [self addSyncObjectsToRealm:r descriptions:@[@"parent-1"]];
        WAIT_FOR_UPLOAD(user, url);
        XCTAssert([SyncObject allObjectsInRealm:r].count == 1, @"Expected 1 item");
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Run the sub-test.
        RLMRunChildAndWait();
        // Open the Realm again and get the items.
        r = [self immediatelyOpenRealmForURL:url user:user];
        [self waitForDownloadsForUser:user realms:@[r] realmURLs:@[url] expectedCounts:@[@5]];
    } else {
        // Add objects.
        WAIT_FOR_DOWNLOAD(user, url);
        CHECK_COUNT(1, SyncObject, r);
        [self addSyncObjectsToRealm:r descriptions:@[@"child-1", @"child-2", @"child-3", @"child-4"]];
        WAIT_FOR_UPLOAD(user, url);
        CHECK_COUNT(5, SyncObject, r);
    }
}

@end
