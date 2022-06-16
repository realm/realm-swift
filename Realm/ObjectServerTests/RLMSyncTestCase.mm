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

#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncConfiguration_Private.h"
#import "RLMUtil.hpp"
#import "RLMApp_Private.hpp"
#import "RLMChildProcessEnvironment.h"
#import "RLMRealmUtil.hpp"

#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>
#import <realm/object-store/sync/sync_user.hpp>

#if TARGET_OS_OSX

@interface RealmServer : NSObject
+ (RealmServer *)shared;
+ (bool)haveServer;
- (NSString *)createAppAndReturnError:(NSError **)error;
- (NSString *)createAppWithQueryableFields:(NSArray *)queryableFields error:(NSError **)error;
@end

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

@interface RLMUser()
- (std::shared_ptr<realm::SyncUser>)_syncUser;
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
    NSString *_appId;
    RLMApp *_app;
    NSString *_flexibleSyncAppId;
    RLMApp *_flexibleSyncApp;
}

#pragma mark - Helper methods

- (RLMUser *)userForTest:(SEL)sel {
    return [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(sel)
                                                               register:self.isParent]];
}

- (RLMRealm *)realmForTest:(SEL)sel {
    RLMUser *user = [self userForTest:sel];
    NSString *realmId = NSStringFromSelector(sel);
    return [self openRealmForPartitionValue:realmId user:user];
}

- (RLMUser *)anonymousUser {
    return [self logInUserForCredentials:[RLMCredentials anonymousCredentials]];
}

- (RLMCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister {
    return [self basicCredentialsWithName:name register:shouldRegister app:nil];
}

- (RLMCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister app:(nullable RLMApp *) app {
    if (shouldRegister) {
        XCTestExpectation *expectation = [self expectationWithDescription:@""];
        RLMApp *currentApp = app ?: self.app;
        [currentApp.emailPasswordAuth registerUserWithEmail:name password:@"password" completion:^(NSError *error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
        [self waitForExpectationsWithTimeout:4.0 handler:nil];
    }
    return [RLMCredentials credentialsWithEmail:name
                                       password:@"password"];
}

- (RLMAppConfiguration*)defaultAppConfiguration {
    return  [[RLMAppConfiguration alloc] initWithBaseURL:@"http://localhost:9090"
                                               transport:[TestNetworkTransport new]
                                            localAppName:nil
                                         localAppVersion:nil
                                 defaultRequestTimeoutMS:60000];
}

- (void)addPersonsToRealm:(RLMRealm *)realm persons:(NSArray<Person *> *)persons {
    [realm beginWriteTransaction];
    [realm addObjects:persons];
    [realm commitWriteTransaction];
}

- (void)addAllTypesSyncObjectToRealm:(RLMRealm *)realm values:(NSDictionary *)dictionary person:(Person *)person {
    [realm beginWriteTransaction];
    AllTypesSyncObject *obj = [[AllTypesSyncObject alloc] initWithValue:dictionary];
    obj.objectCol = person;
    [realm addObject:obj];
    [realm commitWriteTransaction];
}

- (void)waitForDownloadsForUser:(RLMUser *)user
                         realms:(NSArray<RLMRealm *> *)realms
                partitionValues:(NSArray<NSString *> *)partitionValues
                 expectedCounts:(NSArray<NSNumber *> *)counts {
    NSAssert(realms.count == counts.count && realms.count == partitionValues.count,
             @"Test logic error: all array arguments must be the same size.");
    for (NSUInteger i = 0; i < realms.count; i++) {
        [self waitForDownloadsForUser:user partitionValue:partitionValues[i] expectation:nil error:nil];
        [realms[i] refresh];
        CHECK_COUNT([counts[i] integerValue], Person, realms[i]);
    }
}

- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue user:(RLMUser *)user {
    return [self openRealmForPartitionValue:partitionValue
                                       user:user
                              encryptionKey:nil
                                 stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user
                           encryptionKey:(nullable NSData *)encryptionKey
                              stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    RLMRealm *realm = [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                             user:user
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
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
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
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    return error;
}

- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue user:(RLMUser *)user {
    return [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                  user:user
                                         encryptionKey:nil
                                            stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue
                                               user:(RLMUser *)user
                                      encryptionKey:(NSData *)encryptionKey
                                         stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    auto c = [user configurationWithPartitionValue:partitionValue];
    c.encryptionKey = encryptionKey;
    c.objectClasses = @[Dog.self, Person.self, HugeSyncObject.self, RLMSetSyncObject.self,
                        RLMArraySyncObject.self, UUIDPrimaryKeyObject.self, StringPrimaryKeyObject.self,
                        IntPrimaryKeyObject.self, AllTypesSyncObject.self, RLMDictionarySyncObject.self];
    RLMSyncConfiguration *syncConfig = c.syncConfiguration;
    syncConfig.stopPolicy = stopPolicy;
    c.syncConfiguration = syncConfig;
    return [RLMRealm realmWithConfiguration:c error:nil];
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
    [self waitForExpectations:@[expectation] timeout:4.0];
    XCTAssertTrue(user.state == RLMUserStateLoggedIn, @"User should have been valid, but wasn't");
    return user;
}

- (void)logOutUser:(RLMUser *)user {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [user logOutWithCompletion:^(NSError * error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:4.0];
    XCTAssertTrue(user.state == RLMUserStateLoggedOut, @"User should have been logged out, but wasn't");
}

- (NSString *)createJWTWithAppId:(NSString *)appId {
    NSDictionary *header = @{@"alg": @"HS256", @"typ": @"JWT"};
    NSDictionary *payload = @{
        @"aud": appId,
        @"sub": @"someUserId",
        @"exp": @1661896476,
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

- (void)waitForDownloadsForRealm:(RLMRealm *)realm {
    [self waitForDownloadsForRealm:realm error:nil];
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm {
    [self waitForUploadsForRealm:realm error:nil];
}

- (void)waitForDownloadsForUser:(RLMUser *)user
                 partitionValue:(NSString *)partitionValue
                    expectation:(XCTestExpectation *)expectation
                          error:(NSError **)error {
    RLMSyncSession *session = [user sessionForPartitionValue:partitionValue];
    NSAssert(session, @"Cannot call with invalid partition value");
    XCTestExpectation *ex = expectation ?: [self expectationWithDescription:@"Wait for download completion"];
    __block NSError *theError = nil;
    BOOL queued = [session waitForDownloadCompletionOnQueue:dispatch_get_global_queue(0, 0) callback:^(NSError *err) {
        theError = err;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Download waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:20.0];
    if (error) {
        *error = theError;
    }
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMSyncSession *session = realm.syncSession;
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for upload completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForUploadCompletionOnQueue:dispatch_get_global_queue(0, 0) callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Upload waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:20.0];
    if (error)
        *error = completionError;
}

- (void)waitForDownloadsForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMSyncSession *session = realm.syncSession;
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for download completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForDownloadCompletionOnQueue:nil callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Download waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:20.0];
    if (error) {
        *error = completionError;
    }
    [realm refresh];
}

- (void)manuallySetAccessTokenForUser:(RLMUser *)user value:(NSString *)tokenValue {
    [user _syncUser]->update_access_token(tokenValue.UTF8String);
}

- (void)manuallySetRefreshTokenForUser:(RLMUser *)user value:(NSString *)tokenValue {
    [user _syncUser]->update_refresh_token(tokenValue.UTF8String);
}

- (void)writeToPartition:(SEL)testSel block:(void (^)(RLMRealm *))block {
    NSString *testName = NSStringFromSelector(testSel);
    [self writeToPartition:testName userName:testName block:block];
}

- (void)writeToPartition:(nullable NSString *)testName userName:(NSString *)userNameBase block:(void (^)(RLMRealm *))block {
    @autoreleasepool {
        NSString *userName = [userNameBase stringByAppendingString:[NSUUID UUID].UUIDString];
        RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:userName
                                                                            register:YES]];
        auto c = [user configurationWithPartitionValue:testName];
        c.objectClasses = @[Dog.self, Person.self, HugeSyncObject.self, RLMSetSyncObject.self,
                            RLMArraySyncObject.self, UUIDPrimaryKeyObject.self, StringPrimaryKeyObject.self,
                            IntPrimaryKeyObject.self, AllTypesSyncObject.self, RLMDictionarySyncObject.self];
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
    [super tearDown];
}

- (NSString *)appId {
    if (!_appId) {
        static NSString *s_appId;
        if (self.isParent && s_appId) {
            _appId = s_appId;
        }
        else {
            NSError *error;
            _appId = NSProcessInfo.processInfo.environment[@"RLMParentAppId"] ?: [RealmServer.shared createAppAndReturnError:&error];
            if (error) {
                NSLog(@"Failed to create app: %@", error);
                abort();
            }

            if (self.isParent) {
                s_appId = _appId;
            }
        }
    }
    return _appId;
}

- (RLMApp *)app {
    if (!_app) {
        _app = [RLMApp appWithId:self.appId configuration:self.defaultAppConfiguration rootDirectory:self.clientDataRoot];
        RLMSyncManager *syncManager = self.app.syncManager;
        syncManager.logLevel = RLMSyncLogLevelTrace;
        syncManager.userAgent = self.name;
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

            // Sessions are removed from the user asynchronously after a logout.
            // We need to wait for this to happen before calling resetForTesting as
            // that expects all sessions to be cleaned up first.
            if (user.allSessions.count) {
                [exs addObject:[self expectationForPredicate:[NSPredicate predicateWithFormat:@"allSessions.@count == 0"]
                                         evaluatedWithObject:user handler:nil]];
            }
        }];
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

- (NSString *)badAccessToken {
    return @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJl"
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
                              completion:^(NSInteger, NSError * error) {
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
    return [self childTaskWithAppIds:_appId ? @[_appId] : @[]];
}

- (RLMApp *)appFromAppId:(NSString *)appId {
    return [RLMApp appWithId:appId
               configuration:self.defaultAppConfiguration
               rootDirectory:self.clientDataRoot];
}

- (NSString *)partitionBsonType:(id<RLMBSON>)bson {
    switch(bson.bsonType){
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
            return(@"");
        }
}

#pragma mark Flexible Sync App

- (NSString *)flexibleSyncAppId {
    if (!_flexibleSyncAppId) {
        static NSString *s_appId;
        if (s_appId) {
            _flexibleSyncAppId = s_appId;
        }
        else {
            NSError *error;
            _flexibleSyncAppId = [RealmServer.shared createAppWithQueryableFields:@[@"age", @"breed", @"partition", @"firstName", @"boolCol", @"intCol", @"stringCol", @"dateCol", @"lastName"] error:&error];
            if (error) {
                NSLog(@"Failed to create app: %@", error);
                abort();
            }

            s_appId = _flexibleSyncAppId;
        }
    }
    return _flexibleSyncAppId;
}

- (RLMApp *)flexibleSyncApp {
    if (!_flexibleSyncApp) {
        _flexibleSyncApp = [RLMApp appWithId:self.flexibleSyncAppId
                               configuration:self.defaultAppConfiguration
                               rootDirectory:self.clientDataRoot];
        RLMSyncManager *syncManager = self.flexibleSyncApp.syncManager;
        syncManager.logLevel = RLMSyncLogLevelTrace;
        syncManager.userAgent = self.name;
    }
    return _flexibleSyncApp;
}

- (RLMRealm *)flexibleSyncRealmForUser:(RLMUser *)user {
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Dog.self,
                             Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    [self waitForDownloadsForRealm:realm];
    return realm;
}

- (RLMUser *)flexibleSyncUser:(SEL)testSel {
    return [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(testSel)
                                                               register:YES
                                                                    app:self.flexibleSyncApp]
                                     app:self.flexibleSyncApp];
}

- (RLMRealm *)getFlexibleSyncRealm:(SEL)testSel {
    RLMRealm *realm = [self flexibleSyncRealmForUser:[self flexibleSyncUser:testSel]];
    XCTAssertNotNil(realm);
    return realm;
}

- (RLMRealm *)openFlexibleSyncRealm:(SEL)testSel {
    RLMUser *user = [self flexibleSyncUser:testSel];
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Dog.self,
                             Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    XCTAssertNotNil(realm);
    return realm;
}

- (bool)populateData:(void (^)(RLMRealm *))block {
    return [self writeToFlxRealm:^(RLMRealm *realm) {
        [realm beginWriteTransaction];
        block(realm);
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
    }];
}

- (bool)writeToFlxRealm:(void (^)(RLMRealm *))block {
    NSString *userName = [NSStringFromSelector(_cmd) stringByAppendingString:[NSUUID UUID].UUIDString];
    RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:userName
                                                                        register:YES
                                                                             app:self.flexibleSyncApp]
                                              app:self.flexibleSyncApp];
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Dog.self, Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];

    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);

    XCTestExpectation *ex = [self expectationWithDescription:@"state change complete"];
    [subs update:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_all"
                                     where:@"TRUEPREDICATE"];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_all"
                                     where:@"TRUEPREDICATE"];
    } onComplete: ^(NSError *error){
        XCTAssertNil(error);
        [ex fulfill];
    }];

    __block bool didComplete = false;
    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
        didComplete = error == nil;
    }];
    if (didComplete) {
        block(realm);
    }
    return didComplete;
}
- (void)writeQueryAndCompleteForRealm:(RLMRealm *)realm block:(void (^)(RLMSyncSubscriptionSet *))block {
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);

    XCTestExpectation *ex = [self expectationWithDescription:@"state changes"];
    [subs update:^{
        block(subs);
    } onComplete:^(NSError* error) {
        if (error == nil) {
            [ex fulfill];
        } else {
            XCTFail();
        }
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

#endif // TARGET_OS_OSX
