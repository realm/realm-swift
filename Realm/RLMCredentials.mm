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
#import "RLMUtil.hpp"

#import <realm/util/bson/bson.hpp>

using namespace realm::app;

@implementation RLMCredentials
- (instancetype)initWithAppCredentials:(AppCredentials&&)credentials {
    if (self = [super init]) {
        _appCredentials = std::move(credentials);
        _provider = @(_appCredentials.provider_as_string().data());
        return self;
    }
    return nil;
}

+ (instancetype)credentialsWithFacebookToken:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:AppCredentials::facebook(token.UTF8String)];
}

+ (instancetype)credentialsWithGoogleAuthCode:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:AppCredentials::google(AuthCode(token.UTF8String))];
}

+ (instancetype)credentialsWithGoogleIdToken:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:AppCredentials::google(IdToken(token.UTF8String))];
}

+ (instancetype)credentialsWithAppleToken:(RLMCredentialsToken)token {
    return [[self alloc] initWithAppCredentials:AppCredentials::apple(token.UTF8String)];
}

+ (instancetype)credentialsWithEmail:(NSString *)username
                            password:(NSString *)password {
    return [[self alloc] initWithAppCredentials:AppCredentials::username_password(username.UTF8String,
                                                                                  password.UTF8String)];
}

+ (instancetype)credentialsWithJWT:(NSString *)token {
    return [[self alloc] initWithAppCredentials:AppCredentials::custom(token.UTF8String)];
}

+ (instancetype)credentialsWithFunctionPayload:(NSDictionary<NSString *, id<RLMBSON>> *)payload {
    return [[self alloc] initWithAppCredentials:AppCredentials::function(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(payload)))];
}

+ (instancetype)credentialsWithUserAPIKey:(NSString *)apiKey {
    return [[self alloc] initWithAppCredentials:AppCredentials::api_key(apiKey.UTF8String)];
}

+ (instancetype)credentialsWithServerAPIKey:(NSString *)apiKey {
    return [[self alloc] initWithAppCredentials:AppCredentials::api_key(apiKey.UTF8String)];
}

+ (instancetype)anonymousCredentials {
    return [[self alloc] initWithAppCredentials:AppCredentials::anonymous()];
}

- (BOOL)isEqual:(id)object {
    if (auto that = RLMDynamicCast<RLMCredentials>(object)) {
        return [self.provider isEqualToString:that.provider]
            && self.appCredentials.serialize_as_json() == that.appCredentials.serialize_as_json();
    }
    return NO;
}
@end
