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
#import "RLMRealm_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMSchema.h"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.hpp"
#import "RLMConstants.h"

#import <objc/runtime.h>

//
// RLMArray implementation
//
@implementation RLMArrayLinkView {
    tightdb::util::UniquePtr<tightdb::Query> _backingQuery;
}

+ (RLMArrayLinkView *)arrayWithObjectClassName:(NSString *)objectClassName
                                          view:(tightdb::LinkViewRef)view
                                         realm:(RLMRealm *)realm {
    RLMArrayLinkView *ar = [[RLMArrayLinkView alloc] initWithObjectClassName:objectClassName];
    ar->_backingLinkView = view;
    ar->_realm = realm;
    return ar;
}

//
// validation helpers
//
inline void RLMLinkViewArrayValidateAttached(RLMArrayLinkView *ar) {
    if (!ar->_backingLinkView->is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMArray is no longer valid" userInfo:nil];
    }
}
inline void RLMLinkViewArrayValidateInWriteTransaction(RLMArrayLinkView *ar) {
    // first verify attached
    RLMLinkViewArrayValidateAttached(ar);

    if (!ar->_realm->_inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can't mutate a persisted array outside of a write transaction."
                                     userInfo:nil];
    }
}
inline void RLMValidateObjectClass(RLMObject *obj, NSString *expected) {
    NSString *objectClassName = [obj.class className];
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

inline id RLMCreateAccessorForArrayIndex(RLMArrayLinkView *array, NSUInteger index) {
    return RLMCreateObjectAccessor(array->_realm,
                                   array->_objectClassName,
                                   array->_backingLinkView->get(index).get_index());
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    RLMLinkViewArrayValidateAttached(self);

    NSUInteger batchCount = 0, index = state->state, count = self.count;
    
    __autoreleasing id *autoreleasingBuffer = (__autoreleasing id *)(void *)buffer;
    while (index < count && batchCount < len) {
        autoreleasingBuffer[batchCount++] = RLMCreateAccessorForArrayIndex(self, index++);
    }
    
    state->mutationsPtr = state->extra;
    state->itemsPtr = buffer;
    state->state = index;
    return batchCount;
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMLinkViewArrayValidateAttached(self);

    if (index >= self.count) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Index is out of bounds." userInfo:@{@"index": @(index)}];
    }
    return RLMCreateAccessorForArrayIndex(self, index);;
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

- (NSString *)JSONString {
    RLMLinkViewArrayValidateAttached(self);
    return [super JSONString];
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


@end



