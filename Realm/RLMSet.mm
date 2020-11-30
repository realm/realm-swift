////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMSet_Private.hpp"

#import "RLMObjectSchema.h"
#import "RLMObjectStore.h"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUtil.hpp"
#import "RLMConstants.h"

// See -countByEnumeratingWithState:objects:count
@interface RLMSetHolder : NSObject {
@public
    std::unique_ptr<id[]> items;
}
@end
@implementation RLMSetHolder //TODO: Is this required?
@end

@interface RLMSet () <RLMThreadConfined_Private>
@end

@implementation RLMSet {
@public
    // Backing set when this instance is unmanaged
    NSMutableOrderedSet *_backingSet;
}

#pragma mark - Initializers

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

#pragma mark - Convenience wrappers used for all RLMSet types

- (void)addObjects:(id<NSFastEnumeration>)objects {
    for (id obj in objects) {
        [self addObject:obj];
    }
}

- (void)addObject:(id)object {
    [self insertObject:object atIndex:self.count];
}

- (void)removeLastObject {
    NSUInteger count = self.count;
    if (count) {
        [self removeObjectAtIndex:count-1];
    }
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)index {
    REALM_TERMINATE("Replacing objects at an indexed subscript is not supported on RLMSet");
}

- (void)intersectSet:(RLMSet<id> *)set {
    for (id obj in set) {
        RLMSetValidateMatchingObjectType(self, obj);
    }
    [_backingSet intersectOrderedSet:set->_backingSet];
}

- (void)minusSet:(RLMSet<id> *)set {
    for (id obj in set) {
        RLMSetValidateMatchingObjectType(self, obj);
    }
    [_backingSet minusOrderedSet:set->_backingSet];
}

- (void)unionSet:(RLMSet<id> *)set {
    for (id obj in set) {
        RLMSetValidateMatchingObjectType(self, obj);
    }
    [_backingSet unionOrderedSet:set->_backingSet];
}

- (BOOL)intersectsSet:(RLMSet<id> *)set {
    for (id obj in set) {
        RLMSetValidateMatchingObjectType(self, obj);
    }
    return [_backingSet intersectsSet:set->_backingSet.set];
}

- (BOOL)isSubsetOfSet:(RLMSet<id> *)set {
    for (id obj in set) {
        RLMSetValidateMatchingObjectType(self, obj);
    }
    return [_backingSet isSubsetOfSet:set->_backingSet.set];
}

- (RLMResults *)sortedResultsUsingKeyPath:(NSString *)keyPath ascending:(BOOL)ascending {
    return [self sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:keyPath ascending:ascending]]];
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    NSUInteger index = [self indexOfObjectWhere:predicateFormat args:args];
    va_end(args);
    return index;
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:predicateFormat
                                                                   arguments:args]];
}

#pragma mark - Unmanaged RLMSet implementation

- (RLMRealm *)realm {
    return nil;
}

- (id)firstObject {
    if (self.count) {
        return [self objectAtIndex:0];
    }
    return nil;
}

- (id)lastObject {
    NSUInteger count = self.count;
    if (count) {
        return [self objectAtIndex:count-1];
    }
    return nil;
}

- (id)objectAtIndex:(NSUInteger)index {
    validateSetBounds(self, index);
    return [_backingSet.array objectAtIndex:index];
}

- (NSUInteger)count {
    return _backingSet.count;
}

- (NSArray<id> *)array {
    return _backingSet.array;
}

- (BOOL)isInvalidated {
    return NO;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(__unused NSUInteger)len {
    if (state->state != 0) {
        return 0;
    }

    // We need to enumerate a copy of the backing array so that it doesn't
    // reflect changes made during enumeration. This copy has to be autoreleased
    // (since there's nowhere for us to store a strong reference), and uses
    // RLMArrayHolder rather than an NSArray because NSArray doesn't guarantee
    // that it'll use a single contiguous block of memory, and if it doesn't
    // we'd need to forward multiple calls to this method to the same NSArray,
    // which would require holding a reference to it somewhere.
    __autoreleasing RLMSetHolder *copy = [[RLMSetHolder alloc] init];
    copy->items = std::make_unique<id[]>(self.count);

    NSUInteger i = 0;
    for (id object in _backingSet) {
        copy->items[i++] = object;
    }

    state->itemsPtr = (__unsafe_unretained id *)(void *)copy->items.get();
    // needs to point to something valid, but the whole point of this is so
    // that it can't be changed
    state->mutationsPtr = state->extra;
    state->state = i;

    return i;
}


template<typename IndexSetFactory>
static void changeSet(__unsafe_unretained RLMSet *const set,
                      NSKeyValueChange kind, dispatch_block_t f, IndexSetFactory&& is) {
    if (!set->_backingSet) {
        set->_backingSet = [NSMutableOrderedSet new];
    }

    if (RLMObjectBase *parent = set->_parentObject) {
        NSIndexSet *indexes = is();
        [parent willChange:kind valuesAtIndexes:indexes forKey:set->_key];
        f();
        [parent didChange:kind valuesAtIndexes:indexes forKey:set->_key];
    }
    else {
        f();
    }
}

static void changeSet(__weak RLMSet *const set, NSKeyValueChange kind,
                        NSUInteger index, dispatch_block_t f) {
    changeSet(set, kind, f, [=] { return [NSIndexSet indexSetWithIndex:index]; });
}

static void changeSet(__weak RLMSet *const set, NSKeyValueChange kind,
                        NSRange range, dispatch_block_t f) {
    changeSet(set, kind, f, [=] { return [NSIndexSet indexSetWithIndexesInRange:range]; });
}

static void changeSet(__weak RLMSet *const set, NSKeyValueChange kind,
                        NSIndexSet *is, dispatch_block_t f) {
    changeSet(set, kind, f, [=] { return is; });
}

static void validateSetBounds(__unsafe_unretained RLMSet *const set,
                              NSUInteger index,
                              bool allowOnePastEnd=false) {
    NSUInteger max = set->_backingSet.count + allowOnePastEnd;
    if (index >= max) {
        @throw RLMException(@"Index %llu is out of bounds (must be less than %llu).",
                            (unsigned long long)index, (unsigned long long)max);
    }
}

- (void)addObjectsFromSet:(RLMSet *)set {
    for (id obj in set) {
        RLMSetValidateMatchingObjectType(self, obj);
    }
    changeSet(self, NSKeyValueChangeInsertion, NSMakeRange(_backingSet.count, set.count), ^{
        [_backingSet addObjectsFromArray:[set->_backingSet.array copy]];
    });
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index {
    RLMSetValidateMatchingObjectType(self, anObject);
    validateSetBounds(self, index, true);
    changeSet(self, NSKeyValueChangeInsertion, index, ^{
        [_backingSet insertObject:anObject atIndex:index];
    });
}

- (void)insertObjects:(id<NSFastEnumeration>)objects atIndexes:(NSIndexSet *)indexes {
    changeSet(self, NSKeyValueChangeInsertion, indexes, ^{
        NSUInteger currentIndex = [indexes firstIndex];
        for (RLMObject *obj in objects) {
            RLMSetValidateMatchingObjectType(self, obj);
            [_backingSet insertObject:obj atIndex:currentIndex];
            currentIndex = [indexes indexGreaterThanIndex:currentIndex];
        }
    });
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    validateSetBounds(self, index);
    changeSet(self, NSKeyValueChangeRemoval, index, ^{
        [_backingSet removeObjectAtIndex:index];
    });
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    changeSet(self, NSKeyValueChangeRemoval, indexes, ^{
        [_backingSet removeObjectsAtIndexes:indexes];
    });
}

- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex {
    validateSetBounds(self, sourceIndex);
    validateSetBounds(self, destinationIndex);
    id original = _backingSet.array[sourceIndex];

    auto start = std::min(sourceIndex, destinationIndex);
    auto len = std::max(sourceIndex, destinationIndex) - start + 1;
    changeSet(self, NSKeyValueChangeReplacement, {start, len}, ^{
        [_backingSet removeObjectAtIndex:sourceIndex];
        [_backingSet insertObject:original atIndex:destinationIndex];
    });
}

- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2 {
    validateSetBounds(self, index1);
    validateSetBounds(self, index2);

    changeSet(self, NSKeyValueChangeReplacement, ^{
        [_backingSet exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    }, [=] {
        NSMutableIndexSet *set = [[NSMutableIndexSet alloc] initWithIndex:index1];
        [set addIndex:index2];
        return set;
    });
}

- (NSUInteger)indexOfObject:(id)object {
    RLMSetValidateMatchingObjectType(self, object);
    if (!_backingSet) {
        return NSNotFound;
    }
    if (_type != RLMPropertyTypeObject) {
        return [_backingSet.array indexOfObject:object];
    }

    NSUInteger index = 0;
    for (RLMObjectBase *cmp in _backingSet) {
        if (RLMObjectBaseAreEqual(object, cmp)) {
            return index;
        }
        index++;
    }
    return NSNotFound;
}

- (void)removeAllObjects {
    changeSet(self, NSKeyValueChangeRemoval, NSMakeRange(0, _backingSet.count), ^{
        [_backingSet removeAllObjects];
    });
}

- (void)removeObject:(id)object {
    RLMSetValidateMatchingObjectType(self, object);
    changeSet(self, NSKeyValueChangeRemoval, NSMakeRange(0, _backingSet.count), ^{
        // passing in a matching object and calling `[_backingSet removeObject:object]`
        // does not guarantee the object will be deleted. For example if we try to delete
        // an object that is IN the set but was derived from a Results collection the `removeObject:`
        // will fail. To get around this, find the index of the object you are trying to delete
        // and remove it by index.
        [_backingSet removeObjectAtIndex:[self indexOfObject:object]];
    });
}

- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    RLMResults *results = [self objectsWhere:predicateFormat args:args];
    va_end(args);
    return results;
}

- (RLMResults *)objectsWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
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

- (RLMPropertyType)typeForProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"self"]) {
        return _type;
    }

    RLMObjectSchema *objectSchema;
    if (_backingSet.count) {
        objectSchema = [_backingSet.array[0] objectSchema];
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

    bool allowDate = false;
    bool sum = false;
    if ([op isEqualToString:@"@min"] || [op isEqualToString:@"@max"]) {
        allowDate = true;
    }
    else if ([op isEqualToString:@"@sum"]) {
        sum = true;
    }
    else if (![op isEqualToString:@"@avg"]) {
        // Just delegate to NSSet for all other operators
        return [_backingSet valueForKeyPath:[op stringByAppendingPathExtension:key]];
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

    // `valueForKeyPath` on NSSet will only return distinct values, which is an
    // issue as the realm::object_store::Set aggregate methods will calculate
    // the result based on each element of a property regardless of uniqueness.
    // To get around this we will need to use the `array` property of the NSMutableOrderedSet

    NSArray *values = [key isEqualToString:@"self"] ? _backingSet.array : [_backingSet.array valueForKey:key];
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

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath characterAtIndex:0] != '@') {
        return _backingSet ? [_backingSet valueForKeyPath:keyPath] : [super valueForKeyPath:keyPath];
    }

    if (!_backingSet) {
        _backingSet = [NSMutableOrderedSet new];
    }

    NSUInteger dot = [keyPath rangeOfString:@"."].location;
    if (dot == NSNotFound) {
        return [_backingSet valueForKeyPath:keyPath];
    }

    NSString *op = [keyPath substringToIndex:dot];
    NSString *key = [keyPath substringFromIndex:dot + 1];
    return [self aggregateProperty:key operation:op method:nil];
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:RLMInvalidatedKey]) {
        return @NO; // Unmanaged sets are never invalidated
    }
    if (!_backingSet) {
        _backingSet = [NSMutableOrderedSet new];
    }
    return [_backingSet valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"self"]) {
        RLMSetValidateMatchingObjectType(self, value);
        [_backingSet removeAllObjects];
        [_backingSet addObject:value];
        return;
    }
    else if (_type == RLMPropertyTypeObject) {
        [_backingSet setValue:value forKey:key];
    }
    else {
        [self setValue:value forUndefinedKey:key];
    }
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

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    if (!_backingSet) {
        return NSNotFound;
    }

    return [_backingSet indexOfObjectPassingTest:^BOOL(id obj, NSUInteger, BOOL *) {
        return [predicate evaluateWithObject:obj];
    }];
}

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
    if (!_backingSet) {
        _backingSet = [NSMutableOrderedSet new];
    }
    return [_backingSet objectsAtIndexes:indexes];
}

- (BOOL)isEqual:(id)object {
    if (auto set = RLMDynamicCast<RLMSet>(object)) {
        return !set.realm
        && ((_backingSet.count == 0 && set->_backingSet.count == 0)
            || [_backingSet isEqual:set->_backingSet]);
    }
    return NO;
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options context:(void *)context {
    RLMValidateSetObservationKey(keyPath, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

void RLMSetValidateMatchingObjectType(__unsafe_unretained RLMSet *const set,
                                      __unsafe_unretained id const value) {
    if (!value && !set->_optional) {
        @throw RLMException(@"Invalid nil value for set of '%@'.",
                            set->_objectClassName ?: RLMTypeToString(set->_type));
    }
    if (set->_type != RLMPropertyTypeObject) {
        if (!RLMValidateValue(value, set->_type, set->_optional, RLMCollectionTypeNone, nil)) {
            @throw RLMException(@"Invalid value '%@' of type '%@' for expected type '%@%s'.",
                                value, [value class], RLMTypeToString(set->_type),
                                set->_optional ? "?" : "");
        }
        return;
    }

    auto object = RLMDynamicCast<RLMObjectBase>(value);
    if (!object) {
        return;
    }
    if (!object->_objectSchema) {
        @throw RLMException(@"Object cannot be inserted unless the schema is initialized. "
                            "This can happen if you try to insert objects into a RLMSet / Set from a default value or from an overriden unmanaged initializer (`init()`).");
    }
    if (![set->_objectClassName isEqualToString:object->_objectSchema.className]) {
        @throw RLMException(@"Object of type '%@' does not match RLMSet type '%@'.",
                            object->_objectSchema.className, set->_objectClassName);
    }
}


#pragma mark - Methods unsupported on unmanaged RLMSet instances

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    @throw RLMException(@"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties {
    @throw RLMException(@"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

- (RLMResults *)distinctResultsUsingKeyPaths:(NSArray<NSString *> *)keyPaths {
    @throw RLMException(@"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSet *, RLMCollectionChange *, NSError *))block {
    return [self addNotificationBlock:block queue:nil];
}
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMArray *, RLMCollectionChange *, NSError *))block
                                         queue:(nullable dispatch_queue_t)queue {
    @throw RLMException(@"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

- (instancetype)freeze {
    @throw RLMException(@"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

#pragma mark - Thread Confined Protocol Conformance

- (realm::ThreadSafeReference)makeThreadSafeReference {
    REALM_TERMINATE("Unexpected handover of unmanaged `RLMSet`");
}

- (id)objectiveCMetadata {
    REALM_TERMINATE("Unexpected handover of unmanaged `RLMSet`");
}

+ (instancetype)objectWithThreadSafeReference:(realm::ThreadSafeReference)reference
                                     metadata:(id)metadata
                                        realm:(RLMRealm *)realm {
    REALM_TERMINATE("Unexpected handover of unmanaged `RLMSet`");
}

#pragma clang diagnostic pop // unused parameter warning

#pragma mark - Superclass Overrides

- (NSString *)description {
    return [self descriptionWithMaxDepth:RLMDescriptionMaxDepth];
}

- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth {
    return RLMDescriptionWithMaxDepth(@"RLMSet", self, depth);
}
@end
