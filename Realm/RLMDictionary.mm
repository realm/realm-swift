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

#import "RLMDictionary.h"
#import "RLMDictionary_Private.h"
#import "RLMUtil.hpp"

@interface RLMDictionary () {
@public
    // Backing dictionary when this instance is unmanaged
    NSMutableDictionary *_backingDictionary;
}
@end

@implementation RLMDictionary

#pragma mark Initializers

- (instancetype)initWithObjectClassName:(__unsafe_unretained NSString *const)objectClassName {
    REALM_ASSERT([objectClassName length] > 0);
    self = [super init];
    if (self) {
        _objectClassName = objectClassName;
        _type = RLMPropertyTypeObject;
    }
    return self;
}

- (instancetype)initWithObjectType:(RLMPropertyType)type optional:(BOOL)optional {
    self = [super init];
    if (self) {
        _type = type;
        _optional = optional;
    }
    return self;
}

- (BOOL)isInvalidated {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (NSUInteger)count {
    return 0;
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (nonnull RLMNotificationToken *)addNotificationBlock:(nonnull void (^)(RLMDictionary *, RLMCollectionChange *, NSError *))block {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMDictionary *, RLMCollectionChange *, NSError *))block
                                         queue:(nullable dispatch_queue_t)queue {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (nullable NSNumber *)averageOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (instancetype)freeze {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (instancetype)thaw {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (nullable id)maxOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nullable id)minOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull id)objectAtIndex:(NSUInteger)index {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)objectsWhere:(nonnull NSString *)predicateFormat, ... {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)objectsWhere:(nonnull NSString *)predicateFormat args:(va_list)args {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)objectsWithPredicate:(nonnull NSPredicate *)predicate {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)setValue:(nullable id)value forKey:(nonnull NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)sortedResultsUsingDescriptors:(nonnull NSArray<RLMSortDescriptor *> *)properties {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)sortedResultsUsingKeyPath:(nonnull NSString *)keyPath ascending:(BOOL)ascending {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull NSNumber *)sumOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nullable id)valueForKey:(nonnull NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable * _Nonnull)buffer count:(NSUInteger)len {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (NSArray *)allKeys {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (NSArray *)allValues {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nullable id)objectForKey:(NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nullable id)objectForKeyedSubscript:(NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(NSString *key, id obj, BOOL *stop))block {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (NSEnumerator *)objectEnumerator {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)setDictionary:(NSDictionary<NSString *, id> *)otherDictionary {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)removeAllObjects {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)removeObjectsForKeys:(NSArray<NSString *> *)keyArray {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)removeObjectForKey:(NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)setObject:(id)obj forKey:(NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

@end
