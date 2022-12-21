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

#import <Realm/RLMConstants.h>

@class RLMObjectSchema, RLMProperty, RLMObjectBase;

RLM_HEADER_AUDIT_BEGIN(nullability)

//
// Accessors Class Creation/Caching
//

// get accessor classes for an object class - generates classes if not cached
Class RLMManagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema, const char *name);
Class RLMUnmanagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema);

//
// Dynamic getters/setters
//
FOUNDATION_EXTERN void RLMDynamicValidatedSet(RLMObjectBase *obj, NSString *propName, id __nullable val);
FOUNDATION_EXTERN id __nullable RLMDynamicGet(RLMObjectBase *obj, RLMProperty *prop);
FOUNDATION_EXTERN id __nullable RLMDynamicGetByName(RLMObjectBase *obj, NSString *propName);

// by property/column
void RLMDynamicSet(RLMObjectBase *obj, RLMProperty *prop, id val);

//
// Class modification
//

// Replace className method for the given class
void RLMReplaceClassNameMethod(Class accessorClass, NSString *className);

// Replace sharedSchema method for the given class
void RLMReplaceSharedSchemaMethod(Class accessorClass, RLMObjectSchema * __nullable schema);

RLM_HEADER_AUDIT_END(nullability)
