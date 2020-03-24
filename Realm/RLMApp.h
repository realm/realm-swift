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
#import "RLMUsernamePasswordProviderClient.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RLMNetworkTransport;

@class RLMSyncUser, RLMAppCredentials;

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

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

/**
 Get an application with a given appId and configuration.

 @param appId The unique identifier of your Realm app.
 @param configuration A configuration object to configure this client.
 */
+ (instancetype)app:(NSString *) appId
      configuration:(nullable RLMAppConfiguration *)configuration;

- (NSDictionary<NSString *, RLMSyncUser *> *)allUsers;

- (nullable RLMSyncUser *)currentUser;

/**
 Login to a user for the Realm app.

 @param credentials The credentials identifying the user.
 @param completionHandler A callback invoked after completion.
 */
- (void)loginWithCredential:(RLMAppCredentials *)credentials
          completionHandler:(RLMUserCompletionBlock)completionHandler;


/**
 Switch to a specified user. If the user is no longer valid e.g Removed then an error will be thrown
 This call does not invoke any network calls
 @param syncUser The user you would like to switch to
 @returns The user you intend to switch to
 */
- (RLMSyncUser *)switchUser:(RLMSyncUser *)syncUser;

/**
 Removes a specified user

 @param syncUser The user you would like to remove
 @param completionHandler A callback invoked on completion
*/
- (void)removeUser:(RLMSyncUser *)syncUser completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
 Logs out the current user
 @param completionHandler A callback invoked on completion
*/
- (void)log_out:(RLMOptionalErrorBlock)completionHandler;

/**
 Logs out a specific user
 @param syncUser The user to log out
 @param completionHandler A callback invoked on completion
*/
- (void)log_out:(RLMSyncUser *)syncUser completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
  A client for the username/password authentication provider which
  can be used to obtain a credential for logging in,
  and to perform requests specifically related to the username/password provider.
*/
- (RLMUsernamePasswordProviderClient *)usernamePasswordProviderClient;

@end

NS_ASSUME_NONNULL_END
