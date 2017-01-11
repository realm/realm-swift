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

#import "RLMArray_Private.hpp"

#import "RLMObject_Private.h"
#import "RLMObjectStore.h"
#import "RLMObjectSchema.h"
#import "RLMQueryUtil.hpp"
#import "RLMSwiftSupport.h"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/link_view.hpp>

// See -countByEnumeratingWithState:objects:count
@interface RLMArrayHolder : NSObject {
@public
    std::unique_ptr<id[]> items;
}
@end
@implementation RLMArrayHolder
@end

@interface RLMArray () <RLMThreadConfined_Private>
@end

@implementation RLMArray {
@public
    // Backing array when this instance is unmanaged
    NSMutableArray *_backingArray;
}

template<typename IndexSetFactory>
static void changeArray(__unsafe_unretained RLMArray *const ar,
                        NSKeyValueChange kind, dispatch_block_t f, IndexSetFactory&& is) {
    if (!ar->_backingArray) {
        ar->_backingArray = [NSMutableArray new];
    }

    if (RLMObjectBase *parent = ar->_parentObject) {
        NSIndexSet *indexes = is();
        [parent willChange:kind valuesAtIndexes:indexes forKey:ar->_key];
        f();
        [parent didChange:kind valuesAtIndexes:indexes forKey:ar->_key];
    }
    else {
        f();
    }
}

static void changeArray(__unsafe_unretained RLMArray *const ar, NSKeyValueChange kind, NSUInteger index, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndex:index]; });
}

static void changeArray(__unsafe_unretained RLMArray *const ar, NSKeyValueChange kind, NSRange range, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndexesInRange:range]; });
}

static void changeArray(__unsafe_unretained RLMArray *const ar, NSKeyValueChange kind, NSIndexSet *is, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return is; });
}

- (instancetype)initWithObjectClassName:(__unsafe_unretained NSString *const)objectClassName {
    self = [super init];
    if (self) {
        _objectClassName = objectClassName;
    }
    return self;
}

- (RLMRealm *)realm {
    return nil;
}

//
// Generic implementations for all RLMArray variants
//

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

- (void)addObjects:(id<NSFastEnumeration>)objects {
    for (id obj in objects) {
        [self addObject:obj];
    }
}

- (void)addObject:(RLMObject *)object {
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
    [self replaceObjectAtIndex:index withObject:newValue];
}

//
// Unmanaged RLMArray implementation
//

static void RLMValidateMatchingObjectType(RLMArray *array, RLMObject *object) {
    if (!object) {
        @throw RLMException(@"Object must not be nil");
    }
    if (!object->_objectSchema) {
        @throw RLMException(@"Object cannot be inserted unless the schema is initialized. "
                            "This can happen if you try to insert objects into a RLMArray / List from a default value or from an overriden unmanaged initializer (`init()`).");
    }
    if (![array->_objectClassName isEqualToString:object->_objectSchema.className]) {
        @throw RLMException(@"Object type '%@' does not match RLMArray type '%@'.",
                            object->_objectSchema.className, array->_objectClassName);
    }
}

static void RLMValidateArrayBounds(__unsafe_unretained RLMArray *const ar,
                                   NSUInteger index, bool allowOnePastEnd=false) {
    NSUInteger max = ar->_backingArray.count + allowOnePastEnd;
    if (index >= max) {
        @throw RLMException(@"Index %llu is out of bounds (must be less than %llu).",
                            (unsigned long long)index, (unsigned long long)max);
    }
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMValidateArrayBounds(self, index);
    if (!_backingArray) {
        _backingArray = [NSMutableArray new];
    }
    return [_backingArray objectAtIndex:index];
}

- (NSUInteger)count {
    return _backingArray.count;
}

- (BOOL)isInvalidated {
    return NO;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unused __unsafe_unretained id [])buffer count:(__unused NSUInteger)len {
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
    __autoreleasing RLMArrayHolder *copy = [[RLMArrayHolder alloc] init];
    copy->items = std::make_unique<id[]>(self.count);

    NSUInteger i = 0;
    for (id object in _backingArray) {
        copy->items[i++] = object;
    }

    state->itemsPtr = (__unsafe_unretained id *)(void *)copy->items.get();
    // needs to point to something valid, but the whole point of this is so
    // that it can't be changed
    state->mutationsPtr = state->extra;
    state->state = i;

    return i;
}

- (void)addObjectsFromArray:(NSArray *)array {
    for (id obj in array) {
        RLMValidateMatchingObjectType(self, obj);
    }
    changeArray(self, NSKeyValueChangeInsertion, NSMakeRange(_backingArray.count, array.count), ^{
        [_backingArray addObjectsFromArray:array];
    });
}

- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    RLMValidateMatchingObjectType(self, anObject);
    RLMValidateArrayBounds(self, index, true);
    changeArray(self, NSKeyValueChangeInsertion, index, ^{
        [_backingArray insertObject:anObject atIndex:index];
    });
}

- (void)insertObjects:(id<NSFastEnumeration>)objects atIndexes:(NSIndexSet *)indexes {
    changeArray(self, NSKeyValueChangeInsertion, indexes, ^{
        NSUInteger currentIndex = [indexes firstIndex];
        for (RLMObject *obj in objects) {
            RLMValidateMatchingObjectType(self, obj);
            [_backingArray insertObject:obj atIndex:currentIndex];
            currentIndex = [indexes indexGreaterThanIndex:currentIndex];
        }
    });
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    RLMValidateArrayBounds(self, index);
    changeArray(self, NSKeyValueChangeRemoval, index, ^{
        [_backingArray removeObjectAtIndex:index];
    });
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    changeArray(self, NSKeyValueChangeRemoval, indexes, ^{
        [_backingArray removeObjectsAtIndexes:indexes];
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    RLMValidateMatchingObjectType(self, anObject);
    RLMValidateArrayBounds(self, index);
    changeArray(self, NSKeyValueChangeReplacement, index, ^{
        [_backingArray replaceObjectAtIndex:index withObject:anObject];
    });
}

- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex {
    RLMValidateArrayBounds(self, sourceIndex);
    RLMValidateArrayBounds(self, destinationIndex);
    RLMObjectBase *original = _backingArray[sourceIndex];

    auto start = std::min(sourceIndex, destinationIndex);
    auto len = std::max(sourceIndex, destinationIndex) - start + 1;
    changeArray(self, NSKeyValueChangeReplacement, {start, len}, ^{
        [_backingArray removeObjectAtIndex:sourceIndex];
        [_backingArray insertObject:original atIndex:destinationIndex];
    });
}

- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2 {
    RLMValidateArrayBounds(self, index1);
    RLMValidateArrayBounds(self, index2);

    changeArray(self, NSKeyValueChangeReplacement, ^{
        [_backingArray exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    }, [=] {
        NSMutableIndexSet *set = [[NSMutableIndexSet alloc] initWithIndex:index1];
        [set addIndex:index2];
        return set;
    });
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    RLMValidateMatchingObjectType(self, object);
    NSUInteger index = 0;
    for (RLMObject *cmp in _backingArray) {
        if (RLMObjectBaseAreEqual(object, cmp)) {
            return index;
        }
        index++;
    }
    return NSNotFound;
}

- (void)removeAllObjects {
    changeArray(self, NSKeyValueChangeRemoval, NSMakeRange(0, _backingArray.count), ^{
        [_backingArray removeAllObjects];
    });
}

- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    RLMResults *results = [self objectsWhere:predicateFormat args:args];
    va_end(args);
    return results;
}

- (RLMResults *)objectsWhere:(NSString *)predicateFormat args:(va_list)args
{
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (id)valueForKeyPath:(NSString *)keyPath {
    if (!_backingArray) {
        return [super valueForKeyPath:keyPath];
    }
    // Although delegating to valueForKeyPath: here would allow to support
    // nested key paths as well, limiting functionality gives consistency
    // between unmanaged and managed arrays.
    if ([keyPath characterAtIndex:0] == '@') {
        NSRange operatorRange = [keyPath rangeOfString:@"." options:NSLiteralSearch];
        if (operatorRange.location != NSNotFound) {
            NSString *operatorKeyPath = [keyPath substringFromIndex:operatorRange.location + 1];
            if ([operatorKeyPath rangeOfString:@"."].location != NSNotFound) {
                @throw RLMException(@"Nested key paths are not supported yet for KVC collection operators.");
            }
        }
    }
    return [_backingArray valueForKeyPath:keyPath];
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:RLMInvalidatedKey]) {
        return @NO; // Unmanaged arrays are never invalidated
    }
    if (!_backingArray) {
        return @[];
    }
    return [_backingArray valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    [_backingArray setValue:value forKey:key];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    if (!_backingArray) {
        return NSNotFound;
    }
    return [_backingArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger, BOOL *) {
        return [predicate evaluateWithObject:obj];
    }];
}

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
    if (!_backingArray) {
        _backingArray = [NSMutableArray new];
    }
    return [_backingArray objectsAtIndexes:indexes];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    RLMValidateArrayObservationKey(keyPath, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

//
// Methods unsupported on unmanaged RLMArray instances
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate
{
    @throw RLMException(@"This method may only be called on RLMArray instances retrieved from an RLMRealm");
}

- (RLMResults *)sortedResultsUsingKeyPath:(NSString *)keyPath ascending:(BOOL)ascending
{
    return [self sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:keyPath ascending:ascending]]];
}

- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending
{
    return [self sortedResultsUsingKeyPath:property ascending:ascending];
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties
{
    @throw RLMException(@"This method may only be called on RLMArray instances retrieved from an RLMRealm");
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMArray *, RLMCollectionChange *, NSError *))block {
    @throw RLMException(@"This method may only be called on RLMArray instances retrieved from an RLMRealm");
}
#pragma clang diagnostic pop

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    NSUInteger index = [self indexOfObjectWhere:predicateFormat args:args];
    va_end(args);
    return index;
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args
{
    return [self indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:predicateFormat
                                                                   arguments:args]];
}

#pragma mark - Superclass Overrides

- (NSString *)description {
    return [self descriptionWithMaxDepth:RLMDescriptionMaxDepth];
}

- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth {
    return RLMDescriptionWithMaxDepth(@"RLMArray", self, depth);
}

#pragma mark - Thread Confined Protocol Conformance

- (std::unique_ptr<realm::ThreadSafeReferenceBase>)makeThreadSafeReference {
    REALM_TERMINATE("Unexpected handover of unmanaged `RLMArray`");
}

- (id)objectiveCMetadata {
    REALM_TERMINATE("Unexpected handover of unmanaged `RLMArray`");
}

+ (instancetype)objectWithThreadSafeReference:(__unused std::unique_ptr<realm::ThreadSafeReferenceBase>)reference
                                     metadata:(__unused id)metadata
                                        realm:(__unused RLMRealm *)realm {
    REALM_TERMINATE("Unexpected handover of unmanaged `RLMArray`");
}

@end

@implementation RLMSortDescriptor

+ (instancetype)sortDescriptorWithKeyPath:(NSString *)keyPath ascending:(BOOL)ascending {
    RLMSortDescriptor *desc = [[RLMSortDescriptor alloc] init];
    desc->_keyPath = keyPath;
    desc->_ascending = ascending;
    return desc;
}

+ (instancetype)sortDescriptorWithProperty:(NSString *)propertyName ascending:(BOOL)ascending {
    return [RLMSortDescriptor sortDescriptorWithKeyPath:propertyName ascending:ascending];
}

- (instancetype)reversedSortDescriptor {
    return [self.class sortDescriptorWithKeyPath:_keyPath ascending:!_ascending];
}

- (NSString *)property {
    return _keyPath;
}

@end
