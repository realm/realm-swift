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

#import "RLMObject_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMSchema_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMQueryUtil.hpp"

// We declare things in RLMObject which are actually implemented in RLMObjectBase
// for documentation's sake, which leads to -Wunimplemented-method warnings.
// Other alternatives to this would be to disable -Wunimplemented-method for this
// file (but then we could miss legitimately missing things), or declaring the
// inherited things in a category (but they currently aren't nicely grouped for
// that).
@implementation RLMObject

// synthesized in RLMObjectBase
@dynamic invalidated;

- (instancetype)init {
    return [super init];
}

- (instancetype)initWithObject:(id)object {
    return [super initWithObject:object schema:RLMSchema.sharedSchema];
}

+ (instancetype)createInDefaultRealmWithObject:(id)object {
    return (RLMObject *)RLMCreateObjectInRealmWithValue([RLMRealm defaultRealm], [self className], object, RLMCreationOptionsAllowCopy);
}

+ (instancetype)createInRealm:(RLMRealm *)realm withObject:(id)value {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(realm, [self className], value, RLMCreationOptionsAllowCopy);
}

+ (instancetype)createOrUpdateInDefaultRealmWithObject:(id)object {
    return [self createOrUpdateInRealm:[RLMRealm defaultRealm] withObject:object];
}

+ (instancetype)createOrUpdateInRealm:(RLMRealm *)realm withObject:(id)value {
    // verify primary key
    RLMObjectSchema *schema = [self sharedSchema];
    if (!schema.primaryKeyProperty) {
        NSString *reason = [NSString stringWithFormat:@"'%@' does not have a primary key and can not be updated", schema.className];
        @throw [NSException exceptionWithName:@"RLMExecption" reason:reason userInfo:nil];
    }
    return (RLMObject *)RLMCreateObjectInRealmWithValue(realm, [self className], value, RLMCreationOptionsUpdateOrCreate | RLMCreationOptionsAllowCopy);
}

- (id)objectForKeyedSubscript:(NSString *)key {
    return RLMObjectBaseObjectForKeyedSubscript(self, key);
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    RLMObjectBaseSetObjectForKeyedSubscript(self, key, obj);
}

- (RLMRealm *)realm {
    return _realm;
}

- (RLMObjectSchema *)objectSchema {
    return _objectSchema;
}

+ (RLMResults *)allObjects {
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, nil);
}

+ (RLMResults *)allObjectsInRealm:(RLMRealm *)realm {
    return RLMGetObjects(realm, self.className, nil);
}

+ (RLMResults *)objectsWhere:(NSString *)predicateFormat, ... {
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objectsWhere:predicateFormat args:args];
}

+ (RLMResults *)objectsWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

+ (RLMResults *)objectsInRealm:(RLMRealm *)realm where:(NSString *)predicateFormat, ... {
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objectsInRealm:realm where:predicateFormat args:args];
}

+ (RLMResults *)objectsInRealm:(RLMRealm *)realm where:(NSString *)predicateFormat args:(va_list)args {
    return [self objectsInRealm:realm withPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

+ (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(RLMRealm.defaultRealm, self.className, predicate);
}

+ (RLMResults *)objectsInRealm:(RLMRealm *)realm withPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(realm, self.className, predicate);
}

+ (instancetype)objectForPrimaryKey:(id)primaryKey {
    return RLMGetObject(RLMRealm.defaultRealm, self.className, primaryKey);
}

+ (instancetype)objectInRealm:(RLMRealm *)realm forPrimaryKey:(id)primaryKey {
    return RLMGetObject(realm, self.className, primaryKey);
}

- (NSArray *)linkingObjectsOfClass:(NSString *)className forProperty:(NSString *)property {
    return RLMObjectBaseLinkingObjectsOfClass(self, className, property);
}

- (BOOL)isEqualToObject:(RLMObject *)object {
    return [object isKindOfClass:RLMObject.class] && RLMObjectBaseAreEqual(self, object);
}

+ (NSString *)className {
    return [super className];
}

+ (NSArray *)indexedProperties {
    return @[];
}

+ (NSDictionary *)defaultPropertyValues {
    return nil;
}

+ (NSString *)primaryKey {
    return nil;
}

+ (NSArray *)ignoredProperties {
    return nil;
}

@end
