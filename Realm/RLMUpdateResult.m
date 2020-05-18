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

#import "RLMUpdateResult.h"
#import "RLMUpdateResult_Private.hpp"
#import "RLMObjectId.h"

@implementation RLMUpdateResult

- (instancetype)initWithMatchedCount:(NSNumber *)matchedCount
                       modifiedCount:(NSNumber *)modifiedCount
                            objectId:(RLMObjectId * _Nullable)objectId {
    self = [super init];
    if (self) {
        _matchedCount = matchedCount;
        _modifiedCount = modifiedCount;
        _objectId = objectId;
    }
    return self;
}

@end
