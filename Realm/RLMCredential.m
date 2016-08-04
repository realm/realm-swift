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

#import "RLMRealm+Sync.h"
#import "RLMSyncPrivateUtil.h"

static NSURL *s_defaultSyncURL = nil;

@interface RLMCredential ()

@property (nonatomic, readwrite) RLMCredentialToken credentialToken;
@property (nonatomic, readwrite) RLMSyncIdentityProvider provider;
@property (nonatomic, readwrite) NSDictionary *userInfo;

@end

@implementation RLMCredential

/// Validate a URL is a valid URL for a Realm Sync server.
static BOOL syncServerURLIsValid(NSURL *url) {
    NSString *scheme = [url scheme];
    return [scheme isEqualToString:@"realm"] || [scheme isEqualToString:@"realms"];
}

+ (void)setDefaultSyncServerURL:(NSURL *)url {
    s_defaultSyncURL = url;
}

+ (instancetype)credentialWithUsername:(NSString *)username
                              password:(NSString *)password
                      createNewAccount:(BOOL)isNewAccount {
    return [[RLMCredential alloc] initWithCredentialToken:username
                                                 provider:RLMSyncIdentityProviderUsernamePassword
                                                 userInfo:@{kRLMSyncPasswordKey: password,
                                                            kRLMSyncRegisterKey: @(isNewAccount)}];
}

+ (instancetype)credentialWithFacebookToken:(NSString *)facebookToken {
    return [[RLMCredential alloc] initWithCredentialToken:facebookToken
                                                 provider:RLMSyncIdentityProviderFacebook
                                                 userInfo:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RLMSyncUser: %p> credential: %@, provider: %@, userInfo: %@",
            self,
            self.credentialToken,
            self.provider,
            self.userInfo];
}

- (instancetype)initWithCredentialToken:(RLMCredentialToken)credentialToken
                               provider:(RLMSyncIdentityProvider)provider
                               userInfo:(nullable NSDictionary *)userInfo {
    if (self = [super init]) {
        self.credentialToken = credentialToken;
        self.provider = provider;
        self.userInfo = userInfo;
    }
    return self;
}

- (NSURL *)syncServerURL {
    if (!_syncServerURL) {
        return s_defaultSyncURL;
    }
    return _syncServerURL;
}

@end
