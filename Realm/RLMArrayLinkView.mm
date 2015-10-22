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

#import <realm/table_view.hpp>
#import <objc/runtime.h>

//
// RLMArray implementation
//
@implementation RLMArrayLinkView {
@public
    realm::LinkViewRef _backingLinkView;
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
    ar->_backingLinkView = view;
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
                                                    lv->_backingLinkView->get_origin_row_index(),
                                                    observed);
    }
}

//
// validation helpers
//
static inline void RLMLinkViewArrayValidateAttached(__unsafe_unretained RLMArrayLinkView *const ar) {
    if (!ar->_backingLinkView->is_attached()) {
        @throw RLMException(@"RLMArray is no longer valid");
    }
    RLMCheckThread(ar->_realm);
}
static inline void RLMLinkViewArrayValidateInWriteTransaction(__unsafe_unretained RLMArrayLinkView *const ar) {
    // first verify attached
    RLMLinkViewArrayValidateAttached(ar);

    if (!ar->_realm->_inWriteTransaction) {
        @throw RLMException(@"Can't mutate a persisted array outside of a write transaction.");
    }
}
static inline void RLMValidateObjectClass(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained NSString *const expected) {
    if (!obj) {
        @throw RLMException(@"Cannot add `nil` to RLMArray<%@>", expected);
    }

    NSString *objectClassName = obj->_objectSchema.className;
    if (![objectClassName isEqualToString:expected]) {
        @throw RLMException(@"Cannot add object of type '%@' to RLMArray<%@>", objectClassName, expected);
    }
}

template<typename IndexSetFactory>
static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar, NSKeyValueChange kind, dispatch_block_t f, IndexSetFactory&& is) {
    RLMObservationInfo *info = RLMGetObservationInfo(ar->_observationInfo.get(),
                                                     ar->_backingLinkView->get_origin_row_index(),
                                                     ar->_containingObjectSchema);
    if (info) {
        NSIndexSet *indexes = is();
        info->willChange(ar->_key, kind, indexes);
        f();
        info->didChange(ar->_key, kind, indexes);
    }
    else {
        f();
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
    RLMLinkViewArrayValidateAttached(self);
    return _backingLinkView->size();
}

- (BOOL)isInvalidated {
    return !_backingLinkView->is_attached();
}

// These two methods take advantage of that LinkViews are interned, so there's
// only ever at most one LinkView object per SharedGroup for a given row+col.
- (BOOL)isEqual:(id)object {
    if (RLMArrayLinkView *linkView = RLMDynamicCast<RLMArrayLinkView>(object)) {
        return linkView->_backingLinkView.get() == _backingLinkView.get();
    }
    return NO;
}

- (NSUInteger)hash {
    return reinterpret_cast<NSUInteger>(_backingLinkView.get());
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    __autoreleasing RLMFastEnumerator *enumerator;
    if (state->state == 0) {
        RLMLinkViewArrayValidateAttached(self);

        enumerator = [[RLMFastEnumerator alloc] initWithCollection:self objectSchema:_objectSchema];
        state->extra[0] = (long)enumerator;
        state->extra[1] = self.count;
    }
    else {
        enumerator = (__bridge id)(void *)state->extra[0];
    }

    return [enumerator countByEnumeratingWithState:state count:len];
}

static void RLMValidateArrayBounds(__unsafe_unretained RLMArrayLinkView *const ar,
                                   NSUInteger index, bool allowOnePastEnd=false) {
    NSUInteger max = ar->_backingLinkView->size() + allowOnePastEnd;
    if (index >= max) {
        @throw RLMException(@"Index %llu is out of bounds (must be less than %llu).",
                             (unsigned long long)index, (unsigned long long)max);
    }
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMLinkViewArrayValidateAttached(self);
    RLMValidateArrayBounds(self, index);
    return RLMCreateObjectAccessor(_realm, _objectSchema, _backingLinkView->get(index).get_index());
}

static void RLMInsertObject(RLMArrayLinkView *ar, RLMObject *object, NSUInteger index) {
    RLMLinkViewArrayValidateInWriteTransaction(ar);
    RLMValidateObjectClass(object, ar.objectClassName);

    if (index == NSUIntegerMax) {
        index = ar->_backingLinkView->size();
    }
    else {
        RLMValidateArrayBounds(ar, index, true);
    }

    if (object->_realm != ar.realm) {
        [ar.realm addObject:object];
    }
    else if (object->_realm) {
        RLMVerifyAttached(object);
    }

    changeArray(ar, NSKeyValueChangeInsertion, index, ^{
        ar->_backingLinkView->insert(index, object->_row.get_index());
    });
}

- (void)addObject:(RLMObject *)object {
    RLMInsertObject(self, object, NSUIntegerMax);
}

- (void)insertObject:(RLMObject *)object atIndex:(NSUInteger)index {
    RLMInsertObject(self, object, index);
}

- (void)insertObjects:(id<NSFastEnumeration>)objects atIndexes:(NSIndexSet *)indexes {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    changeArray(self, NSKeyValueChangeInsertion, indexes, ^{
        NSUInteger index = [indexes firstIndex];
        for (RLMObject *obj in objects) {
            if (index > _backingLinkView->size()) {
                @throw RLMException(@"Trying to insert object at invalid index");
            }
            if (obj->_realm != _realm) {
                [_realm addObject:obj];
            }
            else {
                RLMVerifyAttached(obj);
            }
            _backingLinkView->insert(index, obj->_row.get_index());
            index = [indexes indexGreaterThanIndex:index];
        }
    });
}


- (void)removeObjectAtIndex:(NSUInteger)index {
    RLMLinkViewArrayValidateInWriteTransaction(self);
    RLMValidateArrayBounds(self, index);
    changeArray(self, NSKeyValueChangeRemoval, index, ^{
        _backingLinkView->remove(index);
    });
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    changeArray(self, NSKeyValueChangeRemoval, indexes, ^{
        for (NSUInteger index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index]) {
            if (index >= _backingLinkView->size()) {
                @throw RLMException(@"Trying to remove object at invalid index");
            }
            _backingLinkView->remove(index);
        }
    });
}

- (void)addObjectsFromArray:(NSArray *)array {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    changeArray(self, NSKeyValueChangeInsertion, NSMakeRange(_backingLinkView->size(), array.count), ^{
        for (RLMObject *obj in array) {
            RLMValidateObjectClass(obj, _objectClassName);
            if (obj->_realm != _realm) {
                [_realm addObject:obj];
            }

            _backingLinkView->add(obj->_row.get_index());
        }
    });
}

- (void)removeAllObjects {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    changeArray(self, NSKeyValueChangeRemoval, NSMakeRange(0, _backingLinkView->size()), ^{
        _backingLinkView->clear();
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(RLMObject *)object {
    RLMLinkViewArrayValidateInWriteTransaction(self);
    RLMValidateObjectClass(object, self.objectClassName);
    RLMValidateArrayBounds(self, index);

    if (object->_realm != self.realm) {
        [self.realm addObject:object];
    }

    changeArray(self, NSKeyValueChangeReplacement, index, ^{
        _backingLinkView->set(index, object->_row.get_index());
    });
}

- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex {
    RLMLinkViewArrayValidateInWriteTransaction(self);
    RLMValidateArrayBounds(self, sourceIndex);
    RLMValidateArrayBounds(self, destinationIndex);

    auto start = std::min(sourceIndex, destinationIndex);
    auto len = std::max(sourceIndex, destinationIndex) - start + 1;
    changeArray(self, NSKeyValueChangeReplacement, {start, len}, ^{
        _backingLinkView->move(sourceIndex, destinationIndex);
    });
}

- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2 {
    RLMLinkViewArrayValidateInWriteTransaction(self);
    RLMValidateArrayBounds(self, index1);
    RLMValidateArrayBounds(self, index2);

    changeArray(self, NSKeyValueChangeReplacement, ^{
        _backingLinkView->swap(index1, index2);
    }, [=] {
        NSMutableIndexSet *set = [[NSMutableIndexSet alloc] initWithIndex:index1];
        [set addIndex:index2];
        return set;
    });
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    // check attached for table and object
    RLMLinkViewArrayValidateAttached(self);

    if (object->_realm && !object->_row.is_attached()) {
        @throw RLMException(@"RLMObject is no longer valid");
    }

    // check that object types align
    if (![_objectClassName isEqualToString:object->_objectSchema.className]) {
        @throw RLMException(@"Object of type (%@) does not match RLMArray type (%@)",
                            object->_objectSchema.className, _objectClassName);
    }

    // if different tables then no match
    if (object->_row.get_table() != &_backingLinkView->get_target_table()) {
        return NSNotFound;
    }

    // call find on backing array
    size_t object_ndx = object->_row.get_index();
    return RLMConvertNotFound(_backingLinkView->find(object_ndx));
}

- (id)valueForKey:(NSString *)key {
    // Ideally we'd use "@invalidated" for this so that "invalidated" would use
    // normal array KVC semantics, but observing @things works very oddly (when
    // it's part of a key path, it's triggered automatically when array index
    // changes occur, and can't be sent explicitly, but works normally when it's
    // the entire key path), and an RLMArrayLinkView *can't* have objects where
    // invalidated is true, so we're not losing much.
    if ([key isEqualToString:RLMInvalidatedKey]) {
        return @(!_backingLinkView->is_attached());
    }

    RLMLinkViewArrayValidateAttached(self);
    return RLMCollectionValueForKey(self, key);
}

- (void)setValue:(id)value forKey:(NSString *)key {
    RLMLinkViewArrayValidateInWriteTransaction(self);
    RLMCollectionSetValueForKey(self, key, value);
}

- (void)deleteObjectsFromRealm {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    // delete all target rows from the realm
    RLMTrackDeletions(_realm, ^{
        _backingLinkView->remove_all_target_rows();
    });
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties {
    RLMLinkViewArrayValidateAttached(self);

    auto query = std::make_unique<realm::Query>(_backingLinkView->get_target_table().where(_backingLinkView));
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                            query:move(query)
                                             sort:RLMSortOrderFromDescriptors(_realm.schema[_objectClassName], properties)
                                            realm:_realm];

}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    RLMLinkViewArrayValidateAttached(self);

    realm::Query query = _backingLinkView->get_target_table().where(_backingLinkView);
    RLMUpdateQueryWithPredicate(&query, predicate, _realm.schema, _realm.schema[self.objectClassName]);
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                            query:std::make_unique<realm::Query>(query)
                                            realm:_realm];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    RLMLinkViewArrayValidateAttached(self);

    realm::Query query = _backingLinkView->get_target_table().where(_backingLinkView);
    RLMUpdateQueryWithPredicate(&query, predicate, _realm.schema, _realm.schema[self.objectClassName]);
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
    return _backingLinkView->get(index).get_index();
}

- (realm::TableView)tableView {
    return _backingLinkView->get_target_table().where(_backingLinkView).find_all();
}

@end
