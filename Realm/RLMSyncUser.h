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

#import <Foundation/Foundation.h>

#import "RLMSyncUtil.h"

@class RLMSyncUser, RLMSyncCredential, RLMSyncSession, RLMRealm;

typedef NS_OPTIONS(NSUInteger, RLMAuthenticationActions) {
    RLMAuthenticationActionsCreateAccount            = 1 << 0,
    RLMAuthenticationActionsUseExistingAccount       = 1 << 1,
};

typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);
typedef void(^RLMFetchedRealmCompletionBlock)(NSError * _Nullable, RLMRealm * _Nullable, BOOL * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

/**
 A `RLMSyncUser` instance represents a single Realm Object Server user account (or just user).

 A user may have one or more credentials associated with it. These credentials uniquely identify the user to a
 third-party auth provider, and are used to sign into a Realm Object Server user account.
 */
@interface RLMSyncUser : NSObject RLM_SYNC_UNINITIALIZABLE

+ (NSArray<RLMSyncUser *> *)all;

@property (nonatomic, readonly) NSString *identity;

/**
 The URL of the authentication server this user will communicate with. If the user is anonymous, this property may be
 nil.
 */
@property (nullable, nonatomic, readonly) NSURL *authenticationServer;

/**
 Whether or not this user is valid. A user may be invalidated by logging out or due to an error condition.

 @warning It is an error to use invalid Realms for creating Realm configurations.
 */
@property (nonatomic, readonly) BOOL isValid;

/**
 Create, log in, and asynchronously return a new user object. A credential identifying the user must be passed in. The
 user becomes available in the completion block, at which point it is guaranteed to be non-anonymous and ready for use
 opening synced Realms.
 */
+ (void)authenticateWithCredential:(RLMSyncCredential *)credential
                           actions:(RLMAuthenticationActions)actions
                     authServerURL:(NSURL *)authServerURL
                           timeout:(NSTimeInterval)timeout
                      onCompletion:(RLMUserCompletionBlock)completion NS_REFINED_FOR_SWIFT;

+ (void)authenticateWithCredential:(RLMSyncCredential *)credential
                           actions:(RLMAuthenticationActions)actions
                     authServerURL:(NSURL *)authServerURL
                      onCompletion:(RLMUserCompletionBlock)completion
NS_SWIFT_UNAVAILABLE("Use the full version of this API.");

/**
 Log a user out, destroying their server state, deregistering them from the SDK, and removing any synced Realms
 associated with them from on-disk storage. This method may be called on an anonymous user.

 This method should be called whenever the application is committed to not using a user again unless they are recreated.
 Failing to call this method may result in unused files and metadata needlessly taking up space.
 */
- (void)logOut;

/**
 Retrieve a valid session object for a given URL, or `nil` if no such object exists.
 */
- (nullable RLMSyncSession *)sessionForURL:(NSURL *)url;

/**
 Retrieve all the valid sessions.
 */
- (NSArray<RLMSyncSession *> *)allSessions;

NS_ASSUME_NONNULL_END

@end
