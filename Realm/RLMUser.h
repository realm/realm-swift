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

@class RLMUser, RLMCredential, RLMSyncSession, RLMRealm;

typedef NS_OPTIONS(NSUInteger, RLMAuthenticationActions) {
    RLMAuthenticationActionsCreateAccount            = 1 << 0,
    RLMAuthenticationActionsUseExistingAccount       = 1 << 1,
};

typedef void(^RLMUserCompletionBlock)(RLMUser * _Nullable, NSError * _Nullable);
typedef void(^RLMFetchedRealmCompletionBlock)(NSError * _Nullable, RLMRealm * _Nullable, BOOL * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

/**
 A `RLMUser` instance represents a single Realm Object Server user account (or just user).

 A user may have one or more credentials associated with it. These credentials uniquely identify the user to a
 third-party auth provider, and are used to sign into a Realm Object Server user account.
 */
@interface RLMUser : NSObject RLMSYNC_UNINITIALIZABLE

+ (NSArray<RLMUser *> *)all;

@property (nonatomic, readonly) RLMIdentity identity;

/**
 The URL of the authentication server this user will communicate with. If the user is anonymous, this property may be
 nil.
 */
@property (nullable, nonatomic, readonly) NSURL *authenticationServer;

/**
 Create, log in, and asynchronously return a new user object. A credential identifying the user must be passed in. The
 user becomes available in the completion block, at which point it is guaranteed to be non-anonymous and ready for use
 opening synced Realms.
 */
+ (void)authenticateWithCredential:(RLMCredential *)credential
                           actions:(RLMAuthenticationActions)actions
                     authServerURL:(NSURL *)authServerURL
                           timeout:(NSTimeInterval)timeout
                      onCompletion:(RLMUserCompletionBlock)completion NS_REFINED_FOR_SWIFT;

+ (void)authenticateWithCredential:(RLMCredential *)credential
                           actions:(RLMAuthenticationActions)actions
                     authServerURL:(NSURL *)authServerURL
                      onCompletion:(RLMUserCompletionBlock)completion
NS_SWIFT_UNAVAILABLE("Use the full version of this API.");

/**
 Create and log in a user given an access token.
 */
+ (instancetype)userWithAccessToken:(RLMServerToken)accessToken identity:(nullable NSString *)identity;

/**
 Log a user out, destroying their server state, deregistering them from the SDK, and removing any synced Realms
 associated with them from on-disk storage. This method may be called on an anonymous user.

 This method should be called whenever the application is committed to not using a user again unless they are recreated.
 Failing to call this method may result in unused files and metadata needlessly taking up space.
 */
//- (void)logOut;

- (NSDictionary<NSURL *, RLMSyncSession *> *)sessions;


#pragma mark - Temporary APIs

- (instancetype)initWithIdentity:(NSString *)identity
                    refreshToken:(RLMServerToken)refreshToken
                   authServerURL:(NSURL *)authServerURL;

- (RLMServerToken)refreshToken;

NS_ASSUME_NONNULL_END

@end
