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
#import <AuthenticationServices/AuthenticationServices.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RLMNetworkTransport, RLMBSON;

@class RLMUser, RLMCredentials, RLMSyncManager, RLMEmailPasswordAuth, RLMPushClient;

/// A block type used for APIs which asynchronously vend an `RLMUser`.
typedef void(^RLMUserCompletionBlock)(RLMUser * _Nullable, NSError * _Nullable);

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

#pragma mark RLMAppConfiguration

/// Properties representing the configuration of a client
/// that communicate with a particular Realm application.
@interface RLMAppConfiguration : NSObject

/// A custom base URL to request against.
@property (nonatomic, strong, nullable) NSString* baseURL;

/// The custom transport for network calls to the server.
@property (nonatomic, strong, nullable) id<RLMNetworkTransport> transport;

/// A custom app name.
@property (nonatomic, strong, nullable) NSString *localAppName;

/// A custom app version.
@property (nonatomic, strong, nullable) NSString *localAppVersion;

/// The default timeout for network requests.
@property (nonatomic, assign) NSUInteger defaultRequestTimeoutMS;

/**
Create a new Realm App configuration.

@param baseURL A custom base URL to request against.
@param transport A custom network transport.
@param localAppName A custom app name.
@param localAppVersion A custom app version.
*/
- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *)localAppName
                localAppVersion:(nullable NSString *)localAppVersion;

/**
 Create a new Realm App configuration.

 @param baseURL A custom base URL to request against.
 @param transport A custom network transport.
 @param localAppName A custom app name.
 @param localAppVersion A custom app version.
 @param defaultRequestTimeoutMS A custom default timeout for network requests.
 */
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

/// The configuration for this Realm app.
@property (nonatomic, readonly) RLMAppConfiguration *configuration;

/// The `RLMSyncManager` for this Realm app.
@property (nonatomic, readonly) RLMSyncManager *syncManager;

/// Get a dictionary containing all users keyed on id.
@property (nonatomic, readonly) NSDictionary<NSString *, RLMUser *> *allUsers;

/// Get the current user logged into the Realm app.
@property (nonatomic, readonly, nullable) RLMUser *currentUser;

/**
  A client for the email/password authentication provider which
  can be used to obtain a credential for logging in.

  Used to perform requests specifically related to the email/password provider.
*/
@property (nonatomic, readonly) RLMEmailPasswordAuth *emailPasswordAuth;

/**
 Get an application with a given appId and configuration.

 @param appId The unique identifier of your Realm app.
 */
+ (instancetype)appWithId:(NSString *)appId;

/**
 Get an application with a given appId and configuration.

 @param appId The unique identifier of your Realm app.
 @param configuration A configuration object to configure this client.
 */
+ (instancetype)appWithId:(NSString *)appId
            configuration:(nullable RLMAppConfiguration *)configuration;

/**
 Login to a user for the Realm app.

 @param credentials The credentials identifying the user.
 @param completion A callback invoked after completion.
 */
- (void)loginWithCredential:(RLMCredentials *)credentials
                 completion:(RLMUserCompletionBlock)completion NS_REFINED_FOR_SWIFT;

/**
 Switches the active user to the specified user.

 This sets which user is used by all RLMApp operations which require a user. This is a local operation which does not access the network.
 An exception will be throw if the user is not valid. The current user will remain logged in.
 
 @param syncUser The user to switch to.
 @returns The user you intend to switch to
 */
- (RLMUser *)switchToUser:(RLMUser *)syncUser;

/**
 A client which can be used to register devices with the server to receive push notificatons
 */
- (RLMPushClient *)pushClientWithServiceName:(NSString *)serviceName
    NS_SWIFT_NAME(pushClient(serviceName:));

/**
 RLMApp instances are cached internally by Realm and cannot be created directly.

 Use `+[RLMRealm appWithId]` or `+[RLMRealm appWithId:configuration:]`
 to obtain a reference to an RLMApp.
 */
- (instancetype)init __attribute__((unavailable("Use +appWithId or appWithId:configuration:.")));

/**
RLMApp instances are cached internally by Realm and cannot be created directly.

Use `+[RLMRealm appWithId]` or `+[RLMRealm appWithId:configuration:]`
to obtain a reference to an RLMApp.
*/
+ (instancetype)new __attribute__((unavailable("Use +appWithId or appWithId:configuration:.")));

@end

NS_ASSUME_NONNULL_END

#pragma mark - Sign In With Apple Extension

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0))
/// Use this delegate to be provided a callback once authentication has succeed or failed
@protocol RLMASLoginDelegate

/// Callback that is invoked should the authentication fail.
/// @param error An error describing the authentication failure.
- (void)authenticationDidCompleteWithError:(NSError *)error NS_SWIFT_NAME(authenticationDidComplete(error:));

/// Callback that is invoked should the authentication succeed.
/// @param user The newly authenticated user.
- (void)authenticationDidCompleteWithUser:(RLMUser *)user NS_SWIFT_NAME(authenticationDidComplete(user:));

@end

API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0))
/// Category extension that deals with Sign In With Apple authentication.
/// This is only available on OS's that support `AuthenticationServices`
@interface RLMApp (ASLogin)

/// Use this delegate to be provided a callback once authentication has succeed or failed.
@property (nonatomic, weak, nullable) id<RLMASLoginDelegate> authorizationDelegate;

/// Sets the ASAuthorizationControllerDelegate to be handled by `RLMApp`
/// @param controller The ASAuthorizationController in which you want `RLMApp` to consume its delegate.
- (void)setASAuthorizationControllerDelegateForController:(ASAuthorizationController *)controller NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
