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

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

// RealmServer is implemented in Swift
@interface RealmServer : NSObject
// Get the shared singleton instance
+ (RealmServer *)shared;
// Check if baas is installed. When running via SPM we can't install it
// automatically, so we skip running tests which require it if it's missing.
+ (bool)haveServer;
// Create a FLX app with the given queryable fields and object types. If
// `persistent:NO` the app will be deleted at the end of the current test, and
// otherwise it will remain until `deleteApp:` is called on it.
- (nullable NSString *)createAppWithFields:(NSArray<NSString *> *)fields
                                     types:(nullable NSArray<Class> *)types
                                persistent:(bool)persistent
                                     error:(NSError **)error;
// Create a PBS app with the given partition key type and object types. If
// `persistent:NO` the app will be deleted at the end of the current test, and
// otherwise it will remain until `deleteApp:` is called on it.
- (nullable NSString *)createAppWithPartitionKeyType:(NSString *)type
                                               types:(nullable NSArray<Class> *)types
                                          persistent:(bool)persistent
                                               error:(NSError **)error;

// Delete all apps created with `persistent:NO`. Called from `-tearDown`.
- (BOOL)deleteAppsAndReturnError:(NSError **)error;
// Delete a specific app created with `persistent:YES`. Called from `+tearDown`
// to delete the shared app for each test case.
- (BOOL)deleteApp:(NSString *)appId error:(NSError **)error;
@end

@interface AsyncOpenConnectionTimeoutTransport : RLMNetworkTransport
@end

// RLMSyncTestCase adds some helper functions for writing sync tests, and most
// importantly creates a shared Atlas app which is used by all tests in a test
// case. `self.app` and `self.appId` create the App if needed, and then the
// App is deleted at the end of the test case (i.e. in `+tearDown`).
//
// Each test case subclass must override `defaultObjectTypes` to return the
// `RLMObject` subclasses which the test case uses. These types are the only
// ones which will be present in the server schema, and using any other types
// will result in an error due to developer mode not being used.
//
// By default the app is a partition-based sync app. Test cases which test
// flexible sync must override `createAppWithError:` to call
// `createFlexibleSyncAppWithError:` and `configurationForUser:` to call `[user
// flexibleSyncConfiguration]`.
//
// Most tests can simply call `[self openRealm]` to obtain a synchronized
// Realm. For PBS tests, this will use the current test's name as the partition
// value. This creates a new user each time, so multiple calls to `openRealm`
// will produce separate Realm files. Users can also be created directly with
// `[self createUser]`.
//
// `writeToPartition:block:` for PBS and `populateData:` for FLX is the
// preferred way to populate the server-side state. This creates a new user,
// opens the Realm, calls the block in a write transaction to populate the
// data, waits for uploads to complete, and then deletes the user.
//
// Each test case's server state is fully isolated from other test cases due to
// the combination of creating a new app for each test case and that we add the
// app ID to the name of the collections used by the app. However, state can
// leak between tests within a test case. For partition-based tests this is
// mostly not a problem: each test uses the test name as the partition key and
// so will naturally be partitioned from other tests. For flexible sync, we
// follow the pattern of setting one of the fields in all objects created to
// the test's name and including that in subscriptions.
@interface RLMSyncTestCase : RLMMultiProcessTestCase

@property (nonatomic, readonly) NSString *appId;
@property (nonatomic, readonly) RLMApp *app;
@property (nonatomic, readonly) RLMUser *anonymousUser;
@property (nonatomic, readonly) RLMAppConfiguration *defaultAppConfiguration;

/// Any stray app ids passed between processes
@property (nonatomic, readonly) NSArray<NSString *> *appIds;

#pragma mark - Customization points

// Override to return the set of RLMObject subclasses used by this test case
- (NSArray<Class> *)defaultObjectTypes;
// Override to customize how the shared App is created for this test case. Most
// commonly this is overrided to `return [self createFlexibleSyncAppWithError:error];`
// for flexible sync test cases.
- (nullable NSString *)createAppWithError:(NSError **)error;
- (nullable NSString *)createFlexibleSyncAppWithError:(NSError **)error;
// Override to produce flexible sync configurations instead of the default PBS one.
- (RLMRealmConfiguration *)configurationForUser:(RLMUser *)user;

#pragma mark - Helpers

// Obtain a user with a name derived from test selector, registering it first
// if this is the parent process. This should only be used in multi-process
// tests (and most tests should not need to be multi-process).
- (RLMUser *)userForTest:(SEL)sel;
- (RLMUser *)userForTest:(SEL)sel app:(RLMApp *)app;

// Create new login credentials for this test, possibly registering the user
// first. This is needed to be able to log a user back in after logging out. If
// a user is only logged in one time, use `createUser` instead.
- (RLMCredentials *)basicCredentialsWithName:(NSString *)name
                                    register:(BOOL)shouldRegister NS_SWIFT_NAME(basicCredentials(name:register:));
- (RLMCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister
                                         app:(RLMApp*)app NS_SWIFT_NAME(basicCredentials(name:register:app:));

/// Synchronously open a synced Realm via asyncOpen and return the Realm.
- (RLMRealm *)asyncOpenRealmWithConfiguration:(RLMRealmConfiguration *)configuration;

/// Synchronously open a synced Realm via asyncOpen and return the expected error.
- (NSError *)asyncOpenErrorWithConfiguration:(RLMRealmConfiguration *)configuration;

// Create a new user, and return a configuration using that user.
- (RLMRealmConfiguration *)configuration NS_REFINED_FOR_SWIFT;

// Open the realm with the partition value `self.name` using a newly created user
- (RLMRealm *)openRealm NS_REFINED_FOR_SWIFT;
// Open the realm with the partition value `self.name` using the given user
- (RLMRealm *)openRealmWithUser:(RLMUser *)user;

/// Synchronously open a synced Realm and wait for downloads.
- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user;

/// Synchronously open a synced Realm and wait for downloads.
- (RLMRealm *)openRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                    user:(RLMUser *)user
                         clientResetMode:(RLMClientResetMode)clientResetMode;

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

/// Immediately open a synced Realm with encryption key and stop policy.
- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(nullable id<RLMBSON>)partitionValue
                                               user:(RLMUser *)user
                                    clientResetMode:(RLMClientResetMode)clientResetMode
                                      encryptionKey:(nullable NSData *)encryptionKey
                                         stopPolicy:(RLMSyncStopPolicy)stopPolicy;

/// Synchronously create, log in, and return a user.
- (RLMUser *)logInUserForCredentials:(RLMCredentials *)credentials;
- (RLMUser *)logInUserForCredentials:(RLMCredentials *)credentials app:(RLMApp *)app;

/// Synchronously register and log in a new non-anonymous user
- (RLMUser *)createUser;
- (RLMUser *)createUserForApp:(RLMApp *)app;

- (RLMCredentials *)jwtCredentialWithAppId:(NSString *)appId;

/// Log out and wait for the completion handler to be called
- (void)logOutUser:(RLMUser *)user;

- (void)addPersonsToRealm:(RLMRealm *)realm persons:(NSArray<Person *> *)persons;

/// Wait for downloads to complete; drop any error.
- (void)waitForDownloadsForRealm:(RLMRealm *)realm;

/// Wait for uploads to complete; drop any error.
- (void)waitForUploadsForRealm:(RLMRealm *)realm;

/// Set the user's tokens to invalid ones to test invalid token handling.
- (void)setInvalidTokensForUser:(RLMUser *)user;

- (void)writeToPartition:(nullable NSString *)partition block:(void (^)(RLMRealm *))block;

- (void)resetSyncManager;

- (const char *)badAccessToken;

- (void)cleanupRemoteDocuments:(RLMMongoCollection *)collection;

- (nonnull NSURL *)clientDataRoot;

- (NSString *)partitionBsonType:(id<RLMBSON>)bson;

- (RLMApp *)appWithId:(NSString *)appId NS_SWIFT_NAME(app(id:));

- (void)resetAppCache;

#pragma mark Flexible Sync App

- (void)populateData:(void (^)(RLMRealm *))block;
- (void)writeQueryAndCompleteForRealm:(RLMRealm *)realm block:(void (^)(RLMSyncSubscriptionSet *))block;

@end

@interface RLMSyncManager ()
// Wait for all sync sessions associated with this sync manager to be fully
// torn down. Once this returns, it is guaranteed that reopening a Realm will
// actually create a new sync session.
- (void)waitForSessionTermination;
@end

// Suspend or resume a sync session without fully tearing it down. These do
// what `suspend` and `resume` will do in the next major version, but it would
// be a breaking change to swap them.
@interface RLMSyncSession ()
- (void)pause;
- (void)unpause;
@end

@interface RLMUser (Test)
// Get the mongo collection for the given object type in the given app. This
// must be used instead of the normal public API because we scope our
// collection names to the app.
- (RLMMongoCollection *)collectionForType:(Class)type app:(RLMApp *)app NS_SWIFT_NAME(collection(for:app:));
@end

FOUNDATION_EXTERN int64_t RLMGetClientFileIdent(RLMRealm *realm);

RLM_HEADER_AUDIT_END(nullability, sendability)

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
