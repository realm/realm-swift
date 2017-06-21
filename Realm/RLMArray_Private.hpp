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
#import <realm/table_ref.hpp>

namespace realm {
    class Results;
}

@class RLMObjectBase, RLMObjectSchema, RLMProperty;
class RLMClassInfo;
class RLMObservationInfo;

@interface RLMArray () {
@protected
    NSString *_objectClassName;
    RLMPropertyType _type;
    bool _optional;
@public
    // The name of the property which this RLMArray represents
    NSString *_key;
    __weak RLMObjectBase *_parentObject;
}
@end

@interface RLMManagedArray : RLMArray <RLMFastEnumerable>
- (instancetype)initWithParent:(RLMObjectBase *)parentObject property:(RLMProperty *)property;
- (RLMManagedArray *)initWithList:(realm::List)list
                            realm:(__unsafe_unretained RLMRealm *const)realm
                       parentInfo:(RLMClassInfo *)parentInfo
                         property:(__unsafe_unretained RLMProperty *const)property;

- (bool)isBackedByList:(realm::List const&)list;

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
+ (instancetype)resultsWithObjectInfo:(RLMClassInfo&)info
                              results:(realm::Results)results;

- (void)deleteObjectsFromRealm;
@end
