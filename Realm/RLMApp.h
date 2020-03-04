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

#import "RLMNetworkTransport.h"

NS_ASSUME_NONNULL_BEGIN

@class RLMSyncUser, RLMAppCredentials;

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

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

@end

NS_ASSUME_NONNULL_END
