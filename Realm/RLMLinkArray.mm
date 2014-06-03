////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMLinkArray.h"
#import "RLMArrayAccessor.h"

#import "RLMRealm_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMSchema.h"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.h"
#import "RLMConstants.h"


//
// RLMArray implementation
//
@implementation RLMLinkArray {
    tightdb::util::UniquePtr<tightdb::Query> _backingQuery;
}

- (NSUInteger)count {
    return _backingLinkView->size();
}

inline id RLMCreateAccessorForArrayIndex(RLMLinkArray *array, NSUInteger index) {
    return RLMCreateObjectAccessor(array.realm,
                                   array.objectClassName,
                                   array->_backingLinkView->get_target_row(index));
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    NSUInteger batchCount = 0, index = state->state, count = self.count;
    while (index < count && batchCount < len) {
        buffer[batchCount++] = RLMCreateAccessorForArrayIndex(self, index++);
    }
    
    void *selfPtr = (__bridge void *)self;
    state->mutationsPtr = (unsigned long *)selfPtr;
    state->state = index;
    state->itemsPtr = buffer;
    return batchCount;
}

- (id)objectAtIndex:(NSUInteger)index {
    if (index >= self.count) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Index is out of bounds." userInfo:@{@"index": @(index)}];
    }
    return RLMCreateAccessorForArrayIndex(self, index);;
}

- (id)firstObject {
    if (self.count) {
        return RLMCreateAccessorForArrayIndex(self, 0);
    }
    return nil;
}

- (id)lastObject {
    NSUInteger count = self.count;
    if (count) {
        return RLMCreateAccessorForArrayIndex(self, count-1);
    }
    return nil;
}

inline void RLMValidateObjectClass(RLMObject *obj, NSString *expected) {
    NSString *objectClassName = [obj.class className];
    if (![objectClassName isEqualToString:expected]) {
        @throw [NSException exceptionWithName:@"RLMExceptoin" reason:@"Attempting to insert wrong object type"
                                     userInfo:@{@"expected class" : expected, @"actual class" : objectClassName}];
    }
}

- (void)addObject:(RLMObject *)object {
    RLMValidateObjectClass(object, self.objectClassName);
    if (object.realm != self.realm) {
        [self.realm addObject:object];
    }
    _backingLinkView->add_link(object.objectIndex);
}

- (void)insertObject:(RLMObject *)object atIndex:(NSUInteger)index {
    RLMValidateObjectClass(object, self.objectClassName);
    if (object.realm != self.realm) {
        [self.realm addObject:object];
    }
    _backingLinkView->insert_link(index, object.objectIndex);
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    if (index >= _backingLinkView->size()) {
        @throw [NSException exceptionWithName:@"RLMExceptoin"
                                       reason:@"Trying to remove object at invalid index" userInfo:nil];
    }
    _backingLinkView->remove_link(index);
}

- (void)removeLastObject {
    size_t size = _backingLinkView->size();
    if (size > 0){
        _backingLinkView->remove_link(size-1);
    }
}

- (void)removeAllObjects {
    _backingLinkView->remove_all_links();
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(RLMObject *)object {
    RLMValidateObjectClass(object, self.objectClassName);
    if (index >= _backingLinkView->size()) {
        @throw [NSException exceptionWithName:@"RLMExceptoin"
                                       reason:@"Trying to replace object at invalid index" userInfo:nil];
    }
    if (object.realm != self.realm) {
        [self.realm addObject:object];
    }
    _backingLinkView->set_link(index, object.objectIndex);
}


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (NSUInteger)indexOfObject:(RLMObject *)object {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (NSUInteger)indexOfObjectWhere:(id)predicate, ... {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}
#pragma GCC diagnostic pop


- (RLMArray *)copy {
    return [RLMArray arrayWithObjectClassName:self.objectClassName view:_backingLinkView realm:self.realm];
}

- (NSString *)JSONString {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)index {
    [self replaceObjectAtIndex:index withObject:newValue];
}

@end



