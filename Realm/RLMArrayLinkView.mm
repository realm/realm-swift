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
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"
#import "RLMUtil.hpp"

#import <objc/runtime.h>

//
// RLMArray implementation
//
@implementation RLMArrayLinkView {
    realm::LinkViewRef _backingLinkView;
    RLMObjectSchema *_objectSchema;
}

+ (RLMArrayLinkView *)arrayWithObjectClassName:(NSString *)objectClassName
                                          view:(realm::LinkViewRef)view
                                         realm:(RLMRealm *)realm {
    RLMArrayLinkView *ar = [[RLMArrayLinkView alloc] initWithObjectClassName:objectClassName standalone:NO];
    ar->_backingLinkView = view;
    ar->_realm = realm;
    ar->_objectSchema = realm.schema[objectClassName];
    return ar;
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
        @throw RLMException(@"Object is `nil`", @{@"expected class" : expected});
    }

    NSString *objectClassName = obj->_objectSchema.className;
    if (![objectClassName isEqualToString:expected]) {
        @throw RLMException(@"Object type is incorrect.", @{@"expected class" : expected, @"actual class" : objectClassName});
    }
}

//
// public method implementations
//
- (NSUInteger)count {
    RLMLinkViewArrayValidateAttached(self);
    return _backingLinkView->size();
}

- (BOOL)isInvalidated {
    return !_backingLinkView->is_attached();
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    RLMLinkViewArrayValidateAttached(self);

    __autoreleasing RLMCArrayHolder *items;
    if (state->state == 0) {
        items = [[RLMCArrayHolder alloc] initWithSize:len];
        state->extra[0] = (long)items;
        state->extra[1] = _backingLinkView->size();
    }
    else {
        // FIXME: mutationsPtr should be pointing to a value updated by core
        // whenever the linkview is changed rather than doing this check
        if (state->extra[1] != self.count) {
            @throw RLMException(@"Collection was mutated while being enumerated.");
        }
        items = (__bridge id)(void *)state->extra[0];
        [items resize:len];
    }

    NSUInteger batchCount = 0, index = state->state, count = state->extra[1];

    Class accessorClass = _objectSchema.accessorClass;
    realm::Table &table = *_objectSchema.table;
    while (index < count && batchCount < len) {
        RLMObject *accessor = [[accessorClass alloc] initWithRealm:_realm schema:_objectSchema];
        accessor->_row = table[_backingLinkView->get(index++).get_index()];
        items->array[batchCount] = accessor;
        buffer[batchCount] = accessor;
        batchCount++;
    }

    for (NSUInteger i = batchCount; i < len; ++i) {
        items->array[i] = nil;
    }

    state->itemsPtr = buffer;
    state->state = index;
    state->mutationsPtr = state->extra+1;

    return batchCount;
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMLinkViewArrayValidateAttached(self);

    if (index >= _backingLinkView->size()) {
        @throw RLMException(@"Index is out of bounds.", @{@"index": @(index)});
    }
    return RLMCreateObjectAccessor(_realm, _objectSchema, _backingLinkView->get(index).get_index());
}

static void RLMInsertObject(RLMArrayLinkView *ar, RLMObject *object, NSUInteger index) {
    RLMLinkViewArrayValidateInWriteTransaction(ar);
    RLMValidateObjectClass(object, ar.objectClassName);

    if (index == NSUIntegerMax) {
        index = ar->_backingLinkView->size();
    }
    else if (index > ar->_backingLinkView->size()) {
        @throw RLMException(@"Trying to insert object at invalid index");
    }

    if (object->_realm != ar.realm) {
        [ar.realm addObject:object];
    }
    else if (object->_realm) {
        RLMVerifyAttached(object);
    }

    ar->_backingLinkView->insert(index, object->_row.get_index());
}

- (void)addObject:(RLMObject *)object {
    RLMInsertObject(self, object, NSUIntegerMax);
}

- (void)insertObject:(RLMObject *)object atIndex:(NSUInteger)index {
    RLMInsertObject(self, object, index);
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    if (index >= _backingLinkView->size()) {
        @throw RLMException(@"Trying to remove object at invalid index");
    }
    _backingLinkView->remove(index);
}

- (void)removeLastObject {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    size_t size = _backingLinkView->size();
    if (size > 0){
        _backingLinkView->remove(size-1);
    }
}

- (void)removeAllObjects {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    _backingLinkView->clear();
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(RLMObject *)object {
    RLMLinkViewArrayValidateInWriteTransaction(self);
    RLMValidateObjectClass(object, self.objectClassName);

    if (index >= _backingLinkView->size()) {
        @throw RLMException(@"Trying to replace object at invalid index");
    }
    if (object->_realm != self.realm) {
        [self.realm addObject:object];
    }
    _backingLinkView->set(index, object->_row.get_index());
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    // check attached for table and object
    RLMLinkViewArrayValidateAttached(self);

    if (object->_realm && !object->_row.is_attached()) {
        @throw RLMException(@"RLMObject is no longer valid");
    }

    // check that object types align
    if (![_objectClassName isEqualToString:object->_objectSchema.className]) {
        @throw RLMException([NSString stringWithFormat:@"Object of type (%@) does not match RLMArray type (%@)",
                             object->_objectSchema.className, _objectClassName]);
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
    RLMLinkViewArrayValidateAttached(self);
    const size_t size = _backingLinkView->size();
    return RLMCollectionValueForKey(key, _realm, _objectSchema, size, ^size_t(size_t index) {
        return _backingLinkView->get(index).get_index();
    });
}

- (void)setValue:(id)value forKey:(NSString *)key {
    RLMLinkViewArrayValidateInWriteTransaction(self);
    const size_t size = _backingLinkView->size();
    RLMCollectionSetValueForKey(value, key, _realm, _objectSchema, size, ^size_t(size_t index) {
        return _backingLinkView->get(index).get_index();
    });
}

- (void)deleteObjectsFromRealm {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    // delete all target rows from the realm
    self->_backingLinkView->remove_all_target_rows();
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties
{
    RLMLinkViewArrayValidateAttached(self);

    std::vector<size_t> columns;
    std::vector<bool> order;
    RLMGetColumnIndices(_realm.schema[_objectClassName], properties, columns, order);

    auto query = std::make_unique<realm::Query>(_backingLinkView->get_target_table().where(_backingLinkView));
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                                 query:move(query)
                                                  view:_backingLinkView->get_sorted_view(move(columns), move(order))
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

@end
