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
#import "RLMObjectId_Private.hpp"

@implementation RLMUpdateResult

- (instancetype)initWithUpdateResult:(realm::app::MongoCollection::UpdateResult)UpdateResult {
    if (self = [super init]) {
        _matchedCount = UpdateResult.matched_count;
        _modifiedCount = UpdateResult.modified_count;
        if (UpdateResult.upserted_id) {
            _objectId = [[RLMObjectId alloc] initWithValue:*UpdateResult.upserted_id];
        }
    }
    return self;
}

@end
