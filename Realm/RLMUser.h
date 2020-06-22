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

#import <Realm/RLMCredentials.h>
#import <Realm/RLMRealmConfiguration.h>

@class RLMUser, RLMUserInfo, RLMSyncSession, RLMRealm, RLMUserIdentity, RLMAPIKeyAuth, RLMMongoClient, RLMMongoDatabase, RLMMongoCollection;
@protocol RLMBSON;

/**
 The state of the user object.
 */
typedef NS_ENUM(NSUInteger, RLMUserState) {
    /// The user is logged out. Call `logInWithCredentials:...` with valid credentials to log the user back in.
    RLMUserStateLoggedOut,
    /// The user is logged in, and any Realms associated with it are syncing with MongoDB Realm.
    RLMUserStateLoggedIn,
    /// The user has been removed, and cannot be used.
    RLMUserStateRemoved,
};

/// A block type used to report an error related to a specific user.
typedef void(^RLMUserErrorReportingBlock)(RLMUser * _Nonnull, NSError * _Nonnull);

/// A block type used to report an error related to a specific user.
typedef void(^RLMOptionalUserBlock)(RLMUser * _Nullable, NSError * _Nullable);

/// A block type used to report an error on a network request from the user.
typedef void(^RLMUserOptionalErrorBlock)(NSError * _Nullable);

/// A block which returns a dictionary should there be any custom data set for a user
typedef void(^RLMUserCustomDataBlock)(NSDictionary * _Nullable, NSError * _Nullable);

/// A block type for returning from function calls.
typedef void(^RLMCallFunctionCompletionBlock)(id<RLMBSON> _Nullable, NSError * _Nullable);

NS_ASSUME_NONNULL_BEGIN

/**
 A `RLMUser` instance represents a single Realm App user account.

 A user may have one or more credentials associated with it. These credentials
 uniquely identify the user to the authentication provider, and are used to sign
 into a MongoDB Realm user account.

 Note that user objects are only vended out via SDK APIs, and cannot be directly
 initialized. User objects can be accessed from any thread.
 */
@interface RLMUser : NSObject

/**
 The unique MongoDB Realm user ID string identifying this user.
 */
@property (nullable, nonatomic, readonly) NSString *identity;

/**
    Returns an array of identities currently linked to a user.
*/
- (NSArray<RLMUserIdentity *> *)identities;

/**
 The user's refresh token used to access the Realm Applcation.

 This is required to make HTTP requests to the Realm App's REST API
 for functionality not exposed natively. It should be treated as sensitive data.
 */
@property (nullable, nonatomic, readonly) NSString *refreshToken;


/**
 The user's refresh token used to access the Realm Application.

 This is required to make HTTP requests to MongoDB Realm's REST API
 for functionality not exposed natively. It should be treated as sensitive data.
 */
@property (nullable, nonatomic, readonly) NSString *accessToken;

/**
 The current state of the user.
 */
@property (nonatomic, readonly) RLMUserState state;

#pragma mark - Lifecycle

/**
 Create a query-based configuration instance for the given url.

 @param partitionValue FIXME
 @return A default configuration object with the sync configuration set to use the given partition value.
 */
- (RLMRealmConfiguration *)configurationWithPartitionValue:(id<RLMBSON>)partitionValue NS_REFINED_FOR_SWIFT;

#pragma mark - Sessions

/**
 Retrieve a valid session object belonging to this user for a given URL, or `nil`
 if no such object exists.
 */
- (nullable RLMSyncSession *)sessionForPartitionValue:(id<RLMBSON>)partitionValue;

/**
 Retrieve all the valid sessions belonging to this user.
 */
- (NSArray<RLMSyncSession *> *)allSessions;

#pragma mark - Custom Data

/**
 The custom data of the user.
 This is configured in your MongoDB Realm App.
 */
@property (nullable, nonatomic, readonly) NSDictionary *customData NS_REFINED_FOR_SWIFT;

/**
 Refresh a user's custom data. This will, in effect, refresh the user's auth session.
 */
- (void)refreshCustomDataWithCompletion:(RLMUserCustomDataBlock)completion;

/**
 Links the currently authenticated user with a new identity, where the identity is defined by the credential
 specified as a parameter. This will only be successful if this `RLMUser` is the currently authenticated
 with the client from which it was created. On success a new user will be returned with the new linked credentials.

 @param credentials The `RLMCredentials` used to link the user to a new identity.
 @param completion The completion handler to call when the linking is complete.
                   If the operation is  successful, the result will contain a new
                   `RLMUser` object representing the currently logged in user.
*/
- (void)linkUserWithCredentials:(RLMCredentials *)credentials
                     completion:(RLMOptionalUserBlock)completion;

/**
 Removes the user

 This logs out and destroys the session related to this user. The completion block will return an error
 if the user is not found or is already removed.

 @param completion A callback invoked on completion
*/
- (void)removeWithCompletion:(RLMUserOptionalErrorBlock)completion;

/**
 Logs out the current user

 The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
 If the logout request fails, this method will still clear local authentication state.

 @param completion A callback invoked on completion
*/
- (void)logOutWithCompletion:(RLMUserOptionalErrorBlock)completion;

/**
  A client for the user API key authentication provider which
  can be used to create and modify user API keys.

  This client should only be used by an authenticated user.
*/
- (RLMAPIKeyAuth *)apiKeyAuth;

/// A client for interacting with a remote MongoDB instance
/// @param serviceName The name of the MongoDB service
- (RLMMongoClient *)mongoClientWithServiceName:(NSString *)serviceName NS_REFINED_FOR_SWIFT;

/**
 Calls the MongoDB Realm function with the provided name and arguments.

 @param name The name of the MongoDB Realm function to be called.
 @param arguments The `BSONArray` of arguments to be provided to the function.
 @param completion The completion handler to call when the function call is complete.
 This handler is executed on a non-main global `DispatchQueue`.
*/
- (void)callFunctionNamed:(NSString *)name
                arguments:(NSArray<id<RLMBSON>> *)arguments
          completionBlock:(RLMCallFunctionCompletionBlock)completion NS_REFINED_FOR_SWIFT;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMUser cannot be created directly")));
/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMUser cannot be created directly")));

@end

#pragma mark - User info classes

/**
 A data object representing a user account associated with a user.

 @see `RLMUserInfo`
 */
@interface RLMUserAccountInfo : NSObject

/// The authentication provider which manages this user account.
@property (nonatomic, readonly) RLMIdentityProvider provider;

/// The username or identity of this user account.
@property (nonatomic, readonly) NSString *providerUserIdentity;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMUserAccountInfo cannot be created directly")));
/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMUserAccountInfo cannot be created directly")));

@end

/**
 A data object representing information about a user that was retrieved from a user lookup call.
 */
@interface RLMUserInfo : NSObject

/**
 An array of all the user accounts associated with this user.
 */
@property (nonatomic, readonly) NSArray<RLMUserAccountInfo *> *accounts;

/**
 The identity issued to this user by MongoDB Realm.
 */
@property (nonatomic, readonly) NSString *identity;

/**
 Metadata about this user stored on MongoDB Realm.
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *metadata;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMUserInfo cannot be created directly")));
/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMUserInfo cannot be created directly")));

@end

/// An identity of a user. A user can have multiple identities, usually associated with multiple providers.
@interface RLMUserIdentity : NSObject

/**
 The associated provider type of the identity
 */
@property (nonatomic, readonly) NSString *providerType;

/**
 The id of the identity
 */
@property (nonatomic, readonly) NSString *identity;

/**
 Initialize a sync user for the given identity and provider type.
 @param providerType the provider type of the user
 @param identity the identity of the user
 */
- (instancetype)initUserIdentityWithProviderType:(NSString *)providerType
                                        identity:(NSString *)identity;

@end

NS_ASSUME_NONNULL_END
