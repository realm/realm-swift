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

#import <Realm/RLMAppCredentials.h>
#import <Realm/RLMRealmConfiguration.h>

@class RLMSyncUser, RLMSyncUserInfo, RLMSyncCredentials, RLMSyncSession, RLMRealm;

/**
 The state of the user object.
 */
typedef NS_ENUM(NSUInteger, RLMSyncUserState) {
    /// The user is logged out. Call `logInWithCredentials:...` with valid credentials to log the user back in.
    RLMSyncUserStateLoggedOut,
    /// The user is logged in, and any Realms associated with it are syncing with the Realm Object Server.
    RLMSyncUserStateLoggedIn,
    /// The user has been removed, and cannot be used.
    RLMSyncUserStateRemoved,
};

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

/// A block type used to report the status of a password change operation.
/// If the `NSError` argument is nil, the operation succeeded.
typedef void(^RLMPasswordChangeStatusBlock)(NSError * _Nullable);

/// A block type used to asynchronously report results of a user info retrieval.
/// Exactly one of the two arguments will be populated.
typedef void(^RLMRetrieveUserBlock)(RLMSyncUserInfo * _Nullable, NSError * _Nullable);

/// A block type used to report an error related to a specific user.
typedef void(^RLMUserErrorReportingBlock)(RLMSyncUser * _Nonnull, NSError * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

/**
 A `RLMSyncUser` instance represents a single Realm App user account.

 A user may have one or more credentials associated with it. These credentials
 uniquely identify the user to the authentication provider, and are used to sign
 into a Realm Object Server user account.

 Note that user objects are only vended out via SDK APIs, and cannot be directly
 initialized. User objects can be accessed from any thread.
 */
@interface RLMSyncUser : NSObject

/**
 The unique Realm Object Server user ID string identifying this user.
 */
@property (nullable, nonatomic, readonly) NSString *identity;

/**
 The user's refresh token used to access the Realm Applcation.

 This is required to make HTTP requests to the Realm App's REST API
 for functionality not exposed natively. It should be treated as sensitive data.
 */
@property (nullable, nonatomic, readonly) NSString *refreshToken;


/**
 The user's refresh token used to access the Realm Application.

 This is required to make HTTP requests to Realm Object Server's REST API
 for functionality not exposed natively. It should be treated as sensitive data.
 */
@property (nullable, nonatomic, readonly) NSString *accessToken;

/**
 The current state of the user.
 */
@property (nonatomic, readonly) RLMSyncUserState state;

#pragma mark - Lifecycle

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
                            enableSSLValidation:(bool)enableSSLValidation
                                      urlPrefix:(nullable NSString *)urlPrefix NS_REFINED_FOR_SWIFT;

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

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncUserInfo cannot be created directly")));
/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncUserInfo cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
