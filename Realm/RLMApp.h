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

#import <Realm/RLMConstants.h>
#import <AuthenticationServices/AuthenticationServices.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@protocol RLMNetworkTransport, RLMBSON;

@class RLMUser, RLMCredentials, RLMSyncManager, RLMEmailPasswordAuth, RLMPushClient, RLMSyncTimeoutOptions;

/// A block type used for APIs which asynchronously vend an `RLMUser`.
typedef void(^RLMUserCompletionBlock)(RLMUser * _Nullable, NSError * _Nullable);

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

#pragma mark RLMAppConfiguration

/// Properties representing the configuration of a client
/// that communicate with a particular Realm application.
///
/// `RLMAppConfiguration` options cannot be modified once the `RLMApp` using it
/// is created. App's configuration values are cached when the App is created so any modifications after it
/// will not have any effect.
@interface RLMAppConfiguration : NSObject <NSCopying>

/// A custom base URL to request against.
@property (nonatomic, strong, nullable) NSString *baseURL;

/// The custom transport for network calls to the server.
@property (nonatomic, strong, nullable) id<RLMNetworkTransport> transport;

/// :nodoc:
@property (nonatomic, strong, nullable) NSString *localAppName
    __attribute__((deprecated("This field is not used")));
/// :nodoc:
@property (nonatomic, strong, nullable) NSString *localAppVersion
    __attribute__((deprecated("This field is not used")));

/// The default timeout for network requests.
@property (nonatomic, assign) NSUInteger defaultRequestTimeoutMS;

/// If enabled (the default), a single connection is used for all Realms opened
/// with a single sync user. If disabled, a separate connection is used for each
/// Realm.
///
/// Session multiplexing reduces resources used and typically improves
/// performance. When multiplexing is enabled, the connection is not immediately
/// closed when the last session is closed, and instead remains open for
/// ``RLMSyncTimeoutOptions.connectionLingerTime`` milliseconds (30 seconds by
/// default).
@property (nonatomic, assign) BOOL enableSessionMultiplexing;

/**
 Options for the assorted types of connection timeouts for sync connections.

 If nil default values for all timeouts are used instead.
 */
@property (nonatomic, nullable, copy) RLMSyncTimeoutOptions *syncTimeouts;

/// :nodoc:
- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *)localAppName
                localAppVersion:(nullable NSString *)localAppVersion
__attribute__((deprecated("localAppName and localAppVersion are unused")));

/// :nodoc:
- (instancetype)initWithBaseURL:(nullable NSString *) baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *)localAppName
                localAppVersion:(nullable NSString *)localAppVersion
        defaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS
__attribute__((deprecated("localAppName and localAppVersion are unused")));

/**
Create a new Realm App configuration.

@param baseURL A custom base URL to request against.
@param transport A custom network transport.
*/
- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport;

/**
 Create a new Realm App configuration.

 @param baseURL A custom base URL to request against.
 @param transport A custom network transport.
 @param defaultRequestTimeoutMS A custom default timeout for network requests.
 */
- (instancetype)initWithBaseURL:(nullable NSString *) baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
        defaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS;

@end

#pragma mark RLMApp

/**
 The `RLMApp` has the fundamental set of methods for communicating with a Realm
 application backend.

 This interface provides access to login and authentication.
 */
RLM_SWIFT_SENDABLE RLM_FINAL // internally thread-safe
@interface RLMApp : NSObject

/// The configuration for this Realm app.
@property (nonatomic, readonly) RLMAppConfiguration *configuration;

/// The `RLMSyncManager` for this Realm app.
@property (nonatomic, readonly) RLMSyncManager *syncManager;

/// Get a dictionary containing all users keyed on id.
@property (nonatomic, readonly) NSDictionary<NSString *, RLMUser *> *allUsers;

/// Get the current user logged into the Realm app.
@property (nonatomic, readonly, nullable) RLMUser *currentUser;

/// The app ID for this Realm app.
@property (nonatomic, readonly) NSString *appId;

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

#pragma mark - Sign In With Apple Extension

API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0))
/// Use this delegate to be provided a callback once authentication has succeed or failed
@protocol RLMASLoginDelegate

/// Callback that is invoked should the authentication fail.
/// @param error An error describing the authentication failure.
- (void)authenticationDidFailWithError:(NSError *)error NS_SWIFT_NAME(authenticationDidComplete(error:));

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

RLM_HEADER_AUDIT_END(nullability, sendability)
