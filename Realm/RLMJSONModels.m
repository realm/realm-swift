////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMJSONModels.h"
#import "RLMSyncUtil_Private.h"
#import "RLMSyncUser.h"

#pragma mark - Constants

static const NSString *const kRLMSyncAccessTokenKey     = @"access_token";
static const NSString *const kRLMSyncAccountsKey        = @"accounts";
static const NSString *const kRLMSyncErrorCodeKey       = @"code";
static const NSString *const kRLMSyncExpiresKey         = @"expires";
static const NSString *const kRLMSyncErrorHintKey       = @"hint";
static const NSString *const kRLMSyncIdKey              = @"id";
static const NSString *const kRLMSyncKeyKey             = @"key";
static const NSString *const kRLMSyncMetadataKey        = @"metadata";
static const NSString *const kRLMSyncRefreshTokenKey    = @"refresh_token";
static const NSString *const kRLMSyncErrorStatusKey     = @"status";
static const NSString *const kRLMSyncErrorTitleKey      = @"title";
static const NSString *const kRLMSyncTokenDataKey       = @"token_data";
static const NSString *const kRLMSyncUserKey            = @"user";
static const NSString *const kRLMSyncValueKey           = @"value";

#pragma mark - RLMTokenDataModel

@interface RLMTokenDataModel ()

@property (nonatomic, readwrite) NSString *identity;
@property (nonatomic, readwrite) NSString *appID;
@property (nonatomic, readwrite) NSString *path;
@property (nonatomic, readwrite) NSTimeInterval expires;
@property (nonatomic, readwrite) BOOL isAdmin;
//@property (nonatomic, readwrite) NSArray *access;

@end

@implementation RLMTokenDataModel

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    if (self = [super init]) {
        self.isAdmin = NO;
        RLM_SYNC_PARSE_STRING_OR_ABORT(jsonDictionary, kRLMSyncIdentityKey, identity);
        RLM_SYNC_PARSE_OPTIONAL_STRING(jsonDictionary, kRLMSyncAppIDKey, appID);
        RLM_SYNC_PARSE_OPTIONAL_STRING(jsonDictionary, kRLMSyncPathKey, path);
        RLM_SYNC_PARSE_OPTIONAL_BOOL(jsonDictionary, kRLMSyncIsAdminKey, isAdmin);
        RLM_SYNC_PARSE_DOUBLE_OR_ABORT(jsonDictionary, kRLMSyncExpiresKey, expires);
        return self;
    }
    return nil;
}

@end

#pragma mark - RLMTokenModel

@interface RLMTokenModel ()

@property (nonatomic, readwrite) NSString *token;
@property (nonatomic, nullable, readwrite) NSString *path;
@property (nonatomic, readwrite) RLMTokenDataModel *tokenData;

@end

@implementation RLMTokenModel

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    if (self = [super init]) {
        RLM_SYNC_PARSE_STRING_OR_ABORT(jsonDictionary, kRLMSyncTokenKey, token);
        RLM_SYNC_PARSE_OPTIONAL_STRING(jsonDictionary, kRLMSyncPathKey, path);
        RLM_SYNC_PARSE_MODEL_OR_ABORT(jsonDictionary, kRLMSyncTokenDataKey, RLMTokenDataModel, tokenData);
        return self;
    }
    return nil;
}

@end

#pragma mark - RLMAuthResponseModel

@interface RLMAuthResponseModel ()

@property (nonatomic, readwrite) RLMTokenModel *accessToken;
@property (nonatomic, readwrite) RLMTokenModel *refreshToken;

@end

@implementation RLMAuthResponseModel

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary
                requireAccessToken:(BOOL)requireAccessToken
               requireRefreshToken:(BOOL)requireRefreshToken {
    if (self = [super init]) {
        // Get the access token.
        if (requireAccessToken) {
            RLM_SYNC_PARSE_MODEL_OR_ABORT(jsonDictionary, kRLMSyncAccessTokenKey, RLMTokenModel, accessToken);
        } else {
            RLM_SYNC_PARSE_OPTIONAL_MODEL(jsonDictionary, kRLMSyncAccessTokenKey, RLMTokenModel, accessToken);
        }
        // Get the refresh token.
        if (requireRefreshToken) {
            RLM_SYNC_PARSE_MODEL_OR_ABORT(jsonDictionary, kRLMSyncRefreshTokenKey, RLMTokenModel, refreshToken);
        } else {
            RLM_SYNC_PARSE_OPTIONAL_MODEL(jsonDictionary, kRLMSyncRefreshTokenKey, RLMTokenModel, refreshToken);
        }
        return self;
    }
    return nil;
}

@end

#pragma mark - RLMUserInfoResponseModel

@interface RLMSyncUserAccountInfo ()
@property (nonatomic, readwrite) NSString *provider;
@property (nonatomic, readwrite) NSString *providerUserIdentity;
@end

@implementation RLMSyncUserAccountInfo

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    if (self = [super init]) {
        RLM_SYNC_PARSE_STRING_OR_ABORT(jsonDictionary, kRLMSyncProviderKey, provider);
        RLM_SYNC_PARSE_STRING_OR_ABORT(jsonDictionary, kRLMSyncProviderIDKey, providerUserIdentity);
        return self;
    }
    return nil;
}

@end

@interface RLMUserResponseModel ()

@property (nonatomic, readwrite) NSString *identity;
@property (nonatomic, readwrite) NSArray *accounts;
@property (nonatomic, readwrite) NSDictionary *metadata;
@property (nonatomic, readwrite) BOOL isAdmin;

@end

@implementation RLMUserResponseModel

- (void)parseMetadataFromJSON:(NSDictionary *)jsonDictionary {
    NSMutableDictionary *buffer = [NSMutableDictionary dictionary];
    NSArray *metadataArray = jsonDictionary[kRLMSyncMetadataKey];
    if (![metadataArray isKindOfClass:[NSArray class]]) {
        self.metadata = @{};
        return;
    }
    for (NSDictionary *object in metadataArray) {
        if (![object isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *key = object[kRLMSyncKeyKey];
        NSString *value = object[kRLMSyncValueKey];
        if (!key || !value) {
            continue;
        }
        buffer[key] = value;
    }
    self.metadata = [buffer copy];
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    if (self = [super init]) {
        self.isAdmin = NO;
        RLM_SYNC_PARSE_STRING_OR_ABORT(jsonDictionary, kRLMSyncUserIDKey, identity);
        RLM_SYNC_PARSE_OPTIONAL_BOOL(jsonDictionary, kRLMSyncIsAdminKey, isAdmin);
        RLM_SYNC_PARSE_MODEL_ARRAY_OR_ABORT(jsonDictionary, kRLMSyncAccountsKey, RLMSyncUserAccountInfo, accounts);
        [self parseMetadataFromJSON:jsonDictionary];
        return self;
    }
    return nil;
}

@end

#pragma mark - RLMSyncErrorResponseModel

@interface RLMSyncErrorResponseModel ()

@property (nonatomic, readwrite) NSInteger status;
@property (nonatomic, readwrite) NSInteger code;
@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSString *hint;

@end

@implementation RLMSyncErrorResponseModel

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    if (self = [super init]) {
        RLM_SYNC_PARSE_DOUBLE_OR_ABORT(jsonDictionary, kRLMSyncErrorStatusKey, status);
        RLM_SYNC_PARSE_DOUBLE_OR_ABORT(jsonDictionary, kRLMSyncErrorCodeKey, code);
        RLM_SYNC_PARSE_OPTIONAL_STRING(jsonDictionary, kRLMSyncErrorTitleKey, title);
        RLM_SYNC_PARSE_OPTIONAL_STRING(jsonDictionary, kRLMSyncErrorHintKey, hint);
        return self;
    }
    return nil;
}

@end
