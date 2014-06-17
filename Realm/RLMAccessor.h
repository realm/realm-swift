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

#import <Foundation/Foundation.h>
#import <tightdb/table.hpp>
#import "RLMRealm.h"

//
// Accessor Protocol
//

// implemented by all persisted objects
@protocol RLMAccessor <NSObject>
@property (nonatomic) RLMRealm *realm;
@property (nonatomic, assign) BOOL writable;
@end


//
// Accessors Class Creation/Caching
//
@class RLMObjectSchema;

// initialize accessor cache
void RLMAccessorCacheInitialize();

// get accessor classes for an object class - generates classes if not cached
Class RLMAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema);
Class RLMInvalidAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema);
Class RLMReadOnlyAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema);
Class RLMInsertionAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema);
Class RLMStandaloneAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema);

//
// Dynamic accessor creation
//
Class RLMDynamicClassForSchema(RLMObjectSchema *schema, NSUInteger version);
