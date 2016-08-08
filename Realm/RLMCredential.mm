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

#import "RLMCredential.h"

#import "RLMRealm+Server.h"
#import "RLMServerUtil_Private.h"
#import "RLMUtil.hpp"

static NSURL *s_defaultObjectServerURL = nil;

@interface RLMCredential ()

@property (nonatomic, readwrite) RLMCredentialToken credentialToken;
@property (nonatomic, readwrite) RLMIdentityProvider provider;
@property (nonatomic, readwrite) NSDictionary *userInfo;

@end

@implementation RLMCredential

@synthesize objectServerURL = _objectServerURL;

/// Validate a URL is a valid URL for a Realm Object Server.
static BOOL objectServerURLIsValid(NSURL *url) {
    NSString *scheme = [url scheme];
    return [scheme isEqualToString:@"realm"] || [scheme isEqualToString:@"realms"];
}

+ (void)setDefaultObjectServerURL:(NSURL *)url {
    if (!objectServerURLIsValid(url)) {
        @throw RLMException(@"The URL passed into '-setDefaultObjectServerURL:' was not a valid Realm Object Server URL.");
    }
    s_defaultObjectServerURL = url;
}

+ (instancetype)credentialWithUsername:(NSString *)username
                              password:(NSString *)password
                      createNewAccount:(BOOL)isNewAccount {
    return [[RLMCredential alloc] initWithCredentialToken:username
                                                 provider:RLMIdentityProviderUsernamePassword
                                                 userInfo:@{kRLMServerPasswordKey: password,
                                                            kRLMServerRegisterKey: @(isNewAccount)}
                                                serverURL:nil];
}

+ (instancetype)credentialWithFacebookToken:(NSString *)facebookToken {
    return [[RLMCredential alloc] initWithCredentialToken:facebookToken
                                                 provider:RLMIdentityProviderFacebook
                                                 userInfo:nil
                                                serverURL:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RLMCredential: %p> data: %@, provider: %@, userInfo: %@",
            self,
            self.credentialToken,
            self.provider,
            self.userInfo];
}

- (instancetype)initWithCredentialToken:(RLMCredentialToken)credentialToken
                               provider:(RLMIdentityProvider)provider
                               userInfo:(nullable NSDictionary *)userInfo
                              serverURL:(nullable NSURL *)serverURL {
    if (self = [super init]) {
        self.credentialToken = credentialToken;
        self.authServerPort = nil;
        self.provider = provider;
        self.userInfo = userInfo;
        if (serverURL && !objectServerURLIsValid(serverURL)) {
            @throw RLMException(@"The URL passed into '-initWithCredentialToken:...' was not a valid server URL.");
        }
        self.objectServerURL = serverURL;
    }
    return self;
}

- (void)setObjectServerURL:(NSURL *)objectServerURL {
    if (!objectServerURLIsValid(objectServerURL)) {
        @throw RLMException(@"The URL set on 'objectServerURL' was not a valid Realm Object Server URL.");
    }
    _objectServerURL = objectServerURL;
}

- (NSURL *)objectServerURL {
    if (!_objectServerURL) {
        return s_defaultObjectServerURL;
    }
    return _objectServerURL;
}

@end
