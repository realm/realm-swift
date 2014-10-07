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
#import "RLMObjectStore.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMConstants.h"
#import <objc/runtime.h>

#import <tightdb/util/unique_ptr.hpp>

//
// RLMResults implementation
//
@implementation RLMResults {
    std::unique_ptr<tightdb::Query> _backingQuery;
    tightdb::TableView _backingView;
    BOOL _viewCreated;
    RowIndexes::Sorter _sortOrder;

@protected
    RLMRealm *_realm;
    NSString *_objectClassName;
}

- (instancetype)initPrivate {
    self = [super init];
    return self;
}

+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<tightdb::Query>)query
                                     realm:(RLMRealm *)realm {
    return [self resultsWithObjectClassName:objectClassName query:move(query) sort:RowIndexes::Sorter{} realm:realm];
}

+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<tightdb::Query>)query
                                      sort:(RowIndexes::Sorter const&)sorter
                                     realm:(RLMRealm *)realm {
    RLMResults *ar = [[RLMResults alloc] initPrivate];
    ar->_objectClassName = objectClassName;
    ar->_viewCreated = NO;
    ar->_backingQuery = move(query);
    ar->_sortOrder = sorter;
    ar->_realm = realm;
    return ar;
}

+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<tightdb::Query>)query
                                      view:(tightdb::TableView)view
                                     realm:(RLMRealm *)realm {
    RLMResults *ar = [[RLMResults alloc] initPrivate];
    ar->_objectClassName = objectClassName;
    ar->_viewCreated = YES;
    ar->_backingView = move(view);
    ar->_backingQuery = move(query);
    ar->_realm = realm;
    return ar;
}

//
// validation helper
//
static inline void RLMResultsValidateAttached(RLMResults *ar) {
    if (!ar->_viewCreated) {
        // create backing view if needed
        ar->_backingView = ar->_backingQuery->find_all();
        ar->_viewCreated = YES;
        if (!ar->_sortOrder.m_columns.empty()) {
            ar->_backingView.sort(ar->_sortOrder.m_columns, ar->_sortOrder.m_ascending);
        }
    }
    else {
        // otherwiser verify attached and sync
        if (!ar->_backingView.is_attached()) {
            @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMResults is no longer valid" userInfo:nil];
        }
        ar->_backingView.sync_if_needed();
    }
}
static inline void RLMResultsValidate(RLMResults *ar) {
    RLMResultsValidateAttached(ar);
    RLMCheckThread(ar->_realm);
}

static inline void RLMResultsValidateInWriteTransaction(RLMResults *ar) {
    // first verify attached
    RLMResultsValidate(ar);

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
    if (_viewCreated) {
        RLMResultsValidate(self);
        return _backingView.size();
    }
    else {
        RLMCheckThread(_realm);
        return _backingQuery->count();
    }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    RLMResultsValidate(self);

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

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ... {
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self indexOfObjectWhere:predicateFormat args:args];
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:predicateFormat
                                                                   arguments:args]];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    RLMResults *objects = [self objectsWithPredicate:predicate];
    if ([objects count] == 0) {
        return NSNotFound;
    }
    return [self indexOfObject:[objects firstObject]];
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMResultsValidate(self);

    if (index >= self.count) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Index is out of bounds." userInfo:@{@"index": @(index)}];
    }
    return RLMCreateObjectAccessor(_realm, _objectClassName, _backingView.get_source_ndx(index));
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

- (NSUInteger)indexOfObject:(RLMObject *)object {
    // check attached for table and object
    RLMResultsValidate(self);
    if (object->_realm && !object->_row.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"RLMObject is no longer valid" userInfo:nil];
    }

    // check that object types align
    if (![_objectClassName isEqualToString:object.objectSchema.className]) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object type does not match RLMResults" userInfo:nil];
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

- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ... {
    // validate predicate
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objectsWhere:predicateFormat args:args];
}

- (RLMResults *)objectsWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    RLMResultsValidate(self);

    // copy array and apply new predicate creating a new query and view
    auto query = std::make_unique<tightdb::Query>(*_backingQuery, tightdb::Query::TCopyExpressionTag{});
    RLMUpdateQueryWithPredicate(query.get(), predicate, _realm.schema, _realm.schema[self.objectClassName]);
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                            query:move(query)
                                             sort:_backingView.m_sorting_predicate
                                            realm:_realm];
}

- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending {
    return [self sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:property ascending:ascending]]];
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties {
    RLMResultsValidate(self);

    auto query = std::make_unique<tightdb::Query>(*_backingQuery, tightdb::Query::TCopyExpressionTag{});
    RLMResults *r = [RLMResults resultsWithObjectClassName:self.objectClassName query:move(query) realm:_realm];

    // attach new table view
    RLMResultsValidateAttached(r);
    RLMUpdateViewWithOrder(r->_backingView, _realm.schema[self.objectClassName], properties);
    return r;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

-(id)minOfProperty:(NSString *)property {
    RLMResultsValidate(self);

    if (self.count == 0) {
        return nil;
    }

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
    RLMResultsValidate(self);

    if (self.count == 0) {
        return nil;
    }

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
    RLMResultsValidate(self);

    if (self.count == 0) {
        return @0;
    }

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
    RLMResultsValidate(self);

    if (self.count == 0) {
        return nil;
    }

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

- (void)deleteObjectsFromRealm {
    RLMResultsValidateInWriteTransaction(self);

    // call clear to remove all from the realm
    _backingView.clear();
}

- (NSString *)description {
    return [self descriptionWithMaxDepth:5];
}

- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth {
    if (depth == 0) {
        return @"<Maximum depth exceeded>";
    }

    const NSUInteger maxObjects = 100;
    NSMutableString *mString = [NSMutableString stringWithFormat:@"RLMResults <0x%lx> (\n", (long)self];
    unsigned long index = 0, skipped = 0;
    for (id obj in self) {
        NSString *sub;
        if ([obj respondsToSelector:@selector(descriptionWithMaxDepth:)]) {
            sub = [obj descriptionWithMaxDepth:depth - 1];
        }
        else {
            sub = [obj description];
        }

        // Indent child objects
        NSString *objDescription = [sub stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        [mString appendFormat:@"\t[%lu] %@,\n", index++, objDescription];
        if (index >= maxObjects) {
            skipped = self.count - maxObjects;
            break;
        }
    }

    // Remove last comma and newline characters
    if(self.count > 0)
        [mString deleteCharactersInRange:NSMakeRange(mString.length-2, 2)];
    if (skipped) {
        [mString appendFormat:@"\n\t... %lu objects skipped.", skipped];
    }
    [mString appendFormat:@"\n)"];
    return [NSString stringWithString:mString];
}

@end

@implementation RLMEmptyResults

+ (instancetype)emptyResultsWithObjectClassName:(NSString *)objectClassName realm:(RLMRealm *)realm {
    RLMEmptyResults *results = [[RLMEmptyResults alloc] initPrivate];
    results->_objectClassName = objectClassName;
    results->_realm = realm;
    return results;
}

- (NSUInteger)count {
    return 0;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    return 0;
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    return NSNotFound;
}

- (id)objectAtIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Index is out of bounds." userInfo:@{@"index": @(index)}];
}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    return self;
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties {
    return self;
}

#pragma clang diagnostic pop

- (void)deleteObjectsFromRealm {
}

@end
