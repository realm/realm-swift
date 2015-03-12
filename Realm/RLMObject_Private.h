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

#import <Realm/RLMObject.h>

// RLMObject accessor and read/write realm
@interface RLMObjectBase () {
  @public
    RLMRealm *_realm;
    // objectSchema is a cached pointer to an object stored in the RLMSchema
    // owned by _realm, so it's guaranteed to stay alive as long as this object
    // without retaining it (and retaining it makes iteration slower)
    __unsafe_unretained RLMObjectSchema *_objectSchema;
}

- (instancetype)initWithRealm:(__unsafe_unretained RLMRealm *const)realm
                       schema:(__unsafe_unretained RLMObjectSchema *const)schema
                defaultValues:(BOOL)useDefaults;

- (instancetype)initWithObjectSchema:(RLMObjectSchema *)schema;
- (instancetype)initWithObject:(id)object;
- (instancetype)initWithObject:(id)object schema:(RLMSchema *)schema;

- (BOOL)isEqualToObject:(RLMObjectBase *)object;
- (NSArray *)linkingObjectsOfClass:(NSString *)className forProperty:(NSString *)property;

// shared schema for this class
+ (RLMObjectSchema *)sharedSchema;

@end

FOUNDATION_EXTERN void RLMObjectBaseSetRealm(RLMObjectBase *object, RLMRealm *realm);
FOUNDATION_EXTERN RLMRealm *RLMObjectBaseRealm(RLMObjectBase *object);
FOUNDATION_EXTERN void RLMObjectBaseSetObjectSchema(RLMObjectBase *object, RLMObjectSchema *objectSchema);
FOUNDATION_EXTERN RLMObjectSchema *RLMObjectBaseObjectSchema(RLMObjectBase *object);
