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
#import "RLMUser+ObjectServerTests.h"
#import "RLMUser_Private.hpp"

#import "RLMCredentials.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMRealm+Sync.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealmUtil.hpp"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSyncUtil_Private.h"

#import "shared_realm.hpp"

#ifndef REALM_ENABLE_SYNC_TESTS
#define REALM_ENABLE_SYNC_TESTS 0
#endif

#pragma mark - Test objects

@interface RLMObjectServerTests : RLMSyncTestCase
@end

@interface AsyncOpenConnectionTimeoutTransport : RLMNetworkTransport
@end

@implementation AsyncOpenConnectionTimeoutTransport

- (void)sendRequestToServer:(RLMRequest *)request completion:(RLMNetworkTransportCompletionBlock)completionBlock {
    if ([request.url hasSuffix:@"location"]) {
        RLMResponse *r = [RLMResponse new];
        r.httpStatusCode = 200;
        r.body = @"{\"deployment_model\":\"GLOBAL\",\"location\":\"US-VA\",\"hostname\":\"http://localhost:5678\",\"ws_hostname\":\"ws://localhost:5678\"}";
        completionBlock(r);
    } else {
        [super sendRequestToServer:request completion:completionBlock];
    }
}

@end

@implementation RLMObjectServerTests

#pragma mark - App Tests

- (NSString *)generateRandomString:(int)num {
    NSMutableString *string = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [string appendFormat:@"%c", (char)('a' + arc4random_uniform(26))];
    }
    return string;
}

- (RLMUser *)anonymousUser {
    XCTestExpectation *expectation = [self expectationWithDescription:@"anonymous login"];
    __block RLMUser *user;
    [self.app loginWithCredential:[RLMCredentials anonymousCredentials] completion:^(RLMUser *u, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(u);
        user = u;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    return user;
}

- (RLMUser *)userForTest:(SEL)sel {
    return [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(sel)
                                                               register:self.isParent]];
}

#pragma mark - Authentication and Tokens

- (void)testAnonymousAuthentication {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    RLMUser *syncUser = self.anonymousUser;

    RLMUser *currentUser = [app currentUser];
    XCTAssert([currentUser.identity isEqualToString:syncUser.identity]);
    XCTAssert([currentUser.refreshToken isEqualToString:syncUser.refreshToken]);
    XCTAssert([currentUser.accessToken isEqualToString:syncUser.accessToken]);
}

- (void)testCallFunction {
    [self.anonymousUser callFunctionNamed:@"sum"
                                arguments:@[@1, @2, @3, @4, @5]
                          completionBlock:^(id<RLMBSON> bson, NSError *error) {
        XCTAssert(!error);
        XCTAssertEqual([((NSNumber *)bson) intValue], 15);
    }];
}

- (void)testLogoutCurrentUser {
    RLMUser *user = self.anonymousUser;
    XCTestExpectation *expectation = [self expectationWithDescription:@"should log out current user"];
    [self.app.currentUser logOutWithCompletion:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(user.state, RLMUserStateRemoved);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testLogoutSpecificUser {
    RLMUser *syncUser = self.anonymousUser;
    XCTestExpectation *expectation = [self expectationWithDescription:@"should log out current user"];
    [syncUser logOutWithCompletion:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(syncUser.state, RLMUserStateRemoved);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testSwitchUser {
    RLMApp *app = self.app;

    RLMUser *syncUserA = [self anonymousUser];
    RLMUser *syncUserB = [self userForTest:_cmd];

    XCTAssertNotEqualObjects(syncUserA.identity, syncUserB.identity);
    XCTAssertEqualObjects(app.currentUser.identity, syncUserB.identity);

    XCTAssertEqualObjects([app switchToUser:syncUserA].identity, syncUserA.identity);
}

- (void)testRemoveUser {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    
    RLMUser *firstUser = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                             register:YES]];
    RLMUser *secondUser = [self logInUserForCredentials:[self basicCredentialsWithName:@"test@10gen.com"
                                                                              register:YES]];

    XCTAssert([[app currentUser].identity isEqualToString:secondUser.identity]);

    XCTestExpectation *removeUserExpectation = [self expectationWithDescription:@"should remove user"];

    [secondUser removeWithCompletion:^(NSError *error) {
        XCTAssert(!error);
        XCTAssert([app allUsers].count == 1);
        XCTAssert([[app currentUser].identity isEqualToString:firstUser.identity]);
        [removeUserExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testDeviceRegistration {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"should login anonymously"];
    __block RLMUser *syncUser;
    [app loginWithCredential:[RLMCredentials anonymousCredentials] completion:^(RLMUser *user, NSError *error) {
        XCTAssertNil(error);
        XCTAssert(user);
        syncUser = user;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    RLMPushClient *client = [app pushClientWithServiceName:@"gcm"];
    expectation = [self expectationWithDescription:@"should register device"];
    [client registerDeviceWithToken:@"token" user:[app currentUser] completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    expectation = [self expectationWithDescription:@"should deregister device"];
    [client deregisterDeviceForUser:[app currentUser] completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testMultipleRegisterDevice {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    XCTestExpectation *loginExpectation = [self expectationWithDescription:@"should login anonymously"];
    XCTestExpectation *registerExpectation = [self expectationWithDescription:@"should register device"];
    XCTestExpectation *secondRegisterExpectation = [self expectationWithDescription:@"should not throw error when attempting to register again"];

    __block RLMUser *syncUser;
    [app loginWithCredential:[RLMCredentials anonymousCredentials] completion:^(RLMUser *user, NSError *error) {
        XCTAssertNil(error);
        XCTAssert(user);
        syncUser = user;
        [loginExpectation fulfill];
    }];
    [self waitForExpectations:@[loginExpectation] timeout:10.0];
    
    RLMPushClient *client = [app pushClientWithServiceName:@"gcm"];
    [client registerDeviceWithToken:@"token" user:[app currentUser] completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [registerExpectation fulfill];
    }];
    [self waitForExpectations:@[registerExpectation] timeout:10.0];
        
    [client registerDeviceWithToken:@"token" user:[app currentUser] completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [secondRegisterExpectation fulfill];
    }];
    [self waitForExpectations:@[secondRegisterExpectation] timeout:10.0];
}

#pragma mark - RLMEmailPasswordAuth

- (void)testRegisterEmailAndPassword {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"should register with email and password"];

    NSString *randomEmail = [NSString stringWithFormat:@"%@@%@.com", [self generateRandomString:10], [self generateRandomString:10]];
    NSString *randomPassword = [self generateRandomString:10];

    [[app emailPasswordAuth] registerEmail:randomEmail password:randomPassword completion:^(NSError *error) {
        XCTAssert(!error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testConfirmUser {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try confirm user and fail"];

    NSString *randomEmail = [NSString stringWithFormat:@"%@@%@.com", [self generateRandomString:10], [self generateRandomString:10]];

    [[app emailPasswordAuth] confirmUser:randomEmail tokenId:@"a_token" completion:^(NSError *error) {
        XCTAssertEqual(error.code, RLMAppErrorBadRequest);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testResendConfirmationEmail {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try resend confirmation email and fail"];

    NSString *randomEmail = [NSString stringWithFormat:@"%@@%@.com", [self generateRandomString:10], [self generateRandomString:10]];

    [[app emailPasswordAuth] resendConfirmationEmail:randomEmail completion:^(NSError *error) {
        XCTAssertEqual(error.code, RLMAppErrorUserNotFound);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testResetPassword {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try reset password and fail"];

    [[app emailPasswordAuth] resetPasswordTo:@"APassword123" token:@"a_token" tokenId:@"a_token_id" completion:^(NSError *error) {
        XCTAssertEqual(error.code, RLMAppErrorBadRequest);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testCallResetPasswordFunction {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try call reset password function and fail"];

    [[app emailPasswordAuth] callResetPasswordFunction:@"test@mongodb.com"
                                                           password:@"aPassword123"
                                                               args:@[@{}]
                                                         completion:^(NSError *error) {
        XCTAssertEqual(error.code, RLMAppErrorUserNotFound);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

#pragma mark - UserAPIKeyProviderClient

- (void)testUserAPIKeyProviderClientFlow {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];

    XCTestExpectation *registerExpectation = [self expectationWithDescription:@"should try register"];
    XCTestExpectation *loginExpectation = [self expectationWithDescription:@"should try login"];
    XCTestExpectation *createAPIKeyExpectationA = [self expectationWithDescription:@"should try create an api key"];
    XCTestExpectation *createAPIKeyExpectationB = [self expectationWithDescription:@"should try create an api key"];
    XCTestExpectation *fetchAPIKeysExpectation = [self expectationWithDescription:@"should try call fetch api keys"];
    XCTestExpectation *disableAPIKeyExpectation = [self expectationWithDescription:@"should try disable api key"];
    XCTestExpectation *enableAPIKeyExpectation = [self expectationWithDescription:@"should try enable api key"];
    XCTestExpectation *deleteAPIKeyExpectation = [self expectationWithDescription:@"should try delete api key"];

    __block RLMUser *syncUser;
    __block RLMUserAPIKey *userAPIKeyA;
    __block RLMUserAPIKey *userAPIKeyB;

    NSString *randomEmail = [NSString stringWithFormat:@"%@@%@.com", [self generateRandomString:10], [self generateRandomString:10]];
    NSString *randomPassword = [self generateRandomString:10];

    [[app emailPasswordAuth] registerEmail:randomEmail password:randomPassword completion:^(NSError *error) {
        XCTAssert(!error);
        [registerExpectation fulfill];
    }];

    [self waitForExpectations:@[registerExpectation] timeout:60.0];

    [app loginWithCredential:[RLMCredentials credentialsWithUsername:randomEmail password:randomPassword]
                  completion:^(RLMUser *user, NSError *error) {
        XCTAssert(!error);
        XCTAssert(user);
        syncUser = user;
        [loginExpectation fulfill];
    }];

    [self waitForExpectations:@[loginExpectation] timeout:60.0];

    [[syncUser apiKeyAuth] createApiKeyWithName:@"apiKeyName1" completion:^(RLMUserAPIKey *userAPIKey, NSError *error) {
        XCTAssert(!error);
        XCTAssert([userAPIKey.name isEqualToString:@"apiKeyName1"]);
        userAPIKeyA = userAPIKey;
        [createAPIKeyExpectationA fulfill];
    }];

    [[syncUser apiKeyAuth] createApiKeyWithName:@"apiKeyName2" completion:^(RLMUserAPIKey *userAPIKey, NSError *error) {
        XCTAssert(!error);
        XCTAssert([userAPIKey.name isEqualToString:@"apiKeyName2"]);
        userAPIKeyB = userAPIKey;
        [createAPIKeyExpectationB fulfill];
    }];

    [self waitForExpectations:@[createAPIKeyExpectationA, createAPIKeyExpectationB] timeout:60.0];

    // sleep for 2 seconds as there seems to be an issue fetching the keys straight after they are created.
    [NSThread sleepForTimeInterval:2];

    [[syncUser apiKeyAuth] fetchApiKeysWithCompletion:^(NSArray<RLMUserAPIKey *> * _Nonnull apiKeys, NSError *error) {
        XCTAssert(!error);
        XCTAssert(apiKeys.count == 2);
        [fetchAPIKeysExpectation fulfill];
    }];

    [self waitForExpectations:@[fetchAPIKeysExpectation] timeout:60.0];

    [[syncUser apiKeyAuth] disableApiKey:userAPIKeyA.objectId completion:^(NSError *error) {
        XCTAssert(!error);
        [disableAPIKeyExpectation fulfill];
    }];

    [self waitForExpectations:@[disableAPIKeyExpectation] timeout:60.0];

    [[syncUser apiKeyAuth] enableApiKey:userAPIKeyA.objectId completion:^(NSError *error) {
        XCTAssert(!error);
        [enableAPIKeyExpectation fulfill];
    }];

    [self waitForExpectations:@[enableAPIKeyExpectation] timeout:60.0];

    [[syncUser apiKeyAuth] deleteApiKey:userAPIKeyA.objectId completion:^(NSError *error) {
        XCTAssert(!error);
        [deleteAPIKeyExpectation fulfill];
    }];

    [self waitForExpectations:@[deleteAPIKeyExpectation] timeout:60.0];
}

#pragma mark - Link user -

- (void)testLinkUser {
    RLMApp *app = [RLMApp appWithId:self.appId configuration:[self defaultAppConfiguration]];

    XCTestExpectation *registerExpectation = [self expectationWithDescription:@"should try register"];
    XCTestExpectation *loginExpectation = [self expectationWithDescription:@"should try login"];
    XCTestExpectation *linkExpectation = [self expectationWithDescription:@"should try link and fail"];

    __block RLMUser *syncUser;

    NSString *randomEmail = [NSString stringWithFormat:@"%@@10gen.com", [self generateRandomString:10]];
    NSString *randomPassword = [self generateRandomString:10];

    [[app emailPasswordAuth] registerEmail:randomEmail password:randomPassword completion:^(NSError *error) {
        XCTAssert(!error);
        [registerExpectation fulfill];
    }];

    [self waitForExpectations:@[registerExpectation] timeout:60.0];

    [app loginWithCredential:[RLMCredentials credentialsWithUsername:randomEmail password:randomPassword]
                  completion:^(RLMUser *user, NSError *error) {
        XCTAssert(!error);
        XCTAssert(user);
        syncUser = user;
        [loginExpectation fulfill];
    }];

    [self waitForExpectations:@[loginExpectation] timeout:60.0];

    [syncUser linkUserWithCredentials:[RLMCredentials credentialsWithFacebookToken:@"a_token"]
                           completion:^(RLMUser *user, NSError *error) {
        XCTAssert(!user);
        XCTAssertEqual(error.code, RLMAppErrorInvalidSession);
        [linkExpectation fulfill];
    }];

    [self waitForExpectations:@[linkExpectation] timeout:60.0];
}

#pragma mark - Auth Credentials -

- (void)testUsernamePasswordCredential {
    RLMCredentials *usernamePasswordCredential = [RLMCredentials credentialsWithUsername:@"test@mongodb.com" password:@"apassword"];
    XCTAssertEqualObjects(usernamePasswordCredential.provider, @"local-userpass");
}

- (void)testJWTCredential {
    RLMCredentials *jwtCredential = [RLMCredentials credentialsWithJWT:@"sometoken"];
    XCTAssertEqualObjects(jwtCredential.provider, @"custom-token");
}

- (void)testAnonymousCredential {
    RLMCredentials *anonymousCredential = [RLMCredentials anonymousCredentials];
    XCTAssertEqualObjects(anonymousCredential.provider, @"anon-user");
}

- (void)testUserAPIKeyCredential {
    RLMCredentials *userAPICredential = [RLMCredentials credentialsWithUserAPIKey:@"apikey"];
    XCTAssertEqualObjects(userAPICredential.provider, @"api-key");
}

- (void)testServerAPIKeyCredential {
    RLMCredentials *serverAPICredential = [RLMCredentials credentialsWithServerAPIKey:@"apikey"];
    XCTAssertEqualObjects(serverAPICredential.provider, @"api-key");
}

- (void)testFacebookCredential {
    RLMCredentials *facebookCredential = [RLMCredentials credentialsWithFacebookToken:@"facebook token"];
    XCTAssertEqualObjects(facebookCredential.provider, @"oauth2-facebook");
}

- (void)testGoogleCredential {
    RLMCredentials *googleCredential = [RLMCredentials credentialsWithGoogleToken:@"google token"];
    XCTAssertEqualObjects(googleCredential.provider, @"oauth2-google");
}

- (void)testAppleCredential {
    RLMCredentials *appleCredential = [RLMCredentials credentialsWithAppleToken:@"apple token"];
    XCTAssertEqualObjects(appleCredential.provider, @"oauth2-apple");
}

- (void)testFunctionCredential {
    NSError *error;
    RLMCredentials *functionCredential = [RLMCredentials credentialsWithFunctionPayload:@{ @"dog" : @{ @"name" : @"fido" } }
                                                                                        error:&error];
    XCTAssertEqualObjects(functionCredential.provider, @"custom-function");
    XCTAssertEqualObjects(error, nil);
}

#pragma mark - Username Password

/// Valid username/password credentials should be able to log in a user. Using the same credentials should return the
/// same user object.
- (void)testUsernamePasswordAuthentication {
    RLMUser *firstUser = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                             register:YES]];
    RLMUser *secondUser = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                              register:NO]];
    // Two users created with the same credential should resolve to the same actual user.
    XCTAssertTrue([firstUser.identity isEqualToString:secondUser.identity]);
}

/// An invalid username/password credential should not be able to log in a user and a corresponding error should be generated.
- (void)testInvalidPasswordAuthentication {
    (void)[self userForTest:_cmd];

    RLMCredentials *credentials = [RLMCredentials credentialsWithUsername:NSStringFromSelector(_cmd)
                                                                 password:@"INVALID_PASSWORD"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"login should fail"];

    [self.app loginWithCredential:credentials completion:^(RLMUser * user, NSError * error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// A non-existsing user should not be able to log in and a corresponding error should be generated.
- (void)testNonExistingUsernameAuthentication {
    RLMCredentials *credentials = [RLMCredentials credentialsWithUsername:@"INVALID_USERNAME"
                                                                       password:@"INVALID_PASSWORD"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"login should fail"];

    [self.app loginWithCredential:credentials completion:^(RLMUser * user, NSError * error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Registering a user with existing username should return corresponding error.
- (void)testExistingUsernameRegistration {
    XCTestExpectation *expectationA = [self expectationWithDescription:@"registration should succeed"];
    [[self.app emailPasswordAuth] registerEmail:NSStringFromSelector(_cmd)
                                       password:@"password"
                                     completion:^(NSError * error) {
        XCTAssertNil(error);
        [expectationA fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTestExpectation *expectationB = [self expectationWithDescription:@"registration should fail"];
    [[self.app emailPasswordAuth] registerEmail:NSStringFromSelector(_cmd)
                                       password:@"password"
                                     completion:^(NSError * error) {
        XCTAssertNotNil(error);
        [expectationB fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Errors reported in RLMSyncManager.errorHandler shouldn't contain sync error domain errors as underlying error

- (void)testSyncErrorHandlerErrorDomain {
    RLMUser *user = [self userForTest:_cmd];
    XCTAssertNotNil(user);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"should fail after setting bad token"];
    [self.app syncManager].errorHandler = ^(__unused NSError *error, __unused RLMSyncSession *session) {
        XCTAssertTrue([error.domain isEqualToString:RLMSyncErrorDomain]);
        XCTAssertFalse([[error.userInfo[kRLMSyncUnderlyingErrorKey] domain] isEqualToString:RLMSyncErrorDomain]);
        [expectation fulfill];
    };

    [self manuallySetAccessTokenForUser:user value:[self badAccessToken]];
    [self manuallySetRefreshTokenForUser:user value:[self badAccessToken]];
    
    [self openRealmForPartitionValue:self.appId user:user];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - Basic Sync

/// It should be possible to successfully open a Realm configured for sync with a normal user.
- (void)testOpenRealmWithNormalCredentials {
    RLMUser *user = [self userForTest:_cmd];
    RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
    XCTAssertTrue(realm.isEmpty);
}

/// If client B adds objects to a synced Realm, client A should see those objects.
- (void)testAddObjects {
    RLMUser *user = [self userForTest:_cmd];
    NSString *realmId = self.appId;
    RLMRealm *realm = [self openRealmForPartitionValue:realmId
                                                  user:user];
    if (self.isParent) {
        CHECK_COUNT(0, Person, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(4, Person, realm);
    } else {
        // Add objects.
        [self addPersonsToRealm:realm
                        persons:@[[Person johnWithRealmId:realmId],
                                  [Person paulWithRealmId:realmId],
                                  [Person ringoWithRealmId:realmId],
                                  [Person georgeWithRealmId:realmId]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(4, Person, realm);
    }
}

/// If client B adds objects to a synced Realm, client A should see those objects.
- (void)testSessionRefresh {
    RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd) register:self.isParent]];
    RLMUser *user2 = [self logInUserForCredentials:[self basicCredentialsWithName:@"lmao@10gen.com" register:self.isParent]];

    [user _syncUser]->update_access_token(self.badAccessToken.UTF8String);

    NSString *realmId = self.appId;
    RLMRealm *realm = [self openRealmForPartitionValue:realmId user:user];
    RLMRealm *realm2 = [self openRealmForPartitionValue:realmId user:user2];
    if (self.isParent) {
        CHECK_COUNT(0, Person, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user
                               realms:@[realm]
                      partitionValues:@[realmId] expectedCounts:@[@4]];
        [self waitForDownloadsForUser:user2
                               realms:@[realm2]
                      partitionValues:@[realmId] expectedCounts:@[@4]];
    } else {
        // Add objects.
        [self addPersonsToRealm:realm
                        persons:@[[Person johnWithRealmId:realmId],
                                  [Person paulWithRealmId:realmId],
                                  [Person ringoWithRealmId:realmId],
                                  [Person georgeWithRealmId:realmId]]];
        [self waitForUploadsForRealm:realm];
    }
}

/// If client B deletes objects from a synced Realm, client A should see the effects of that deletion.
- (void)testDeleteObjects {
    RLMUser *user = [self userForTest:_cmd];
    RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
    if (self.isParent) {
        // Add objects.
        [self addPersonsToRealm:realm persons:@[[Person johnWithRealmId:self.appId]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(0, Person, realm);
    } else {
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(0, Person, realm);
    }
}

#pragma mark - Encryption -

/// If client B encrypts its synced Realm, client A should be able to access that Realm with a different encryption key.
- (void)testEncryptedSyncedRealm {
    RLMUser *user = [self userForTest:_cmd];

    NSData *key = RLMGenerateKey();
    RLMRealm *realm = [self openRealmForPartitionValue:self.appId
                                                  user:user
                                         encryptionKey:key
                                            stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                                      immediatelyBlock:nil];

    if (self.isParent) {
        CHECK_COUNT(0, Person, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user
                               realms:@[realm]
                      partitionValues:@[self.appId]
                       expectedCounts:@[@1]];
    } else {
        // Add objects.
        [self addPersonsToRealm:realm persons:@[[Person johnWithRealmId:self.appId]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    }
}

/// If an encrypted synced Realm is re-opened with the wrong key, throw an exception.
- (void)testEncryptedSyncedRealmWrongKey {
    RLMUser *user = [self userForTest:_cmd];

    if (self.isParent) {
        NSString *path;
        @autoreleasepool {
            RLMRealm *realm = [self openRealmForPartitionValue:self.appId
                                                          user:user
                                                 encryptionKey:RLMGenerateKey()
                                                    stopPolicy:RLMSyncStopPolicyImmediately
                                              immediatelyBlock:nil];
            path = realm.configuration.pathOnDisk;
            CHECK_COUNT(0, Person, realm);
            RLMRunChildAndWait();
            [self waitForDownloadsForUser:user
                                   realms:@[realm]
                          partitionValues:@[self.appId]
                           expectedCounts:@[@1]];
        }

        RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
        c.fileURL = [NSURL fileURLWithPath:path];
        RLMAssertThrowsWithError([RLMRealm realmWithConfiguration:c error:nil],
                                 @"Unable to open a realm at path",
                                 RLMErrorFileAccess,
                                 @"Realm file initial open failed");
        c.encryptionKey = RLMGenerateKey();
        RLMAssertThrowsWithError([RLMRealm realmWithConfiguration:c error:nil],
                                 @"Unable to open a realm at path",
                                 RLMErrorFileAccess,
                                 @"Realm file decryption failed");
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId
                                                      user:user
                                             encryptionKey:RLMGenerateKey()
                                                stopPolicy:RLMSyncStopPolicyImmediately
                                          immediatelyBlock:nil];
        [self addPersonsToRealm:realm persons:@[[Person johnWithRealmId:self.appId]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    }
}

#pragma mark - Multiple Realm Sync

/// If a client opens multiple Realms, there should be one session object for each Realm that was opened.
- (void)testMultipleRealmsSessions {
    NSString *partitionValueA = self.appId;
    NSString *partitionValueB = @"bar";
    NSString *partitionValueC = @"baz";
    RLMUser *user = [self userForTest:_cmd];

    // Open three Realms.

    __attribute__((objc_precise_lifetime)) RLMRealm *realmealmA = [self openRealmForPartitionValue:partitionValueA
                                                                                              user:user];
    __attribute__((objc_precise_lifetime)) RLMRealm *realmealmB = [self openRealmForPartitionValue:partitionValueB
                                                                                              user:user];
    __attribute__((objc_precise_lifetime)) RLMRealm *realmealmC = [self openRealmForPartitionValue:partitionValueC
                                                                                              user:user];
    // Make sure there are three active sessions for the user.
    XCTAssert(user.allSessions.count == 3, @"Expected 3 sessions, but didn't get 3 sessions");
    XCTAssertNotNil([user sessionForPartitionValue:partitionValueA],
                    @"Expected to get a session for partition value A");
    XCTAssertNotNil([user sessionForPartitionValue:partitionValueB],
                    @"Expected to get a session for partition value B");
    XCTAssertNotNil([user sessionForPartitionValue:partitionValueC],
                    @"Expected to get a session for partition value C");
    XCTAssertTrue([user sessionForPartitionValue:partitionValueA].state == RLMSyncSessionStateActive,
                  @"Expected active session for URL A");
    XCTAssertTrue([user sessionForPartitionValue:partitionValueB].state == RLMSyncSessionStateActive,
                  @"Expected active session for URL B");
    XCTAssertTrue([user sessionForPartitionValue:partitionValueC].state == RLMSyncSessionStateActive,
                  @"Expected active session for URL C");
}

/// A client should be able to open multiple Realms and add objects to each of them.
- (void)testMultipleRealmsAddObjects {
    NSString *partitionValueA = self.appId;
    NSString *partitionValueB = @"bar";
    NSString *partitionValueC = @"baz";
    RLMUser *user = [self userForTest:_cmd];

    RLMRealm *realmA = [self openRealmForPartitionValue:partitionValueA user:user];
    RLMRealm *realmB = [self openRealmForPartitionValue:partitionValueB user:user];
    RLMRealm *realmC = [self openRealmForPartitionValue:partitionValueC user:user];

    if (self.isParent) {
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(0, Person, realmB);
        CHECK_COUNT(0, Person, realmC);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user
                               realms:@[realmA, realmB, realmC]
                      partitionValues:@[partitionValueA,
                                        partitionValueB,
                                        partitionValueC]
                       expectedCounts:@[@3, @2, @5]];

        RLMResults *resultsA = [Person objectsInRealm:realmA where:@"firstName == %@", @"Ringo"];
        RLMResults *resultsB = [Person objectsInRealm:realmB where:@"firstName == %@", @"Ringo"];

        XCTAssertEqual([resultsA count], 1UL);
        XCTAssertEqual([resultsB count], 0UL);
    } else {
        // Add objects.
        [self addPersonsToRealm:realmA
                        persons:@[[Person johnWithRealmId:partitionValueA],
                                  [Person paulWithRealmId:partitionValueA],
                                  [Person ringoWithRealmId:partitionValueA]]];
        [self addPersonsToRealm:realmB
                        persons:@[[Person johnWithRealmId:partitionValueB],
                                  [Person paulWithRealmId:partitionValueB]]];
        [self addPersonsToRealm:realmC
                        persons:@[[Person johnWithRealmId:partitionValueC],
                                  [Person paulWithRealmId:partitionValueC],
                                  [Person ringoWithRealmId:partitionValueC],
                                  [Person georgeWithRealmId:partitionValueC],
                                  [Person ringoWithRealmId:partitionValueC]]];
        [self waitForUploadsForRealm:realmA];
        [self waitForUploadsForRealm:realmB];
        [self waitForUploadsForRealm:realmC];
        CHECK_COUNT(3, Person, realmA);
        CHECK_COUNT(2, Person, realmB);
        CHECK_COUNT(5, Person, realmC);
    }
}

/// A client should be able to open multiple Realms and delete objects from each of them.
- (void)testMultipleRealmsDeleteObjects {
    NSString *partitionValueA = self.appId;
    NSString *partitionValueB = @"bar";
    NSString *partitionValueC = @"baz";
    RLMUser *user = [self userForTest:_cmd];
    RLMRealm *realmA = [self openRealmForPartitionValue:partitionValueA user:user];
    RLMRealm *realmB = [self openRealmForPartitionValue:partitionValueB user:user];
    RLMRealm *realmC = [self openRealmForPartitionValue:partitionValueC user:user];

    if (self.isParent) {
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
        // Add objects.
        [self addPersonsToRealm:realmA
                        persons:@[[Person johnWithRealmId:partitionValueA],
                                  [Person paulWithRealmId:partitionValueA],
                                  [Person ringoWithRealmId:partitionValueA],
                                  [Person georgeWithRealmId:partitionValueA]]];
        [self addPersonsToRealm:realmB
                        persons:@[[Person johnWithRealmId:partitionValueB],
                                  [Person paulWithRealmId:partitionValueB],
                                  [Person ringoWithRealmId:partitionValueB],
                                  [Person georgeWithRealmId:partitionValueB],
                                  [Person georgeWithRealmId:partitionValueB]]];
        [self addPersonsToRealm:realmC
                        persons:@[[Person johnWithRealmId:partitionValueC],
                                  [Person paulWithRealmId:partitionValueC]]];

        [self waitForUploadsForRealm:realmA];
        [self waitForUploadsForRealm:realmB];
        [self waitForUploadsForRealm:realmC];
        CHECK_COUNT(4, Person, realmA);
        CHECK_COUNT(5, Person, realmB);
        CHECK_COUNT(2, Person, realmC);
        RLMRunChildAndWait();
        [self waitForDownloadsForUser:user
                               realms:@[realmA, realmB, realmC]
                      partitionValues:@[partitionValueA,
                                        partitionValueB,
                                        partitionValueC]
                       expectedCounts:@[@0, @0, @0]];
    } else {
        // Delete all the objects from the Realms.
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
        CHECK_COUNT(4, Person, realmA);
        CHECK_COUNT(5, Person, realmB);
        CHECK_COUNT(2, Person, realmC);
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
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(0, Person, realmB);
        CHECK_COUNT(0, Person, realmC);
    }
}

#pragma mark - Session Lifetime
/// When a session opened by a Realm goes out of scope, it should stay alive long enough to finish any waiting uploads.
- (void)testUploadChangesWhenRealmOutOfScope {
    const NSInteger OBJECT_COUNT = 3;
    // Log in the user.
    RLMUser *user = [self userForTest:_cmd];

    if (self.isParent) {
        // Open the Realm in an autorelease pool so that it is destroyed as soon as possible.
        @autoreleasepool {
            RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
            [self addPersonsToRealm:realm
                            persons:@[[Person johnWithRealmId:self.appId],
                                      [Person paulWithRealmId:self.appId],
                                      [Person ringoWithRealmId:self.appId]]];
            CHECK_COUNT(OBJECT_COUNT, Person, realm);

            [self waitForUploadsForRealm:realm];
        }

        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        // Wait for download to complete.
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(OBJECT_COUNT, Person, realm);
    }
}

#pragma mark - Logging Back In

/// A Realm that was opened before a user logged out should be able to resume uploading if the user logs back in.
- (void)testLogBackInSameRealmUpload {
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:YES];
    RLMUser *user = [self logInUserForCredentials:credentials];
    RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];

    [self addPersonsToRealm:realm persons:@[[Person johnWithRealmId:self.appId]]];
    CHECK_COUNT(1, Person, realm);
    [self waitForUploadsForRealm:realm];
    // Log out the user.
    [self logOutUser:user];
    // Log the user back in.
    user = [self logInUserForCredentials:credentials];
    [self addPersonsToRealm:realm
                    persons:@[[Person johnWithRealmId:self.appId],
                              [Person paulWithRealmId:self.appId],
                              [Person ringoWithRealmId:self.appId]]];
    CHECK_COUNT(4, Person, realm);
}

// FIXME: Depencancy on Stitch deployment
/// A Realm that was opened before a user logged out should be able to resume downloading if the user logs back in.
#if 0
- (void)testLogBackInSameRealmDownload {
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:YES];
    RLMUser *user = [self logInUserForCredentials:credentials];
    RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];

    [self addPersonsToRealm:realm persons:@[[Person john]]];
    CHECK_COUNT(1, Person, realm);
    [self waitForUploadsForRealm:realm];
    // Log out the user.
    [self logOutUser:user];
    // Log the user back in.
    user = [self logInUserForCredentials:credentials];
    [self waitForDownloadsForRealm:realm];
    [self addPersonsToRealm:realm
                    persons:@[[Person john],
                              [Person paul],
                              [Person ringo]]];
    [self waitForUploadsForRealm:realm];

    CHECK_COUNT(4, Person, realm);
}

// FIXME: Disabled until sync server fixes progress notifications

/// A Realm that was opened while a user was logged out should be able to start uploading if the user logs back in.
- (void)testLogBackInDeferredRealmUpload {
    // Log in the user.
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:YES];
    RLMUser *user = [self logInUserForCredentials:credentials];

    NSError *error = nil;
    if (self.isParent) {
        // Semaphore for knowing when the Realm is successfully opened for sync.
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self logOutUser:user];
        // Open a Realm after the user's been logged out.
        [self primeSyncManagerWithSemaphore:sema];
        RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        
        [self addPersonsToRealm:realm
                        persons:@[[Person john]]];
        
        CHECK_COUNT(1, Person, realm);
        user = [self logInUserForCredentials:credentials];
        // Wait for the Realm's session to be bound.
        WAIT_FOR_SEMAPHORE(sema, 30);
        [self addPersonsToRealm:realm
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person ringo]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(3, Person, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(3, Person, realm);
    }
}

/// A Realm that was opened while a user was logged out should be able to start downloading if the user logs back in.
- (void)testLogBackInDeferredRealmDownload {
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:YES];
    RLMUser *user = [self logInUserForCredentials:credentials];

    NSError *error = nil;
    if (self.isParent) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        RLMRunChildAndWait();

        [self logOutUser:user];
        // Open a Realm after the user's been logged out.
        [self primeSyncManagerWithSemaphore:sema];
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);

        [self addPersonsToRealm:realm persons:@[[Person john]]];
        CHECK_COUNT(1, Person, realm);

        user = [self logInUserForCredentials:credentials];

        // Wait for the Realm's session to be bound.
        WAIT_FOR_SEMAPHORE(sema, 30);

        [self waitForDownloadsForUser:user
                               realms:@[realm]
                      partitionValues:@[self.appId] expectedCounts:@[@4]];

    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        XCTAssertNil(error, @"Error when opening Realm: %@", error);
        [self addPersonsToRealm:realm
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person ringo]]];
        [self waitForUploadsForRealm:realm];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(3, Person, realm);
    }
}
#endif

/// After logging back in, a Realm whose path has been opened for the first time should properly upload changes.
- (void)testLogBackInOpenFirstTimePathUpload {
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];
    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [self logOutUser:user];
        // Log the user back in.
        user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                   register:NO]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        [self addPersonsToRealm:realm
                        persons:@[[Person johnWithRealmId:self.appId],
                                  [Person paulWithRealmId:self.appId]]];
        
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(2, Person, realm);
        RLMRunChildAndWait();
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        // Add objects.
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(2, Person, realm);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly download changes.
- (void)testLogBackInOpenFirstTimePathDownload {
    // Log in the user.
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                           register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    // Now run a basic multi-client test.
    if (self.isParent) {
        // Log out the user.
        [self logOutUser:user];
        // Log the user back in.
        user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                   register:NO]];
        // Open the Realm (for the first time).
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        // Run the sub-test.
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(2, Person, realm);
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        // Add objects.
        [self waitForDownloadsForRealm:realm];
        [self addPersonsToRealm:realm
                        persons:@[[Person johnWithRealmId:self.appId],
                                  [Person paulWithRealmId:self.appId]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(2, Person, realm);
    }
}

// FIXME: Dependancy on Stitch deployment
#if 0
/// If a client logs in, connects, logs out, and logs back in, sync should properly upload changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmUpload {
    // Log in the user.
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    // Open the Realm
    RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
    if (self.isParent) {
        [self addPersonsToRealm:realm
                        persons:@[[Person john]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
        // Log out the user.
        [self logOutUser:user];
        // Log the user back in.
        user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                   register:NO]];
        // Open the Realm again.
        RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        [self addPersonsToRealm:realm
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person george],
                                  [Person ringo]]];
        CHECK_COUNT(5, Person, realm);
        [self waitForUploadsForRealm:realm];
        RLMRunChildAndWait();
    } else {
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(5, Person, realm);
    }
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly download changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmDownload {
    // Log in the user.
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    // Open the Realm
    if (self.isParent) {
        RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        [self addPersonsToRealm:realm
                        persons:@[[Person john]]];
        [self waitForUploadsForRealm:realm];
        XCTAssert([Person allObjectsInRealm:realm].count == 1, @"Expected 1 item");
        // Log out the user.
        [self logOutUser:user];
        // Log the user back in.
        user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                   register:NO]];
        // Run the sub-test.
        RLMRunChildAndWait();
        // Open the Realm again and get the items.
        realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        [self waitForDownloadsForUser:user
                               realms:@[realm]
                      partitionValues:@[@"realm_id"] expectedCounts:@[@5]];
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        // Add objects.
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
        [self addPersonsToRealm:realm
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person george],
                                  [Person ringo]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(5, Person, realm);
    }
}

#pragma mark - Session suspend and resume

- (void)testSuspendAndResume {
    RLMUser *user = [self userForTest:_cmd];

    __attribute__((objc_precise_lifetime)) RLMRealm *realmA = [self openRealmForPartitionValue:@"realm_id" user:user];
    __attribute__((objc_precise_lifetime)) RLMRealm *realmB = [self openRealmForPartitionValue:@"realm_id" user:user];
    if (self.isParent) {
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(0, Person, realmB);
        
        // Suspend the session for realm A and then add an object to each Realm
        RLMSyncSession *sessionA = [RLMSyncSession sessionForRealm:realmA];
        [sessionA suspend];
        
        [self addPersonsToRealm:realmA
                        persons:@[[Person john]]];

        [self addPersonsToRealm:realmB
                        persons:@[[Person ringo]]];
        [self waitForUploadsForRealm:realmB];
        RLMRunChildAndWait();
        
        // A should still be 1 since it's suspended. If it wasn't suspended, it
        // should have downloaded before B due to the ordering in the child.
        [self waitForDownloadsForRealm:realmB];
        CHECK_COUNT(1, Person, realmA);
        CHECK_COUNT(3, Person, realmB);

        // A should see the other two from the child after resuming
        [sessionA resume];
        [self waitForDownloadsForRealm:realmA];
        CHECK_COUNT(3, Person, realmA);
    } else {
        // Child shouldn't see the object in A
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(1, Person, realmB);
        [self addPersonsToRealm:realmA
                        persons:@[[Person john],
                                  [Person paul]]];
        [self waitForUploadsForRealm:realmA];
        [self addPersonsToRealm:realmB
                        persons:@[[Person john],
                                  [Person paul]]];
        [self waitForUploadsForRealm:realmB];
        CHECK_COUNT(2, Person, realmA);
        CHECK_COUNT(3, Person, realmB);
    }
}
#endif

#pragma mark - Client reset

/// Ensure that a client reset error is propagated up to the binding successfully.
- (void)testClientReset {
    RLMUser *user = [self userForTest:_cmd];
    // Open the Realm
    __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];

    __block NSError *theError = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Waiting for error handler to be called..."];
    [self.app syncManager].errorHandler = ^void(NSError *error, RLMSyncSession *) {
        theError = error;
        [ex fulfill];
    };
    [user simulateClientResetErrorForSession:@"realm_id"];
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
    RLMUser *user = [self userForTest:_cmd];

    __block NSError *theError = nil;
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
        XCTestExpectation *ex = [self expectationWithDescription:@"Waiting for error handler to be called..."];
        [self.app syncManager].errorHandler = ^void(NSError *error, RLMSyncSession *) {
            theError = error;
            [ex fulfill];
        };
        [user simulateClientResetErrorForSession:@"realm_id"];
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

- (void)populateDataForUser:(RLMUser *)user partitionValue:(NSString *)partitionValue {
    RLMRealm *realm = [self openRealmForPartitionValue:partitionValue user:user];
    [realm beginWriteTransaction];
    for (NSInteger i=0; i<NUMBER_OF_BIG_OBJECTS; i++) {
        [realm addObject:[HugeSyncObject objectWithRealmId:partitionValue]];
    }
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
}

// FIXME: Dependancy on Stitch deployment
#if 0
- (void)testStreamingDownloadNotifier {
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    if (!self.isParent) {
        [self populateDataForUser:user partitionValue:@"realm_id"];
        return;
    }

    __block NSInteger callCount = 0;
    __block NSUInteger transferred = 0;
    __block NSUInteger transferrable = 0;
    __block BOOL hasBeenFulfilled = NO;
    // Register a notifier.
    RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];
    RLMSyncSession *session = realm.syncSession;
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
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];
    __block NSInteger callCount = 0;
    __block NSUInteger transferred = 0;
    __block NSUInteger transferrable = 0;
    // Open the Realm
    RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id" user:user];

    // Register a notifier.
    RLMSyncSession *session = realm.syncSession;
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
        [realm addObject:[Person john]];
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

#endif

#pragma mark - Download Realm

- (void)testDownloadRealm {
    const NSInteger NUMBER_OF_BIG_OBJECTS = 2;
    RLMUser *user = [self userForTest:_cmd];

    if (!self.isParent) {
        [self populateDataForUser:user partitionValue:self.appId];
        return;
    }

    // Wait for the child process to upload everything.
    RLMRunChildAndWait();

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [user configurationWithPartitionValue:self.appId];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:c.pathOnDisk isDirectory:nil]);

    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
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
    RLMUser *user = [self userForTest:_cmd];

    if (!self.isParent) {
        [self populateDataForUser:user partitionValue:self.appId];
        return;
    }

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [user configurationWithPartitionValue:self.appId];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:c.pathOnDisk isDirectory:nil]);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];
    CHECK_COUNT(0, Person, realm);
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
                                callback:^(RLMRealm *realm, NSError *error) {
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
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];
    [self manuallySetAccessTokenForUser:user value:[self badAccessToken]];
    [self manuallySetRefreshTokenForUser:user value:[self badAccessToken]];
    auto ex = [self expectationWithDescription:@"async open"];
    auto c = [user configurationWithPartitionValue:self.appId];
    [RLMRealm asyncOpenWithConfiguration:c callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNil(realm);
        XCTAssertNotNil(error);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testCancelDownload {
    RLMUser *user = [self userForTest:_cmd];

    if (!self.isParent) {
        [self populateDataForUser:user partitionValue:self.appId];
        return;
    }

    // Wait for the child process to upload everything.
    RLMRunChildAndWait();

    // Use a serial queue for asyncOpen to ensure that the first one adds
    // the completion block before the second one cancels it
    RLMSetAsyncOpenQueue(dispatch_queue_create("io.realm.asyncOpen", 0));

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [user configurationWithPartitionValue:self.appId];

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

// FIXME: Dependancy on new stitch deployment
#if 0
- (void)testAsyncOpenProgressNotifications {
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent];
    RLMSUser *user = [self logInUserForCredentials:credentials];

    if (!self.isParent) {
        [self populateDataForUser:user partitionValue:self.appId];
        return;
    }

    RLMRunChildAndWait();

    XCTestExpectation *ex1 = [self expectationWithDescription:@"async open"];
    XCTestExpectation *ex2 = [self expectationWithDescription:@"download progress complete"];
    RLMRealmConfiguration *c = [user configurationWithPartitionValue:self.appId];

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
#endif

- (void)testAsyncOpenConnectionTimeout {
    [self resetSyncManager];

    NSTask *task = [[NSTask alloc] init];
    NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
    task.currentDirectoryPath = directory;
    task.launchPath = @"/usr/bin/ruby";
    task.arguments = @[[directory stringByAppendingPathComponent:@"run_baas.rb"], @"start_proxy", @"5678", @"2"];
    [task launch];

    RLMAppConfiguration *config = [[RLMAppConfiguration alloc] initWithBaseURL:@"http://localhost:5678"
                                                                     transport:[AsyncOpenConnectionTimeoutTransport new]
                                                                  localAppName:nil
                                                               localAppVersion:nil
                                                       defaultRequestTimeoutMS:60];
    RLMApp *app = [RLMApp appWithId:[[RealmObjectServer sharedServer] createApp] configuration:config];

    RLMRealmConfiguration *c = [self.anonymousUser configurationWithPartitionValue:self.appId];
    RLMSyncConfiguration *syncConfig = c.syncConfiguration;
    syncConfig.cancelAsyncOpenOnNonFatalErrors = true;
    c.syncConfiguration = syncConfig;

    RLMSyncTimeoutOptions *timeoutOptions = [RLMSyncTimeoutOptions new];
    timeoutOptions.connectTimeout = 1000.0;
    [app syncManager].timeoutOptions = timeoutOptions;

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
    [task terminate];
    [task waitUntilExit];
}

#pragma mark - Compact on Launch

- (void)testCompactOnLaunch {
    RLMUser *user = [self userForTest:_cmd];
    NSString *partitionValue = self.appId;
    NSString *path;
    // Create a large object and then delete it in the next transaction so that
    // the file is bloated
    @autoreleasepool {
        RLMRealm *realm = [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                                 user:user
                                                        encryptionKey:nil
                                                           stopPolicy:RLMSyncStopPolicyImmediately];
        [realm beginWriteTransaction];
        [realm addObject:[HugeSyncObject objectWithRealmId:partitionValue]];
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
    auto config = [user configurationWithPartitionValue:partitionValue];
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

#pragma mark - Mongo Client

- (void)testFindOneAndModifyOptions {
    NSDictionary<NSString *, id<RLMBSON>> *projection = @{@"name": @1, @"breed": @1};
    NSDictionary<NSString *, id<RLMBSON>> *sort = @{@"age" : @1, @"coat" : @1};

    RLMFindOneAndModifyOptions *findOneAndModifyOptions1 = [[RLMFindOneAndModifyOptions alloc] init];
    XCTAssertNil(findOneAndModifyOptions1.projection);
    XCTAssertNil(findOneAndModifyOptions1.sort);
    XCTAssertFalse(findOneAndModifyOptions1.shouldReturnNewDocument);
    XCTAssertFalse(findOneAndModifyOptions1.upsert);

    RLMFindOneAndModifyOptions *findOneAndModifyOptions2 = [[RLMFindOneAndModifyOptions alloc] init];
    findOneAndModifyOptions2.projection = projection;
    findOneAndModifyOptions2.sort = sort;
    XCTAssertNotNil(findOneAndModifyOptions2.projection);
    XCTAssertNotNil(findOneAndModifyOptions2.sort);
    findOneAndModifyOptions2.shouldReturnNewDocument = YES;
    findOneAndModifyOptions2.upsert = YES;
    XCTAssertTrue(findOneAndModifyOptions2.shouldReturnNewDocument);
    XCTAssertTrue(findOneAndModifyOptions2.upsert);

    XCTAssertFalse([findOneAndModifyOptions2.projection isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions2.projection isEqual:projection]);
    XCTAssertFalse([findOneAndModifyOptions2.sort isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions2.sort isEqual:sort]);

    RLMFindOneAndModifyOptions *findOneAndModifyOptions3 = [[RLMFindOneAndModifyOptions alloc]
                                                            initWithProjection:projection
                                                            sort:sort
                                                            upsert:YES
                                                            shouldReturnNewDocument:YES];
    
    XCTAssertNotNil(findOneAndModifyOptions3.projection);
    XCTAssertNotNil(findOneAndModifyOptions3.sort);
    XCTAssertTrue(findOneAndModifyOptions3.shouldReturnNewDocument);
    XCTAssertTrue(findOneAndModifyOptions3.upsert);
    XCTAssertFalse([findOneAndModifyOptions3.projection isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions3.projection isEqual:projection]);
    XCTAssertFalse([findOneAndModifyOptions3.sort isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions3.sort isEqual:sort]);

    findOneAndModifyOptions3.projection = nil;
    findOneAndModifyOptions3.sort = nil;
    XCTAssertNil(findOneAndModifyOptions3.projection);
    XCTAssertNil(findOneAndModifyOptions3.sort);
    
    RLMFindOneAndModifyOptions *findOneAndModifyOptions4 = [[RLMFindOneAndModifyOptions alloc]
                                                            initWithProjection:nil
                                                            sort:nil
                                                            upsert:NO
                                                            shouldReturnNewDocument:NO];

    XCTAssertNil(findOneAndModifyOptions4.projection);
    XCTAssertNil(findOneAndModifyOptions4.sort);
    XCTAssertFalse(findOneAndModifyOptions4.upsert);
    XCTAssertFalse(findOneAndModifyOptions4.shouldReturnNewDocument);
}

- (void)testFindOptions {
    NSDictionary<NSString *, id<RLMBSON>> *projection = @{@"name": @1, @"breed": @1};
    NSDictionary<NSString *, id<RLMBSON>> *sort = @{@"age" : @1, @"coat" : @1};

    RLMFindOptions *findOptions1 = [[RLMFindOptions alloc] init];
    findOptions1.limit = 37;
    XCTAssertNil(findOptions1.projection);
    findOptions1.projection = projection;
    XCTAssertTrue([findOptions1.projection isEqual:projection]);
    XCTAssertNil(findOptions1.sort);
    findOptions1.sort = sort;
    XCTAssertTrue([findOptions1.sort isEqual:sort]);
    XCTAssertEqual(findOptions1.limit, 37);

    RLMFindOptions *findOptions2 = [[RLMFindOptions alloc] initWithProjection:projection
                                                                         sort:sort];
    XCTAssertTrue([findOptions2.projection isEqual:projection]);
    XCTAssertTrue([findOptions2.sort isEqual:sort]);
    XCTAssertEqual(findOptions2.limit, 0);
    
    RLMFindOptions *findOptions3 = [[RLMFindOptions alloc] initWithLimit:37
                                                              projection:projection
                                                                    sort:sort];
    XCTAssertTrue([findOptions3.projection isEqual:projection]);
    XCTAssertTrue([findOptions3.sort isEqual:sort]);
    XCTAssertEqual(findOptions3.limit, 37);

    findOptions3.projection = nil;
    findOptions3.sort = nil;
    XCTAssertNil(findOptions3.projection);
    XCTAssertNil(findOptions3.sort);

    RLMFindOptions *findOptions4 = [[RLMFindOptions alloc] initWithProjection:nil
                                                                         sort:nil];
    XCTAssertNil(findOptions4.projection);
    XCTAssertNil(findOptions4.sort);
    XCTAssertEqual(findOptions4.limit, 0);
}

- (void)testMongoInsert {
    RLMMongoClient *client = [self.anonymousUser mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"Dog"];

    [self cleanupRemoteDocuments:collection];

    XCTestExpectation *insertOneExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertOneDocument:@{@"name": @"fido", @"breed": @"cane corso"} completion:^(RLMObjectId * objectId, NSError * error) {
        XCTAssertTrue(![objectId.stringValue isEqualToString:@""]);
        XCTAssertNil(error);
        [insertOneExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<RLMObjectId *> * objectIds, NSError * error) {
        XCTAssertTrue(objectIds.count > 0);
        XCTAssertNil(error);
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation = [self expectationWithDescription:@"should find documents"];
    RLMFindOptions *options = [[RLMFindOptions alloc] initWithLimit:0 projection:nil sort:nil];
    [collection findWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                  options:options
               completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertEqual((int)documents.count, 3);
        XCTAssertNil(error);
        [findExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoFind {
    RLMMongoClient *client = [self.anonymousUser mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"Dog"];

    [self cleanupRemoteDocuments:collection];

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<RLMObjectId *> * objectIds, NSError * error) {
        XCTAssertTrue(objectIds.count > 0);
        XCTAssertNil(error);
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation = [self expectationWithDescription:@"should find documents"];
    RLMFindOptions *options = [[RLMFindOptions alloc] initWithLimit:0 projection:nil sort:nil];
    [collection findWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                  options:options
               completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertEqual((int)documents.count, 2);
        XCTAssertNil(error);
        [findExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation2 = [self expectationWithDescription:@"should find documents"];
    [collection findWhere:@{@"name": @"fido", @"breed": @"cane corso"}
               completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertEqual((int)documents.count, 2);
        XCTAssertNil(error);
        [findExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation3 = [self expectationWithDescription:@"should not find documents"];
    [collection findWhere:@{@"name": @"should not exist", @"breed": @"should not exist"}
               completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertEqual(documents.count, NSUInteger(0));
        XCTAssertNil(error);
        [findExpectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation4 = [self expectationWithDescription:@"should not find documents"];
    [collection findWhere:@{}
               completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertTrue(documents.count > 0);
        XCTAssertNil(error);
        [findExpectation4 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneExpectation1 = [self expectationWithDescription:@"should find documents"];
    [collection findOneDocumentWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                          completion:^(NSDictionary * document, NSError * error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"fido"]);
        XCTAssertTrue([document[@"breed"] isEqualToString:@"cane corso"]);
        XCTAssertNil(error);
        [findOneExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneExpectation2 = [self expectationWithDescription:@"should find documents"];
    [collection findOneDocumentWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                             options:options
                          completion:^(NSDictionary * document, NSError * error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"fido"]);
        XCTAssertTrue([document[@"breed"] isEqualToString:@"cane corso"]);
        XCTAssertNil(error);
        [findOneExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoAggregateAndCount {
    RLMMongoClient *client = [self.anonymousUser mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"Dog"];

    [self cleanupRemoteDocuments:collection];

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<RLMObjectId *> * objectIds, NSError * error) {
        XCTAssertTrue(objectIds.count > 0);
        XCTAssertNil(error);
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *aggregateExpectation1 = [self expectationWithDescription:@"should aggregate documents"];
    [collection aggregateWithPipeline:@[@{@"name" : @"fido"}]
                           completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain.description isEqualToString:@"realm::app::ServiceError"]);
        XCTAssertNil(documents);
        [aggregateExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *aggregateExpectation2 = [self expectationWithDescription:@"should aggregate documents"];
    [collection aggregateWithPipeline:@[@{@"$match" : @{@"name" : @"fido"}}, @{@"$group" : @{@"_id" : @"$name"}}]
                           completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertNotNil(documents);
        XCTAssertTrue(documents.count > 0);
        XCTAssertNil(error);
        [aggregateExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *countExpectation1 = [self expectationWithDescription:@"should aggregate documents"];
    [collection countWhere:@{@"name" : @"fido"}
                completion:^(NSInteger count, NSError * error) {
        XCTAssertTrue(count > 0);
        XCTAssertNil(error);
        [countExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *countExpectation2 = [self expectationWithDescription:@"should aggregate documents"];
    [collection countWhere:@{@"name" : @"fido"}
                     limit:1
                completion:^(NSInteger count, NSError * error) {
        XCTAssertEqual(count, 1);
        XCTAssertNil(error);
        [countExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoUpdate {
    RLMMongoClient *client = [self.anonymousUser mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"Dog"];

    [self cleanupRemoteDocuments:collection];

    XCTestExpectation *updateExpectation1 = [self expectationWithDescription:@"should update document"];
    [collection updateOneDocumentWhere:@{@"name" : @"scrabby doo"}
                        updateDocument:@{@"name" : @"scooby"}
                                upsert:YES
                            completion:^(RLMUpdateResult * result, NSError * error) {
        XCTAssertNotNil(result);
        XCTAssertNotNil(result.objectId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)0);
        XCTAssertEqual(result.matchedCount, (NSUInteger)0);
        XCTAssertNil(error);
        [updateExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateExpectation2 = [self expectationWithDescription:@"should update document"];
    [collection updateOneDocumentWhere:@{@"name" : @"scooby"}
                        updateDocument:@{@"name" : @"fred"}
                                upsert:NO
                            completion:^(RLMUpdateResult * result, NSError * error) {
        XCTAssertNotNil(result);
        XCTAssertNil(result.objectId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)1);
        XCTAssertEqual(result.matchedCount, (NSUInteger)1);
        XCTAssertNil(error);
        [updateExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateExpectation3 = [self expectationWithDescription:@"should update document"];
    [collection updateOneDocumentWhere:@{@"name" : @"fred"}
                        updateDocument:@{@"name" : @"scrabby"}
                            completion:^(RLMUpdateResult * result, NSError * error) {
        XCTAssertNotNil(result);
        XCTAssertNil(result.objectId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)1);
        XCTAssertEqual(result.matchedCount, (NSUInteger)1);
        XCTAssertNil(error);
        [updateExpectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateManyExpectation1 = [self expectationWithDescription:@"should update many documents"];
    [collection updateManyDocumentsWhere:@{@"name" : @"scrabby"}
                          updateDocument:@{@"name" : @"fred"}
                              completion:^(RLMUpdateResult * result, NSError * error) {
        XCTAssertNotNil(result);
        XCTAssertNil(result.objectId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)1);
        XCTAssertEqual(result.matchedCount, (NSUInteger)1);
        XCTAssertNil(error);
        [updateManyExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateManyExpectation2 = [self expectationWithDescription:@"should update many documents"];
    [collection updateManyDocumentsWhere:@{@"name" : @"john"}
                          updateDocument:@{@"name" : @"alex"}
                                  upsert:YES
                              completion:^(RLMUpdateResult * result, NSError * error) {
        XCTAssertNotNil(result);
        XCTAssertNotNil(result.objectId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)0);
        XCTAssertEqual(result.matchedCount, (NSUInteger)0);
        XCTAssertNil(error);
        [updateManyExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoFindAndModify {
    RLMMongoClient *client = [self.anonymousUser mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"Dog"];

    [self cleanupRemoteDocuments:collection];

    RLMFindOneAndModifyOptions *findAndModifyOptions = [[RLMFindOneAndModifyOptions alloc] initWithProjection:@{@"name" : @1, @"breed" : @1}
                                                                                                         sort:@{@"name" : @1, @"breed" : @1}
                                                                                                       upsert:YES
                                                                                      shouldReturnNewDocument:YES];

    XCTestExpectation *findOneAndUpdateExpectation1 = [self expectationWithDescription:@"should find one document and update"];
    [collection findOneAndUpdateWhere:@{@"name" : @"alex"}
                       updateDocument:@{@"name" : @"max"}
                              options:findAndModifyOptions
                           completion:^(NSDictionary * document, NSError * error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndUpdateExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndUpdateExpectation2 = [self expectationWithDescription:@"should find one document and update"];
    [collection findOneAndUpdateWhere:@{@"name" : @"max"}
                       updateDocument:@{@"name" : @"john"}
                           completion:^(NSDictionary * document, NSError * error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndUpdateExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndReplaceExpectation1 = [self expectationWithDescription:@"should find one document and replace"];
    [collection findOneAndReplaceWhere:@{@"name" : @"alex"}
                   replacementDocument:@{@"name" : @"max"}
                               options:findAndModifyOptions
                            completion:^(NSDictionary * document, NSError * error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndReplaceExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndReplaceExpectation2 = [self expectationWithDescription:@"should find one document and replace"];
    [collection findOneAndReplaceWhere:@{@"name" : @"max"}
                   replacementDocument:@{@"name" : @"john"}
                            completion:^(NSDictionary * document, NSError * error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndReplaceExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoDelete {
    RLMMongoClient *client = [self.anonymousUser mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"Dog"];

    [self cleanupRemoteDocuments:collection];
    __block RLMObjectId * fidoObjectId;
    __block RLMObjectId * rexObjectId;

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"},
        @{@"name": @"john", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<RLMObjectId *> * objectIds, NSError * error) {
        XCTAssertEqual((int)objectIds.count, 3);
        XCTAssertNil(error);
        fidoObjectId = objectIds[0];
        rexObjectId = objectIds[1];
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *deleteOneExpectation1 = [self expectationWithDescription:@"should delete first document in collection"];
    [collection deleteOneDocumentWhere:@{@"_id" : rexObjectId}
                            completion:^(NSInteger count, NSError * error) {
        XCTAssertTrue(count == 1);
        XCTAssertNil(error);
        [deleteOneExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation1 = [self expectationWithDescription:@"should find documents"];
    [collection findWhere:@{}
               completion:^(NSArray<NSDictionary *> * documents, NSError * error) {
        XCTAssertEqual((int)documents.count, 2);
        XCTAssertTrue([documents[0][@"name"] isEqualToString:@"fido"]);
        XCTAssertNil(error);
        [findExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *deleteManyExpectation1 = [self expectationWithDescription:@"should delete many documents"];
    [collection deleteManyDocumentsWhere:@{@"name" : @"rex"}
                              completion:^(NSInteger count, NSError * error) {
        XCTAssertTrue(count == 0);
        XCTAssertNil(error);
        [deleteManyExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *deleteManyExpectation2 = [self expectationWithDescription:@"should delete many documents"];
    [collection deleteManyDocumentsWhere:@{@"breed" : @"cane corso"}
                              completion:^(NSInteger count, NSError * error) {
        XCTAssertTrue(count == 1);
        XCTAssertNil(error);
        [deleteManyExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndDeleteExpectation1 = [self expectationWithDescription:@"should find one and delete"];
    [collection findOneAndDeleteWhere:@{@"name": @"john"}
                           completion:^(NSDictionary<NSString *, id<RLMBSON>> * document, NSError * error) {
        XCTAssertNotNil(document);
        NSString *name = (NSString *)document[@"name"];
        XCTAssertTrue([name isEqualToString:@"john"]);
        XCTAssertNil(error);
        [findOneAndDeleteExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    // FIXME: It seems there is a possible server bug that does not handle
    // `projection` in `RLMFindOneAndModifyOptions` correctly. The returned error is:
    // "expected pre-image to match projection matcher"
    /*
    XCTestExpectation *findOneAndDeleteExpectation2 = [self expectationWithDescription:@"should find one and delete"];
    NSDictionary<NSString *, id<RLMBSON>> *projection = @{@"name": @1, @"breed": @1};
    NSDictionary<NSString *, id<RLMBSON>> *sort = @{@"_id" : @1, @"breed" : @1};
    RLMFindOneAndModifyOptions *findOneAndModifyOptions = [[RLMFindOneAndModifyOptions alloc]
                                                           initWithProjection:projection
                                                           sort:sort
                                                           upsert:YES
                                                           shouldReturnNewDocument:YES];
    
    [collection findOneAndDeleteWhere:@{@"name": @"john"}
                              options:findOneAndModifyOptions
                           completion:^(NSDictionary<NSString *, id<RLMBSON>> * document, NSError * error) {
        XCTAssertNil(document);
        XCTAssertNil(error);
        [findOneAndDeleteExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
    */
}

#pragma mark - Read Only

- (void)testOpenSynchronouslyInReadOnlyBeforeRemoteSchemaIsInitialized {
    RLMUser *user = [self userForTest:_cmd];
    NSString *realmId = self.appId;

    if (self.isParent) {
        RLMRealmConfiguration *config = [user configurationWithPartitionValue:realmId];
        config.readOnly = true;
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        CHECK_COUNT(0, Person, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        [self addPersonsToRealm:realm persons:@[[Person johnWithRealmId:realmId]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    }
}

- (void)testAddPropertyToReadOnlyRealmWithExistingLocalCopy {
    RLMUser *user = [self userForTest:_cmd];
    NSString *realmId = self.appId;

    if (!self.isParent) {
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        [self addPersonsToRealm:realm persons:@[[Person johnWithRealmId:realmId]]];
        [self waitForUploadsForRealm:realm];
        return;
    }
    RLMRunChildAndWait();

    RLMRealmConfiguration *config = [user configurationWithPartitionValue:realmId];
    config.readOnly = true;
    @autoreleasepool {
        RLMRealm *realm = [self asyncOpenRealmWithConfiguration:config];
        CHECK_COUNT(1, Person, realm);
    }

    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:Person.class];
    objectSchema.properties = [RLMObjectSchema schemaForObjectClass:HugeSyncObject.class].properties;
    config.customSchema = [[RLMSchema alloc] init];
    config.customSchema.objectSchema = @[objectSchema];

    RLMAssertThrowsWithReason([RLMRealm realmWithConfiguration:config error:nil],
                              @"Property 'Person.dataProp' has been added.");

    @autoreleasepool {
        NSError *error = [self asyncOpenErrorWithConfiguration:config];
        XCTAssertNotEqual([error.localizedDescription rangeOfString:@"Property 'Person.dataProp' has been added."].location,
                          NSNotFound);
    }
}

- (void)testAddPropertyToReadOnlyRealmWithAsyncOpen {
    RLMUser *user = [self userForTest:_cmd];
    NSString *realmId = self.appId;

    if (!self.isParent) {
        RLMRealm *realm = [self openRealmForPartitionValue:self.appId user:user];
        [self addPersonsToRealm:realm persons:@[[Person johnWithRealmId:realmId]]];
        [self waitForUploadsForRealm:realm];
        return;
    }
    RLMRunChildAndWait();

    RLMRealmConfiguration *config = [user configurationWithPartitionValue:realmId];
    config.readOnly = true;

    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:Person.class];
    objectSchema.properties = [RLMObjectSchema schemaForObjectClass:HugeSyncObject.class].properties;
    config.customSchema = [[RLMSchema alloc] init];
    config.customSchema.objectSchema = @[objectSchema];

    @autoreleasepool {
        NSError *error = [self asyncOpenErrorWithConfiguration:config];
        XCTAssertNotEqual([error.localizedDescription rangeOfString:@"Property 'Person.dataProp' has been added."].location,
                          NSNotFound);
    }
}

@end
