////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMUpdateResult_Private.hpp"

#import "RLMBSON_Private.hpp"
#import "RLMUtil.hpp"

@implementation RLMUpdateResult

- (instancetype)initWithUpdateResult:(realm::app::MongoCollection::UpdateResult)updateResult {
    if (self = [super init]) {
        _matchedCount = updateResult.matched_count;
        _modifiedCount = updateResult.modified_count;
        if (updateResult.upserted_id) {
            _documentId = RLMConvertBsonToRLMBSON(*updateResult.upserted_id);
            _objectId = RLMDynamicCast<RLMObjectId>(_documentId);
        }
    }
    return self;
}

@end
