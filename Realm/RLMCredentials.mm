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

#import "RLMCredentials_Private.hpp"

#import "RLMBSON_Private.hpp"
#import "RLMSyncUtil_Private.h"
#import "RLMUtil.hpp"

#import <realm/object-store/util/bson/bson.hpp>

using namespace realm;

@implementation RLMCredentials
- (instancetype)initWithAppCredentials:(app::AppCredentials&&)credentials {
    if (self = [super init]) {
        _appCredentials = std::move(credentials);
        self.provider = @(_appCredentials.provider_as_string().data());
        return self;
    }
    return nil;
}

+ (instancetype)credentialsWithFacebookToken:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::facebook(token.UTF8String)];
}

+ (instancetype)credentialsWithGoogleAuthCode:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::google(app::AuthCode(token.UTF8String))];
}

+ (instancetype)credentialsWithGoogleIdToken:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::google(app::IdToken(token.UTF8String))];
}

+ (instancetype)credentialsWithAppleToken:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::apple(token.UTF8String)];
}

+ (instancetype)credentialsWithEmail:(NSString *)username
                            password:(NSString *)password {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::username_password(username.UTF8String,
                                                                                       password.UTF8String)];
}

+ (instancetype)credentialsWithJWT:(NSString *)token {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::custom(token.UTF8String)];
}

+ (instancetype)credentialsWithFunctionPayload:(NSDictionary<NSString *, id<RLMBSON>> *)payload {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::function(static_cast<bson::BsonDocument>(RLMConvertRLMBSONToBson(payload)))];
}

+ (instancetype)credentialsWithUserAPIKey:(NSString *)apiKey {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::user_api_key(apiKey.UTF8String)];
}

+ (instancetype)credentialsWithServerAPIKey:(NSString *)apiKey {
    return [[self alloc] initWithAppCredentials:app::AppCredentials::server_api_key(apiKey.UTF8String)];
}

+ (instancetype)anonymousCredentials {
    return [[self alloc] initWithAppCredentials:realm::app::AppCredentials::anonymous()];
}

- (BOOL)isEqual:(id)object {
    if (auto that = RLMDynamicCast<RLMCredentials>(object)) {
        return [self.provider isEqualToString:that.provider]
            && self.appCredentials.serialize_as_json() == that.appCredentials.serialize_as_json();
    }
    return NO;
}
@end
