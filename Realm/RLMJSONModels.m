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
static const NSString *const kRLMSyncExpiresKey         = @"exp";
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
static const NSString *const kRLMSyncIssuedAtKey        = @"iat";
static const NSString *const kRLMSyncUserDataKey        = @"user_data";

@implementation RLMJwt

+(NSArray<NSString *>*)splitToken:(NSString *)jwt {
    NSArray* parts = [jwt componentsSeparatedByString:@"."];
    if ([parts count] != 3) {
        @throw [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{}];
    }
    return parts;
}

-(instancetype)initWithEncodedJWT:(NSString *)encodedJWT {
    if (self = [super init]) {
        NSArray<NSString *> *parts = [RLMJwt splitToken:encodedJWT];

        NSString *secondPart = parts[1];

        NSUInteger secondPartLength = [secondPart length];
        NSInteger extraCharacters = secondPartLength % 4;

        if (extraCharacters != 0) {
            secondPart = [secondPart
                          stringByPaddingToLength:secondPartLength + 4 - extraCharacters
                          withString:@"="
                          startingAtIndex:0];
        }

        NSData *json = [[NSData alloc] initWithBase64EncodedString:secondPart options:0];

        NSDictionary *token = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];

        self.token = encodedJWT;
        self.expires  = [token[kRLMSyncExpiresKey] doubleValue];
        self.issuedAt = [token[kRLMSyncIssuedAtKey] doubleValue];
        self.userData = token[kRLMSyncUserDataKey];

        return self;
    }
    return nil;
}
@end
#pragma mark - RLMTokenDataModel

@interface RLMTokenDataModel ()

@property (nonatomic, readwrite) NSString *identity;
@property (nonatomic, readwrite) NSString *appID;
@property (nonatomic, readwrite) NSString *path;
@property (nonatomic, readwrite) NSTimeInterval expires;
@property (nonatomic, readwrite) BOOL isAdmin;

@end

@implementation RLMTokenDataModel

- (instancetype)initWithJWT:(RLMJwt *)jwt {
    if (self = [super init]) {
        self.isAdmin = NO;
        self.expires = jwt.expires;
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

- (instancetype)initWithJWT:(RLMJwt *)jwt {
    if (self = [super init]) {
        self.token = jwt.token;
        self.tokenData = [[RLMTokenDataModel alloc] initWithJWT:jwt];
        return self;
    }
    return nil;
}

@end

#pragma mark - RLMAuthResponseModel

@interface RLMAuthResponseModel ()

@property (nonatomic, readwrite) RLMTokenModel *accessToken;
@property (nonatomic, readwrite) RLMTokenModel *refreshToken;
@property (nonatomic, readwrite) NSString *urlPrefix;

@end

@implementation RLMAuthResponseModel

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary
                requireAccessToken:(BOOL)requireAccessToken
               requireRefreshToken:(BOOL)requireRefreshToken {
    if (self = [super init]) {
        // Get the access token.
        self.accessToken = [[RLMTokenModel alloc] initWithJWT:[[RLMJwt alloc] initWithEncodedJWT: jsonDictionary[kRLMSyncAccessTokenKey]]];
        self.refreshToken = [[RLMTokenModel alloc] initWithJWT:[[RLMJwt alloc] initWithEncodedJWT: jsonDictionary[kRLMSyncRefreshTokenKey]]];
//        // Get the refresh token.

//        self.urlPrefix = jsonDictionary[@"sync_worker"][@"path"];
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

        NSString *detail = jsonDictionary[@"detail"];
        if ([detail isKindOfClass:[NSString class]]) {
            _title = detail;
        }

        for (NSDictionary<NSString *, NSString *> *problem in jsonDictionary[@"invalid_params"]) {
            NSString *name = problem[@"name"];
            NSString *reason = problem[@"reason"];
            if (name && reason) {
                _title = [NSString stringWithFormat:@"%@ %@: %@;", _title, name, reason];
            }
        }

        return self;
    }
    return nil;
}

@end
