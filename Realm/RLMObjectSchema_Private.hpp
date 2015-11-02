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

#import "RLMObjectSchema_Private.h"

#import "object_schema.hpp"
#import "RLMObject_Private.hpp"

#import <realm/row.hpp>
#import <vector>

namespace realm {
    class Table;
    template<typename T> class BasicTableRef;
    typedef BasicTableRef<Table> TableRef;
}

class RLMObservationInfo;

// RLMObjectSchema private
@interface RLMObjectSchema () {
    @public
    std::vector<RLMObservationInfo *> _observedObjects;
}
@property (nonatomic) realm::Table *table;

// shallow copy reusing properties and property map
- (instancetype)shallowCopy;

// create realm::ObjectSchema copy
- (realm::ObjectSchema)objectStoreCopy;

// initialize with realm::ObjectSchema
+ (instancetype)objectSchemaForObjectStoreSchema:(realm::ObjectSchema &)objectSchema;

@end
