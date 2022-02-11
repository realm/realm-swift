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

@class RLMFastEnumerator;

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

@end

NS_ASSUME_NONNULL_END
