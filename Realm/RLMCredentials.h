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

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)
@protocol RLMBSON;

/// A token representing an identity provider's credentials.
typedef NSString *RLMCredentialsToken;

/// A type representing the unique identifier of an Atlas App Services identity provider.
typedef NSString *RLMIdentityProvider NS_EXTENSIBLE_STRING_ENUM;

/// The username/password identity provider. User accounts are handled by Atlas App Services directly without the
/// involvement of a third-party identity provider.
extern RLMIdentityProvider const RLMIdentityProviderUsernamePassword;

/// A Facebook account as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderFacebook;

/// A Google account as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderGoogle;

/// An Apple account as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderApple;

/// A JSON Web Token as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderJWT;

/// An Anonymous account as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderAnonymous;

/// An Realm Cloud function as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderFunction;

/// A user api key as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderUserAPIKey;

/// A server api key as an identity provider.
extern RLMIdentityProvider const RLMIdentityProviderServerAPIKey;

/**
 Opaque credentials representing a specific Realm App user.
 */
RLM_SWIFT_SENDABLE RLM_FINAL // immutable final class
@interface RLMCredentials : NSObject

/// The name of the identity provider which generated the credentials token.
@property (nonatomic, readonly) RLMIdentityProvider provider;

/**
 Construct and return credentials from a Facebook account token.
 */
+ (instancetype)credentialsWithFacebookToken:(RLMCredentialsToken)token;

/**
 Construct and return credentials from a Google account token.
 */
+ (instancetype)credentialsWithGoogleAuthCode:(RLMCredentialsToken)token;

/**
 Construct and return credentials from a Google id token.
 */
+ (instancetype)credentialsWithGoogleIdToken:(RLMCredentialsToken)token;

/**
 Construct and return credentials from an Apple account token.
 */
+ (instancetype)credentialsWithAppleToken:(RLMCredentialsToken)token;

/**
 Construct and return credentials for an Atlas App Services function using a mongodb document as a json payload.
*/
+ (instancetype)credentialsWithFunctionPayload:(NSDictionary<NSString *, id<RLMBSON>> *)payload;

/**
 Construct and return credentials from a user api key.
*/
+ (instancetype)credentialsWithUserAPIKey:(NSString *)apiKey;

/**
 Construct and return credentials from a server api key.
*/
+ (instancetype)credentialsWithServerAPIKey:(NSString *)apiKey;

/**
 Construct and return Atlas App Services credentials from an email and password.
 */
+ (instancetype)credentialsWithEmail:(NSString *)email
                            password:(NSString *)password;

/**
 Construct and return credentials from a JSON Web Token.
 */
+ (instancetype)credentialsWithJWT:(NSString *)token;

/**
 Construct and return anonymous credentials
 */
+ (instancetype)anonymousCredentials;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMAppCredentials cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMAppCredentials cannot be created directly")));

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
