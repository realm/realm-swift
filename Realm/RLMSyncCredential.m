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

#import "RLMSyncCredential.h"
#import "RLMSyncUtil_Private.h"

RLMIdentityProvider const RLMIdentityProviderDebug                  = @"debug";
RLMIdentityProvider const RLMIdentityProviderRealm                  = @"realm";
RLMIdentityProvider const RLMIdentityProviderUsernamePassword       = @"password";
RLMIdentityProvider const RLMIdentityProviderFacebook               = @"facebook";
RLMIdentityProvider const RLMIdentityProviderTwitter                = @"twitter";
RLMIdentityProvider const RLMIdentityProviderGoogle                 = @"google";
RLMIdentityProvider const RLMIdentityProviderICloud                 = @"icloud";

@interface RLMSyncCredential ()

@property (nonatomic, readwrite) RLMCredentialToken token;
@property (nonatomic, readwrite) RLMIdentityProvider provider;
@property (nonatomic, readwrite) NSDictionary *userInfo;

@end

@implementation RLMSyncCredential

+ (instancetype)credentialWithFacebookToken:(RLMCredentialToken)token {
    return [[self alloc] initWithCustomToken:token provider:RLMIdentityProviderFacebook userInfo:nil];
}

+ (instancetype)credentialWithUsername:(NSString *)username
                              password:(NSString *)password
                               actions:(RLMAuthenticationActions)actions {
    return [[self alloc] initWithCustomToken:username
                                    provider:RLMIdentityProviderUsernamePassword
                                    userInfo:@{kRLMSyncPasswordKey: password,
                                               kRLMSyncActionsKey: @(actions)}];
}

+ (instancetype)credentialWithAccessToken:(RLMServerToken)accessToken identity:(NSString *)identity {
    return [[self alloc] initWithCustomToken:accessToken
                                    provider:RLMIdentityProviderAccessToken
                                    userInfo:@{kRLMSyncIdentityKey: identity}];
}

- (instancetype)initWithCustomToken:(RLMCredentialToken)token
                           provider:(RLMIdentityProvider)provider
                           userInfo:(NSDictionary *)userInfo {
    if (self = [super init]) {
        self.token = token;
        self.provider = provider;
        self.userInfo = userInfo;
        return self;
    }
    return nil;
}

@end
