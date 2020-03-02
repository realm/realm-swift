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

#import "RLMNetworkTransporting.h"

#ifndef RLMApp_h
#define RLMApp_h

@class RLMSyncUser, RLMAppCredentials;

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

#pragma mark RLMAppConfiguration

/// Properties representing the configuration of a client
/// that communicate with a particular Realm application.
@interface RLMAppConfiguration : NSObject

/// A custom base URL to request against.
@property (nonatomic, strong) NSString* _Nullable baseURL;

/// A transport for customizing network handling.
@property (nonatomic, strong) id <RLMNetworkTransporting> _Nullable transport;

/// A custom app name.
@property (nonatomic, strong) NSString* _Nullable localAppName;

/// A custom app version.
@property (nonatomic, strong) NSString* _Nullable localAppVersion;

/// The default timeout for network requests.
@property (nonatomic, assign) NSUInteger defaultRequestTimeoutMS;

-(instancetype _Nonnull) initWithBaseURL:(NSString* _Nullable) baseURL
                               transport:(id<RLMNetworkTransporting> _Nullable)transport
                            localAppName:(NSString* _Nullable) localAppName
                         localAppVersion:(NSString* _Nullable)localAppVersion;

-(instancetype _Nonnull) initWithBaseURL:(NSString* _Nullable) baseURL
                               transport:(id<RLMNetworkTransporting> _Nullable)transport
                            localAppName:(NSString* _Nullable) localAppName
                         localAppVersion:(NSString* _Nullable)localAppVersion
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
+(_Nonnull instancetype) app:(NSString * _Nonnull) appId
               configuration:(RLMAppConfiguration * _Nullable)configuration;

- (NSDictionary * _Nonnull)allUsers;

- (RLMSyncUser * _Nullable)currentUser;

/**
 Login to a user for the Realm app.

 @param credentials The credentials identifying the user.
 @param completionHandler A callback invoked after completion.
 */
-(void) loginWithCredential:(RLMAppCredentials * _Nonnull)credentials
          completionHandler:(RLMUserCompletionBlock _Nonnull)completionHandler;

@end

#endif /* RLMApp_h */
