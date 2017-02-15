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

@class RLMSyncUser, RLMSyncCredentials, RLMNotificationToken, RLMSyncSession, RLMRealm;

/**
 The state of the user object.
 */
typedef NS_ENUM(NSUInteger, RLMSyncUserState) {
    /// The user is logged out. Call `logInWithCredentials:...` with valid credentials to log the user back in.
    RLMSyncUserStateLoggedOut,
    /// The user is logged in, and any Realms associated with it are syncing with the Realm Object Server.
    RLMSyncUserStateActive,
    /// The user has encountered a fatal error state, and cannot be used.
    RLMSyncUserStateError,
};

/**
 Possible values for permissions that can be granted to a given user for working
 with a given synced Realm.
 */
typedef NS_OPTIONS(NSUInteger, RLMSyncRealmPermission) {
    /// The Realm can be read by a target user.
    RLMSyncRealmPermissionRead,
    /// The Realm can be modified by a target user.
    RLMSyncRealmPermissionWrite,
    /// The Realm can be managed by a target user.
    RLMSyncRealmPermissionManage,
};

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

/// A block type used to asynchronously report permission changes.
typedef void(^RLMSyncPermissionChangeBlock)(RLMSyncManagementObjectStatus, NSError * _Nullable);

NS_ASSUME_NONNULL_BEGIN

/**
 A `RLMSyncUser` instance represents a single Realm Object Server user account (or just user).

 A user may have one or more credentials associated with it. These credentials uniquely identify the user to a
 third-party auth provider, and are used to sign into a Realm Object Server user account.

 Note that users are only vended out via SDK APIs, and only one user instance ever exists for a given user account.
 */
@interface RLMSyncUser : NSObject

/**
 A dictionary of all valid, logged-in user identities corresponding to their `RLMSyncUser` objects.
 */
+ (NSDictionary<NSString *, RLMSyncUser *> *)allUsers NS_REFINED_FOR_SWIFT;

/**
 The logged-in user. `nil` if none exists.

 @warning Throws an exception if more than one logged-in user exists.
 */
+ (nullable RLMSyncUser *)currentUser NS_REFINED_FOR_SWIFT;

/**
 The unique Realm Object Server user ID string identifying this user.
 */
@property (nullable, nonatomic, readonly) NSString *identity;

/**
 The URL of the authentication server this user will communicate with.
 */
@property (nullable, nonatomic, readonly) NSURL *authenticationServer;

/**
 The current state of the user.
 */
@property (nonatomic, readonly) RLMSyncUserState state;

#pragma mark - Login/logout

/**
 Create, log in, and asynchronously return a new user object, specifying a custom timeout for the network request.
 Credentials identifying the user must be passed in. The user becomes available in the completion block, at which point
 it is ready for use.
 */
+ (void)logInWithCredentials:(RLMSyncCredentials *)credentials
               authServerURL:(NSURL *)authServerURL
                     timeout:(NSTimeInterval)timeout
                onCompletion:(RLMUserCompletionBlock)completion NS_REFINED_FOR_SWIFT;

/**
 Create, log in, and asynchronously return a new user object. Credentials identifying the user must be passed in. The
 user becomes available in the completion block, at which point it is ready for use.
 */
+ (void)logInWithCredentials:(RLMSyncCredentials *)credentials
               authServerURL:(NSURL *)authServerURL
                onCompletion:(RLMUserCompletionBlock)completion
NS_SWIFT_UNAVAILABLE("Use the full version of this API.");

/**
 Log a user out, destroying their server state, deregistering them from the SDK, and removing any synced Realms
 associated with them from on-disk storage. If the user is already logged out or in an error state, this is a no-op.

 This method should be called whenever the application is committed to not using a user again unless they are recreated.
 Failing to call this method may result in unused files and metadata needlessly taking up space.
 */
- (void)logOut;

#pragma mark - Sessions

/**
 Retrieve a valid session object belonging to this user for a given URL, or `nil` if no such object exists.
 */
- (nullable RLMSyncSession *)sessionForURL:(NSURL *)url;

/**
 Retrieve all the valid sessions belonging to this user.
 */
- (NSArray<RLMSyncSession *> *)allSessions;

#pragma mark - Permissions

/**
 Given a synced Realm managed by this user, set the permissions of a
 different user with respect to that Realm.

 If no URL is passed in, the permission changes will be applied to ALL
 synced Realms managed by this user.

 If no user is passed in, the permission changes will be applied with
 respect to the given synced Realm (or all synced Realms) for ALL users.

 @param realmURL        The URL of the synced Realm on the server whose
                        permissions should be modified, or nil.
 @param identity        The identity of the user whose permissions for
                        the Realm at `realmURL` should be modified, or
                        `nil`.
 @param permissions     The new permissions to be set.
 @param callback        An optional block through which the progress of
                        the permission change operation can be reported.
                        The callback will be periodically called until
                        the permissions change has been resolved by the
                        server.
 */
- (void)setPermissions:(RLMSyncRealmPermission)permissions
         forRealmAtURL:(nullable NSURL *)realmURL
               forUser:(nullable NSString *)identity
              callback:(nullable RLMSyncPermissionChangeBlock)callback
NS_REFINED_FOR_SWIFT;

/**
 Returns an instance of the Management Realm owned by the user.

 This Realm can be used to control access permissions for Realms managed by the user.
 This includes granting other users access to Realms.
 */
- (RLMRealm *)managementRealmWithError:(NSError **)error NS_REFINED_FOR_SWIFT;

#pragma mark - Miscellaneous

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncUser cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncUser cannot be created directly")));

NS_ASSUME_NONNULL_END

@end
