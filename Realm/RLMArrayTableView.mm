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

#import "RLMObject_Private.h"
#import "RLMArray_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.hpp"
#import "RLMConstants.h"
#import <objc/runtime.h>

#import <tightdb/util/unique_ptr.hpp>

//
// RLMArray implementation
//
@implementation RLMArrayTableView

@dynamic backingQuery;

+ (instancetype)arrayWithObjectClassName:(NSString *)objectClassName
                                  query:(tightdb::Query *)query
                                   view:(tightdb::TableView &)view
                                  realm:(RLMRealm *)realm{
    RLMArrayTableView *ar = [[RLMArrayTableView alloc] initWithObjectClassName:objectClassName];
    ar.backingQuery = query;
    ar->_backingView = view;
    ar->_realm = realm;
    ar->_readOnly = YES;
    return ar;
}

//
// validation helper
//
inline void RLMArrayTableViewValidateAttached(RLMArrayTableView *ar) {
    if (!ar->_backingView.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMArray is no longer valid" userInfo:nil];
    }
}
inline void RLMArrayTableViewValidateInWriteTransaction(RLMArrayTableView *ar) {
    // first verify attached
    RLMArrayTableViewValidateAttached(ar);

    if (!ar->_realm->_inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can't mutate a persisted array outside of a write transaction."
                                     userInfo:nil];
    }
}

//
// public method implementations
//
- (NSUInteger)count {
    RLMArrayTableViewValidateAttached(self);
    return _backingView.size();
}

inline id RLMCreateAccessorForArrayIndex(RLMArrayTableView *array, NSUInteger index) {
    return RLMCreateObjectAccessor(array->_realm,
                                   array->_objectClassName,
                                   array->_backingView.get_source_ndx(index));
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    RLMArrayTableViewValidateAttached(self);

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
    RLMArrayTableViewValidateAttached(self);

    if (index >= self.count) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Index is out of bounds." userInfo:@{@"index": @(index)}];
    }
    return RLMCreateAccessorForArrayIndex(self, index);;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (void)addObject:(RLMObject *)object {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"Attempting to mutate a readOnly RLMArray" userInfo:nil];
}

- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"Attempting to mutate a readOnly RLMArray" userInfo:nil];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"Attempting to mutate a readOnly RLMArray" userInfo:nil];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"Attempting to mutate a readOnly RLMArray" userInfo:nil];
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    // check attached for table and object
    RLMArrayTableViewValidateAttached(self);
    if (object->_realm && !object->_row.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMObject is no longer valid" userInfo:nil];
    }

    // check that object types align
    if (![_objectClassName isEqualToString:object.objectSchema.className]) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object type does not match RLMArray" userInfo:nil];
    }

    // if different tables then no match
    if (object->_row.get_table() != &_backingView.get_parent()) {
        return NSNotFound;
    }

    size_t object_ndx = object->_row.get_index();
    size_t result = _backingView.find_by_source_ndx(object_ndx);
    if (result == tightdb::not_found) {
        return NSNotFound;
    }

    return result;
}

- (NSUInteger)indexOfObjectWithPredicateFormat:(NSString *)predicateFormat, ... {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}
#pragma GCC diagnostic pop

- (void)setBackingQuery:(tightdb::Query *)backingQuery {
    _backingQuery.reset(backingQuery);
}

- (tightdb::Query *)backingQuery {
    return _backingQuery.get();
}

- (RLMArray *)copy {
    RLMArrayTableViewValidateAttached(self);

    tightdb::TableView viewCopy = _backingView.get_parent().where(&_backingView).find_all();
    return [RLMArrayTableView arrayWithObjectClassName:self.objectClassName
                                                 query:new tightdb::Query(*_backingQuery)
                                                  view:viewCopy
                                                 realm:_realm];
}

- (RLMArray *)objectsWithPredicateFormat:(NSString *)predicateFormat, ...
{
    // validate predicate
    NSPredicate *outPred;
    RLM_PREDICATE(predicateFormat, outPred);
    return [self objectsWithPredicate:outPred];
}

- (RLMArray *)objectsWithPredicate:(NSPredicate *)predicate
{
    // copy array and apply new predicate creating a new query and view
    RLMArrayTableView *array = [self copy];
    RLMUpdateQueryWithPredicate(array.backingQuery, predicate, array.realm.schema[self.objectClassName]);
    array->_backingView = array.backingQuery->find_all();
    return array;
}

- (RLMArray *)arraySortedByProperty:(NSString *)property ascending:(BOOL)ascending
{
    // copy array and apply new predicate
    RLMArrayTableView *array = [self copy];
    RLMObjectSchema *schema = array.realm.schema[self.objectClassName];
    tightdb::TableView view = array.backingQuery->find_all();
    
    // apply order
    RLMUpdateViewWithOrder(view, schema, property, ascending);
    array->_backingView = view;
    return array;
}

-(id)minOfProperty:(NSString *)property {
    RLMArrayTableViewValidateAttached(self);

    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[self.objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(_backingView.get_column_type(colIndex));
    
    switch (colType) {
        case RLMPropertyTypeInt:
            return @(_backingView.minimum_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(_backingView.minimum_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(_backingView.minimum_float(colIndex));
        case RLMPropertyTypeDate: {
            tightdb::DateTime dt = _backingView.minimum_datetime(colIndex);
            return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
        }
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"minOfProperty only supported for int, float, double and date properties."
                                         userInfo:nil];
    }
}

-(id)maxOfProperty:(NSString *)property {
    RLMArrayTableViewValidateAttached(self);

    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[self.objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(_backingView.get_column_type(colIndex));
    
    switch (colType) {
        case RLMPropertyTypeInt:
            return @(_backingView.maximum_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(_backingView.maximum_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(_backingView.maximum_float(colIndex));
        case RLMPropertyTypeDate: {
            tightdb::DateTime dt = _backingView.maximum_datetime(colIndex);
            return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
        }
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"maxOfProperty only supported for int, float, double and date properties."
                                         userInfo:nil];
    }
}

-(NSNumber *)sumOfProperty:(NSString *)property {
    RLMArrayTableViewValidateAttached(self);

    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[self.objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(_backingView.get_column_type(colIndex));
    
    switch (colType) {
        case RLMPropertyTypeInt:
            return @(_backingView.sum_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(_backingView.sum_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(_backingView.sum_float(colIndex));
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"sumOfProperty only supported for int, float and double properties."
                                         userInfo:nil];
    }
}

-(NSNumber *)averageOfProperty:(NSString *)property {
    RLMArrayTableViewValidateAttached(self);

    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[self.objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(_backingView.get_column_type(colIndex));
    
    switch (colType) {
        case RLMPropertyTypeInt:
            return @(_backingView.average_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(_backingView.average_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(_backingView.average_float(colIndex));
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"averageOfProperty only supported for int, float and double properties."
                                         userInfo:nil];
    }
}

- (NSString *)JSONString {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)deleteObjectsFromRealm {
    RLMArrayTableViewValidateInWriteTransaction(self);

    // call clear to remove all from the realm
    _backingView.clear();
}

@end
