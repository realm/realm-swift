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

#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"
#import "RLMUtil.hpp"

#import "list.hpp"
#import "results.hpp"

#import <realm/table_view.hpp>
#import <objc/runtime.h>

//
// RLMArray implementation
//
@implementation RLMArrayLinkView {
@public
    realm::List _backingList;
    RLMRealm *_realm;
    __unsafe_unretained RLMObjectSchema *_containingObjectSchema;
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

+ (RLMArrayLinkView *)arrayWithObjectClassName:(NSString *)objectClassName
                                          view:(realm::LinkViewRef)view
                                         realm:(RLMRealm *)realm
                                           key:(NSString *)key
                                  parentSchema:(RLMObjectSchema *)parentSchema {
    RLMArrayLinkView *ar = [[RLMArrayLinkView alloc] initWithObjectClassName:objectClassName];
    ar->_backingList = realm::List(realm->_realm, view);
    ar->_realm = realm;
    ar->_objectSchema = ar->_realm.schema[objectClassName];
    ar->_containingObjectSchema = parentSchema;
    ar->_key = key;
    return ar;
}

void RLMValidateArrayObservationKey(__unsafe_unretained NSString *const keyPath,
                                    __unsafe_unretained RLMArray *const array) {
    if (![keyPath isEqualToString:RLMInvalidatedKey]) {
        @throw RLMException(@"[<%@ %p> addObserver:forKeyPath:options:context:] is not supported. Key path: %@",
                            [array class], array, keyPath);
    }
}

void RLMEnsureArrayObservationInfo(std::unique_ptr<RLMObservationInfo>& info,
                                   __unsafe_unretained NSString *const keyPath,
                                   __unsafe_unretained RLMArray *const array,
                                   __unsafe_unretained id const observed) {
    RLMValidateArrayObservationKey(keyPath, array);
    if (!info && array.class == [RLMArrayLinkView class]) {
        RLMArrayLinkView *lv = static_cast<RLMArrayLinkView *>(array);
        info = std::make_unique<RLMObservationInfo>(lv->_containingObjectSchema,
                                                    lv->_backingList.get_origin_row_index(),
                                                    observed);
    }
}

//
// validation helpers
//
[[gnu::noinline]]
[[noreturn]]
static void throwError() {
    try {
        throw;
    }
    catch (realm::InvalidTransactionException const&) {
        @throw RLMException(@"Cannot modify managed RLMArray outside of a write transaction");
    }
    catch (realm::IncorrectThreadException const&) {
        @throw RLMException(@"Realm accessed from incorrect thread");
    }
    catch (realm::List::InvalidatedException const&) {
        @throw RLMException(@"RLMArray has been invalidated or the containing object has been deleted");
    }
    catch (realm::List::OutOfBoundsIndexException const& e) {
        @throw RLMException(@"Index %zu is out of bounds (must be less than %zu)",
                            e.requested, e.valid_count);
    }
}

template<typename Function>
static auto translateErrors(Function&& f) {
    try {
        return f();
    }
    catch (...) {
        throwError();
    }
}

static void validateObjectToAdd(__unsafe_unretained RLMArrayLinkView *const ar,
                                __unsafe_unretained RLMObject *const obj) {
    if (!obj) {
        @throw RLMException(@"Cannot add `nil` to RLMArray<%@>", ar->_objectClassName);
    }

    NSString *objectClassName = obj->_objectSchema.className;
    if (![objectClassName isEqualToString:ar->_objectClassName]) {
        @throw RLMException(@"Cannot add object of type '%@' to RLMArray<%@>",
                            objectClassName, ar->_objectClassName);
    }

    if (obj->_realm != ar.realm) {
        [ar.realm addObject:obj];
    }
    else if (obj->_realm && !obj->_row.is_attached()) {
        @throw RLMException(@"Object has been deleted or invalidated.");
    }
}

template<typename IndexSetFactory>
static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar,
                        NSKeyValueChange kind, dispatch_block_t f, IndexSetFactory&& is) {
    translateErrors([&] { ar->_backingList.verify_in_transaction(); });
    RLMObservationInfo *info = RLMGetObservationInfo(ar->_observationInfo.get(),
                                                     ar->_backingList.get_origin_row_index(),
                                                     ar->_containingObjectSchema);
    if (info) {
        NSIndexSet *indexes = is();
        info->willChange(ar->_key, kind, indexes);
        try {
            f();
        }
        catch (...) {
            info->didChange(ar->_key, kind, indexes);
            throwError();
        }
        info->didChange(ar->_key, kind, indexes);
    }
    else {
        translateErrors([&] { f(); });
    }
}

static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar, NSKeyValueChange kind, NSUInteger index, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndex:index]; });
}

static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar, NSKeyValueChange kind, NSRange range, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndexesInRange:range]; });
}

static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar, NSKeyValueChange kind, NSIndexSet *is, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return is; });
}

//
// public method implementations
//
- (RLMRealm *)realm {
    return _realm;
}

- (NSUInteger)count {
    return translateErrors([&] { return _backingList.size(); });
}

- (BOOL)isInvalidated {
    return translateErrors([&] { return !_backingList.is_valid(); });
}

- (BOOL)isEqual:(id)object {
    if (RLMArrayLinkView *linkView = RLMDynamicCast<RLMArrayLinkView>(object)) {
        return linkView->_backingList == _backingList;
    }
    return NO;
}

- (NSUInteger)hash {
    return std::hash<realm::List>()(_backingList);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    __autoreleasing RLMFastEnumerator *enumerator;
    if (state->state == 0) {
        translateErrors([&] { _backingList.verify_attached(); });

        enumerator = [[RLMFastEnumerator alloc] initWithCollection:self objectSchema:_objectSchema];
        state->extra[0] = (long)enumerator;
        state->extra[1] = self.count;
    }
    else {
        enumerator = (__bridge id)(void *)state->extra[0];
    }

    return [enumerator countByEnumeratingWithState:state count:len];
}

- (id)objectAtIndex:(NSUInteger)index {
    return RLMCreateObjectAccessor(_realm, _objectSchema,
                                   translateErrors([&] { return _backingList.get(index).get_index(); }));
}

static void RLMInsertObject(RLMArrayLinkView *ar, RLMObject *object, NSUInteger index) {
    if (index == NSUIntegerMax) {
        index = translateErrors([&] { return ar->_backingList.size(); });
    }

    validateObjectToAdd(ar, object);
    changeArray(ar, NSKeyValueChangeInsertion, index, ^{
        ar->_backingList.insert(index, object->_row.get_index());
    });
}

- (void)addObject:(RLMObject *)object {
    RLMInsertObject(self, object, NSUIntegerMax);
}

- (void)insertObject:(RLMObject *)object atIndex:(NSUInteger)index {
    RLMInsertObject(self, object, index);
}

- (void)insertObjects:(id<NSFastEnumeration>)objects atIndexes:(NSIndexSet *)indexes {
    changeArray(self, NSKeyValueChangeInsertion, indexes, ^{
        NSUInteger index = [indexes firstIndex];
        for (RLMObject *obj in objects) {
            validateObjectToAdd(self, obj);
            _backingList.insert(index, obj->_row.get_index());
            index = [indexes indexGreaterThanIndex:index];
        }
    });
}


- (void)removeObjectAtIndex:(NSUInteger)index {
    changeArray(self, NSKeyValueChangeRemoval, index, ^{
        _backingList.remove(index);
    });
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    changeArray(self, NSKeyValueChangeRemoval, indexes, ^{
        [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *) {
            _backingList.remove(idx);
        }];
    });
}

- (void)addObjectsFromArray:(NSArray *)array {
    changeArray(self, NSKeyValueChangeInsertion, NSMakeRange(self.count, array.count), ^{
        for (RLMObject *obj in array) {
            validateObjectToAdd(self, obj);
            _backingList.add(obj->_row.get_index());
        }
    });
}

- (void)removeAllObjects {
    changeArray(self, NSKeyValueChangeRemoval, NSMakeRange(0, self.count), ^{
        _backingList.remove_all();
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(RLMObject *)object {
    validateObjectToAdd(self, object);
    changeArray(self, NSKeyValueChangeReplacement, index, ^{
        _backingList.set(index, object->_row.get_index());
    });
}

- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex {
    auto start = std::min(sourceIndex, destinationIndex);
    auto len = std::max(sourceIndex, destinationIndex) - start + 1;
    changeArray(self, NSKeyValueChangeReplacement, {start, len}, ^{
        _backingList.move(sourceIndex, destinationIndex);
    });
}

- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2 {
    changeArray(self, NSKeyValueChangeReplacement, ^{
        _backingList.swap(index1, index2);
    }, [=] {
        NSMutableIndexSet *set = [[NSMutableIndexSet alloc] initWithIndex:index1];
        [set addIndex:index2];
        return set;
    });
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    if (object.invalidated) {
        @throw RLMException(@"Object has been deleted or invalidated");
    }

    // check that object types align
    if (![_objectClassName isEqualToString:object->_objectSchema.className]) {
        @throw RLMException(@"Object of type (%@) does not match RLMArray type (%@)",
                            object->_objectSchema.className, _objectClassName);
    }

    return translateErrors([&] { return RLMConvertNotFound(_backingList.find(object->_row)); });
}

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:@"@"]) {
        // Delegate KVC collection operators to RLMResults
        auto query = translateErrors([&] { return _backingList.get_query(); });
        RLMResults *results = [RLMResults resultsWithObjectSchema:_objectSchema
                                                          results:realm::Results(_realm->_realm, std::move(query))];
        return [results valueForKeyPath:keyPath];
    }
    return [super valueForKeyPath:keyPath];
}

- (id)valueForKey:(NSString *)key {
    // Ideally we'd use "@invalidated" for this so that "invalidated" would use
    // normal array KVC semantics, but observing @things works very oddly (when
    // it's part of a key path, it's triggered automatically when array index
    // changes occur, and can't be sent explicitly, but works normally when it's
    // the entire key path), and an RLMArrayLinkView *can't* have objects where
    // invalidated is true, so we're not losing much.
    if ([key isEqualToString:RLMInvalidatedKey]) {
        return @(!_backingList.is_valid());
    }

    translateErrors([&] { _backingList.verify_attached(); });
    return RLMCollectionValueForKey(self, key);
}

- (void)setValue:(id)value forKey:(NSString *)key {
    translateErrors([&] { _backingList.verify_in_transaction(); });
    RLMCollectionSetValueForKey(self, key, value);
}

- (void)deleteObjectsFromRealm {
    // delete all target rows from the realm
    RLMTrackDeletions(_realm, ^{
        translateErrors([&] { _backingList.delete_all(); });
    });
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties {
    auto order = RLMSortOrderFromDescriptors(*_objectSchema.table, properties);
    auto results = translateErrors([&] { return _backingList.sort(std::move(order)); });
    return [RLMResults resultsWithObjectSchema:_objectSchema results:std::move(results)];
}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    auto query = RLMPredicateToQuery(predicate, _objectSchema, _realm.schema, *_realm.group);
    auto results = translateErrors([&] { return _backingList.filter(std::move(query)); });
    return [RLMResults resultsWithObjectSchema:_objectSchema results:std::move(results)];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    auto query = translateErrors([&] { return _backingList.get_query(); });
    query.and_query(RLMPredicateToQuery(predicate, _objectSchema, _realm.schema, *_realm.group));
    return RLMConvertNotFound(query.find());
}

- (NSArray *)objectsAtIndexes:(__unused NSIndexSet *)indexes {
    // FIXME: this is called by KVO when array changes are made. It's not clear
    // why, and returning nil seems to work fine.
    return nil;
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureArrayObservationInfo(_observationInfo, keyPath, self, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (NSUInteger)indexInSource:(NSUInteger)index {
    return _backingList.get_unchecked(index);
}

- (realm::TableView)tableView {
    return translateErrors([&] { return _backingList.get_query(); }).find_all();
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMArray *, RLMCollectionChange *, NSError *))block {
    [_realm verifyNotificationsAreSupported];
    return RLMAddNotificationBlock(self, _backingList, block);
}
#pragma clang diagnostic pop

@end
