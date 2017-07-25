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

#import "RLMSyncErrorResponseModel.h"

static const NSString *const kRLMSyncErrorStatusKey     = @"status";
static const NSString *const kRLMSyncErrorCodeKey       = @"code";
static const NSString *const kRLMSyncErrorTitleKey      = @"title";
static const NSString *const kRLMSyncErrorHintKey       = @"hint";

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
