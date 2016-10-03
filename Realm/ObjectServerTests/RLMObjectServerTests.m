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

#pragma mark - Sync

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
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:@"realm://localhost:9080/testSyncWithAdminToken"];
    RLMRealm *realm = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(realm.isEmpty);
}

/// It should be possible to successfully open a Realm configured for sync with a normal user.
- (void)testOpenRealmWithNormalCredential {
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:YES]
                                              server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    NSURL *url = REALM_URL();
    RLMRealm *realm = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(realm.isEmpty);
}

/// If client B adds objects to a synced Realm, client A should see those objects.
- (void)testRemoteAddObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    RLMRealm *r = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error, @"Error when opening Realm: %@", error);
    if (self.isParent) {
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(0, SyncObject, r);
        RLMRunChildAndWait();
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
    } else {
        // Add objects.
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-2"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-3"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
    }
}

/// If client B deletes objects from a synced Realm, client A should see the effects of that deletion.
- (void)testRemoteDeleteObjects {
    NSURL *url = REALM_URL();
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    RLMRealm *r = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error, @"Error when opening Realm: %@", error);
    if (self.isParent) {
        [user waitForDownloadToFinish:url];
        // Add objects.
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-2"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-3"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
        RLMRunChildAndWait();
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(0, SyncObject, r);
    } else {
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
        [r beginWriteTransaction];
        [r deleteAllObjects];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(0, SyncObject, r);
    }
}

/// When a session opened by a Realm goes out of scope, it should stay alive long enough to finish any waiting uploads.
- (void)testUploadChangesWhenRealmOutOfScope {
    const NSInteger OBJECT_COUNT = 10000;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    NSError *error = nil;

    if (self.isParent) {
        // Open the Realm in an autorelease pool so that it is destroyed as soon as possible.
        @autoreleasepool {
            RLMRealm *r = [self openRealmForURL:url user:user error:&error];
            XCTAssertNil(error, @"Error when opening Realm: %@", error);
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
        RLMRealm *r = [self openRealmForURL:url user:user error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        // Wait for download to complete.
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(OBJECT_COUNT, SyncObject, r);
    }
}

/// A Realm that was opened before a user logged out should be able to resume uploading if the user logs back in.
- (void)testLogBackInSameRealmUpload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    RLMRealm *r = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error, @"Error when opening Realm: %@", error);

    if (self.isParent) {
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-1"]]];
        [r commitWriteTransaction];
        CHECK_COUNT(1, SyncObject, r);
        [user waitForUploadToFinish:url];
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        sleep(1);
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-2"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-3"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
        RLMRunChildAndWait();
    } else {
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
    }
}

/// A Realm that was opened before a user logged out should be able to resume downloading if the user logs back in.
- (void)testLogBackInSameRealmDownload {
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    NSError *error = nil;
    RLMRealm *r = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error, @"Error when opening Realm: %@", error);

    if (self.isParent) {
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-1"]]];
        [r commitWriteTransaction];
        CHECK_COUNT(1, SyncObject, r);
        [user waitForUploadToFinish:url];
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        sleep(1);
        RLMRunChildAndWait();;
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
    } else {
        [user waitForDownloadToFinish:url];
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-2"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
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
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-1"]]];
        [r commitWriteTransaction];
        CHECK_COUNT(1, SyncObject, r);
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        usleep(500000);
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-2"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-3"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(3, SyncObject, r);
        RLMRunChildAndWait();
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [user waitForDownloadToFinish:url];
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
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-1"]]];
        [r commitWriteTransaction];
        CHECK_COUNT(1, SyncObject, r);
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Wait for the sessions to asynchronously rebind
        // FIXME: once new token system is in this will be unnecessary
        usleep(500000);
        [user waitForDownloadToFinish:url];
        XCTestExpectation *checkCountExpectation = [self expectationWithDescription:@""];
        dispatch_async(dispatch_get_main_queue(), ^{
            CHECK_COUNT(4, SyncObject, r);
            [checkCountExpectation fulfill];
        });
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-2"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-3"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
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
    NSError *error = nil;
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Open the Realm (for the first time).
        RLMRealm *r = [self openRealmForURL:url user:user error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-2"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(2, SyncObject, r);
        RLMRunChildAndWait();
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        // Add objects.
        [user waitForDownloadToFinish:url];
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
    NSError *error = nil;
    if (self.isParent) {
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Allow for asynchronous binding work.
        // FIXME: remove this once we get the new token system
        usleep(500000);
        // Open the Realm (for the first time).
        RLMRealm *r = [self openRealmForURL:url user:user error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        // Run the sub-test.
        RLMRunChildAndWait();
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(2, SyncObject, r);
    } else {
        RLMRealm *r = [self openRealmForURL:url user:user error:&error];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        // Add objects.
        [user waitForDownloadToFinish:url];
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-2"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
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
    NSError *error = nil;
    RLMRealm *r = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error, @"Error when opening Realm: %@", error);
    if (self.isParent) {
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-1"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(1, SyncObject, r);
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Give the sessions time to asynchronously re-bind.
        sleep(1);
        // Open the Realm again.
        r = [self immediatelyOpenRealmForURL:url user:user error:nil];
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-2"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-3"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-4"]]];
        [r commitWriteTransaction];
        CHECK_COUNT(5, SyncObject, r);
        [user waitForUploadToFinish:url];
        RLMRunChildAndWait();
    } else {
        [user waitForDownloadToFinish:url];
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
    NSError *error = nil;
    RLMRealm *r = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error, @"Error when opening Realm: %@", error);
    if (self.isParent) {
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"parent-1"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        XCTAssert([SyncObject allObjectsInRealm:r].count == 1, @"Expected 1 item");
        // Log out the user.
        [user logOut];
        // Log the user back in.
        user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:NO]
                                     server:[RLMObjectServerTests authServerURL]];
        // Run the sub-test.
        RLMRunChildAndWait();
        // Open the Realm again.
        r = [self immediatelyOpenRealmForURL:url user:user error:nil];
        [user waitForDownloadToFinish:url];
        // Dispatch async since Realm notifiers depend on their runloop being able to run.
        XCTestExpectation *checkCountExpectation = [self expectationWithDescription:@""];
        dispatch_async(dispatch_get_main_queue(), ^{
            CHECK_COUNT(5, SyncObject, r);
            [checkCountExpectation fulfill];
        });
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    } else {
        // Add objects.
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(1, SyncObject, r);
        [r beginWriteTransaction];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-1"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-2"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-3"]]];
        [r addObject:[[SyncObject alloc] initWithValue:@[@"child-4"]]];
        [r commitWriteTransaction];
        [user waitForUploadToFinish:url];
        CHECK_COUNT(5, SyncObject, r);
    }
}

/// If a client logs out, the session should be immediately terminated.
- (void)testImmediateSessionTerminationWhenLoggingOut {
    const NSInteger OBJECT_COUNT = 10000;
    NSURL *url = REALM_URL();
    // Log in the user.
    RLMSyncUser *user = [self logInUserForCredential:[RLMObjectServerTests basicCredential:self.isParent]
                                              server:[RLMObjectServerTests authServerURL]];
    // Open the Realm
    NSError *error = nil;
    RLMRealm *r = [self openRealmForURL:url user:user error:&error];
    XCTAssertNil(error, @"Error when opening Realm: %@", error);
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
        [user waitForDownloadToFinish:url];
        CHECK_COUNT(0, SyncObject, r);
    }
}

@end
