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

@protocol RLMNetworkTransport, RLMBSON;

@class RLMSyncUser, RLMAppCredentials, RLMUsernamePasswordProviderClient, RLMUserAPIKeyProviderClient, RLMSyncManager;

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

/// A block type for returning from function calls.
typedef void(^RLMCallFunctionCompletionBlock)(id<RLMBSON> _Nullable, NSError * _Nullable);

#pragma mark RLMAppConfiguration

/// Properties representing the configuration of a client
/// that communicate with a particular Realm application.
@interface RLMAppConfiguration : NSObject

/// A custom base URL to request against.
@property (nonatomic, strong, nullable) NSString* baseURL;

/// A transport for customizing network handling.
@property (nonatomic, strong, nullable) id <RLMNetworkTransport> transport;

/// A custom app name.
@property (nonatomic, strong, nullable) NSString *localAppName;

/// A custom app version.
@property (nonatomic, strong, nullable) NSString *localAppVersion;

/// The default timeout for network requests.
@property (nonatomic, assign) NSUInteger defaultRequestTimeoutMS;

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *) localAppName
                localAppVersion:(nullable NSString *)localAppVersion;

- (instancetype)initWithBaseURL:(nullable NSString *) baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *) localAppName
                localAppVersion:(nullable NSString *)localAppVersion
        defaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS;

@end

#pragma mark RLMApp

/**
 The `RLMApp` has the fundamental set of methods for communicating with a Realm
 application backend.

 This interface provides access to login and authentication.
 */
@interface RLMApp : NSObject

@property (readonly) RLMAppConfiguration *configuration;

/**
 Get an application with a given appId and configuration.

 @param appId The unique identifier of your Realm app.
 @param configuration A configuration object to configure this client.
 */
+ (instancetype)app:(NSString *)appId
      configuration:(nullable RLMAppConfiguration *)configuration;

- (RLMSyncManager *)sharedManager;

- (NSDictionary<NSString *, RLMSyncUser *> *)allUsers;

- (nullable RLMSyncUser *)currentUser;

/**
 Login to a user for the Realm app.

 @param credentials The credentials identifying the user.
 @param completion A callback invoked after completion.
 */
- (void)loginWithCredential:(RLMAppCredentials *)credentials
                 completion:(RLMUserCompletionBlock)completion;

/**
 Switches the active user to the specified user.

 This sets which user is used by all RLMApp operations which require a user. This is a local operation which does not access the network.
 An exception will be throw if the user is not valid. The current user will remain logged in.
 
 @param syncUser The user to switch to.
 @returns The user you intend to switch to
 */
- (RLMSyncUser *)switchToUser:(RLMSyncUser *)syncUser;

/**
 Removes a specified user
 
 This logs out and destroys the session related to the user. The completion block will return an error
 if the user is not found or is already removed.

 @param syncUser The user you would like to remove
 @param completion A callback invoked on completion
*/
- (void)removeUser:(RLMSyncUser *)syncUser
        completion:(RLMOptionalErrorBlock)completion;

/**
 Logs out the current user
 
 The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
 If the logout request fails, this method will still clear local authentication state.
 
 @param completion A callback invoked on completion
*/
- (void)logOutWithCompletion:(RLMOptionalErrorBlock)completion;

/**
 Logs out a specific user
 
 The users state will be set to `Removed` is they are an anonymous user or `LoggedOut` if they are authenticated by a username / password or third party auth clients
 If the logout request fails, this method will still clear local authentication state.
 
 @param syncUser The user to log out
 @param completion A callback invoked on completion
*/
- (void)logOut:(RLMSyncUser *)syncUser
    completion:(RLMOptionalErrorBlock)completion;

/**
 Links the currently authenticated user with a new identity, where the identity is defined by the credential
 specified as a parameter. This will only be successful if this `RLMSyncUser` is the currently authenticated
 with the client from which it was created. On success a new user will be returned with the new linked credentials.
 
 @param syncUser The user which will have the credentials linked to, the user must be logged in
 @param credentials The `RLMAppCredentials` used to link the user to a new identity.
 @param completion The completion handler to call when the linking is complete.
                   If the operation is  successful, the result will contain a new
                   `RLMSyncUser` object representing the currently logged in user.
*/
- (void)linkUser:(RLMSyncUser *)syncUser
     credentials:(RLMAppCredentials *)credentials
      completion:(RLMUserCompletionBlock)completion;

/**
  A client for the username/password authentication provider which
  can be used to obtain a credential for logging in.
 
  Used to perform requests specifically related to the username/password provider.
*/
- (RLMUsernamePasswordProviderClient *)usernamePasswordProviderClient;

/**
  A client for the user API key authentication provider which
  can be used to create and modify user API keys.
 
  This client should only be used by an authenticated user.
*/
- (RLMUserAPIKeyProviderClient *)userAPIKeyProviderClient;

- (void)callFunction:(NSString *)name
           arguments:(NSArray<id<RLMBSON>> *)arguments
     completionBlock:(RLMCallFunctionCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
