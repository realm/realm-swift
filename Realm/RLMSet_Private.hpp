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

#import "RLMSet_Private.h"

#import "RLMCollection_Private.hpp"

#import "RLMResults_Private.hpp"

namespace realm {
class SetBase;
class CollectionBase;
    namespace object_store {
        class Set;
    }
}

@class RLMObjectBase, RLMObjectSchema, RLMProperty;
class RLMClassInfo;
class RLMObservationInfo;

@interface RLMSet () {
@protected
    NSString *_objectClassName;
    RLMPropertyType _type;
    BOOL _optional;
@public
    // The name of the property which this RLMSet represents
    RLMProperty *_property;
    __weak RLMObjectBase *_parentObject;
}
@end

@interface RLMManagedSet () <RLMCollectionPrivate>

- (RLMManagedSet *)initWithBackingCollection:(realm::object_store::Set)set
                                  parentInfo:(RLMClassInfo *)parentInfo
                                    property:(__unsafe_unretained RLMProperty *const)property;

- (bool)isBackedBySet:(realm::object_store::Set const&)set;

// deletes all objects in the RLMSet from their containing realms
- (void)deleteObjectsFromRealm;

@end

void RLMValidateSetObservationKey(NSString *keyPath, RLMSet *set);

// Initialize the observation info for a set if needed
void RLMEnsureSetObservationInfo(std::unique_ptr<RLMObservationInfo>& info,
                                 NSString *keyPath, RLMSet *set, id observed);
