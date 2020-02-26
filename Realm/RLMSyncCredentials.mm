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

#import "RLMSyncCredentials_Private.hpp"
#import "RLMSyncUtil_Private.h"
#import "app.hpp"

RLMIdentityProvider const RLMIdentityProviderUsernamePassword       = @"local-userpass";
RLMIdentityProvider const RLMIdentityProviderFacebook               = @"oauth2-facebook";
RLMIdentityProvider const RLMIdentityProviderGoogle                 = @"oauth2-google";
RLMIdentityProvider const RLMIdentityProviderApple                  = @"oauth2-apple";
RLMIdentityProvider const RLMIdentityProviderJWT                    = @"custom-token";
RLMIdentityProvider const RLMIdentityProviderAnonymous              = @"anon-user";

@implementation RLMSyncCredentials

+ (instancetype)credentialsWithFacebookToken:(RLMSyncCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:realm::AppCredentials::credentialsWithFacebookToken(token.UTF8String)];
}

//+ (instancetype)credentialsWithGoogleToken:(RLMSyncCredentialsToken)token {
//    return [[self alloc] initWithCustomToken:token provider:RLMIdentityProviderGoogle userInfo:nil];
//}

//+ (instancetype)credentialsWithUsername:(NSString *)username
//                               password:(NSString *)password
//                               register:(BOOL)shouldRegister {
//    return [[self alloc] initWithCustomToken:username
//                                    provider:RLMIdentityProviderUsernamePassword
//                                    userInfo:@{kRLMSyncPasswordKey: password,
//                                               kRLMSyncRegisterKey: @(shouldRegister)}];
//}

//+ (instancetype)credentialsWithJWT:(NSString *)token {
//    return [[self alloc] initWithCustomToken:token provider:RLMIdentityProviderJWT userInfo:nil];
//}
    
+ (instancetype)anonymousCredentials {
    return [[self alloc] initWithAppCredentials:realm::AppCredentials::anonymousCredentials()];
}

+ (instancetype)credentialsWithAppleToken:(RLMSyncCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:realm::AppCredentials::credentialsWithAppleToken(token.UTF8String)];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMSyncCredentials class]]) {
        return NO;
    }
    RLMSyncCredentials *that = (RLMSyncCredentials *)object;
    return ([self.token isEqualToString:that.token]
            && [self.provider isEqualToString:that.provider]
            && [self.userInfo isEqual:that.userInfo]);
}

- (instancetype)initWithAppCredentials:(realm::AppCredentials *)appCredentials {
    if (self = [super init]) {
        self.appCredentials = appCredentials;
        return self;
    }
    return nil;
}

@end
