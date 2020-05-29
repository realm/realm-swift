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

#import <Realm/RLMSyncUtil.h>

NS_ASSUME_NONNULL_BEGIN

/// A token representing an identity provider's credentials.
typedef NSString *RLMAppCredentialsToken;

/// A type representing the unique identifier of a MongoDB Realm identity provider.
typedef NSString *RLMIdentityProvider NS_EXTENSIBLE_STRING_ENUM;

/// The username/password identity provider. User accounts are handled by MongoDB Realm directly without the
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
@interface RLMAppCredentials : NSObject

/// The name of the identity provider which generated the credentials token.
@property (nonatomic) RLMIdentityProvider provider;

/**
 Construct and return credentials from a Facebook account token.
 */
+ (instancetype)credentialsWithFacebookToken:(RLMAppCredentialsToken)token;

/**
 Construct and return credentials from a Google account token.
 */
+ (instancetype)credentialsWithGoogleToken:(RLMAppCredentialsToken)token;

/**
 Construct and return credentials from an Apple account token.
 */
+ (instancetype)credentialsWithAppleToken:(RLMAppCredentialsToken)token;

/**
 Construct and return credentials for a MongoDB Realm function using a mongodb document as a json payload.
 If the json can not be successfully serialised and error will be produced and the object will be nil.
*/
+ (instancetype)credentialsWithFunctionPayload:(NSDictionary *)payload
                                         error:(NSError **)error;

/**
 Construct and return credentials from a user api key.
*/
+ (instancetype)credentialsWithUserAPIKey:(NSString *)apiKey;

/**
 Construct and return credentials from a server api key.
*/
+ (instancetype)credentialsWithServerAPIKey:(NSString *)apiKey;

/**
 Construct and return credentials from a MongoDB Realm username and password.
 */
+ (instancetype)credentialsWithUsername:(NSString *)username
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

NS_ASSUME_NONNULL_END

@end
