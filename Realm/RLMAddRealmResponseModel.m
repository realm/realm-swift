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

#import "RLMAddRealmResponseModel.h"

@interface RLMAddRealmResponseModel ()

@property (nonatomic, readwrite) RLMServerToken accessToken;
@property (nonatomic, readwrite) NSTimeInterval accessTokenExpiry;
@property (nonatomic, readwrite) NSString *fullPath;

@end

@implementation RLMAddRealmResponseModel

- (instancetype)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
        RLMSERVER_PARSE_STRING_OR_ABORT(json, kRLMSyncTokenKey, accessToken);
        RLMSERVER_PARSE_DOUBLE_OR_ABORT(json, kRLMSyncExpiresKey, accessTokenExpiry);
        RLMSERVER_PARSE_STRING_OR_ABORT(json, kRLMSyncPathKey, fullPath);
    }
    return self;
}

@end
