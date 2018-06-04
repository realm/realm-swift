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

#import "RLMRealmConfiguration.h"
#import "RLMResults.h"
#import "RLMSyncCredentials.h"
#import "RLMSyncPermission.h"

@class RLMSyncUser, RLMSyncUserInfo, RLMSyncCredentials, RLMSyncPermission, RLMSyncSession, RLMRealm;

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

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

/// A block type used to report the status of a password change operation.
/// If the `NSError` argument is nil, the operation succeeded.
typedef void(^RLMPasswordChangeStatusBlock)(NSError * _Nullable);

/// A block type used to report the status of a permission apply or revoke operation.
/// If the `NSError` argument is nil, the operation succeeded.
typedef void(^RLMPermissionStatusBlock)(NSError * _Nullable);

/// A block type used to report the status of a permission offer operation.
typedef void(^RLMPermissionOfferStatusBlock)(NSString * _Nullable, NSError * _Nullable);

/// A block type used to report the status of a permission offer response operation.
typedef void(^RLMPermissionOfferResponseStatusBlock)(NSURL * _Nullable, NSError * _Nullable);

/// A block type used to asynchronously report results of a permissions get operation.
/// Exactly one of the two arguments will be populated.
typedef void(^RLMPermissionResultsBlock)(RLMResults<RLMSyncPermission *> * _Nullable, NSError * _Nullable);

/// A block type used to asynchronously report results of a user info retrieval.
/// Exactly one of the two arguments will be populated.
typedef void(^RLMRetrieveUserBlock)(RLMSyncUserInfo * _Nullable, NSError * _Nullable);

/// A block type used to report an error related to a specific user.
typedef void(^RLMUserErrorReportingBlock)(RLMSyncUser * _Nonnull, NSError * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

/**
 A `RLMSyncUser` instance represents a single Realm Object Server user account.

 A user may have one or more credentials associated with it. These credentials
 uniquely identify the user to the authentication provider, and are used to sign
 into a Realm Object Server user account.

 Note that user objects are only vended out via SDK APIs, and cannot be directly
 initialized. User objects can be accessed from any thread.
 */
@interface RLMSyncUser : NSObject

/**
 A dictionary of all valid, logged-in user identities corresponding to their user objects.
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
 Whether the user is a Realm Object Server administrator. Value reflects the
 state at the time of the last successful login of this user.
 */
@property (nonatomic, readonly) BOOL isAdmin;

/**
 The current state of the user.
 */
@property (nonatomic, readonly) RLMSyncUserState state;

#pragma mark - Lifecycle

/**
 Create, log in, and asynchronously return a new user object, specifying a custom
 timeout for the network request and a custom queue to run the callback upon.
 Credentials identifying the user must be passed in. The user becomes available in
 the completion block, at which point it is ready for use.
 */
+ (void)logInWithCredentials:(RLMSyncCredentials *)credentials
               authServerURL:(NSURL *)authServerURL
                     timeout:(NSTimeInterval)timeout
               callbackQueue:(dispatch_queue_t)callbackQueue
                onCompletion:(RLMUserCompletionBlock)completion NS_REFINED_FOR_SWIFT;

/**
 Create, log in, and asynchronously return a new user object.

 If the login completes successfully, the completion block will invoked with
 a `RLMSyncUser` object representing the logged-in user. This object can be
 used to open synchronized Realms. If the login fails, the completion block
 will be invoked with an error.

 The completion block always runs on the main queue.

 @param credentials     A credentials value identifying the user to be logged in.
 @param authServerURL   The URL of the authentication server (e.g. "http://realm.example.org:9080").
 @param completion      A callback block that returns a user object or an error,
                        indicating the completion of the login operation.
 */
+ (void)logInWithCredentials:(RLMSyncCredentials *)credentials
               authServerURL:(NSURL *)authServerURL
                onCompletion:(RLMUserCompletionBlock)completion
NS_SWIFT_UNAVAILABLE("Use the full version of this API.");


/**
 Returns the default configuration for the user. The default configuration
 points to the default query-based Realm on the server the user authenticated against.
 */
- (RLMRealmConfiguration *)configuration NS_REFINED_FOR_SWIFT;

/**
 Create a query-based configuration instance for the given url.

 @param url The unresolved absolute URL to the Realm on the Realm Object Server,
            e.g. "realm://example.org/~/path/to/realm". "Unresolved" means the
            path should contain the wildcard marker `~`, which will automatically
            be filled in with the user identity by the Realm Object Server.
 @return A default configuration object with the sync configuration set to use the given URL.
 */
- (RLMRealmConfiguration *)configurationWithURL:(nullable NSURL *)url NS_REFINED_FOR_SWIFT;

/**
 Create a configuration instance for the given url.

 @param url The unresolved absolute URL to the Realm on the Realm Object Server,
            e.g. "realm://example.org/~/path/to/realm". "Unresolved" means the
            path should contain the wildcard marker `~`, which will automatically
            be filled in with the user identity by the Realm Object Server.
 @param fullSynchronization If YES, all objects in the server Realm are
                            automatically synchronized, and the query subscription
                            methods cannot be used.
 @return A default configuration object with the sync configuration set to use
         the given URL and options.
 */
- (RLMRealmConfiguration *)configurationWithURL:(nullable NSURL *)url
                            fullSynchronization:(bool)fullSynchronization NS_REFINED_FOR_SWIFT;

/**
 Create a configuration instance for the given url.

 @param url The unresolved absolute URL to the Realm on the Realm Object Server,
            e.g. "realm://example.org/~/path/to/realm". "Unresolved" means the
            path should contain the wildcard marker `~`, which will automatically
            be filled in with the user identity by the Realm Object Server.
 @param fullSynchronization If YES, all objects in the server Realm are
                            automatically synchronized, and the query subscription
                            methods cannot be used.
 @param enableSSLValidation If NO, invalid SSL certificates for the server will
                            not be rejected. THIS SHOULD NEVER BE USED IN
                            PRODUCTION AND EXISTS ONLY FOR TESTING PURPOSES.
 @param urlPrefix A prefix which is prepending to URLs constructed for
                  the server. This should normally be `nil`, and customized only
                  to match corresponding settings on the server.
 @return A default configuration object with the sync configuration set to use
         the given URL and options.
 */
- (RLMRealmConfiguration *)configurationWithURL:(nullable NSURL *)url
                            fullSynchronization:(bool)fullSynchronization
                            enableSSLValidation:(bool)enableSSLValidation
                                      urlPrefix:(nullable NSString *)urlPrefix NS_REFINED_FOR_SWIFT;

/**
 Log a user out, destroying their server state, unregistering them from the SDK,
 and removing any synced Realms associated with them from on-disk storage on
 next app launch. If the user is already logged out or in an error state, this
 method does nothing.

 This method should be called whenever the application is committed to not using
 a user again unless they are recreated.
 Failing to call this method may result in unused files and metadata needlessly
 taking up space.
 */
- (void)logOut;

/**
 An optional error handler which can be set to notify the host application when
 the user encounters an error. Errors reported by this error handler are always
 `RLMSyncAuthError`s.

 @note Check for `RLMSyncAuthErrorInvalidAccessToken` to see if the user has
       been remotely logged out because its refresh token expired, or because the
       third party authentication service providing the user's identity has
       logged the user out.

 @warning Regardless of whether an error handler is installed, certain user errors
          will automatically cause the user to enter the logged out state.
 */
@property (nullable, nonatomic) RLMUserErrorReportingBlock errorHandler NS_REFINED_FOR_SWIFT;

#pragma mark - Sessions

/**
 Retrieve a valid session object belonging to this user for a given URL, or `nil`
 if no such object exists.
 */
- (nullable RLMSyncSession *)sessionForURL:(NSURL *)url;

/**
 Retrieve all the valid sessions belonging to this user.
 */
- (NSArray<RLMSyncSession *> *)allSessions;

#pragma mark - Passwords

/**
 Change this user's password asynchronously.

 @warning Changing a user's password using an authentication server that doesn't
          use HTTPS is a major security flaw, and should only be done while
          testing.

 @param newPassword The user's new password.
 @param completion  Completion block invoked when login has completed or failed.
                    The callback will be invoked on a background queue provided
                    by `NSURLSession`.
 */
- (void)changePassword:(NSString *)newPassword completion:(RLMPasswordChangeStatusBlock)completion;

/**
 Change an arbitrary user's password asynchronously.

 @note    The current user must be an admin user for this operation to succeed.

 @warning Changing a user's password using an authentication server that doesn't
          use HTTPS is a major security flaw, and should only be done while
          testing.

 @param newPassword The user's new password.
 @param userID      The identity of the user whose password should be changed.
 @param completion  Completion block invoked when login has completed or failed.
                    The callback will be invoked on a background queue provided
                    by `NSURLSession`.
 */
- (void)changePassword:(NSString *)newPassword forUserID:(NSString *)userID completion:(RLMPasswordChangeStatusBlock)completion;

/**
 Ask the server to send a password reset email to the given email address.

 If `email` is an email address which is associated with a user account that was
 registered using the "password" authentication service, the server will send an
 email to that address with a password reset token. No error is reported if the
 email address is invalid or not associated with an account.

 @param serverURL  The authentication server URL for the user.
 @param email      The email address to send the email to.
 @param completion A block which will be called when the request completes or
                   fails. The callback will be invoked on a background queue
                   provided by `NSURLSession`, and not on the calling queue.
 */
+ (void)requestPasswordResetForAuthServer:(NSURL *)serverURL
                                userEmail:(NSString *)email
                               completion:(RLMPasswordChangeStatusBlock)completion;

/**
 Change a user's password using a one-time password reset token.

 By default, the password reset email sent by ROS will link to a web site where
 the user can select a new password, and the app will not need to call this
 method. If you wish to instead handle this within your native app, you must
 change the `baseURL` in the server configuration for `PasswordAuthProvider` to
 a scheme registered for your app, extract the token from the URL, and call this
 method after prompting the user for a new password.

 @warning Changing a user's password using an authentication server that doesn't
          use HTTPS is a major security flaw, and should only be done while
          testing.

 @param serverURL   The authentication server URL for the user.
 @param token       The one-time use token from the URL.
 @param newPassword The user's new password.
 @param completion  A block which will be called when the request completes or
                    fails. The callback will be invoked on a background queue
                    provided by `NSURLSession`, and not on the calling queue.
 */
+ (void)completePasswordResetForAuthServer:(NSURL *)serverURL
                                     token:(NSString *)token
                                  password:(NSString *)newPassword
                                completion:(RLMPasswordChangeStatusBlock)completion;

/**
 Ask the server to send a confirmation email to the given email address.

 If `email` is an email address which is associated with a user account that was
 registered using the "password" authentication service, the server will send an
 email to that address with a confirmation token. No error is reported if the
 email address is invalid or not associated with an account.

 @param serverURL  The authentication server URL for the user.
 @param email      The email address to send the email to.
 @param completion A block which will be called when the request completes or
                   fails. The callback will be invoked on a background queue
                   provided by `NSURLSession`, and not on the calling queue.
 */
+ (void)requestEmailConfirmationForAuthServer:(NSURL *)serverURL
                                    userEmail:(NSString *)email
                                   completion:(RLMPasswordChangeStatusBlock)completion;

/**
 Confirm a user's email using a one-time confirmation token.

 By default, the confirmation email sent by ROS will link to a web site with
 a generic "thank you for confirming your email" message, and the app will not
 need to call this method. If you wish to instead handle this within your native
 app, you must change the `baseURL` in the server configuration for
 `PasswordAuthProvider` to a scheme registered for your app, extract the token
 from the URL, and call this method.

 @param serverURL   The authentication server URL for the user.
 @param token       The one-time use token from the URL.
 @param completion  A block which will be called when the request completes or
                    fails. The callback will be invoked on a background queue
                    provided by `NSURLSession`, and not on the calling queue.
 */
+ (void)confirmEmailForAuthServer:(NSURL *)serverURL
                            token:(NSString *)token
                       completion:(RLMPasswordChangeStatusBlock)completion;

#pragma mark - Administrator

/**
 Given a Realm Object Server authentication provider and a provider identifier for a user
 (for example, a username), look up and return user information for that user.

 @param providerUserIdentity    The username or identity of the user as issued by the authentication provider.
                                In most cases this is different from the Realm Object Server-issued identity.
 @param provider                The authentication provider that manages the user whose information is desired.
 @param completion              Completion block invoked when request has completed or failed.
                                The callback will be invoked on a background queue provided
                                by `NSURLSession`.
 */
- (void)retrieveInfoForUser:(NSString *)providerUserIdentity
           identityProvider:(RLMIdentityProvider)provider
                 completion:(RLMRetrieveUserBlock)completion;

#pragma mark - Permissions

/**
 Asynchronously retrieve all permissions associated with the user calling this method.

 The results will be returned through the callback block, or an error if the operation failed.
 The callback block will be run on the same thread the method was called on.

 @warning This method must be called from a thread with a currently active run loop. Unless
          you have manually configured a run loop on a side thread, this will usually be the
          main thread.
 */
- (void)retrievePermissionsWithCallback:(RLMPermissionResultsBlock)callback NS_REFINED_FOR_SWIFT;

/**
 Apply a given permission.

 The operation will take place asynchronously, and the callback will be used to report whether
 the permission change succeeded or failed. The user calling this method must have the right
 to grant the given permission, or else the operation will fail.

 @see `RLMSyncPermission`
 */
- (void)applyPermission:(RLMSyncPermission *)permission callback:(RLMPermissionStatusBlock)callback;

/**
 Revoke a given permission.

 The operation will take place asynchronously, and the callback will be used to report whether
 the permission change succeeded or failed. The user calling this method must have the right
 to grant the given permission, or else the operation will fail.

 @see `RLMSyncPermission`
 */
- (void)revokePermission:(RLMSyncPermission *)permission callback:(RLMPermissionStatusBlock)callback;

/**
 Create a permission offer for a Realm.

 A permission offer is used to grant access to a Realm this user manages to another
 user. Creating a permission offer produces a string token which can be passed to the
 recepient in any suitable way (for example, via e-mail).

 The operation will take place asynchronously. The token can be accepted by the recepient
 using the `-[RLMSyncUser acceptOfferForToken:callback:]` method.

 @param url             The URL of the Realm for which the permission offer should pertain. This
                        may be the URL of any Realm which this user is allowed to manage. If the URL
                        has a `~` wildcard it will be replaced with this user's user identity.
 @param accessLevel     What access level to grant to whoever accepts the token.
 @param expirationDate  Optionally, a date which indicates when the offer expires. If the
                        recepient attempts to accept the offer after the date it will be rejected.
 @param callback        A callback indicating whether the operation succeeded or failed. If it
                        succeeded the token will be passed in as a string.

 @see `acceptOfferForToken:callback:`
 */
- (void)createOfferForRealmAtURL:(NSURL *)url
                     accessLevel:(RLMSyncAccessLevel)accessLevel
                      expiration:(nullable NSDate *)expirationDate
                        callback:(RLMPermissionOfferStatusBlock)callback NS_REFINED_FOR_SWIFT;

/**
 Accept a permission offer.

 Pass in a token representing a permission offer. The operation will take place asynchronously.
 If the operation succeeds, the callback will be passed the URL of the Realm for which the
 offer applied, so the Realm can be opened.

 The token this method accepts can be created by the offering user through the
 `-[RLMSyncUser createOfferForRealmAtURL:accessLevel:expiration:callback:]` method.

 @see `createOfferForRealmAtURL:accessLevel:expiration:callback:`
 */
- (void)acceptOfferForToken:(NSString *)token
                   callback:(RLMPermissionOfferResponseStatusBlock)callback;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncUser cannot be created directly")));
/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncUser cannot be created directly")));

@end

#pragma mark - User info classes

/**
 A data object representing a user account associated with a user.

 @see `RLMSyncUserInfo`
 */
@interface RLMSyncUserAccountInfo : NSObject

/// The authentication provider which manages this user account.
@property (nonatomic, readonly) RLMIdentityProvider provider;

/// The username or identity of this user account.
@property (nonatomic, readonly) NSString *providerUserIdentity;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncUserAccountInfo cannot be created directly")));
/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncUserAccountInfo cannot be created directly")));

@end

/**
 A data object representing information about a user that was retrieved from a user lookup call.
 */
@interface RLMSyncUserInfo : NSObject

/**
 An array of all the user accounts associated with this user.
 */
@property (nonatomic, readonly) NSArray<RLMSyncUserAccountInfo *> *accounts;

/**
 The identity issued to this user by the Realm Object Server.
 */
@property (nonatomic, readonly) NSString *identity;

/**
 Metadata about this user stored on the Realm Object Server.
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *metadata;

/**
 Whether the user is flagged on the Realm Object Server as an administrator.
 */
@property (nonatomic, readonly) BOOL isAdmin;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncUserInfo cannot be created directly")));
/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncUserInfo cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
