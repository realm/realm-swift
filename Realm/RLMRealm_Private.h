////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import <Realm/RLMRealm.h>

@class RLMFastEnumerator, RLMScheduler, RLMAsyncRefreshTask, RLMAsyncWriteTask;

RLM_HEADER_AUDIT_BEGIN(nullability)

// Disable syncing files to disk. Cannot be re-enabled. Use only for tests.
FOUNDATION_EXTERN void RLMDisableSyncToDisk(void);
// Set whether the skip backup attribute should be set on temporary files.
FOUNDATION_EXTERN void RLMSetSkipBackupAttribute(bool value);

FOUNDATION_EXTERN NSData * _Nullable RLMRealmValidatedEncryptionKey(NSData *key);

// Set the queue used for async open. For testing purposes only.
FOUNDATION_EXTERN void RLMSetAsyncOpenQueue(dispatch_queue_t queue);

// Translate an in-flight exception resulting from an operation on a SharedGroup to
// an NSError or NSException (if error is nil)
void RLMRealmTranslateException(NSError **error);

// Block until the Realm at the given path is closed.
FOUNDATION_EXTERN void RLMWaitForRealmToClose(NSString *path);
BOOL RLMIsRealmCachedAtPath(NSString *path);

// Register a block to be called from the next before_notify() invocation
FOUNDATION_EXTERN void RLMAddBeforeNotifyBlock(RLMRealm *realm, dispatch_block_t block);

// Test hook to run the async notifiers for a Realm which has the background thread disabled
FOUNDATION_EXTERN void RLMRunAsyncNotifiers(NSString *path);

// Get the cached Realm for the given configuration and scheduler, if any
FOUNDATION_EXTERN RLMRealm *_Nullable RLMGetCachedRealm(RLMRealmConfiguration *, RLMScheduler *) NS_RETURNS_RETAINED;
// Get a cached Realm for the given configuration and any scheduler. The returned
// Realm is not confined to the current thread, so very few operations are safe
// to perform on it
FOUNDATION_EXTERN RLMRealm *_Nullable RLMGetAnyCachedRealm(RLMRealmConfiguration *) NS_RETURNS_RETAINED;

// Scheduler an async refresh for the given Realm
FOUNDATION_EXTERN RLMAsyncRefreshTask *_Nullable RLMRealmRefreshAsync(RLMRealm *rlmRealm) NS_RETURNS_RETAINED;

// RLMRealm private members
@interface RLMRealm ()
@property (nonatomic, readonly) BOOL dynamic;
@property (nonatomic, readwrite) RLMSchema *schema;
@property (nonatomic, readonly, nullable) id actor;
@property (nonatomic, readonly) bool isFlexibleSync;

+ (void)resetRealmState;

- (void)registerEnumerator:(RLMFastEnumerator *)enumerator;
- (void)unregisterEnumerator:(RLMFastEnumerator *)enumerator;
- (void)detachAllEnumerators;

- (void)sendNotifications:(RLMNotification)notification;
- (void)verifyThread;
- (void)verifyNotificationsAreSupported:(bool)isCollection;

- (RLMRealm *)frozenCopy NS_RETURNS_RETAINED;

+ (nullable instancetype)realmWithConfiguration:(RLMRealmConfiguration *)configuration
                                     confinedTo:(RLMScheduler *)options
                                          error:(NSError **)error;

- (RLMAsyncWriteTask *)beginAsyncWrite NS_RETURNS_RETAINED;
- (void)commitAsyncWriteWithGrouping:(bool)allowGrouping
                          completion:(void(^)(NSError *_Nullable))completion;
@end

@interface RLMPinnedRealm : NSObject
@property (nonatomic, readonly) RLMRealmConfiguration *configuration;

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)unpin;
@end

RLM_HEADER_AUDIT_END(nullability)
