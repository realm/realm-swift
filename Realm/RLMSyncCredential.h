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

#import "RLMSyncUtil.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *RLMIdentityProvider RLM_EXTENSIBLE_STRING_ENUM;

extern RLMIdentityProvider const RLMIdentityProviderDebug;
extern RLMIdentityProvider const RLMIdentityProviderRealm;
extern RLMIdentityProvider const RLMIdentityProviderUsernamePassword;
extern RLMIdentityProvider const RLMIdentityProviderFacebook;
extern RLMIdentityProvider const RLMIdentityProviderTwitter;
extern RLMIdentityProvider const RLMIdentityProviderGoogle;
extern RLMIdentityProvider const RLMIdentityProviderICloud;
// FIXME: add more providers as necessary...

@interface RLMSyncCredential : NSObject

@property (nonatomic, readonly) RLMCredentialToken token;
@property (nonatomic, readonly) RLMIdentityProvider provider;
@property (nonatomic, readonly) NSDictionary<NSString *, id> *userInfo;

/**
 Construct and return a credential from a Facebook account token.
 */
+ (instancetype)credentialWithFacebookToken:(RLMCredentialToken)token;

/**
 Construct and return a credential from a Realm Object Server username and password.
 */
+ (instancetype)credentialWithUsername:(NSString *)username password:(NSString *)password;

/**
 Construct and return a special credential representing a token that can be directly used to open a Realm. The identity
 is used to uniquely identify the user across application launches.
 */
+ (instancetype)credentialWithAccessToken:(RLMServerToken)accessToken identity:(NSString *)identity;

- (instancetype)initWithCustomToken:(RLMCredentialToken)token
                           provider:(RLMIdentityProvider)provider
                           userInfo:(nullable NSDictionary *)userInfo NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

NS_ASSUME_NONNULL_END

@end
