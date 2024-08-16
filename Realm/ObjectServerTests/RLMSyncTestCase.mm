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

#import <CommonCrypto/CommonHMAC.h>
#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "RLMApp_Private.hpp"
#import "RLMChildProcessEnvironment.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealmUtil.hpp"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSyncConfiguration_Private.h"
#import "RLMSyncManager_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/app_user.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>

#if TARGET_OS_OSX

// Set this to 1 if you want the test ROS instance to log its debug messages to console.
#define LOG_ROS_OUTPUT 0

@interface RLMSyncManager ()
+ (void)_setCustomBundleID:(NSString *)customBundleID;
- (NSArray<RLMUser *> *)_allUsers;
@end

@interface RLMSyncTestCase ()
@property (nonatomic) NSTask *task;
@end

@interface RLMSyncSession ()
- (BOOL)waitForUploadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(NSError *))callback;
- (BOOL)waitForDownloadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(NSError *))callback;
@end

@interface TestNetworkTransport : RLMNetworkTransport
- (void)waitForCompletion;
@end

#pragma mark AsyncOpenConnectionTimeoutTransport

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

static NSURL *syncDirectoryForChildProcess() {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleIdentifier = bundle.bundleIdentifier ?: bundle.executablePath.lastPathComponent;
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-child", bundleIdentifier]];
    return [NSURL fileURLWithPath:path isDirectory:YES];
}

#pragma mark RLMSyncTestCase

@implementation RLMSyncTestCase {
    RLMApp *_app;
}

- (NSArray *)defaultObjectTypes {
    return @[Person.self];
}

#pragma mark - Helper methods

- (RLMUser *)userForTest:(SEL)sel {
    return [self userForTest:sel app:self.app];
}

- (RLMUser *)userForTest:(SEL)sel app:(RLMApp *)app {
    return [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(sel)
                                                               register:self.isParent app:app]
                                     app:app];
}

- (RLMUser *)anonymousUser {
    return [self logInUserForCredentials:[RLMCredentials anonymousCredentials]];
}

- (RLMCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister {
    return [self basicCredentialsWithName:name register:shouldRegister app:self.app];
}

- (RLMCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister app:(RLMApp *)app {
    if (shouldRegister) {
        XCTestExpectation *ex = [self expectationWithDescription:@""];
        [app.emailPasswordAuth registerUserWithEmail:name password:@"password" completion:^(NSError *error) {
            XCTAssertNil(error);
            [ex fulfill];
        }];
        [self waitForExpectations:@[ex] timeout:20.0];
    }
    return [RLMCredentials credentialsWithEmail:name password:@"password"];
}

- (RLMAppConfiguration*)defaultAppConfiguration {
    auto config = [[RLMAppConfiguration alloc] initWithBaseURL:@"http://localhost:9090"
                                                     transport:[TestNetworkTransport new]
                                       defaultRequestTimeoutMS:60000];
    config.rootDirectory = self.clientDataRoot;
    return config;
}

- (void)addPersonsToRealm:(RLMRealm *)realm persons:(NSArray<Person *> *)persons {
    [realm beginWriteTransaction];
    [realm addObjects:persons];
    [realm commitWriteTransaction];
}

- (RLMRealmConfiguration *)configuration {
    RLMRealmConfiguration *configuration = [self configurationForUser:self.createUser];
    configuration.objectClasses = self.defaultObjectTypes;
    return configuration;
}

- (RLMRealmConfiguration *)configurationForUser:(RLMUser *)user {
    return [user configurationWithPartitionValue:self.name];
}

- (RLMRealm *)openRealm {
    return [self openRealmWithUser:self.createUser];
}

- (RLMRealm *)openRealmWithUser:(RLMUser *)user {
    auto c = [self configurationForUser:user];
    c.objectClasses = self.defaultObjectTypes;
    return [self openRealmWithConfiguration:c];
}

- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue user:(RLMUser *)user {
    auto c = [user configurationWithPartitionValue:partitionValue];
    c.objectClasses = self.defaultObjectTypes;
    return [self openRealmWithConfiguration:c];
}

- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user
                         clientResetMode:(RLMClientResetMode)clientResetMode {
    auto c = [user configurationWithPartitionValue:partitionValue clientResetMode:clientResetMode];
    c.objectClasses = self.defaultObjectTypes;
    return [self openRealmWithConfiguration:c];
}

- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user
                           encryptionKey:(nullable NSData *)encryptionKey
                              stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    return [self openRealmForPartitionValue:partitionValue
                                       user:user
                            clientResetMode:RLMClientResetModeRecoverUnsyncedChanges
                              encryptionKey:encryptionKey
                                 stopPolicy:stopPolicy];
}

- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user
                         clientResetMode:(RLMClientResetMode)clientResetMode
                           encryptionKey:(nullable NSData *)encryptionKey
                              stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    RLMRealm *realm = [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                             user:user
                                                  clientResetMode:clientResetMode
                                                    encryptionKey:encryptionKey
                                                       stopPolicy:stopPolicy];
    [self waitForDownloadsForRealm:realm];
    return realm;
}

- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration {
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nullptr];
    [self waitForDownloadsForRealm:realm];
    return realm;
}

- (RLMRealm *)asyncOpenRealmWithConfiguration:(RLMRealmConfiguration *)config {
    __block RLMRealm *r = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Should asynchronously open a Realm"];
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *err) {
        XCTAssertNil(err);
        XCTAssertNotNil(realm);
        r = realm;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    // Ensure that the block does not retain the Realm, as it may not be dealloced
    // immediately and so would extend the lifetime of the Realm an inconsistent amount
    auto realm = r;
    r = nil;
    return realm;
}

- (NSError *)asyncOpenErrorWithConfiguration:(RLMRealmConfiguration *)config {
    __block NSError *error = nil;
    XCTestExpectation *ex = [self expectationWithDescription:@"Should fail to asynchronously open a Realm"];
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *r, NSError *err){
        XCTAssertNotNil(err);
        XCTAssertNil(r);
        error = err;
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    return error;
}

- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue user:(RLMUser *)user {
    return [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                  user:user
                                       clientResetMode:RLMClientResetModeRecoverUnsyncedChanges];
}

- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue
                                               user:(RLMUser *)user
                                    clientResetMode:(RLMClientResetMode)clientResetMode {
    return [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                  user:user
                                       clientResetMode:clientResetMode
                                         encryptionKey:nil
                                            stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue
                                               user:(RLMUser *)user
                                      encryptionKey:(NSData *)encryptionKey
                                         stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    return [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                  user:user
                                       clientResetMode:RLMClientResetModeRecoverUnsyncedChanges
                                         encryptionKey:encryptionKey
                                            stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue
                                               user:(RLMUser *)user
                                    clientResetMode:(RLMClientResetMode)clientResetMode
                                      encryptionKey:(NSData *)encryptionKey
                                         stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    auto c = [user configurationWithPartitionValue:partitionValue clientResetMode:clientResetMode];
    c.encryptionKey = encryptionKey;
    c.objectClasses = self.defaultObjectTypes;
    RLMSyncConfiguration *syncConfig = c.syncConfiguration;
    syncConfig.stopPolicy = stopPolicy;
    c.syncConfiguration = syncConfig;
    return [RLMRealm realmWithConfiguration:c error:nil];
}

- (RLMUser *)createUser {
    return [self createUserForApp:self.app];
}

- (RLMUser *)createUserForApp:(RLMApp *)app {
    NSString *name = [self.name stringByAppendingFormat:@" %@", NSUUID.UUID.UUIDString];
    return [self logInUserForCredentials:[self basicCredentialsWithName:name register:YES app:app] app:app];
}

- (RLMUser *)logInUserForCredentials:(RLMCredentials *)credentials {
    return [self logInUserForCredentials:credentials app:self.app];
}

- (RLMUser *)logInUserForCredentials:(RLMCredentials *)credentials app:(RLMApp *)app {
    __block RLMUser* user;
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [app loginWithCredential:credentials completion:^(RLMUser *u, NSError *e) {
        XCTAssertNotNil(u);
        XCTAssertNil(e);
        user = u;
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:20.0];
    XCTAssertTrue(user.state == RLMUserStateLoggedIn, @"User should have been valid, but wasn't");
    return user;
}

- (void)logOutUser:(RLMUser *)user {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [user logOutWithCompletion:^(NSError * error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:20.0];
    XCTAssertTrue(user.state == RLMUserStateLoggedOut, @"User should have been logged out, but wasn't");
}

- (NSString *)createJWTWithAppId:(NSString *)appId {
    NSDictionary *header = @{@"alg": @"HS256", @"typ": @"JWT"};
    NSDictionary *payload = @{
        @"aud": appId,
        @"sub": @"someUserId",
        @"exp": @1961896476,
        @"user_data": @{
            @"name": @"Foo Bar",
            @"occupation": @"firefighter"
        },
        @"my_metadata": @{
            @"name": @"Bar Foo",
            @"occupation": @"stock analyst"
        }
    };

    NSData *jsonHeader = [NSJSONSerialization  dataWithJSONObject:header options:0 error:nil];
    NSData *jsonPayload = [NSJSONSerialization  dataWithJSONObject:payload options:0 error:nil];

    NSString *base64EncodedHeader = [jsonHeader base64EncodedStringWithOptions:0];
    NSString *base64EncodedPayload = [jsonPayload base64EncodedStringWithOptions:0];

    // Remove padding characters.
    base64EncodedHeader = [base64EncodedHeader stringByReplacingOccurrencesOfString:@"=" withString:@""];
    base64EncodedPayload = [base64EncodedPayload stringByReplacingOccurrencesOfString:@"=" withString:@""];

    std::string jwtPayload = [[NSString stringWithFormat:@"%@.%@", base64EncodedHeader, base64EncodedPayload] UTF8String];
    std::string jwtKey = [@"My_very_confidential_secretttttt" UTF8String];

    NSString *key = @"My_very_confidential_secretttttt";
    NSString *data = @(jwtPayload.c_str());

    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    NSString *hmac = [HMAC base64EncodedStringWithOptions:0];

    hmac = [hmac stringByReplacingOccurrencesOfString:@"=" withString:@""];
    hmac = [hmac stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    hmac = [hmac stringByReplacingOccurrencesOfString:@"/" withString:@"_"];

    return [NSString stringWithFormat:@"%@.%@", @(jwtPayload.c_str()), hmac];
}

- (RLMCredentials *)jwtCredentialWithAppId:(NSString *)appId {
    return [RLMCredentials credentialsWithJWT:[self createJWTWithAppId:appId]];
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm {
    [self waitForUploadsForRealm:realm error:nil];
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMSyncSession *session = realm.syncSession;
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for upload completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForUploadCompletionOnQueue:dispatch_get_global_queue(0, 0)
                                                 callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Upload waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:60.0];
}

- (void)waitForDownloadsForRealm:(RLMRealm *)realm {
    RLMSyncSession *session = realm.syncSession;
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for download completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForDownloadCompletionOnQueue:dispatch_get_global_queue(0, 0)
                                                   callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Download waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:60.0];
    [realm refresh];
}

- (void)setInvalidTokensForUser:(RLMUser *)user {
    realm::RealmJWT token(std::string_view(self.badAccessToken));
    user.user->update_data_for_testing([&](auto& data) {
        data.access_token = token;
        data.refresh_token = token;
    });
}

- (void)writeToPartition:(NSString *)partition block:(void (^)(RLMRealm *))block {
    @autoreleasepool {
        RLMUser *user = [self createUser];
        auto c = [user configurationWithPartitionValue:partition];
        c.objectClasses = self.defaultObjectTypes;
        [self writeToConfiguration:c block:block];
    }
}

- (void)writeToConfiguration:(RLMRealmConfiguration *)config block:(void (^)(RLMRealm *))block {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nullptr];
        [self waitForDownloadsForRealm:realm];
        [realm beginWriteTransaction];
        block(realm);
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
    }

    // A synchronized Realm is not closed immediately when we release our last
    // reference as the sync worker thread also has to clean up, so retry deleting
    // it until we can, waiting up to one second. This typically takes a single
    // retry.
    int retryCount = 0;
    NSError *error;
    while (![RLMRealm deleteFilesForConfiguration:config error:&error]) {
        XCTAssertEqual(error.code, RLMErrorAlreadyOpen);
        if (++retryCount > 1000) {
            XCTFail(@"Waiting for Realm to be closed timed out");
            break;
        }
        usleep(1000);
    }
}

#pragma mark - XCUnitTest Lifecycle

+ (XCTestSuite *)defaultTestSuite {
    if ([RealmServer haveServer]) {
        return [super defaultTestSuite];
    }
    NSLog(@"Skipping sync tests: server is not present. Run `build.sh setup-baas` to install it.");
    return [[XCTestSuite alloc] initWithName:[super defaultTestSuite].name];
}

+ (void)setUp {
    [super setUp];
    // Wait for the server to launch
    if ([RealmServer haveServer]) {
        (void)[RealmServer shared];
    }
}

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    if (auto ids = NSProcessInfo.processInfo.environment[@"RLMParentAppIds"]) {
        _appIds = [ids componentsSeparatedByString:@","];   //take the one array for split the string
    }
    NSURL *clientDataRoot = self.clientDataRoot;
    [NSFileManager.defaultManager removeItemAtURL:clientDataRoot error:nil];
    NSError *error;
    [NSFileManager.defaultManager createDirectoryAtURL:clientDataRoot
                           withIntermediateDirectories:YES attributes:nil error:&error];
    XCTAssertNil(error);
}

- (void)tearDown {
    [self resetSyncManager];
    [RealmServer.shared deleteAppsAndReturnError:nil];
    [super tearDown];
}

static NSString *s_appId;
static bool s_opensApp;
+ (void)tearDown {
    if (s_appId && s_opensApp) {
        [RealmServer.shared deleteApp:s_appId error:nil];
        s_appId = nil;
        s_opensApp = false;
    }
}

- (NSString *)appId {
    if (s_appId) {
        return s_appId;
    }
    if (NSString *appId = NSProcessInfo.processInfo.environment[@"RLMParentAppId"]) {
        return s_appId = appId;
    }
    NSError *error;
    s_appId = [self createAppWithError:&error];
    if (error) {
        NSLog(@"Failed to create app: %@", error);
        abort();
    }
    s_opensApp = true;
    return s_appId;
}

- (NSString *)createAppWithError:(NSError **)error {
    return [RealmServer.shared createAppWithPartitionKeyType:@"string"
                                                       types:self.defaultObjectTypes
                                                  persistent:true error:error];
}

- (RLMApp *)app {
    if (!_app) {
        _app = [self appWithId:self.appId];
    }
    return _app;
}

- (void)resetSyncManager {
    _app = nil;
    [self resetAppCache];
}

- (void)resetAppCache {
    NSArray<RLMApp *> *apps = [RLMApp allApps];
    NSMutableArray<XCTestExpectation *> *exs = [NSMutableArray new];
    for (RLMApp *app : apps) @autoreleasepool {
        [app.allUsers enumerateKeysAndObjectsUsingBlock:^(NSString *, RLMUser *user, BOOL *) {
            XCTestExpectation *ex = [self expectationWithDescription:@"Wait for logout"];
            [exs addObject:ex];
            [user logOutWithCompletion:^(NSError *) {
                [ex fulfill];
            }];
        }];

        // Sessions are removed from the user asynchronously after a logout.
        // We need to wait for this to happen before calling resetForTesting as
        // that expects all sessions to be cleaned up first.
        [exs addObject:[self expectationForPredicate:[NSPredicate predicateWithFormat:@"hasAnySessions = false"]
                                 evaluatedWithObject:app.syncManager handler:nil]];
    }

    if (exs.count) {
        [self waitForExpectations:exs timeout:60.0];
    }

    for (RLMApp *app : apps) {
        if (auto transport = RLMDynamicCast<TestNetworkTransport>(app.configuration.transport)) {
            [transport waitForCompletion];
        }
        [app.syncManager resetForTesting];
    }
    [RLMApp resetAppCache];
}

- (const char *)badAccessToken {
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJl"
    "eHAiOjE1ODE1MDc3OTYsImlhdCI6MTU4MTUwNTk5NiwiaXNzIjoiN"
    "WU0M2RkY2M2MzZlZTEwNmVhYTEyYmRjIiwic3RpdGNoX2RldklkIjo"
    "iMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwIiwic3RpdGNoX2RvbWFpbk"
    "lkIjoiNWUxNDk5MTNjOTBiNGFmMGViZTkzNTI3Iiwic3ViIjoiNWU0M2R"
    "kY2M2MzZlZTEwNmVhYTEyYmRhIiwidHlwIjoiYWNjZXNzIn0.0q3y9KpFx"
    "EnbmRwahvjWU1v9y1T1s3r2eozu93vMc3s";
}

- (void)cleanupRemoteDocuments:(RLMMongoCollection *)collection {
    XCTestExpectation *deleteManyExpectation = [self expectationWithDescription:@"should delete many documents"];
    [collection deleteManyDocumentsWhere:@{}
                              completion:^(NSInteger, NSError *error) {
        XCTAssertNil(error);
        [deleteManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (NSURL *)clientDataRoot {
    if (self.isParent) {
        return [NSURL fileURLWithPath:RLMDefaultDirectoryForBundleIdentifier(nil)];
    } else {
        return syncDirectoryForChildProcess();
    }
}

- (NSTask *)childTask {
    return [self childTaskWithAppIds:s_appId ? @[s_appId] : @[]];
}

- (RLMApp *)appWithId:(NSString *)appId {
    auto config = self.defaultAppConfiguration;
    config.appId = appId;
    RLMApp *app = [RLMApp appWithConfiguration:config];
    RLMSyncManager *syncManager = app.syncManager;
    syncManager.userAgent = self.name;
    RLMLogger.defaultLogger.level = RLMLogLevelWarn;
    return app;
}

- (NSString *)partitionBsonType:(id<RLMBSON>)bson {
    switch (bson.bsonType){
        case RLMBSONTypeString:
            return @"string";
        case RLMBSONTypeUUID:
            return @"uuid";
        case RLMBSONTypeInt32:
        case RLMBSONTypeInt64:
            return @"long";
        case RLMBSONTypeObjectId:
            return @"objectId";
        default:
            return @"";
    }
}

#pragma mark Flexible Sync App

- (NSString *)createFlexibleSyncAppWithError:(NSError **)error {
    NSArray *fields = @[@"age", @"breed", @"partition", @"firstName", @"boolCol", @"intCol", @"stringCol", @"dateCol", @"lastName", @"_id", @"uuidCol"];
    return [RealmServer.shared createAppWithFields:fields
                                             types:self.defaultObjectTypes
                                        persistent:true
                                             error:error];
}

- (void)populateData:(void (^)(RLMRealm *))block {
    RLMRealm *realm = [self openRealm];
    RLMRealmSubscribeToAll(realm);
    [realm beginWriteTransaction];
    block(realm);
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
}

- (void)writeQueryAndCompleteForRealm:(RLMRealm *)realm block:(void (^)(RLMSyncSubscriptionSet *))block {
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);

    XCTestExpectation *ex = [self expectationWithDescription:@"state changes"];
    [subs update:^{
        block(subs);
    } onComplete:^(NSError* error) {
        XCTAssertNil(error);
        [ex fulfill];
    }];
    XCTAssertNotNil(subs);
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
    [self waitForDownloadsForRealm:realm];
}

@end

@implementation TestNetworkTransport {
    dispatch_group_t _group;
}
- (instancetype)init {
    if (self = [super init]) {
        _group = dispatch_group_create();
    }
    return self;
}
- (void)sendRequestToServer:(RLMRequest *)request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock {
    dispatch_group_enter(_group);
    [super sendRequestToServer:request completion:^(RLMResponse *response) {
        completionBlock(response);
        dispatch_group_leave(_group);
    }];
}

- (void)waitForCompletion {
    dispatch_group_wait(_group, DISPATCH_TIME_FOREVER);
}
@end

@implementation RLMUser (Test)
- (RLMMongoCollection *)collectionForType:(Class)type app:(RLMApp *)app {
    return [[[self mongoClientWithServiceName:@"mongodb1"]
             databaseWithName:@"test_data"]
            collectionWithName:[NSString stringWithFormat:@"%@ %@", [type className], app.appId]];
}
@end

int64_t RLMGetClientFileIdent(RLMRealm *realm) {
    return realm->_realm->sync_session()->get_file_ident().ident;
}

#endif // TARGET_OS_OSX
