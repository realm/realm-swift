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

#import "RLMAppCredentials_Private.hpp"
#import "RLMSyncUtil_Private.h"
#import "RLMUtil.hpp"

using namespace realm;

@interface RLMAppCredentials ()

- (instancetype) initWithAppCredentials:(const app::AppCredentials&)credentials NS_DESIGNATED_INITIALIZER;

@end

@implementation RLMAppCredentials

- (instancetype)initWithAppCredentials:(const app::AppCredentials&)credentials {
    if (self = [super init]) {
        self->_appCredentials = std::make_shared<app::AppCredentials>(credentials);
        self.provider = @(credentials.provider_as_string().data());
        return self;
    }
    return nil;
}

+ (instancetype)credentialsWithFacebookToken:(RLMAppCredentialsToken)token {
    return [[self alloc] initWithAppCredentials: app::AppCredentials::facebook([token cStringUsingEncoding: NSUTF8StringEncoding])];
}

+ (instancetype)credentialsWithGoogleToken:(RLMAppCredentialsToken)token {
    // FIXME: Implement once available in the object store
    REALM_UNREACHABLE();
}

+ (instancetype)credentialsWithUsername:(NSString *)username
                               password:(NSString *)password {
    return [[self alloc] initWithAppCredentials: app::AppCredentials::username_password([username cStringUsingEncoding: NSUTF8StringEncoding], [password cStringUsingEncoding: NSUTF8StringEncoding])];
}

+ (instancetype)credentialsWithJWT:(NSString *)token {
    // FIXME: Implement once available in the object store
    REALM_UNREACHABLE();
}
    
+ (instancetype)anonymousCredentials {
    return [[self alloc] initWithAppCredentials: realm::app::AppCredentials::anonymous()];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMAppCredentials class]]) {
        return NO;
    }
    RLMAppCredentials *that = (RLMAppCredentials *)object;
    return ([self.provider isEqualToString:that.provider]
            && self.appCredentials->serialize_as_json() == that.appCredentials->serialize_as_json());
}

@end
