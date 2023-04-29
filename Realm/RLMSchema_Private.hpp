////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMSchema_Private.h"

#import <memory>

namespace realm {
    class Schema;
    class ObjectSchema;
}

RLM_DIRECT_MEMBERS
@interface RLMSchema ()
+ (instancetype)dynamicSchemaFromObjectStoreSchema:(realm::Schema const&)objectStoreSchema;
- (realm::Schema)objectStoreCopy;
@end

// Ensure that all objectSchema in the given schema have managed accessors created.
// This is normally done during schema discovery but may not be when using
// dynamically created schemas.
void RLMSchemaEnsureAccessorsCreated(RLMSchema *schema);
