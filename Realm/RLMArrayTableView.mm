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
#import "RLMSchema_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.hpp"
#import "RLMConstants.h"
#import <objc/runtime.h>

#import <tightdb/util/unique_ptr.hpp>

//
// RLMArray implementation
//
@implementation RLMArrayTableView

+ (instancetype)arrayWithObjectClassName:(NSString *)objectClassName
                                   view:(tightdb::TableView const &)view
                                  realm:(RLMRealm *)realm {
    RLMArrayTableView *ar = [[RLMArrayTableView alloc] initViewWithObjectClassName:objectClassName];
    ar->_backingView = view;
    ar->_realm = realm;
    return ar;
}

- (BOOL)isReadOnly {
    return YES;
}

//
// validation helper
//
inline void RLMArrayTableViewValidateAttached(RLMArrayTableView *ar) {
    if (!ar->_backingView.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMArray is no longer valid" userInfo:nil];
    }
    ar->_backingView.sync_if_needed();
    RLMCheckThread(ar->_realm);
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

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    RLMArrayTableViewValidateAttached(self);

    __autoreleasing RLMCArrayHolder *items;
    if (state->state == 0) {
        items = [[RLMCArrayHolder alloc] initWithSize:len];
        state->extra[0] = (long)items;
        state->extra[1] = self.count;
    }
    else {
        items = (__bridge id)(void *)state->extra[0];
        [items resize:len];
    }

    NSUInteger batchCount = 0, index = state->state, count = state->extra[1];

    RLMObjectSchema *objectSchema = _realm.schema[_objectClassName];
    Class accessorClass = objectSchema.accessorClass;
    while (index < count && batchCount < len) {
        // get acessor fot the object class
        RLMObject *accessor = [[accessorClass alloc] initWithRealm:_realm schema:objectSchema defaultValues:NO];
        accessor->_row = (*objectSchema->_table)[_backingView.get_source_ndx(index++)];
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
    RLMArrayTableViewValidateAttached(self);

    if (index >= self.count) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Index is out of bounds." userInfo:@{@"index": @(index)}];
    }
    return RLMCreateObjectAccessor(_realm, _objectClassName, _backingView.get_source_ndx(index));
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

#pragma GCC diagnostic pop

- (RLMArray *)objectsWhere:(NSString *)predicateFormat, ...
{
    // validate predicate
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objectsWhere:predicateFormat args:args];
}

- (RLMArray *)objectsWhere:(NSString *)predicateFormat args:(va_list)args
{
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMArray *)objectsWithPredicate:(NSPredicate *)predicate
{
    RLMArrayTableViewValidateAttached(self);

    // copy array and apply new predicate creating a new query and view
    tightdb::Query query = _backingView.get_parent().where();
    query.tableview(_backingView);

    RLMUpdateQueryWithPredicate(&query, predicate, _realm.schema, _realm.schema[self.objectClassName]);
    return [RLMArrayTableView arrayWithObjectClassName:self.objectClassName view:query.find_all() realm:_realm];
}

- (RLMArray *)arraySortedByProperty:(NSString *)property ascending:(BOOL)ascending
{
    RLMArrayTableViewValidateAttached(self);

    tightdb::Query query = _backingView.get_parent().where();
    query.tableview(_backingView);
    
    // apply order
    RLMArrayTableView *ar = [RLMArrayTableView arrayWithObjectClassName:self.objectClassName
                                                                   view:query.find_all()
                                                                  realm:_realm];
    RLMUpdateViewWithOrder(ar->_backingView, _realm.schema[self.objectClassName], property, ascending);
    return ar;
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
