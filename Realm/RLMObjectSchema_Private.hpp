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

namespace realm {
    class Table;
    template<typename T> class BasicTableRef;
    typedef BasicTableRef<Table> TableRef;
}

// RLMObjectSchema private
@interface RLMObjectSchema ()

@property (nonatomic) realm::Table *table;

// shallow copy reusing properties and property map
- (instancetype)shallowCopy;

@end

// get the table used to store object of objectClass
realm::TableRef RLMTableForObjectClass(RLMRealm *realm, NSString *className, bool &created);
realm::TableRef RLMTableForObjectClass(RLMRealm *realm, NSString *className);
