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
#import "RLMProperty_Private.h"
#import "RLMObject_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMConstants.h"
#import "RLMObjectStore.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMSchema.h"

#import <objc/runtime.h>

//
// RLMArray implementation
//
@implementation RLMArrayLinkView {
    tightdb::LinkViewRef _backingLinkView;
}

+ (RLMArrayLinkView *)arrayWithObjectClassName:(NSString *)objectClassName
                                          view:(tightdb::LinkViewRef)view
                                         realm:(RLMRealm *)realm {
    RLMArrayLinkView *ar = [[RLMArrayLinkView alloc] initWithObjectClassName:objectClassName standalone:NO];
    ar->_backingLinkView = view;
    ar->_realm = realm;
    return ar;
}

//
// validation helpers
//
static inline void RLMLinkViewArrayValidateAttached(RLMArrayLinkView *ar) {
    if (!ar->_backingLinkView->is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMArray is no longer valid" userInfo:nil];
    }
    RLMCheckThread(ar->_realm);
}
static inline void RLMLinkViewArrayValidateInWriteTransaction(RLMArrayLinkView *ar) {
    // first verify attached
    RLMLinkViewArrayValidateAttached(ar);

    if (!ar->_realm->_inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can't mutate a persisted array outside of a write transaction."
                                     userInfo:nil];
    }
}
static inline void RLMValidateObjectClass(RLMObject *obj, NSString *expected) {
    NSString *objectClassName = obj.objectSchema.className;
    if (![objectClassName isEqualToString:expected]) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Attempting to insert wrong object type"
                                     userInfo:@{@"expected class" : expected, @"actual class" : objectClassName}];
    }
}

//
// public method implementations
//
- (NSUInteger)count {
    RLMLinkViewArrayValidateAttached(self);
    return _backingLinkView->size();
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
        items = (__bridge id)(void *)state->extra[0];
        [items resize:len];
    }

    NSUInteger batchCount = 0, index = state->state, count = state->extra[1];

    RLMObjectSchema *objectSchema = _realm.schema[_objectClassName];
    Class accessorClass = objectSchema.accessorClass;
    tightdb::Table &table = *objectSchema->_table;
    while (index < count && batchCount < len) {
        RLMObject *accessor = [[accessorClass alloc] initWithRealm:_realm schema:objectSchema defaultValues:NO];
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
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Index is out of bounds." userInfo:@{@"index": @(index)}];
    }
    return RLMCreateObjectAccessor(_realm,
                                   _objectClassName,
                                   _backingLinkView->get(index).get_index());
}

- (void)addObject:(RLMObject *)object {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    RLMValidateObjectClass(object, self.objectClassName);
    if (object.realm != self.realm) {
        [self.realm addObject:object];
    }
    _backingLinkView->add(object->_row.get_index());
}

- (void)insertObject:(RLMObject *)object atIndex:(NSUInteger)index {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    RLMValidateObjectClass(object, self.objectClassName);
    if (object.realm != self.realm) {
        [self.realm addObject:object];
    }
    _backingLinkView->insert(index, object->_row.get_index());
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    RLMLinkViewArrayValidateInWriteTransaction(self);

    if (index >= _backingLinkView->size()) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Trying to remove object at invalid index" userInfo:nil];
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
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Trying to replace object at invalid index" userInfo:nil];
    }
    if (object.realm != self.realm) {
        [self.realm addObject:object];
    }
    _backingLinkView->set(index, object->_row.get_index());
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    // check attached for table and object
    RLMLinkViewArrayValidateAttached(self);
    if (object->_realm && !object->_row.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMObject is no longer valid" userInfo:nil];
    }

    // check that object types align
    if (![_objectClassName isEqualToString:object.objectSchema.className]) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object type does not match RLMArray"
                                     userInfo:nil];
    }

    // if different tables then no match
    if (object->_row.get_table() != &_backingLinkView->get_target_table()) {
        return NSNotFound;
    }

    // call find on backing array
    size_t object_ndx = object->_row.get_index();
    size_t result = _backingLinkView->find(object_ndx);
    if (result == tightdb::not_found) {
        return NSNotFound;
    }

    return result;
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

    tightdb::TableView const &tv = _backingLinkView->get_sorted_view(move(columns), move(order));
    auto query = std::make_unique<tightdb::Query>(_backingLinkView->get_target_table().where(_backingLinkView));
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                                 query:move(query)
                                                  view:tv
                                                 realm:_realm];

}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    RLMLinkViewArrayValidateAttached(self);

    tightdb::Query query = _backingLinkView->get_target_table().where(_backingLinkView);
    RLMUpdateQueryWithPredicate(&query, predicate, _realm.schema, _realm.schema[self.objectClassName]);
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                            query:std::make_unique<tightdb::Query>(query)
                                            realm:_realm];
}

@end
