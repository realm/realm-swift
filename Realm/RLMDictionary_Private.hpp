////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#import "RLMDictionary_Private.h"

#import "RLMCollection_Private.hpp"

#import "RLMResults_Private.hpp"

#import <realm/table_ref.hpp>

namespace realm {
    class Results;
}

@class RLMObjectBase, RLMObjectSchema, RLMProperty;
class RLMClassInfo;
class RLMObservationInfo;

@interface RLMDictionary () {
@public
    NSString *_objectClassName;
    RLMPropertyType _type;
    BOOL _optional;
    // The name of the property which this RLMDictionary represents
    NSString *_key;
    __weak RLMObjectBase *_parentObject;
}
@end

@interface RLMManagedDictionary : RLMDictionary <RLMFastEnumerable>

- (instancetype)initWithParent:(RLMObjectBase *)parentObject property:(RLMProperty *)property;
- (RLMManagedDictionary *)initWithBackingCollection:(realm::object_store::Dictionary)dictionary
                                         parentInfo:(RLMClassInfo *)parentInfo
                                           property:(__unsafe_unretained RLMProperty *const)property;

- (bool)isBackedByDictionary:(realm::object_store::Dictionary const&)dictionary;

// deletes all objects in the RLMDictionary from their containing realms
- (void)deleteObjectsFromRealm;
@end

void RLMValidateDictionaryObservationKey(NSString *keyPath, RLMDictionary *dictionary);

// Initialize the observation info for an dictionary if needed
void RLMEnsureDictionaryObservationInfo(std::unique_ptr<RLMObservationInfo>& info,
                                   NSString *keyPath, RLMDictionary *array, id observed);
