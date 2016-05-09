////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMArray_Private.h"

#import "RLMCollection_Private.hpp"

#import <Realm/RLMResults.h>

#import <realm/link_view_fwd.hpp>
#import <vector>

namespace realm {
    class LinkView;
    class Results;
    class TableView;
    struct SortOrder;
}

@class RLMObjectBase;
@class RLMObjectSchema;
class RLMObservationInfo;

@interface RLMArray () {
  @protected
    NSString *_objectClassName;
  @public
    // The name of the property which this RLMArray represents
    NSString *_key;
    __weak RLMObjectBase *_parentObject;
}
@end

//
// LinkView backed RLMArray subclass
//
@interface RLMArrayLinkView : RLMArray <RLMFastEnumerable>
@property (nonatomic, unsafe_unretained) RLMObjectSchema *objectSchema;

+ (RLMArrayLinkView *)arrayWithObjectClassName:(NSString *)objectClassName
                                          view:(realm::LinkViewRef)view
                                         realm:(RLMRealm *)realm
                                           key:(NSString *)key
                                  parentSchema:(RLMObjectSchema *)parentSchema;

// deletes all objects in the RLMArray from their containing realms
- (void)deleteObjectsFromRealm;
@end

void RLMValidateArrayObservationKey(NSString *keyPath, RLMArray *array);

// Initialize the observation info for an array if needed
void RLMEnsureArrayObservationInfo(std::unique_ptr<RLMObservationInfo>& info,
                                   NSString *keyPath, RLMArray *array, id observed);


//
// RLMResults private methods
//
@interface RLMResults () <RLMFastEnumerable>
+ (instancetype)resultsWithObjectSchema:(RLMObjectSchema *)objectSchema
                                   results:(realm::Results)results;

- (void)deleteObjectsFromRealm;
@end
