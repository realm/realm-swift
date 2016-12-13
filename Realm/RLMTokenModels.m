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

#import "RLMTokenModels.h"
#import "RLMSyncUtil_Private.h"

static const NSString *const kRLMSyncTokenDataKey       = @"token_data";
static const NSString *const kRLMSyncTokenKey           = @"token";
static const NSString *const kRLMSyncExpiresKey         = @"expires";

@interface RLMTokenDataModel ()

@property (nonatomic, readwrite) NSString *identity;
@property (nonatomic, readwrite) NSString *appID;
@property (nonatomic, readwrite) NSString *path;
@property (nonatomic, readwrite) NSTimeInterval expires;
//@property (nonatomic, readwrite) NSArray *access;

@end

@implementation RLMTokenDataModel

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    if (self = [super init]) {
        RLM_SYNC_PARSE_STRING_OR_ABORT(jsonDictionary, kRLMSyncIdentityKey, identity);
        RLM_SYNC_PARSE_OPTIONAL_STRING(jsonDictionary, kRLMSyncAppIDKey, appID);
        RLM_SYNC_PARSE_OPTIONAL_STRING(jsonDictionary, kRLMSyncPathKey, path);
        RLM_SYNC_PARSE_DOUBLE_OR_ABORT(jsonDictionary, kRLMSyncExpiresKey, expires);
        return self;
    }
    return nil;
}

@end

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
