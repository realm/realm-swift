////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMSyncCredentials, RLMSyncUser;

/// A block type used for auth APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

/// RLMAuth` acts as an authentication manager for a given `RLMApp`.
@interface RLMAuth: NSObject

/// All logged in users for an application
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, RLMSyncUser *>* allUsers;
/// The currently active user for an application
@property (nonatomic, readonly, nullable) RLMSyncUser *currentUser;

/**
 Log in a user and asynchronously retrieve a user object.

 If the log in completes successfully, the completion block will be called, and a
 `SyncUser` representing the logged-in user will be passed to it. This user object
 can be used to open `Realm`s and retrieve `SyncSession`s. Otherwise, the
 completion block will be called with an error.

 - parameter credentials: A `SyncCredentials` object representing the user to log in.
 - parameter timeout: How long the network client should wait, in seconds, before timing out.
 - parameter callbackQueue: The dispatch queue upon which the callback should run. Defaults to the main queue.
 - parameter completion: A callback block to be invoked once the log in completes.
 */
- (void)logInWithCredentials:(RLMSyncCredentials *)credentials
                     timeout:(NSTimeInterval)timeout
               callbackQueue:(dispatch_queue_t)callbackQueue
                onCompletion:(RLMUserCompletionBlock)completion NS_REFINED_FOR_SWIFT;

- (void)switchUser:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
