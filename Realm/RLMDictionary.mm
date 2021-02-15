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
#import "RLMObject_Private.h"
#import "RLMObjectSchema.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

@interface RLMDictionary () {
@public
    // Backing dictionary when this instance is unmanaged
    NSMutableDictionary *_backingCollection;
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
    return NO;
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

- (instancetype)freeze {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (instancetype)thaw {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (id)minOfProperty:(NSString *)property {
    return [self aggregateProperty:property operation:@"@min" method:_cmd];
}

- (id)maxOfProperty:(NSString *)property {
    return [self aggregateProperty:property operation:@"@max" method:_cmd];
}

- (id)sumOfProperty:(NSString *)property {
    return [self aggregateProperty:property operation:@"@sum" method:_cmd];
}

- (id)averageOfProperty:(NSString *)property {
    return [self aggregateProperty:property operation:@"@avg" method:_cmd];
}

- (RLMPropertyType)typeForProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"self"]) {
        return _type;
    }

    RLMObjectSchema *objectSchema;
    if (_backingCollection.count) {
        objectSchema = [_backingCollection.allValues[0] objectSchema];
    }
    else {
        objectSchema = [RLMSchema.partialPrivateSharedSchema schemaForClassName:_objectClassName];
    }

    return RLMValidatedProperty(objectSchema, propertyName).type;
}

- (id)aggregateProperty:(NSString *)key operation:(NSString *)op method:(SEL)sel {
    // Although delegating to valueForKeyPath: here would allow to support
    // nested key paths as well, limiting functionality gives consistency
    // between unmanaged and managed arrays.
    if ([key rangeOfString:@"."].location != NSNotFound) {
        @throw RLMException(@"Nested key paths are not supported yet for KVC collection operators.");
    }

    if ([op isEqualToString:@"@distinctUnionOfObjects"]) {
        @throw RLMException(@"this class does not implement the distinctUnionOfObjects");
    }

    bool allowDate = false;
    bool sum = false;
    if ([op isEqualToString:@"@min"] || [op isEqualToString:@"@max"]) {
        allowDate = true;
    }
    else if ([op isEqualToString:@"@sum"]) {
        sum = true;
    }
    else if (![op isEqualToString:@"@avg"]) {
        // Just delegate to NSDictionary for all other operators
        return [_backingCollection valueForKeyPath:[op stringByAppendingPathExtension:key]];
    }

    RLMPropertyType type = [self typeForProperty:key];
    if (!canAggregate(type, allowDate)) {
        NSString *method = sel ? NSStringFromSelector(sel) : op;
        if (_type == RLMPropertyTypeObject) {
            @throw RLMException(@"%@: is not supported for %@ property '%@.%@'",
                                method, RLMTypeToString(type), _objectClassName, key);
        }
        else {
            @throw RLMException(@"%@ is not supported for %@%s set",
                                method, RLMTypeToString(_type), _optional ? "?" : "");
        }
    }

    NSArray *values = [key isEqualToString:@"self"] ? _backingCollection : [_backingCollection valueForKey:key];
    if (_optional) {
        // Filter out NSNull values to match our behavior on managed arrays
        NSIndexSet *nonnull = [values indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger, BOOL *) {
            return obj != NSNull.null;
        }];
        if (nonnull.count < values.count) {
            values = [values objectsAtIndexes:nonnull];
        }
    }
    id result = [values valueForKeyPath:[op stringByAppendingString:@".self"]];
    return sum && !result ? @0 : result;
}

- (nonnull id)objectAtIndex:(NSUInteger)index {
    validateDictionaryBounds(self, index);
    @throw RLMException(@"Not implemented in RLMDictionary");
//    return [_backingCollection objectAtIndex:index];
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

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath characterAtIndex:0] != '@') {
        return _backingCollection ? [_backingCollection valueForKeyPath:keyPath] : [super valueForKeyPath:keyPath];
    }
    if (!_backingCollection) {
        _backingCollection = [NSMutableDictionary new];
    }
    NSUInteger dot = [keyPath rangeOfString:@"."].location;
    if (dot == NSNotFound) {
        return [_backingCollection valueForKeyPath:keyPath];
    }

    NSString *op = [keyPath substringToIndex:dot];
    NSString *key = [keyPath substringFromIndex:dot + 1];
    return [self aggregateProperty:key operation:op method:nil];
}

- (nullable id)valueForKey:(nonnull NSString *)key {
    if ([key isEqualToString:RLMInvalidatedKey]) {
        return @NO; // Unmanaged dictionaries are never invalidated
    }
    if (!_backingCollection) {
        _backingCollection = [NSMutableDictionary new];
    }
    return [_backingCollection valueForKey:key];
}

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable * _Nonnull)buffer count:(NSUInteger)len {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (NSArray *)allKeys {
    return _backingCollection.allKeys;
}

- (NSArray *)allValues {
    return _backingCollection.allValues;
}

- (nullable id)objectForKey:(NSString *)key {
    return [_backingCollection objectForKey:key];
}

- (nullable id)objectForKeyedSubscript:(NSString *)key {
    return [_backingCollection objectForKey:key];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block {
    [_backingCollection enumerateKeysAndObjectsUsingBlock:block];
}

- (NSEnumerator *)objectEnumerator {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)setDictionary:(RLMDictionary *)dictionary {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull value, BOOL *) {
        RLMDictionaryValidateMatchingObjectType(self, key, value);
    }];
    changeDictionary(self, ^{
        [_backingCollection setDictionary: dictionary->_backingCollection];
    });
}

- (void)removeAllObjects {
    changeDictionary(self, ^{
        [_backingCollection removeAllObjects];
    });
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
    changeDictionary(self, ^{
        [_backingCollection removeObjectsForKeys:keyArray];
    });
}

- (void)removeObjectForKey:(id)key {
    changeDictionary(self, ^{
        [_backingCollection removeObjectForKey:key];
    });
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    RLMDictionaryValidateMatchingObjectType(self, key, obj);
    changeDictionary(self, ^{
        [_backingCollection setObject:obj forKey:key];
    });
}

- (void)setObject:(id)obj forKey:(NSString *)key {
    RLMDictionaryValidateMatchingObjectType(self, key, obj);
    changeDictionary(self, ^{
        [_backingCollection setObject:obj forKey:key];
    });
}

- (void)addEntriesFromDictionary:(RLMDictionary *)otherDictionary {
    [otherDictionary enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull value, BOOL *) {
        RLMDictionaryValidateMatchingObjectType(self, key, value);
    }];
    changeDictionary(self, ^{
        [_backingCollection addEntriesFromDictionary:otherDictionary->_backingCollection];
    });

    @throw RLMException(@"Not implemented in RLMDictionary");
}

static void validateDictionaryBounds(__unsafe_unretained RLMDictionary *const dictionary,
                              NSUInteger index,
                              bool allowOnePastEnd=false) {
    NSUInteger max = dictionary->_backingCollection.count + allowOnePastEnd;
    if (index >= max) {
        @throw RLMException(@"Index %llu is out of bounds (must be less than %llu).",
                            (unsigned long long)index, (unsigned long long)max);
    }
}

static bool canAggregate(RLMPropertyType type, bool allowDate) {
    switch (type) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeDecimal128:
            return true;
        case RLMPropertyTypeDate:
            return allowDate;
        default:
            return false;
    }
}

void RLMDictionaryValidateMatchingObjectType(__unsafe_unretained RLMDictionary *const dictionary, __unsafe_unretained id const key, __unsafe_unretained id const value) {
    if (!key) {
        @throw RLMException(@"Invalid nil key for dictionary of '%@'.",
                            dictionary->_objectClassName ?: RLMTypeToString(dictionary->_keyType));
    }
    if (!value && !dictionary->_optional) {
        @throw RLMException(@"Invalid nil value for dictionary of '%@'.",
                            dictionary->_objectClassName ?: RLMTypeToString(dictionary->_type));
    }
    if (dictionary->_type != RLMPropertyTypeObject) {
        if (!RLMValidateValue(value, dictionary->_type, dictionary->_optional, false, nil)) {
            @throw RLMException(@"Invalid value '%@' of type '%@' for expected type '%@%s'.",
                                value, [value class], RLMTypeToString(dictionary->_type),
                                dictionary->_optional ? "?" : "");
        }
        return;
    }
    if (dictionary->_keyType != RLMPropertyTypeObject) {
        if (!RLMValidateValue(key, dictionary->_keyType, false, false, nil)) {
            @throw RLMException(@"Invalid key '%@' of type '%@' for expected type '%@'.",
                                key, [key class], RLMTypeToString(dictionary->_keyType));
        }
        return;
    }
    auto keyObject = RLMDynamicCast<RLMObjectBase>(key);
    auto valueObject = RLMDynamicCast<RLMObjectBase>(value);
    if (!keyObject || !valueObject) {
        return;
    }
    if (!keyObject->_objectSchema || !valueObject->_objectSchema) {
        @throw RLMException(@"Object cannot be inserted unless the schema is initialized. "
                            "This can happen if you try to insert objects into a RLMDictionary / Map from a default value or from an overriden unmanaged initializer (`init()`) or if the key is uninitialized.");
    }
}

static void changeDictionary(__unsafe_unretained RLMDictionary *const dictionary,
                      dispatch_block_t f) {
    if (!dictionary->_backingCollection) {
        dictionary->_backingCollection = [NSMutableDictionary new];
    }
    if (RLMObjectBase *parent = dictionary->_parentObject) {
        [parent willChangeValueForKey:dictionary->_key];
        f();
        [parent didChangeValueForKey:dictionary->_key];
    }
    else {
        f();
    }
}

@end
