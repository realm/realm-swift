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

@class RLMFastEnumerator, RLMAsyncRefreshTask;

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

// This struct is awkward to make it compatible with Swift. Non-c++ obj-c can't
// have retaining struct members (as that requires copy constructors etc.), so
// it needs to be non-owning and passed via a pointer to C. In C++ land, though,
// we need to be able to copy it and have it retain things. This is arguable an
// ODR violation but Foundation does it all over the place.
typedef struct RLMConfinement {
#ifdef __cplusplus
    _Nullable dispatch_queue_t queue;
    _Nullable id actor;
    void (^_Nullable scheduler)(dispatch_block_t);
    _Nullable dispatch_block_t verifier;
#else
    __unsafe_unretained _Nullable dispatch_queue_t queue;
    __unsafe_unretained _Nullable id actor;
    __unsafe_unretained void (^_Nullable scheduler)(dispatch_block_t);
    __unsafe_unretained _Nullable dispatch_block_t verifier;
#endif
} RLMConfinement;

FOUNDATION_EXTERN RLMRealm *_Nullable RLMGetCachedRealm(RLMRealmConfiguration *, const RLMConfinement *) NS_RETURNS_RETAINED;

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
                                     confinedTo:(const RLMConfinement *)options
                                          error:(NSError **)error;
- (void)waitForDownloadCompletion:(void (^)(NSError *_Nullable))completion;
@end

@interface RLMPinnedRealm : NSObject
@property (nonatomic, readonly) RLMRealmConfiguration *configuration;

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)unpin;
@end

RLM_HEADER_AUDIT_END(nullability)
