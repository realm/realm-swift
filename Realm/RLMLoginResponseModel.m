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

#import "RLMLoginResponseModel.h"

#import "RLMSyncUtil_Private.h"

@interface RLMLoginResponseModel ()

@property (nonatomic, readwrite) RLMIdentity identity;
@property (nonatomic, readwrite) RLMRenewalTokenModel *renewalTokenModel;

//@property (nonatomic, readwrite) NSArray *access;

@end

@implementation RLMLoginResponseModel

- (instancetype)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
        RLMSERVER_PARSE_STRING_OR_ABORT(json, kRLMSyncIdentityKey, identity);
        RLMSERVER_PARSE_MODEL_OR_ABORT(json, kRLMSyncRefreshKey, RLMRenewalTokenModel, renewalTokenModel);
    }
    return self;
}

@end

@interface RLMRenewalTokenModel ()

@property (nonatomic, readwrite) RLMServerToken renewalToken;
@property (nonatomic, readwrite) NSTimeInterval tokenExpiry;

@end

@implementation RLMRenewalTokenModel

- (instancetype)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
        RLMSERVER_PARSE_STRING_OR_ABORT(json, kRLMSyncTokenKey, renewalToken);
        RLMSERVER_PARSE_DOUBLE_OR_ABORT(json, kRLMSyncExpiresKey, tokenExpiry);
    }
    return self;
}

@end
