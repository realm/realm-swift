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

@class RLMFastEnumerator, RLMSyncSubscription;

NS_ASSUME_NONNULL_BEGIN

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


@protocol RLMScheduler <NSObject>

// Trigger a call to the registered notify callback on the scheduler's event loop.
//
// This function can be called from any thread.
- (void)notify;
// Check if the caller is currently running on the scheduler's thread.
//
// This function can be called from any thread.
- (BOOL)isOnThread;

// Checks if this scheduler instance wraps the same underlying instance.
// This is up to the platforms to define, but if this method returns true,
// caching may occur.
- (BOOL)isEqualToScheduler:(id<RLMScheduler>)scheduler;

// Check if this scehduler actually can support notify(). Notify may be
// either not implemented, not applicable to a scheduler type, or simply not
// be possible currently (e.g. if the associated event loop is not actually
// running).
//
// This function is not thread-safe.
- (BOOL)canDeliverNotifications;
// Set the callback function which will be called by notify().
//
// This function is not thread-safe.
- (void)setNotifyCallback:(void(^)(void))callback;

@end


// RLMRealm private members
@interface RLMRealm ()

@property (nonatomic, readonly) BOOL dynamic;
@property (nonatomic, readwrite) RLMSchema *schema;

+ (void)resetRealmState;

- (void)registerEnumerator:(RLMFastEnumerator *)enumerator;
- (void)unregisterEnumerator:(RLMFastEnumerator *)enumerator;
- (void)detachAllEnumerators;

- (void)sendNotifications:(RLMNotification)notification;
- (void)verifyThread;
- (void)verifyNotificationsAreSupported:(bool)isCollection;

- (RLMRealm *)frozenCopy NS_RETURNS_RETAINED;
+ (RLMAsyncOpenTask *)asyncOpenWithConfiguration:(RLMRealmConfiguration *)configuration
                                        callback:(void (^)(NSError * _Nullable))callback;
/**
 Obtains an `RLMRealm` instance with the given configuration.

 @param configuration A configuration object to use when creating the Realm.
 @param error         If an error occurs, upon return contains an `NSError` object
                      that describes the problem. If you are not interested in
                      possible errors, pass in `NULL`.

 @return An `RLMRealm` instance.
 */
+ (nullable instancetype)realmWithConfiguration:(nonnull RLMRealmConfiguration *)configuration
                                      scheduler:(nonnull id<RLMScheduler>)scheduler
                                          error:(NSError **)error;


@end

NS_ASSUME_NONNULL_END
