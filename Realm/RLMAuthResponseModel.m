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

#import "RLMAuthResponseModel.h"

#import "RLMTokenModels.h"
#import "RLMSyncUtil_Private.h"

static const NSString *const kRLMSyncAccessTokenKey = @"access_token";
static const NSString *const kRLMSyncRefreshTokenKey = @"refresh_token";

@interface RLMAuthResponseModel ()

@property (nonatomic, readwrite) RLMTokenModel *accessToken;
@property (nonatomic, readwrite) RLMTokenModel *refreshToken;

@end

@implementation RLMAuthResponseModel

- (instancetype)initWithJSON:(NSDictionary *)json
          requireAccessToken:(BOOL)requireAccessToken
         requireRefreshToken:(BOOL)requireRefreshToken {
    if (self = [super init]) {
        // Get the access token.
        if (requireAccessToken) {
            RLMSERVER_PARSE_MODEL_OR_ABORT(json, kRLMSyncAccessTokenKey, RLMTokenModel, accessToken);
        } else {
            RLMSERVER_PARSE_OPTIONAL_MODEL(json, kRLMSyncAccessTokenKey, RLMTokenModel, accessToken);
        }
        // Get the refresh token.
        if (requireRefreshToken) {
            RLMSERVER_PARSE_MODEL_OR_ABORT(json, kRLMSyncRefreshTokenKey, RLMTokenModel, refreshToken);
        } else {
            RLMSERVER_PARSE_OPTIONAL_MODEL(json, kRLMSyncRefreshTokenKey, RLMTokenModel, refreshToken);
        }
        return self;
    }
    return nil;
}

@end
