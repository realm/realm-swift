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

#if TARGET_OS_OSX

#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMCredentials.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMRealm+Sync.h"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealmUtil.hpp"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMWatchTestUtility.h"

#import <realm/object-store/shared_realm.hpp>
#import <realm/object-store/sync/app_user.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/thread_safe_reference.hpp>
#import <realm/util/file.hpp>

#import <atomic>

#pragma mark - Helpers

@interface TimeoutProxyServer : NSObject
- (instancetype)initWithPort:(uint16_t)port targetPort:(uint16_t)targetPort;
- (void)startAndReturnError:(NSError **)error;
- (void)stop;
@property (nonatomic) double delay;
@end

@interface RLMObjectServerTests : RLMSyncTestCase
@end
@implementation RLMObjectServerTests

- (NSArray *)defaultObjectTypes {
    return @[
        AllTypesSyncObject.class,
        HugeSyncObject.class,
        IntPrimaryKeyObject.class,
        Person.class,
        RLMSetSyncObject.class,
        StringPrimaryKeyObject.class,
        UUIDPrimaryKeyObject.class,
    ];
}

#pragma mark - App Tests

static NSString *generateRandomString(int num) {
    NSMutableString *string = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [string appendFormat:@"%c", (char)('a' + arc4random_uniform(26))];
    }
    return string;
}

#pragma mark - Authentication and Tokens

- (void)testUpdateBaseUrl {
    RLMApp *app = self.app;
    XCTAssertEqualObjects(app.baseURL, @"http://localhost:9090");

    XCTestExpectation *expectation = [self expectationWithDescription:@"should update base url"];
    [app updateBaseURL:@"http://127.0.0.1:9090" completion:^(NSError *error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation]];
    XCTAssertEqualObjects(app.baseURL, @"http://127.0.0.1:9090");

    TimeoutProxyServer *proxy = [[TimeoutProxyServer alloc] initWithPort:7070 targetPort:9090];
    proxy.delay = 0;
    [proxy startAndReturnError:nil];

    expectation = [self expectationWithDescription:@"should update base url"];
    [app updateBaseURL:@"http://localhost:7070/" completion:^(NSError *error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation]];
    XCTAssertEqualObjects(app.baseURL, @"http://localhost:7070");
    [proxy stop];

    expectation = [self expectationWithDescription:@"should fail to update base url to default value"];
    [app updateBaseURL:nil completion:^(NSError *error) {
        // This fails because our local app doesn't exist in the prod env
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, RLMAppErrorUnknown);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation]];
    // baseURL update failed, so it's left unchanged
    XCTAssertEqualObjects(app.baseURL, @"http://localhost:7070");
}

- (void)testAnonymousAuthentication {
    RLMUser *syncUser = self.anonymousUser;
    RLMUser *currentUser = [self.app currentUser];
    XCTAssert([currentUser.identifier isEqualToString:syncUser.identifier]);
    XCTAssert([currentUser.refreshToken isEqualToString:syncUser.refreshToken]);
    XCTAssert([currentUser.accessToken isEqualToString:syncUser.accessToken]);
}

- (void)testCustomTokenAuthentication {
    RLMUser *user = [self logInUserForCredentials:[self jwtCredentialWithAppId:self.appId]];
    XCTAssertTrue([user.profile.metadata[@"anotherName"] isEqualToString:@"Bar Foo"]);
    XCTAssertTrue([user.profile.metadata[@"name"] isEqualToString:@"Foo Bar"]);
    XCTAssertTrue([user.profile.metadata[@"occupation"] isEqualToString:@"firefighter"]);
}

- (void)testCallFunction {
    XCTestExpectation *expectation = [self expectationWithDescription:@"should get sum of arguments from remote function"];
    [self.anonymousUser callFunctionNamed:@"sum"
                                arguments:@[@1, @2, @3, @4, @5]
                          completionBlock:^(id<RLMBSON> bson, NSError *error) {
        XCTAssert(!error);
        XCTAssertEqual([((NSNumber *)bson) intValue], 15);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
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
    RLMUser *firstUser = [self createUser];
    RLMUser *secondUser = [self createUser];

    XCTAssertEqualObjects(self.app.currentUser.identifier, secondUser.identifier);
    // `[app currentUser]` will now be `secondUser`, so let's logout firstUser and ensure
    // the state is correct
    XCTestExpectation *expectation = [self expectationWithDescription:@"should log out current user"];
    [firstUser logOutWithCompletion:^(NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(firstUser.state, RLMUserStateLoggedOut);
        XCTAssertEqual(secondUser.state, RLMUserStateLoggedIn);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

- (void)testSwitchUser {
    RLMUser *syncUserA = [self createUser];
    RLMUser *syncUserB = [self createUser];

    XCTAssertNotEqualObjects(syncUserA.identifier, syncUserB.identifier);
    XCTAssertEqualObjects(self.app.currentUser.identifier, syncUserB.identifier);

    XCTAssertEqualObjects([self.app switchToUser:syncUserA].identifier, syncUserA.identifier);
}

- (void)testRemoveUser {
    RLMUser *firstUser = [self createUser];
    RLMUser *secondUser = [self createUser];

    XCTAssert([self.app.currentUser.identifier isEqualToString:secondUser.identifier]);

    XCTestExpectation *removeUserExpectation = [self expectationWithDescription:@"should remove user"];

    [secondUser removeWithCompletion:^(NSError *error) {
        XCTAssert(!error);
        XCTAssert(self.app.allUsers.count == 1);
        XCTAssert([self.app.currentUser.identifier isEqualToString:firstUser.identifier]);
        [removeUserExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testDeleteUser {
    RLMUser *firstUser = [self createUser];
    RLMUser *secondUser = [self createUser];

    XCTAssert([self.app.currentUser.identifier isEqualToString:secondUser.identifier]);

    XCTestExpectation *deleteUserExpectation = [self expectationWithDescription:@"should delete user"];

    [secondUser deleteWithCompletion:^(NSError *error) {
        XCTAssert(!error);
        XCTAssert(self.app.allUsers.count == 1);
        XCTAssertEqualObjects(self.app.currentUser, firstUser);
        XCTAssertEqual(secondUser.state, RLMUserStateRemoved);
        [deleteUserExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testDeviceRegistration {
    RLMPushClient *client = [self.app pushClientWithServiceName:@"gcm"];
    auto expectation = [self expectationWithDescription:@"should register device"];
    [client registerDeviceWithToken:@"token" user:self.anonymousUser completion:^(NSError *error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];

    expectation = [self expectationWithDescription:@"should deregister device"];
    [client deregisterDeviceForUser:self.app.currentUser completion:^(NSError *error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

// FIXME: Reenable once possible underlying race condition is understood
- (void)fixme_testMultipleRegisterDevice {
    RLMApp *app = self.app;
    XCTestExpectation *registerExpectation = [self expectationWithDescription:@"should register device"];
    XCTestExpectation *secondRegisterExpectation = [self expectationWithDescription:@"should not throw error when attempting to register again"];

    RLMUser *user = self.anonymousUser;
    RLMPushClient *client = [app pushClientWithServiceName:@"gcm"];
    [client registerDeviceWithToken:@"token" user:user completion:^(NSError *_Nullable error) {
        XCTAssertNil(error);
        [registerExpectation fulfill];
    }];
    [self waitForExpectations:@[registerExpectation] timeout:10.0];

    [client registerDeviceWithToken:@"token" user:user completion:^(NSError *_Nullable error) {
        XCTAssertNil(error);
        [secondRegisterExpectation fulfill];
    }];
    [self waitForExpectations:@[secondRegisterExpectation] timeout:10.0];
}

#pragma mark - RLMEmailPasswordAuth

static NSString *randomEmail() {
    return [NSString stringWithFormat:@"%@@%@.com", generateRandomString(10), generateRandomString(10)];
}

- (void)testRegisterEmailAndPassword {
    XCTestExpectation *expectation = [self expectationWithDescription:@"should register with email and password"];

    NSString *randomPassword = generateRandomString(10);
    [self.app.emailPasswordAuth registerUserWithEmail:randomEmail() password:randomPassword completion:^(NSError *error) {
        XCTAssert(!error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testConfirmUser {
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try confirm user and fail"];

    [self.app.emailPasswordAuth confirmUser:randomEmail() tokenId:@"a_token" completion:^(NSError *error) {
        XCTAssertEqual(error.code, RLMAppErrorBadRequest);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testRetryCustomConfirmation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try retry confirmation email and fail"];

    [self.app.emailPasswordAuth retryCustomConfirmation:@"some-email@email.com" completion:^(NSError *error) {
        XCTAssertTrue([error.userInfo[@"NSLocalizedDescription"] isEqualToString:@"cannot run confirmation for some-email@email.com: automatic confirmation is enabled"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testResendConfirmationEmail {
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try resend confirmation email and fail"];

    [self.app.emailPasswordAuth resendConfirmationEmail:randomEmail() completion:^(NSError *error) {
        XCTAssertEqual(error.code, RLMAppErrorUserNotFound);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testResetPassword {
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try reset password and fail"];
    [self.app.emailPasswordAuth resetPasswordTo:@"APassword123" token:@"a_token" tokenId:@"a_token_id" completion:^(NSError *error) {
        XCTAssertEqual(error.code, RLMAppErrorBadRequest);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testCallResetPasswordFunction {
    XCTestExpectation *expectation = [self expectationWithDescription:@"should try call reset password function and fail"];
    [self.app.emailPasswordAuth callResetPasswordFunction:@"test@mongodb.com"
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

    NSString *randomPassword = generateRandomString(10);
    NSString *email = randomEmail();
    [self.app.emailPasswordAuth registerUserWithEmail:email password:randomPassword completion:^(NSError *error) {
        XCTAssert(!error);
        [registerExpectation fulfill];
    }];

    [self waitForExpectations:@[registerExpectation] timeout:60.0];

    [self.app loginWithCredential:[RLMCredentials credentialsWithEmail:email password:randomPassword]
                  completion:^(RLMUser *user, NSError *error) {
        XCTAssert(!error);
        XCTAssert(user);
        syncUser = user;
        [loginExpectation fulfill];
    }];

    [self waitForExpectations:@[loginExpectation] timeout:60.0];

    [[syncUser apiKeysAuth] createAPIKeyWithName:@"apiKeyName1" completion:^(RLMUserAPIKey *userAPIKey, NSError *error) {
        XCTAssert(!error);
        XCTAssert([userAPIKey.name isEqualToString:@"apiKeyName1"]);
        XCTAssert(![userAPIKey.key isEqualToString:@"apiKeyName1"] && userAPIKey.key.length > 0);
        userAPIKeyA = userAPIKey;
        [createAPIKeyExpectationA fulfill];
    }];

    [[syncUser apiKeysAuth] createAPIKeyWithName:@"apiKeyName2" completion:^(RLMUserAPIKey *userAPIKey, NSError *error) {
        XCTAssert(!error);
        XCTAssert([userAPIKey.name isEqualToString:@"apiKeyName2"]);
        userAPIKeyB = userAPIKey;
        [createAPIKeyExpectationB fulfill];
    }];

    [self waitForExpectations:@[createAPIKeyExpectationA, createAPIKeyExpectationB] timeout:60.0];

    // sleep for 2 seconds as there seems to be an issue fetching the keys straight after they are created.
    [NSThread sleepForTimeInterval:2];

    [[syncUser apiKeysAuth] fetchAPIKeysWithCompletion:^(NSArray<RLMUserAPIKey *> *_Nonnull apiKeys, NSError *error) {
        XCTAssert(!error);
        XCTAssert(apiKeys.count == 2);
        [fetchAPIKeysExpectation fulfill];
    }];

    [self waitForExpectations:@[fetchAPIKeysExpectation] timeout:60.0];

    [[syncUser apiKeysAuth] disableAPIKey:userAPIKeyA.objectId completion:^(NSError *error) {
        XCTAssert(!error);
        [disableAPIKeyExpectation fulfill];
    }];

    [self waitForExpectations:@[disableAPIKeyExpectation] timeout:60.0];

    [[syncUser apiKeysAuth] enableAPIKey:userAPIKeyA.objectId completion:^(NSError *error) {
        XCTAssert(!error);
        [enableAPIKeyExpectation fulfill];
    }];

    [self waitForExpectations:@[enableAPIKeyExpectation] timeout:60.0];

    [[syncUser apiKeysAuth] deleteAPIKey:userAPIKeyA.objectId completion:^(NSError *error) {
        XCTAssert(!error);
        [deleteAPIKeyExpectation fulfill];
    }];

    [self waitForExpectations:@[deleteAPIKeyExpectation] timeout:60.0];
}

#pragma mark - Link user -

- (void)testLinkUser {
    XCTestExpectation *registerExpectation = [self expectationWithDescription:@"should try register"];
    XCTestExpectation *loginExpectation = [self expectationWithDescription:@"should try login"];
    XCTestExpectation *linkExpectation = [self expectationWithDescription:@"should try link and fail"];

    __block RLMUser *syncUser;

    NSString *email = randomEmail();
    NSString *randomPassword = generateRandomString(10);

    [self.app.emailPasswordAuth registerUserWithEmail:email password:randomPassword completion:^(NSError *error) {
        XCTAssert(!error);
        [registerExpectation fulfill];
    }];

    [self waitForExpectations:@[registerExpectation] timeout:60.0];

    [self.app loginWithCredential:[RLMCredentials credentialsWithEmail:email password:randomPassword]
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

- (void)testEmailPasswordCredential {
    RLMCredentials *emailPasswordCredential = [RLMCredentials credentialsWithEmail:@"test@mongodb.com" password:@"apassword"];
    XCTAssertEqualObjects(emailPasswordCredential.provider, @"local-userpass");
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
    RLMCredentials *googleCredential = [RLMCredentials credentialsWithGoogleAuthCode:@"google token"];
    XCTAssertEqualObjects(googleCredential.provider, @"oauth2-google");
}

- (void)testGoogleIdCredential {
    RLMCredentials *googleCredential = [RLMCredentials credentialsWithGoogleIdToken:@"id token"];
    XCTAssertEqualObjects(googleCredential.provider, @"oauth2-google");
}

- (void)testAppleCredential {
    RLMCredentials *appleCredential = [RLMCredentials credentialsWithAppleToken:@"apple token"];
    XCTAssertEqualObjects(appleCredential.provider, @"oauth2-apple");
}

- (void)testFunctionCredential {
    NSError *error;
    RLMCredentials *functionCredential = [RLMCredentials credentialsWithFunctionPayload:@{@"dog": @{@"name": @"fido"}}];
    XCTAssertEqualObjects(functionCredential.provider, @"custom-function");
    XCTAssertEqualObjects(error, nil);
}

#pragma mark - Username Password

/// Valid email/password credentials should be able to log in a user. Using the same credentials should return the
/// same user object.
- (void)testEmailPasswordAuthentication {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name register:YES];
    RLMUser *firstUser = [self logInUserForCredentials:credentials];
    RLMUser *secondUser = [self logInUserForCredentials:credentials];
    // Two users created with the same credential should resolve to the same actual user.
    XCTAssertTrue([firstUser.identifier isEqualToString:secondUser.identifier]);
}

/// An invalid email/password credential should not be able to log in a user and a corresponding error should be generated.
- (void)testInvalidPasswordAuthentication {
    (void)[self basicCredentialsWithName:self.name register:YES];
    RLMCredentials *credentials = [RLMCredentials credentialsWithEmail:self.name
                                                              password:@"INVALID_PASSWORD"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"login should fail"];

    [self.app loginWithCredential:credentials completion:^(RLMUser *user, NSError *error) {
        XCTAssertNil(user);
        RLMValidateError(error, RLMAppErrorDomain, RLMAppErrorInvalidPassword,
                         @"unauthorized");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// A non-existsing user should not be able to log in and a corresponding error should be generated.
- (void)testNonExistingEmailAuthentication {
    RLMCredentials *credentials = [RLMCredentials credentialsWithEmail:@"INVALID_USERNAME"
                                                              password:@"INVALID_PASSWORD"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"login should fail"];

    [self.app loginWithCredential:credentials completion:^(RLMUser *user, NSError *error) {
        XCTAssertNil(user);
        RLMValidateError(error, RLMAppErrorDomain, RLMAppErrorInvalidPassword,
                         @"unauthorized");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Registering a user with existing email should return corresponding error.
- (void)testExistingEmailRegistration {
    XCTestExpectation *expectationA = [self expectationWithDescription:@"registration should succeed"];
    [self.app.emailPasswordAuth registerUserWithEmail:self.name
                                             password:@"password"
                                           completion:^(NSError *error) {
        XCTAssertNil(error);
        [expectationA fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTestExpectation *expectationB = [self expectationWithDescription:@"registration should fail"];
    [self.app.emailPasswordAuth registerUserWithEmail:self.name
                                             password:@"password"
                                           completion:^(NSError *error) {
        RLMValidateError(error, RLMAppErrorDomain, RLMAppErrorAccountNameInUse, @"name already in use");
        XCTAssertNotNil(error.userInfo[RLMServerLogURLKey]);
        [expectationB fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testSyncErrorHandlerErrorDomain {
    RLMRealmConfiguration *config = self.configuration;
    XCTestExpectation *expectation = [self expectationWithDescription:@"should fail after setting bad token"];
    self.app.syncManager.errorHandler = ^(NSError *error, RLMSyncSession *) {
        RLMValidateError(error, RLMSyncErrorDomain, RLMSyncErrorClientUserError,
                         @"Unable to refresh the user access token: signature is invalid");
        [expectation fulfill];
    };

    [self setInvalidTokensForUser:config.syncConfiguration.user];
    [RLMRealm realmWithConfiguration:config error:nil];
    [self waitForExpectations:@[expectation] timeout:3.0];
}

#pragma mark - User Profile

- (void)testUserProfileInitialization {
    RLMUserProfile *profile = [[RLMUserProfile alloc] initWithUserProfile:realm::app::UserProfile()];
    XCTAssertNil(profile.name);
    XCTAssertNil(profile.maxAge);
    XCTAssertNil(profile.minAge);
    XCTAssertNil(profile.birthday);
    XCTAssertNil(profile.gender);
    XCTAssertNil(profile.firstName);
    XCTAssertNil(profile.lastName);
    XCTAssertNil(profile.pictureURL);

    auto metadata = realm::bson::BsonDocument({{"some_key", "some_value"}});

    profile = [[RLMUserProfile alloc] initWithUserProfile:realm::app::UserProfile(realm::bson::BsonDocument({
        {"name", "Jane"},
        {"max_age", "40"},
        {"min_age", "30"},
        {"birthday", "October 10th"},
        {"gender", "unknown"},
        {"first_name", "Jane"},
        {"last_name", "Jannson"},
        {"picture_url", "SomeURL"},
        {"other_data", metadata}
    }))];

    XCTAssert([profile.name isEqualToString:@"Jane"]);
    XCTAssert([profile.maxAge isEqualToString:@"40"]);
    XCTAssert([profile.minAge isEqualToString:@"30"]);
    XCTAssert([profile.birthday isEqualToString:@"October 10th"]);
    XCTAssert([profile.gender isEqualToString:@"unknown"]);
    XCTAssert([profile.firstName isEqualToString:@"Jane"]);
    XCTAssert([profile.lastName isEqualToString:@"Jannson"]);
    XCTAssert([profile.pictureURL isEqualToString:@"SomeURL"]);
    XCTAssertEqualObjects(profile.metadata[@"other_data"], @{@"some_key": @"some_value"});
}

#pragma mark - Basic Sync

/// It should be possible to successfully open a Realm configured for sync with a normal user.
- (void)testOpenRealmWithNormalCredentials {
    RLMRealm *realm = [self openRealm];
    XCTAssertTrue(realm.isEmpty);
}

/// If client B adds objects to a synced Realm, client A should see those objects.
- (void)testAddObjects {
    RLMRealm *realm = [self openRealm];
    NSDictionary *values = [AllTypesSyncObject values:1];
    CHECK_COUNT(0, Person, realm);
    CHECK_COUNT(0, AllTypesSyncObject, realm);

    [self writeToPartition:self.name block:^(RLMRealm *realm) {
        [realm addObjects:@[[Person john], [Person paul], [Person george]]];
        AllTypesSyncObject *obj = [[AllTypesSyncObject alloc] initWithValue:values];
        obj.objectCol = [Person ringo];
        [realm addObject:obj];
    }];
    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(4, Person, realm);
    CHECK_COUNT(1, AllTypesSyncObject, realm);

    AllTypesSyncObject *obj = [[AllTypesSyncObject allObjectsInRealm:realm] firstObject];
    XCTAssertEqual(obj.boolCol, [values[@"boolCol"] boolValue]);
    XCTAssertEqual(obj.cBoolCol, [values[@"cBoolCol"] boolValue]);
    XCTAssertEqual(obj.intCol, [values[@"intCol"] intValue]);
    XCTAssertEqual(obj.doubleCol, [values[@"doubleCol"] doubleValue]);
    XCTAssertEqualObjects(obj.stringCol, values[@"stringCol"]);
    XCTAssertEqualObjects(obj.binaryCol, values[@"binaryCol"]);
    XCTAssertEqualObjects(obj.decimalCol, values[@"decimalCol"]);
    XCTAssertEqual(obj.dateCol, values[@"dateCol"]);
    XCTAssertEqual(obj.longCol, [values[@"longCol"] longValue]);
    XCTAssertEqualObjects(obj.uuidCol, values[@"uuidCol"]);
    XCTAssertEqualObjects((NSNumber *)obj.anyCol, values[@"anyCol"]);
    XCTAssertEqualObjects(obj.objectCol.firstName, [Person ringo].firstName);
}

- (void)testAddObjectsWithNilPartitionValue {
    RLMRealm *realm = [self openRealmForPartitionValue:nil user:self.anonymousUser];

    CHECK_COUNT(0, Person, realm);
    [self writeToPartition:nil block:^(RLMRealm *realm) {
        [realm addObjects:@[[Person john], [Person paul], [Person george], [Person ringo]]];
    }];
    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(4, Person, realm);
}

- (void)testRountripForDistinctPrimaryKey {
    RLMRealm *realm = [self openRealm];

    CHECK_COUNT(0, Person, realm);
    CHECK_COUNT(0, UUIDPrimaryKeyObject, realm);
    CHECK_COUNT(0, StringPrimaryKeyObject, realm);
    CHECK_COUNT(0, IntPrimaryKeyObject, realm);

    [self writeToPartition:self.name block:^(RLMRealm *realm) {
        Person *person = [[Person alloc] initWithPrimaryKey:[[RLMObjectId alloc] initWithString:@"1234567890ab1234567890ab" error:nil]
                                                        age:5
                                                  firstName:@"Ringo"
                                                   lastName:@"Starr"];
        UUIDPrimaryKeyObject *uuidPrimaryKeyObject = [[UUIDPrimaryKeyObject alloc] initWithPrimaryKey:[[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"]
                                                                                               strCol:@"Steve"
                                                                                               intCol:10];
        StringPrimaryKeyObject *stringPrimaryKeyObject = [[StringPrimaryKeyObject alloc] initWithPrimaryKey:@"1234567890ab1234567890aa"
                                                                                                     strCol:@"Paul"
                                                                                                     intCol:20];
        IntPrimaryKeyObject *intPrimaryKeyObject = [[IntPrimaryKeyObject alloc] initWithPrimaryKey:1234567890
                                                                                            strCol:@"Jackson"
                                                                                            intCol:30];

        [realm addObject:person];
        [realm addObject:uuidPrimaryKeyObject];
        [realm addObject:stringPrimaryKeyObject];
        [realm addObject:intPrimaryKeyObject];
    }];
    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(1, Person, realm);
    CHECK_COUNT(1, UUIDPrimaryKeyObject, realm);
    CHECK_COUNT(1, StringPrimaryKeyObject, realm);
    CHECK_COUNT(1, IntPrimaryKeyObject, realm);

    Person *person = [Person objectInRealm:realm forPrimaryKey:[[RLMObjectId alloc] initWithString:@"1234567890ab1234567890ab" error:nil]];
    XCTAssertEqualObjects(person.firstName, @"Ringo");
    XCTAssertEqualObjects(person.lastName, @"Starr");

    UUIDPrimaryKeyObject *uuidPrimaryKeyObject = [UUIDPrimaryKeyObject objectInRealm:realm forPrimaryKey:[[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"]];
    XCTAssertEqualObjects(uuidPrimaryKeyObject.strCol, @"Steve");
    XCTAssertEqual(uuidPrimaryKeyObject.intCol, 10);

    StringPrimaryKeyObject *stringPrimaryKeyObject = [StringPrimaryKeyObject objectInRealm:realm forPrimaryKey:@"1234567890ab1234567890aa"];
    XCTAssertEqualObjects(stringPrimaryKeyObject.strCol, @"Paul");
    XCTAssertEqual(stringPrimaryKeyObject.intCol, 20);

    IntPrimaryKeyObject *intPrimaryKeyObject = [IntPrimaryKeyObject objectInRealm:realm forPrimaryKey:@1234567890];
    XCTAssertEqualObjects(intPrimaryKeyObject.strCol, @"Jackson");
    XCTAssertEqual(intPrimaryKeyObject.intCol, 30);
}

- (void)testAddObjectsMultipleApps {
    NSString *appId1 = [RealmServer.shared createAppWithPartitionKeyType:@"string" types:@[Person.self] persistent:false error:nil];
    NSString *appId2 = [RealmServer.shared createAppWithPartitionKeyType:@"string" types:@[Person.self] persistent:false error:nil];
    RLMApp *app1 = [self appWithId:appId1];
    RLMApp *app2 = [self appWithId:appId2];

    auto openRealm = [=](RLMApp *app) {
        RLMUser *user = [self createUserForApp:app];
        RLMRealmConfiguration *config = [user configurationWithPartitionValue:self.name];
        config.objectClasses = @[Person.self];
        return [self openRealmWithConfiguration:config];
    };

    RLMRealm *realm1 = openRealm(app1);
    RLMRealm *realm2 = openRealm(app2);

    CHECK_COUNT(0, Person, realm1);
    CHECK_COUNT(0, Person, realm2);

    @autoreleasepool {
        RLMRealm *realm = openRealm(app1);
        [self addPersonsToRealm:realm
                        persons:@[[Person john], [Person paul]]];
        [self waitForUploadsForRealm:realm];
    }

    // realm2 should not see realm1's objcets despite being the same partition
    // as they're from different apps
    [self waitForDownloadsForRealm:realm1];
    [self waitForDownloadsForRealm:realm2];
    CHECK_COUNT(2, Person, realm1);
    CHECK_COUNT(0, Person, realm2);

    @autoreleasepool {
        RLMRealm *realm = openRealm(app2);
        [self addPersonsToRealm:realm
                        persons:@[[Person ringo], [Person george]]];
        [self waitForUploadsForRealm:realm];
    }

    [self waitForDownloadsForRealm:realm1];
    [self waitForDownloadsForRealm:realm2];
    CHECK_COUNT(2, Person, realm1);
    CHECK_COUNT(2, Person, realm2);

    XCTAssertEqual([Person objectsInRealm:realm1 where:@"firstName = 'John'"].count, 1UL);
    XCTAssertEqual([Person objectsInRealm:realm1 where:@"firstName = 'Paul'"].count, 1UL);
    XCTAssertEqual([Person objectsInRealm:realm1 where:@"firstName = 'Ringo'"].count, 0UL);
    XCTAssertEqual([Person objectsInRealm:realm1 where:@"firstName = 'George'"].count, 0UL);

    XCTAssertEqual([Person objectsInRealm:realm2 where:@"firstName = 'John'"].count, 0UL);
    XCTAssertEqual([Person objectsInRealm:realm2 where:@"firstName = 'Paul'"].count, 0UL);
    XCTAssertEqual([Person objectsInRealm:realm2 where:@"firstName = 'Ringo'"].count, 1UL);
    XCTAssertEqual([Person objectsInRealm:realm2 where:@"firstName = 'George'"].count, 1UL);
}

- (void)testSessionRefresh {
    RLMUser *user = [self createUser];

    // Should result in an access token error followed by a refresh when we
    // open the Realm which is entirely transparent to the user
    realm::RealmJWT token(std::string_view(self.badAccessToken));
    user.user->update_data_for_testing([&](auto& data) {
        data.access_token = token;
    });
    RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];

    RLMRealm *realm2 = [self openRealm];
    [self addPersonsToRealm:realm2
                    persons:@[[Person john],
                              [Person paul],
                              [Person ringo],
                              [Person george]]];
    [self waitForUploadsForRealm:realm2];
    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(4, Person, realm);
}

- (void)testDeleteObjects {
    RLMRealm *realm1 = [self openRealm];
    [self addPersonsToRealm:realm1 persons:@[[Person john]]];
    [self waitForUploadsForRealm:realm1];
    CHECK_COUNT(1, Person, realm1);

    RLMRealm *realm2 = [self openRealm];
    CHECK_COUNT(1, Person, realm2);
    [realm2 beginWriteTransaction];
    [realm2 deleteAllObjects];
    [realm2 commitWriteTransaction];
    [self waitForUploadsForRealm:realm2];

    [self waitForDownloadsForRealm:realm1];
    CHECK_COUNT(0, Person, realm1);
}

- (void)testIncomingSyncWritesTriggerNotifications {
    RLMRealm *syncRealm = [self openRealm];
    RLMRealm *asyncRealm = [self asyncOpenRealmWithConfiguration:self.configuration];
    RLMRealm *writeRealm = [self openRealm];

    __block XCTestExpectation *ex = [self expectationWithDescription:@"got initial notification"];
    ex.expectedFulfillmentCount = 2;
    RLMNotificationToken *token1 = [[Person allObjectsInRealm:syncRealm] addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {
        [ex fulfill];
    }];
    RLMNotificationToken *token2 = [[Person allObjectsInRealm:asyncRealm] addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:5.0];

    ex = [self expectationWithDescription:@"got update notification"];
    ex.expectedFulfillmentCount = 2;
    [self addPersonsToRealm:writeRealm persons:@[[Person john]]];
    [self waitForExpectations:@[ex] timeout:5.0];

    [token1 invalidate];
    [token2 invalidate];
}

#pragma mark - RLMValue Sync with missing schema

- (void)testMissingSchema {
    @autoreleasepool {
        RLMRealm *realm = [self openRealm];
        AllTypesSyncObject *obj = [[AllTypesSyncObject alloc] initWithValue:[AllTypesSyncObject values:0]];
        RLMSetSyncObject *o = [RLMSetSyncObject new];
        Person *p = [Person john];
        [o.anySet addObjects:@[p]];
        obj.anyCol = o;
        obj.objectCol = p;
        [realm beginWriteTransaction];
        [realm addObject:obj];
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, AllTypesSyncObject, realm);
    }

    RLMUser *user = [self createUser];
    auto c = [user configurationWithPartitionValue:self.name];
    c.objectClasses = @[Person.self, AllTypesSyncObject.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];
    [self waitForDownloadsForRealm:realm];
    RLMResults<AllTypesSyncObject *> *res = [AllTypesSyncObject allObjectsInRealm:realm];
    AllTypesSyncObject *o = res.firstObject;
    Person *p = o.objectCol;
    RLMSet<RLMValue> *anySet = ((RLMObject *)o.anyCol)[@"anySet"];
    XCTAssertTrue([anySet.allObjects[0][@"firstName"] isEqualToString:p.firstName]);
    [realm beginWriteTransaction];
    anySet.allObjects[0][@"firstName"] = @"Bob";
    [realm commitWriteTransaction];
    XCTAssertTrue([anySet.allObjects[0][@"firstName"] isEqualToString:p.firstName]);
    CHECK_COUNT(1, AllTypesSyncObject, realm);
}

#pragma mark - Encryption -

/// If client B encrypts its synced Realm, client A should be able to access that Realm with a different encryption key.
- (void)testEncryptedSyncedRealm {
    RLMUser *user = [self userForTest:_cmd];

    NSData *key = RLMGenerateKey();
    RLMRealm *realm = [self openRealmForPartitionValue:self.name
                                                  user:user
                                         encryptionKey:key
                                            stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];

    if (self.isParent) {
        CHECK_COUNT(0, Person, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    } else {
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    }
}

/// If an encrypted synced Realm is re-opened with the wrong key, throw an exception.
- (void)testEncryptedSyncedRealmWrongKey {
    RLMUser *user = [self createUser];

    NSString *path;
    @autoreleasepool {
        RLMRealm *realm = [self openRealmForPartitionValue:self.name
                                                      user:user
                                             encryptionKey:RLMGenerateKey()
                                                stopPolicy:RLMSyncStopPolicyImmediately];
        path = realm.configuration.pathOnDisk;
    }
    [user.app.syncManager waitForSessionTermination];

    RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
    c.fileURL = [NSURL fileURLWithPath:path];
    RLMAssertRealmExceptionContains([RLMRealm realmWithConfiguration:c error:nil],
                                    RLMErrorInvalidDatabase,
                                    @"Failed to open Realm file at path '%@': header has invalid mnemonic. The file is either not a Realm file, is an encrypted Realm file but no encryption key was supplied, or is corrupted.",
                                    c.fileURL.path);
    c.encryptionKey = RLMGenerateKey();
    RLMAssertRealmExceptionContains([RLMRealm realmWithConfiguration:c error:nil],
                                    RLMErrorInvalidDatabase,
                                    @"Failed to open Realm file at path '%@': Realm file decryption failed (Decryption failed: page 0 in file of size ",
                                    c.fileURL.path);
}

#pragma mark - Multiple Realm Sync

/// If a client opens multiple Realms, there should be one session object for each Realm that was opened.
- (void)testMultipleRealmsSessions {
    NSString *partitionValueA = self.name;
    NSString *partitionValueB = [partitionValueA stringByAppendingString:@"bar"];
    NSString *partitionValueC = [partitionValueA stringByAppendingString:@"baz"];
    RLMUser *user = [self createUser];

    __attribute__((objc_precise_lifetime))
    RLMRealm *realmA = [self openRealmForPartitionValue:partitionValueA user:user];
    __attribute__((objc_precise_lifetime))
    RLMRealm *realmB = [self openRealmForPartitionValue:partitionValueB user:user];
    __attribute__((objc_precise_lifetime))
    RLMRealm *realmC = [self openRealmForPartitionValue:partitionValueC user:user];
    // Make sure there are three active sessions for the user.
    XCTAssertEqual(user.allSessions.count, 3U);
    XCTAssertNotNil([user sessionForPartitionValue:partitionValueA],
                    @"Expected to get a session for partition value A");
    XCTAssertNotNil([user sessionForPartitionValue:partitionValueB],
                    @"Expected to get a session for partition value B");
    XCTAssertNotNil([user sessionForPartitionValue:partitionValueC],
                    @"Expected to get a session for partition value C");
    XCTAssertEqual(realmA.syncSession.state, RLMSyncSessionStateActive);
    XCTAssertEqual(realmB.syncSession.state, RLMSyncSessionStateActive);
    XCTAssertEqual(realmC.syncSession.state, RLMSyncSessionStateActive);
}

/// A client should be able to open multiple Realms and add objects to each of them.
- (void)testMultipleRealmsAddObjects {
    NSString *partitionValueA = self.name;
    NSString *partitionValueB = [partitionValueA stringByAppendingString:@"bar"];
    NSString *partitionValueC = [partitionValueA stringByAppendingString:@"baz"];
    RLMUser *user = [self userForTest:_cmd];

    RLMRealm *realmA = [self openRealmForPartitionValue:partitionValueA user:user];
    RLMRealm *realmB = [self openRealmForPartitionValue:partitionValueB user:user];
    RLMRealm *realmC = [self openRealmForPartitionValue:partitionValueC user:user];

    if (self.isParent) {
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(0, Person, realmB);
        CHECK_COUNT(0, Person, realmC);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
        CHECK_COUNT(3, Person, realmA);
        CHECK_COUNT(2, Person, realmB);
        CHECK_COUNT(5, Person, realmC);

        RLMResults *resultsA = [Person objectsInRealm:realmA where:@"firstName == %@", @"Ringo"];
        RLMResults *resultsB = [Person objectsInRealm:realmB where:@"firstName == %@", @"Ringo"];

        XCTAssertEqual([resultsA count], 1UL);
        XCTAssertEqual([resultsB count], 0UL);
    } else {
        // Add objects.
        [self addPersonsToRealm:realmA
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person ringo]]];
        [self addPersonsToRealm:realmB
                        persons:@[[Person john],
                                  [Person paul]]];
        [self addPersonsToRealm:realmC
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person ringo],
                                  [Person george],
                                  [Person ringo]]];
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
    NSString *partitionValueA = self.name;
    NSString *partitionValueB = [partitionValueA stringByAppendingString:@"bar"];
    NSString *partitionValueC = [partitionValueA stringByAppendingString:@"baz"];
    RLMUser *user = [self userForTest:_cmd];
    RLMRealm *realmA = [self openRealmForPartitionValue:partitionValueA user:user];
    RLMRealm *realmB = [self openRealmForPartitionValue:partitionValueB user:user];
    RLMRealm *realmC = [self openRealmForPartitionValue:partitionValueC user:user];

    if (self.isParent) {
        [self addPersonsToRealm:realmA
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person ringo],
                                  [Person george]]];
        [self addPersonsToRealm:realmB
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person ringo],
                                  [Person george],
                                  [Person george]]];
        [self addPersonsToRealm:realmC
                        persons:@[[Person john],
                                  [Person paul]]];

        [self waitForUploadsForRealm:realmA];
        [self waitForUploadsForRealm:realmB];
        [self waitForUploadsForRealm:realmC];
        CHECK_COUNT(4, Person, realmA);
        CHECK_COUNT(5, Person, realmB);
        CHECK_COUNT(2, Person, realmC);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realmA];
        [self waitForDownloadsForRealm:realmB];
        [self waitForDownloadsForRealm:realmC];
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(0, Person, realmB);
        CHECK_COUNT(0, Person, realmC);
    } else {
        // Delete all the objects from the Realms.
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

    // Open the Realm in an autorelease pool so that it is destroyed as soon as possible.
    @autoreleasepool {
        RLMRealm *realm = [self openRealm];
        [self addPersonsToRealm:realm
                        persons:@[[Person john], [Person paul], [Person ringo]]];
        CHECK_COUNT(OBJECT_COUNT, Person, realm);
    }

    [self.app.syncManager waitForSessionTermination];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(OBJECT_COUNT, Person, realm);
}

#pragma mark - Logging Back In

/// A Realm that was opened before a user logged out should be able to resume uploading if the user logs back in.
- (void)testLogBackInSameRealmUpload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    RLMRealmConfiguration *config;
    @autoreleasepool {
        RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];
        config = realm.configuration;
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        CHECK_COUNT(1, Person, realm);
        [self waitForUploadsForRealm:realm];
        // Log out the user out and back in
        [self logOutUser:user];
        [self addPersonsToRealm:realm
                        persons:@[[Person john], [Person paul], [Person ringo]]];
        [self logInUserForCredentials:credentials];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(4, Person, realm);
        [realm.syncSession suspend];
        [self.app.syncManager waitForSessionTermination];
    }

    // Verify that the post-login objects were actually synced
    XCTAssertTrue([RLMRealm deleteFilesForConfiguration:config error:nil]);
    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(4, Person, realm);
}

/// A Realm that was opened before a user logged out should be able to resume downloading if the user logs back in.
- (void)testLogBackInSameRealmDownload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];
    RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];

    if (self.isParent) {
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        CHECK_COUNT(1, Person, realm);
        [self waitForUploadsForRealm:realm];
        // Log out the user.
        [self logOutUser:user];
        // Log the user back in.
        [self logInUserForCredentials:credentials];

        RLMRunChildAndWait();

        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(3, Person, realm);
    } else {
        [self addPersonsToRealm:realm persons:@[[Person john], [Person paul]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(3, Person, realm);
    }
}

/// A Realm that was opened while a user was logged out should be able to start uploading if the user logs back in.
- (void)testLogBackInDeferredRealmUpload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name register:YES];
    RLMUser *user = [self logInUserForCredentials:credentials];
    [self logOutUser:user];

    // Open a Realm after the user's been logged out.
    RLMRealm *realm = [self immediatelyOpenRealmForPartitionValue:self.name user:user];

    [self addPersonsToRealm:realm persons:@[[Person john]]];
    CHECK_COUNT(1, Person, realm);

    [self logInUserForCredentials:credentials];
    [self addPersonsToRealm:realm
                    persons:@[[Person john], [Person paul], [Person ringo]]];
    [self waitForUploadsForRealm:realm];
    CHECK_COUNT(4, Person, realm);

    RLMRealm *realm2 = [self openRealm];
    CHECK_COUNT(4, Person, realm2);
}

/// A Realm that was opened while a user was logged out should be able to start downloading if the user logs back in.
- (void)testLogBackInDeferredRealmDownload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    if (self.isParent) {
        [self logOutUser:user];
        RLMRunChildAndWait();

        // Open a Realm after the user's been logged out.
        RLMRealm *realm = [self immediatelyOpenRealmForPartitionValue:self.name user:user];
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        CHECK_COUNT(1, Person, realm);

        [self logInUserForCredentials:credentials];
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(4, Person, realm);

    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];
        [self addPersonsToRealm:realm
                        persons:@[[Person john], [Person paul], [Person ringo]]];
        [self waitForUploadsForRealm:realm];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(3, Person, realm);
    }
}

/// After logging back in, a Realm whose path has been opened for the first time should properly upload changes.
- (void)testLogBackInOpenFirstTimePathUpload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name register:YES];
    RLMUser *user = [self logInUserForCredentials:credentials];
    [self logOutUser:user];

    @autoreleasepool {
        auto c = [user configurationWithPartitionValue:self.name];
        c.objectClasses = @[Person.self];
        RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];
        [self addPersonsToRealm:realm
                        persons:@[[Person john], [Person paul]]];

        [self logInUserForCredentials:credentials];
        [self waitForUploadsForRealm:realm];
    }

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(2, Person, realm);
}

/// After logging back in, a Realm whose path has been opened for the first time should properly download changes.
- (void)testLogBackInOpenFirstTimePathDownload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name register:YES];
    RLMUser *user = [self logInUserForCredentials:credentials];
    [self logOutUser:user];

    auto c = [user configurationWithPartitionValue:self.name];
    c.objectClasses = @[Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];

    @autoreleasepool {
        RLMRealm *realm = [self openRealm];
        [self addPersonsToRealm:realm
                        persons:@[[Person john], [Person paul]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(2, Person, realm);
    }

    CHECK_COUNT(0, Person, realm);
    [self logInUserForCredentials:credentials];
    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(2, Person, realm);
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly upload changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmUpload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    @autoreleasepool {
        RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
        [self logOutUser:user];
        user = [self logInUserForCredentials:credentials];
    }

    RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];
    [self addPersonsToRealm:realm
                    persons:@[[Person john], [Person paul], [Person george], [Person ringo]]];
    CHECK_COUNT(5, Person, realm);
    [self waitForUploadsForRealm:realm];

    RLMRealm *realm2 = [self openRealmForPartitionValue:self.name user:self.createUser];
    CHECK_COUNT(5, Person, realm2);
}

/// If a client logs in, connects, logs out, and logs back in, sync should properly download changes for a new
/// `RLMRealm` that is opened for the same path as a previously-opened Realm.
- (void)testLogBackInReopenRealmDownload {
    RLMCredentials *credentials = [self basicCredentialsWithName:self.name
                                                        register:self.isParent];
    RLMUser *user = [self logInUserForCredentials:credentials];

    RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];
    [self addPersonsToRealm:realm persons:@[[Person john]]];
    [self waitForUploadsForRealm:realm];
    XCTAssert([Person allObjectsInRealm:realm].count == 1, @"Expected 1 item");
    [self logOutUser:user];
    user = [self logInUserForCredentials:credentials];
    RLMRealm *realm2 = [self openRealmForPartitionValue:self.name user:self.createUser];
    CHECK_COUNT(1, Person, realm2);
    [self addPersonsToRealm:realm2
                    persons:@[[Person john], [Person paul], [Person george], [Person ringo]]];
    [self waitForUploadsForRealm:realm2];
    CHECK_COUNT(5, Person, realm2);

    // Open the Realm again and get the items.
    [self openRealmForPartitionValue:self.name user:user];
    CHECK_COUNT(5, Person, realm2);
}

#pragma mark - Session suspend and resume

- (void)testSuspendAndResume {
    RLMUser *user = [self userForTest:_cmd];

    __attribute__((objc_precise_lifetime))
    RLMRealm *realmA = [self openRealmForPartitionValue:@"suspend and resume 1" user:user];
    __attribute__((objc_precise_lifetime))
    RLMRealm *realmB = [self openRealmForPartitionValue:@"suspend and resume 2" user:user];
    if (self.isParent) {
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(0, Person, realmB);

        // Suspend the session for realm A and then add an object to each Realm
        RLMSyncSession *sessionA = [RLMSyncSession sessionForRealm:realmA];
        RLMSyncSession *sessionB = [RLMSyncSession sessionForRealm:realmB];
        XCTAssertEqual(sessionB.state, RLMSyncSessionStateActive);
        [sessionA suspend];
        XCTAssertEqual(realmB.syncSession.state, RLMSyncSessionStateActive);

        [self addPersonsToRealm:realmA persons:@[[Person john]]];
        [self addPersonsToRealm:realmB persons:@[[Person ringo]]];
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
        CHECK_COUNT(0, Person, realmA);
        CHECK_COUNT(1, Person, realmB);
        [self addPersonsToRealm:realmA
                        persons:@[[Person john], [Person paul]]];
        [self waitForUploadsForRealm:realmA];
        [self addPersonsToRealm:realmB
                        persons:@[[Person john], [Person paul]]];
        [self waitForUploadsForRealm:realmB];
        CHECK_COUNT(2, Person, realmA);
        CHECK_COUNT(3, Person, realmB);
    }
}

#pragma mark - Client reset

/// Ensure that a client reset error is propagated up to the binding successfully.
- (void)testClientReset {
    RLMUser *user = [self userForTest:_cmd];
    // Open the Realm
    __attribute__((objc_precise_lifetime))
    RLMRealm *realm = [self openRealmForPartitionValue:@"realm_id"
                                                  user:user
                                       clientResetMode:RLMClientResetModeManual];

    __block NSError *theError = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Waiting for error handler to be called..."];
    [self.app syncManager].errorHandler = ^void(NSError *error, RLMSyncSession *) {
        theError = error;
        [ex fulfill];
    };
    [user simulateClientResetErrorForSession:@"realm_id"];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    XCTAssertNotNil(theError);
    XCTAssertTrue(theError.code == RLMSyncErrorClientResetError);
    NSString *pathValue = [theError rlmSync_clientResetBackedUpRealmPath];
    XCTAssertNotNil(pathValue);
    // Sanity check the recovery path.
    NSString *recoveryPath = [NSString stringWithFormat:@"mongodb-realm/%@/recovered-realms", self.appId];
    XCTAssertTrue([pathValue rangeOfString:recoveryPath].location != NSNotFound);
    XCTAssertNotNil([theError rlmSync_errorActionToken]);
}

/// Test manually initiating client reset.
- (void)testClientResetManualInitiation {
    RLMUser *user = [self createUser];

    __block NSError *theError = nil;
    @autoreleasepool {
        __attribute__((objc_precise_lifetime))
        RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user
                                           clientResetMode:RLMClientResetModeManual];
        XCTestExpectation *ex = [self expectationWithDescription:@"Waiting for error handler to be called..."];
        self.app.syncManager.errorHandler = ^(NSError *error, RLMSyncSession *) {
            theError = error;
            [ex fulfill];
        };
        [user simulateClientResetErrorForSession:self.name];
        [self waitForExpectationsWithTimeout:30 handler:nil];
        XCTAssertNotNil(theError);
    }

    // At this point the Realm should be invalidated and client reset should be possible.
    NSString *pathValue = [theError rlmSync_clientResetBackedUpRealmPath];
    XCTAssertFalse([NSFileManager.defaultManager fileExistsAtPath:pathValue]);
    [RLMSyncSession immediatelyHandleError:theError.rlmSync_errorActionToken];
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:pathValue]);
}

- (void)testSetClientResetMode {
    RLMUser *user = [self createUser];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    RLMRealmConfiguration *config = [user configurationWithPartitionValue:self.name
                                                          clientResetMode:RLMClientResetModeDiscardLocal];
    XCTAssertEqual(config.syncConfiguration.clientResetMode, RLMClientResetModeDiscardLocal);
    #pragma clang diagnostic pop

    // Default is recover
    config = [user configurationWithPartitionValue:self.name];
    XCTAssertEqual(config.syncConfiguration.clientResetMode, RLMClientResetModeRecoverUnsyncedChanges);

    RLMSyncErrorReportingBlock block = ^(NSError *, RLMSyncSession *) {
        XCTFail("Should never hit");
    };
    RLMAssertThrowsWithReason([user configurationWithPartitionValue:self.name
                                                    clientResetMode:RLMClientResetModeDiscardUnsyncedChanges
                                           manualClientResetHandler:block],
                              @"A manual client reset handler can only be set with RLMClientResetModeManual");
}

- (void)testSetClientResetCallbacks {
    RLMUser *user = [self createUser];

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    RLMRealmConfiguration *config = [user configurationWithPartitionValue:self.name
                                                          clientResetMode:RLMClientResetModeDiscardLocal];

    XCTAssertNil(config.syncConfiguration.beforeClientReset);
    XCTAssertNil(config.syncConfiguration.afterClientReset);

    RLMClientResetBeforeBlock beforeBlock = ^(RLMRealm *local __unused) {
        XCTAssert(false, @"Should not execute callback");
    };
    RLMClientResetAfterBlock afterBlock = ^(RLMRealm *before __unused, RLMRealm *after __unused) {
        XCTAssert(false, @"Should not execute callback");
    };
    RLMRealmConfiguration *config2 = [user configurationWithPartitionValue:self.name
                                                           clientResetMode:RLMClientResetModeDiscardLocal
                                                         notifyBeforeReset:beforeBlock
                                                          notifyAfterReset:afterBlock];
    XCTAssertNotNil(config2.syncConfiguration.beforeClientReset);
    XCTAssertNotNil(config2.syncConfiguration.afterClientReset);
    #pragma clang diagnostic pop

}

// TODO: Consider testing with sync_config->on_sync_client_event_hook or a client reset
- (void)testBeforeClientResetCallbackNotVersioned {
    // Setup sync config
    RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithRawConfig:{} path:""];
    XCTestExpectation *beforeExpectation = [self expectationWithDescription:@"block called once"];
    syncConfig.clientResetMode = RLMClientResetModeRecoverUnsyncedChanges;
    syncConfig.beforeClientReset = ^(RLMRealm *beforeFrozen) {
        XCTAssertNotEqual(RLMNotVersioned, beforeFrozen->_realm->schema_version());
        [beforeExpectation fulfill];
    };
    auto& beforeWrapper = syncConfig.rawConfiguration.notify_before_client_reset;

    // Setup a realm with a versioned schema
    RLMRealmConfiguration *configVersioned = [RLMRealmConfiguration defaultConfiguration];
    configVersioned.fileURL = RLMTestRealmURL();
    @autoreleasepool {
        RLMRealm *versioned = [RLMRealm realmWithConfiguration:configVersioned error:nil];
        XCTAssertEqual(0U, versioned->_realm->schema_version());
    }
    std::shared_ptr<realm::Realm> versioned = realm::Realm::get_shared_realm(configVersioned.config);

    // Create a config that's not versioned.
    RLMRealmConfiguration *configUnversioned = [RLMRealmConfiguration defaultConfiguration];
    configUnversioned.configRef.schema_version = RLMNotVersioned;
    std::shared_ptr<realm::Realm> unversioned = realm::Realm::get_shared_realm(configUnversioned.config);

    XCTAssertNotEqual(versioned->schema_version(), RLMNotVersioned);
    XCTAssertEqual(unversioned->schema_version(), RLMNotVersioned);
    beforeWrapper(versioned); // one realm should invoke the block
    beforeWrapper(unversioned); // while the other should not invoke the block

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

// TODO: Consider testing with sync_config->on_sync_client_event_hook or a client reset
- (void)testAfterClientResetCallbackNotVersioned {
    // Setup sync config
    RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithRawConfig:{} path:""];
    XCTestExpectation *afterExpectation = [self expectationWithDescription:@"block should not be called"];
    afterExpectation.inverted = true;

    syncConfig.clientResetMode = RLMClientResetModeRecoverUnsyncedChanges;
    syncConfig.afterClientReset = ^(RLMRealm * _Nonnull, RLMRealm * _Nonnull) {
        [afterExpectation fulfill];
    };
    auto& afterWrapper = syncConfig.rawConfiguration.notify_after_client_reset;

    // Create a config that's not versioned.
    RLMRealmConfiguration *configUnversioned = [RLMRealmConfiguration defaultConfiguration];
    configUnversioned.configRef.schema_version = RLMNotVersioned;
    std::shared_ptr<realm::Realm> unversioned = realm::Realm::get_shared_realm(configUnversioned.config);

    auto unversionedTsr = realm::ThreadSafeReference(unversioned);
    XCTAssertEqual(unversioned->schema_version(), RLMNotVersioned);
    afterWrapper(unversioned, std::move(unversionedTsr), false);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Progress Notifications

static const NSInteger NUMBER_OF_BIG_OBJECTS = 2;

- (void)populateData {
    NSURL *realmURL;
    RLMUser *user = [self createUser];
    @autoreleasepool {
        RLMRealm *realm = [self openRealmWithUser:user];
        realmURL = realm.configuration.fileURL;
        CHECK_COUNT(0, HugeSyncObject, realm);
        [realm beginWriteTransaction];
        for (NSInteger i = 0; i < NUMBER_OF_BIG_OBJECTS; i++) {
            [realm addObject:[HugeSyncObject hugeSyncObject]];
        }
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(NUMBER_OF_BIG_OBJECTS, HugeSyncObject, realm);
    }
    [user.app.syncManager waitForSessionTermination];
    [self deleteRealmFileAtURL:realmURL];
}

- (void)testStreamingDownloadNotifier {
    RLMRealm *realm = [self openRealm];
    RLMSyncSession *session = realm.syncSession;
    XCTAssertNotNil(session);

    XCTestExpectation *ex = [self expectationWithDescription:@"streaming-download-notifier"];
    std::atomic<NSInteger> callCount{0};
    std::atomic<NSUInteger> transferred{0};
    std::atomic<NSUInteger> transferrable{0};
    BOOL hasBeenFulfilled = NO;
    RLMNotificationToken *token = [session
                                   addProgressNotificationForDirection:RLMSyncProgressDirectionDownload
                                   mode:RLMSyncProgressModeReportIndefinitely
                                   block:[&](NSUInteger xfr, NSUInteger xfb) {
        // Make sure the values are increasing, and update our stored copies.
        XCTAssertGreaterThanOrEqual(xfr, transferred.load());
        XCTAssertGreaterThanOrEqual(xfb, transferrable.load());
        transferred = xfr;
        transferrable = xfb;
        callCount++;
        if (transferrable > 0 && transferred >= transferrable && !hasBeenFulfilled) {
            [ex fulfill];
            hasBeenFulfilled = YES;
        }
    }];

    [self populateData];

    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    [token invalidate];
    // The notifier should have been called at least twice: once at the beginning and at least once
    // to report progress.
    XCTAssertGreaterThan(callCount.load(), 1);
    XCTAssertGreaterThanOrEqual(transferred.load(), transferrable.load());
}

- (void)testStreamingUploadNotifier {
    RLMRealm *realm = [self openRealm];
    RLMSyncSession *session = realm.syncSession;
    XCTAssertNotNil(session);

    XCTestExpectation *ex = [self expectationWithDescription:@"streaming-upload-expectation"];
    std::atomic<NSInteger> callCount{0};
    std::atomic<NSUInteger> transferred{0};
    std::atomic<NSUInteger> transferrable{0};
    auto token = [session addProgressNotificationForDirection:RLMSyncProgressDirectionUpload
                                                         mode:RLMSyncProgressModeReportIndefinitely
                                                        block:[&](NSUInteger xfr, NSUInteger xfb) {
        // Make sure the values are increasing, and update our stored copies.
        XCTAssertGreaterThanOrEqual(xfr, transferred.load());
        XCTAssertGreaterThanOrEqual(xfb, transferrable.load());
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
        [realm addObject:[HugeSyncObject hugeSyncObject]];
    }
    [realm commitWriteTransaction];

    // Wait for upload to begin and finish
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    [token invalidate];

    // The notifier should have been called at least twice: once at the beginning and at least once
    // to report progress.
    XCTAssertGreaterThan(callCount.load(), 1);
    XCTAssertGreaterThanOrEqual(transferred.load(), transferrable.load());
}

#pragma mark - Download Realm

- (void)testDownloadRealm {
    [self populateData];

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [self configuration];
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
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    XCTAssertGreaterThan(fileSize(c.pathOnDisk), 0U);
    XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
}

- (void)testDownloadAlreadyOpenRealm {
    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    RLMRealmConfiguration *c = [self configuration];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:c.pathOnDisk isDirectory:nil]);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:c error:nil];
    CHECK_COUNT(0, HugeSyncObject, realm);
    [self waitForUploadsForRealm:realm];
    [realm.syncSession suspend];

    [self populateData];

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
}

- (void)testDownloadCancelsOnAuthError {
    auto c = [self configuration];
    [self setInvalidTokensForUser:c.syncConfiguration.user];
    auto ex = [self expectationWithDescription:@"async open"];
    [RLMRealm asyncOpenWithConfiguration:c callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNil(realm);
        RLMValidateError(error, RLMAppErrorDomain, RLMAppErrorUnknown,
                         @"Unable to refresh the user access token: signature is invalid");
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testCancelDownload {
    [self populateData];

    // Use a serial queue for asyncOpen to ensure that the first one adds
    // the completion block before the second one cancels it
    auto queue = dispatch_queue_create("io.realm.asyncOpen", 0);
    RLMSetAsyncOpenQueue(queue);

    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    ex.expectedFulfillmentCount = 2;
    RLMRealmConfiguration *c = [self configuration];
    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNil(realm);
        RLMValidateError(error, NSPOSIXErrorDomain, ECANCELED, @"Operation canceled");
        [ex fulfill];
    }];
    auto task = [RLMRealm asyncOpenWithConfiguration:c
                            callbackQueue:dispatch_get_main_queue()
                                 callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNil(realm);
        RLMValidateError(error, NSPOSIXErrorDomain, ECANCELED, @"Operation canceled");
        [ex fulfill];
    }];

    // The cancel needs to be scheduled after we've actually started the task,
    // which is itself async
    dispatch_sync(queue, ^{ [task cancel]; });
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testAsyncOpenProgressNotifications {
    [self populateData];

    XCTestExpectation *ex1 = [self expectationWithDescription:@"async open"];
    XCTestExpectation *ex2 = [self expectationWithDescription:@"download progress complete"];

    auto task = [RLMRealm asyncOpenWithConfiguration:self.configuration
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
    TimeoutProxyServer *proxy = [[TimeoutProxyServer alloc] initWithPort:5678 targetPort:9090];
    NSError *error;
    [proxy startAndReturnError:&error];
    XCTAssertNil(error);

    RLMAppConfiguration *config = [[RLMAppConfiguration alloc]
                                   initWithBaseURL:@"http://localhost:9090"
                                   transport:[AsyncOpenConnectionTimeoutTransport new]
                                   defaultRequestTimeoutMS:60];
    RLMSyncTimeoutOptions *timeoutOptions = [RLMSyncTimeoutOptions new];
    timeoutOptions.connectTimeout = 1000.0;
    config.syncTimeouts = timeoutOptions;
    NSString *appId = [RealmServer.shared
                       createAppWithPartitionKeyType:@"string"
                       types:@[Person.self] persistent:false error:nil];
    RLMUser *user = [self createUserForApp:[RLMApp appWithId:appId configuration:config]];

    RLMRealmConfiguration *c = [user configurationWithPartitionValue:appId];
    c.objectClasses = @[Person.class];
    RLMSyncConfiguration *syncConfig = c.syncConfiguration;
    syncConfig.cancelAsyncOpenOnNonFatalErrors = true;
    c.syncConfiguration = syncConfig;

    // Set delay above the timeout so it should fail
    proxy.delay = 2.0;

    XCTestExpectation *ex = [self expectationWithDescription:@"async open"];
    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        RLMValidateError(error, NSPOSIXErrorDomain, ETIMEDOUT,
                         @"Sync connection was not fully established in time");
        XCTAssertNil(realm);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];

    // Delay below the timeout should work
    proxy.delay = 0.5;

    ex = [self expectationWithDescription:@"async open"];
    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNotNil(realm);
        XCTAssertNil(error);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];

    [proxy stop];
}

#pragma mark - Compact on Launch

- (void)testCompactOnLaunch {
    RLMRealmConfiguration *config = self.configuration;
    NSString *path = config.fileURL.path;
    // Create a large object and then delete it in the next transaction so that
    // the file is bloated
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        [realm beginWriteTransaction];
        [realm addObject:[HugeSyncObject hugeSyncObject]];
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];

        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    }

    RLMWaitForRealmToClose(config.fileURL.path);

    auto fileManager = NSFileManager.defaultManager;
    auto initialSize = [[fileManager attributesOfItemAtPath:path error:nil][NSFileSize] unsignedLongLongValue];

    // Reopen the file with a shouldCompactOnLaunch block and verify that it is
    // actually compacted
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
    XCTAssertLessThanOrEqual(finalSize, usedSize + realm::util::page_size());
}

- (void)testWriteCopy {
    RLMRealm *syncRealm = [self openRealm];
    [self addPersonsToRealm:syncRealm persons:@[[Person john]]];

    NSError *writeError;
    XCTAssertTrue([syncRealm writeCopyToURL:RLMTestRealmURL()
                              encryptionKey:syncRealm.configuration.encryptionKey
                                      error:&writeError]);
    XCTAssertNil(writeError);

    RLMRealmConfiguration *localConfig = [RLMRealmConfiguration new];
    localConfig.fileURL = RLMTestRealmURL();
    localConfig.objectClasses = @[Person.self];
    localConfig.schemaVersion = 1;

    RLMRealm *localCopy = [RLMRealm realmWithConfiguration:localConfig error:nil];
    XCTAssertEqual(1U, [Person allObjectsInRealm:localCopy].count);
}

#pragma mark - Read Only

- (void)testOpenSynchronouslyInReadOnlyBeforeRemoteSchemaIsInitialized {
    RLMUser *user = [self userForTest:_cmd];

    if (self.isParent) {
        RLMRealmConfiguration *config = [user configurationWithPartitionValue:self.name];
        config.objectClasses = self.defaultObjectTypes;
        config.readOnly = true;
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        CHECK_COUNT(0, Person, realm);
        RLMRunChildAndWait();
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    } else {
        RLMRealm *realm = [self openRealmForPartitionValue:self.name user:user];
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        [self waitForUploadsForRealm:realm];
        CHECK_COUNT(1, Person, realm);
    }
}

- (void)testAddPropertyToReadOnlyRealmWithExistingLocalCopy {
    @autoreleasepool {
        RLMRealm *realm = [self openRealm];
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        [self waitForUploadsForRealm:realm];
    }

    RLMRealmConfiguration *config = [self.createUser configurationWithPartitionValue:self.name];
    config.objectClasses = self.defaultObjectTypes;
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
    @autoreleasepool {
        RLMRealm *realm = [self openRealm];
        [self addPersonsToRealm:realm persons:@[[Person john]]];
        [self waitForUploadsForRealm:realm];
    }
    [self.app.syncManager waitForSessionTermination];

    RLMRealmConfiguration *config = [self configuration];
    config.readOnly = true;

    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:Person.class];
    objectSchema.properties = [RLMObjectSchema schemaForObjectClass:HugeSyncObject.class].properties;
    config.customSchema = [[RLMSchema alloc] init];
    config.customSchema.objectSchema = @[objectSchema];

    @autoreleasepool {
        NSError *error = [self asyncOpenErrorWithConfiguration:config];
        XCTAssert([error.localizedDescription containsString:@"Property 'Person.dataProp' has been added."]);
    }
}

- (void)testSyncConfigShouldNotMigrate {
    RLMRealm *realm = [self openRealm];
    RLMAssertThrowsWithReason(realm.configuration.deleteRealmIfMigrationNeeded = YES,
                              @"Cannot set 'deleteRealmIfMigrationNeeded' when sync is enabled");

    RLMRealmConfiguration *localRealmConfiguration = [RLMRealmConfiguration defaultConfiguration];
    XCTAssertNoThrow(localRealmConfiguration.deleteRealmIfMigrationNeeded = YES);
}

#pragma mark - Write Copy For Configuration

- (void)testWriteCopyForConfigurationLocalToSync {
    RLMRealmConfiguration *localConfig = [RLMRealmConfiguration new];
    localConfig.objectClasses = @[Person.class];
    localConfig.fileURL = RLMTestRealmURL();

    RLMRealmConfiguration *syncConfig = self.configuration;
    syncConfig.objectClasses = @[Person.class];

    RLMRealm *localRealm = [RLMRealm realmWithConfiguration:localConfig error:nil];
    [localRealm transactionWithBlock:^{
        [localRealm addObject:[Person ringo]];
    }];

    [localRealm writeCopyForConfiguration:syncConfig error:nil];

    RLMRealm *syncedRealm = [RLMRealm realmWithConfiguration:syncConfig error:nil];
    XCTAssertEqual([[Person allObjectsInRealm:syncedRealm] objectsWhere:@"firstName = 'Ringo'"].count, 1U);

    [self waitForDownloadsForRealm:syncedRealm];
    [syncedRealm transactionWithBlock:^{
        [syncedRealm addObject:[Person john]];
    }];
    [self waitForUploadsForRealm:syncedRealm];

    RLMResults<Person *> *syncedResults = [Person allObjectsInRealm:syncedRealm];
    XCTAssertEqual([syncedResults objectsWhere:@"firstName = 'Ringo'"].count, 1U);
    XCTAssertEqual([syncedResults objectsWhere:@"firstName = 'John'"].count, 1U);
}

- (void)testWriteCopyForConfigurationSyncToSyncRealmError {
    RLMRealmConfiguration *syncConfig = self.configuration;
    RLMRealmConfiguration *syncConfig2 = self.configuration;

    RLMRealm *syncedRealm = [RLMRealm realmWithConfiguration:syncConfig error:nil];
    [syncedRealm.syncSession suspend];
    [syncedRealm transactionWithBlock:^{
        [syncedRealm addObject:[Person ringo]];
    }];
    // Cannot export a synced realm as not all changes have been synced.
    NSError *error;
    [syncedRealm writeCopyForConfiguration:syncConfig2 error:&error];
    XCTAssertEqual(error.code, RLMErrorFail);
    XCTAssertEqualObjects(error.localizedDescription,
                          @"All client changes must be integrated in server before writing copy");
}

- (void)testWriteCopyForConfigurationLocalRealmForSyncWithExistingData {
    RLMRealmConfiguration *initialSyncConfig = self.configuration;
    initialSyncConfig.objectClasses = @[Person.class];

    // Make sure objects with confliciting primary keys sync ok.
    RLMObjectId *conflictingObjectId = [RLMObjectId objectId];
    Person *person = [Person ringo];
    person._id = conflictingObjectId;

    RLMRealm *initialRealm = [RLMRealm realmWithConfiguration:initialSyncConfig error:nil];
    [initialRealm transactionWithBlock:^{
        [initialRealm addObject:person];
        [initialRealm addObject:[Person john]];
    }];
    [self waitForUploadsForRealm:initialRealm];

    RLMRealmConfiguration *localConfig = [RLMRealmConfiguration new];
    localConfig.objectClasses = @[Person.class];
    localConfig.fileURL = RLMTestRealmURL();

    RLMRealmConfiguration *syncConfig = self.configuration;
    syncConfig.objectClasses = @[Person.class];

    RLMRealm *localRealm = [RLMRealm realmWithConfiguration:localConfig error:nil];
    // `person2` will override what was previously stored on the server.
    Person *person2 = [Person new];
    person2._id = conflictingObjectId;
    person2.firstName = @"John";
    person2.lastName = @"Doe";

    [localRealm transactionWithBlock:^{
        [localRealm addObject:person2];
        [localRealm addObject:[Person george]];
    }];

    [localRealm writeCopyForConfiguration:syncConfig error:nil];

    RLMRealm *syncedRealm = [RLMRealm realmWithConfiguration:syncConfig error:nil];
    [self waitForDownloadsForRealm:syncedRealm];
    XCTAssertEqual([syncedRealm allObjects:@"Person"].count, 3U);
    [syncedRealm transactionWithBlock:^{
        [syncedRealm addObject:[Person stuart]];
    }];

    [self waitForUploadsForRealm:syncedRealm];
    RLMResults<Person *> *syncedResults = [Person allObjectsInRealm:syncedRealm];

    NSPredicate *p = [NSPredicate predicateWithFormat:@"firstName = 'John' AND lastName = 'Doe' AND _id = %@", conflictingObjectId];
    XCTAssertEqual([syncedResults objectsWithPredicate:p].count, 1U);
    XCTAssertEqual([syncedRealm allObjects:@"Person"].count, 4U);
}

#pragma mark - File paths

static NSString *newPathForPartitionValue(RLMUser *user, id<RLMBSON> partitionValue) {
    std::stringstream s;
    s << RLMConvertRLMBSONToBson(partitionValue);
    // Intentionally not passing the correct partition value here as we (accidentally?)
    // don't use the filename generated from the partition value
    realm::SyncConfig config(user.user, "null");
    return @(user.user->path_for_realm(config, s.str()).c_str());
}

- (void)testSyncFilePaths {
    RLMUser *user = self.anonymousUser;
    auto configuration = [user configurationWithPartitionValue:@"abc"];
    XCTAssertTrue([configuration.fileURL.path
                   hasSuffix:([NSString stringWithFormat:@"mongodb-realm/%@/%@/%%22abc%%22.realm",
                               self.appId, user.identifier])]);
    configuration = [user configurationWithPartitionValue:@123];
    XCTAssertTrue([configuration.fileURL.path
                   hasSuffix:([NSString stringWithFormat:@"mongodb-realm/%@/%@/%@.realm",
                               self.appId, user.identifier, @"%7B%22%24numberInt%22%3A%22123%22%7D"])]);
    configuration = [user configurationWithPartitionValue:nil];
    XCTAssertTrue([configuration.fileURL.path
                   hasSuffix:([NSString stringWithFormat:@"mongodb-realm/%@/%@/null.realm",
                               self.appId, user.identifier])]);

    XCTAssertEqualObjects([user configurationWithPartitionValue:@"abc"].fileURL.path,
                          newPathForPartitionValue(user, @"abc"));
    XCTAssertEqualObjects([user configurationWithPartitionValue:@123].fileURL.path,
                          newPathForPartitionValue(user, @123));
    XCTAssertEqualObjects([user configurationWithPartitionValue:nil].fileURL.path,
                          newPathForPartitionValue(user, nil));
}

static NSString *oldPathForPartitionValue(RLMUser *user, NSString *oldName) {
    realm::SyncConfig config(user.user, "null");
    return [NSString stringWithFormat:@"%@/%s%@.realm",
            [@(user.user->path_for_realm(config).c_str()) stringByDeletingLastPathComponent],
            user.user->user_id().c_str(), oldName];
}

- (void)testLegacyFilePathsAreUsedIfFilesArePresent {
    RLMUser *user = self.anonymousUser;

    auto testPartitionValue = [&](id<RLMBSON> partitionValue, NSString *oldName) {
        NSURL *url = [NSURL fileURLWithPath:oldPathForPartitionValue(user, oldName)];
        @autoreleasepool {
            auto configuration = [user configurationWithPartitionValue:partitionValue];
            configuration.fileURL = url;
            configuration.objectClasses = @[Person.class];
            RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
            [realm beginWriteTransaction];
            [Person createInRealm:realm withValue:[Person george]];
            [realm commitWriteTransaction];
        }

        auto configuration = [user configurationWithPartitionValue:partitionValue];
        configuration.objectClasses = @[Person.class];
        XCTAssertEqualObjects(configuration.fileURL, url);
        RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
        XCTAssertEqual([Person allObjectsInRealm:realm].count, 1U);
    };

    testPartitionValue(@"abc", @"%2F%2522abc%2522");
    testPartitionValue(@123, @"%2F%257B%2522%24numberInt%2522%253A%2522123%2522%257D");
    testPartitionValue(nil, @"%2Fnull");
}
@end

#endif // TARGET_OS_OSX
