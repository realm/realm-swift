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

#import "RLMMultiProcessTestCase.h"
#import "RLMServerTestObjects.h"

@class RLMAppConfiguration;
typedef NS_ENUM(NSUInteger, RLMSyncStopPolicy);
typedef void(^RLMSyncBasicErrorReportingBlock)(NSError * _Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface AsyncOpenConnectionTimeoutTransport : RLMNetworkTransport
@end

@interface RLMSyncTestCase : RLMMultiProcessTestCase

@property (nonatomic, readonly) NSString *appId;
@property (nonatomic, readonly) RLMApp *app;
@property (nonatomic, readonly) RLMUser *anonymousUser;
@property (nonatomic, readonly) RLMAppConfiguration *defaultAppConfiguration;

/// Any stray app ids passed between processes
@property (nonatomic, readonly) NSArray<NSString *> *appIds;

- (RLMUser *)userForTest:(SEL)sel;

- (RLMRealm *)realmForTest:(SEL)sel;

- (RLMCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister NS_SWIFT_NAME(basicCredentials(name:register:));

- (RLMCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister
                                         app:(nullable RLMApp*)app NS_SWIFT_NAME(basicCredentials(name:register:app:));

/// Synchronously open a synced Realm via asyncOpen and return the Realm.
- (RLMRealm *)asyncOpenRealmWithConfiguration:(RLMRealmConfiguration *)configuration;

/// Synchronously open a synced Realm via asyncOpen and return the expected error.
- (NSError *)asyncOpenErrorWithConfiguration:(RLMRealmConfiguration *)configuration;

/// Synchronously open a synced Realm and wait for downloads.
- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user;

/// Synchronously open a synced Realm with encryption key and stop policy and wait for downloads.
- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user
                           encryptionKey:(nullable NSData *)encryptionKey
                              stopPolicy:(RLMSyncStopPolicy)stopPolicy;

/// Synchronously open a synced Realm.
- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration;

/// Immediately open a synced Realm.
- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue user:(RLMUser *)user;

/// Immediately open a synced Realm with encryption key and stop policy.
- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                               user:(RLMUser *)user
                                      encryptionKey:(nullable NSData *)encryptionKey
                                         stopPolicy:(RLMSyncStopPolicy)stopPolicy;

/// Synchronously create, log in, and return a user.
- (RLMUser *)logInUserForCredentials:(RLMCredentials *)credentials;
- (RLMUser *)logInUserForCredentials:(RLMCredentials *)credentials app:(RLMApp *)app;

- (RLMCredentials *)jwtCredentialWithAppId:(NSString *)appId;

/// Synchronously, log out.
- (void)logOutUser:(RLMUser *)user;

- (void)addPersonsToRealm:(RLMRealm *)realm persons:(NSArray<Person *> *)persons;

- (void)addAllTypesSyncObjectToRealm:(RLMRealm *)realm values:(NSDictionary *)dictionary person:(Person *)person;

/// Synchronously wait for downloads to complete for any number of Realms, and then check their `SyncObject` counts.
- (void)waitForDownloadsForUser:(RLMUser *)user
                         realms:(NSArray<RLMRealm *> *)realms
                partitionValues:(NSArray<NSString *> *)partitionValues
                 expectedCounts:(NSArray<NSNumber *> *)counts;

/// Wait for downloads to complete; drop any error.
- (void)waitForDownloadsForRealm:(RLMRealm *)realm;
- (void)waitForDownloadsForRealm:(RLMRealm *)realm error:(NSError **)error;

/// Wait for uploads to complete; drop any error.
- (void)waitForUploadsForRealm:(RLMRealm *)realm;
- (void)waitForUploadsForRealm:(RLMRealm *)realm error:(NSError **)error;

/// Wait for downloads to complete while spinning the runloop. This method uses expectations.
- (void)waitForDownloadsForUser:(RLMUser *)user
                 partitionValue:(NSString *)partitionValue
                    expectation:(nullable XCTestExpectation *)expectation
                          error:(NSError **)error;

/// Manually set the access token for a user. Used for testing invalid token conditions.
- (void)manuallySetAccessTokenForUser:(RLMUser *)user value:(NSString *)tokenValue;

/// Manually set the refresh token for a user. Used for testing invalid token conditions.
- (void)manuallySetRefreshTokenForUser:(RLMUser *)user value:(NSString *)tokenValue;

- (void)writeToPartition:(SEL)testSel block:(void (^)(RLMRealm *))block;
- (void)writeToPartition:(nullable NSString *)testName userName:(NSString *)userNameBase block:(void (^)(RLMRealm *))block;

- (void)resetSyncManager;

- (NSString *)badAccessToken;

- (void)cleanupRemoteDocuments:(RLMMongoCollection *)collection;

- (nonnull NSURL *)clientDataRoot;

- (NSString *)partitionBsonType:(id<RLMBSON>)bson;

- (RLMApp *)appFromAppId:(NSString *)appId;

- (void)resetAppCache;

#pragma mark Flexible Sync App

@property (nonatomic, readonly) NSString *flexibleSyncAppId;
@property (nonatomic, readonly) RLMApp *flexibleSyncApp;

- (RLMUser *)flexibleSyncUser:(SEL)testSel;
- (RLMRealm *)openFlexibleSyncRealm:(SEL)testSel;
- (RLMRealm *)getFlexibleSyncRealm:(SEL)testSel;
- (bool)populateData:(void (^)(RLMRealm *))block;
- (void)writeQueryAndCompleteForRealm:(RLMRealm *)realm block:(void (^)(RLMSyncSubscriptionSet *))block;

@end

NS_ASSUME_NONNULL_END

#define WAIT_FOR_SEMAPHORE(macro_semaphore, macro_timeout) do {                                                        \
    int64_t delay_in_ns = (int64_t)(macro_timeout * NSEC_PER_SEC);                                                     \
    BOOL sema_success = dispatch_semaphore_wait(macro_semaphore, dispatch_time(DISPATCH_TIME_NOW, delay_in_ns)) == 0;  \
    XCTAssertTrue(sema_success, @"Semaphore timed out.");                                                              \
} while (0)

#define CHECK_COUNT(d_count, macro_object_type, macro_realm) do {                                         \
    [macro_realm refresh];                                                                                \
    RLMResults *r = [macro_object_type allObjectsInRealm:macro_realm];                                    \
    NSInteger c = r.count;                                                                                \
    NSString *w = self.isParent ? @"parent" : @"child";                                                   \
    XCTAssert(d_count == c, @"Expected %@ items, but actually got %@ (%@) (%@)", @(d_count), @(c), r, w); \
} while (0)
