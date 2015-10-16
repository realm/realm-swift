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

#import "RLMResults_Private.h"

#import "RLMArray_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

#import <objc/runtime.h>
#import <realm/table_view.hpp>

using namespace realm;

static const int RLMEnumerationBufferSize = 16;

@implementation RLMFastEnumerator {
    // The buffer supplied by fast enumeration does not retain the objects given
    // to it, but because we create objects on-demand and don't want them
    // autoreleased (a table can have more rows than the device has memory for
    // accessor objects) we need a thing to retain them.
    id _strongBuffer[RLMEnumerationBufferSize];

    RLMRealm *_realm;
    RLMObjectSchema *_objectSchema;

    // Collection being enumerated. Only one of these two will be valid: when
    // possible we enumerate the collection directly, but when in a write
    // transaction we instead create a frozen TableView and enumerate that
    // instead so that mutating the collection during enumeration works.
    id<RLMFastEnumerable> _collection;
    realm::TableView _tableView;
}

- (instancetype)initWithCollection:(id<RLMFastEnumerable>)collection objectSchema:(RLMObjectSchema *)objectSchema {
    self = [super init];
    if (self) {
        _realm = collection.realm;
        _objectSchema = objectSchema;

        if (_realm.inWriteTransaction) {
            _tableView = [collection tableView];
        }
        else {
            _collection = collection;
            [_realm registerEnumerator:self];
        }
    }
    return self;
}

- (void)dealloc {
    if (_collection) {
        [_realm unregisterEnumerator:self];
    }
}

- (void)detach {
    _tableView = [_collection tableView];
    _collection = nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len {
    RLMCheckThread(_realm);
    if (!_tableView.is_attached() && !_collection) {
        @throw RLMException(@"Collection is no longer valid");
    }
    // The fast enumeration buffer size is currently a hardcoded number in the
    // compiler so this can't actually happen, but just in case it changes in
    // the future...
    if (len > RLMEnumerationBufferSize) {
        len = RLMEnumerationBufferSize;
    }

    NSUInteger batchCount = 0, count = state->extra[1];

    Class accessorClass = _objectSchema.accessorClass;
    for (NSUInteger index = state->state; index < count && batchCount < len; ++index) {
        RLMObject *accessor = [[accessorClass alloc] initWithRealm:_realm schema:_objectSchema];
        if (_collection) {
            accessor->_row = (*_objectSchema.table)[[_collection indexInSource:index]];
        }
        else if (_tableView.is_row_attached(index)) {
            accessor->_row = (*_objectSchema.table)[_tableView.get_source_ndx(index)];
        }
        _strongBuffer[batchCount] = accessor;
        batchCount++;
    }

    for (NSUInteger i = batchCount; i < len; ++i) {
        _strongBuffer[i] = nil;
    }

    if (batchCount == 0) {
        // Release our data if we're done, as we're autoreleased and so may
        // stick around for a while
        _collection = nil;
        if (_tableView.is_attached()) {
            _tableView = TableView();
        }
        else {
            [_realm unregisterEnumerator:self];
        }
    }

    state->itemsPtr = (__unsafe_unretained id *)(void *)_strongBuffer;
    state->state += batchCount;
    state->mutationsPtr = state->extra+1;

    return batchCount;
}
@end

//
// RLMResults implementation
//
@implementation RLMResults {
    std::unique_ptr<realm::Query> _backingQuery;
    realm::TableView _backingView;
    BOOL _viewCreated;
    RLMSortOrder _sortOrder;

@protected
    RLMRealm *_realm;
    NSString *_objectClassName;
}

- (instancetype)initPrivate {
    self = [super init];
    return self;
}

+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<realm::Query>)query
                                     realm:(RLMRealm *)realm {
    return [self resultsWithObjectClassName:objectClassName query:move(query) sort:{} realm:realm];
}

+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<realm::Query>)query
                                      sort:(RLMSortOrder)sorter
                                     realm:(RLMRealm *)realm {
    RLMResults *ar = [[self alloc] initPrivate];
    ar->_objectClassName = objectClassName;
    ar->_viewCreated = NO;
    ar->_backingQuery = move(query);
    ar->_sortOrder = std::move(sorter);
    ar->_realm = realm;
    ar->_objectSchema = realm.schema[objectClassName];
    return ar;
}

+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<realm::Query>)query
                                      view:(realm::TableView &&)view
                                     realm:(RLMRealm *)realm {
    RLMResults *ar = [[RLMResults alloc] initPrivate];
    ar->_objectClassName = objectClassName;
    ar->_viewCreated = YES;
    ar->_backingView = std::move(view);
    ar->_backingQuery = move(query);
    ar->_realm = realm;
    ar->_objectSchema = realm.schema[objectClassName];
    return ar;
}

//
// validation helper
//
static inline void RLMResultsValidateAttached(__unsafe_unretained RLMResults *const ar) {
    if (ar->_viewCreated) {
        // verify view is attached and up to date
        if (!ar->_backingView.is_attached()) {
            @throw RLMException(@"RLMResults is no longer valid");
        }
        ar->_backingView.sync_if_needed();
    }
    else if (ar->_backingQuery) {
        // create backing view if needed
        ar->_backingView = ar->_backingQuery->find_all();
        ar->_viewCreated = YES;
        if (ar->_sortOrder) {
            ar->_backingView.sort(ar->_sortOrder.columnIndices, ar->_sortOrder.ascending);
        }
    }
    // otherwise we're backed by a table and don't need to update anything
}
static inline void RLMResultsValidate(__unsafe_unretained RLMResults *const ar) {
    RLMResultsValidateAttached(ar);
    RLMCheckThread(ar->_realm);
}

static inline void RLMResultsValidateInWriteTransaction(__unsafe_unretained RLMResults *const ar) {
    // first verify attached
    RLMResultsValidate(ar);

    if (!ar->_realm->_inWriteTransaction) {
        @throw RLMException(@"Can't mutate a persisted array outside of a write transaction.");
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
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    __autoreleasing RLMFastEnumerator *enumerator;
    if (state->state == 0) {
        RLMResultsValidate(self);

        enumerator = [[RLMFastEnumerator alloc] initWithCollection:self objectSchema:_objectSchema];
        state->extra[0] = (long)enumerator;
        state->extra[1] = self.count;
    }
    else {
        enumerator = (__bridge id)(void *)state->extra[0];
    }

    return [enumerator countByEnumeratingWithState:state count:len];
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
    RLMResultsValidate(self);

    // copy array and apply new predicate creating a new query and view
    auto query = [self cloneQuery];
    RLMUpdateQueryWithPredicate(query.get(), predicate, _realm.schema, _realm.schema[self.objectClassName]);
    size_t index = query->find();
    if (index == realm::not_found) {
        return NSNotFound;
    }
    return _backingView.find_by_source_ndx(index);
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMResultsValidate(self);

    if (index >= self.count) {
        @throw RLMException(@"Index %@ is out of bounds.", @(index));
    }
    return RLMCreateObjectAccessor(_realm, _objectSchema, [self indexInSource:index]);
}

- (id)firstObject {
    RLMResultsValidate(self);

    if (self.count) {
        return [self objectAtIndex:0];
    }
    return nil;
}

- (id)lastObject {
    RLMResultsValidate(self);

    NSUInteger count = self.count;
    if (count) {
        return [self objectAtIndex:count-1];
    }
    return nil;
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    // check attached for table and object
    RLMResultsValidate(self);
    if (object.invalidated) {
        @throw RLMException(@"RLMObject is no longer valid");
    }
    if (!object->_row) {
        return NSNotFound;
    }

    // check that object types align
    if (object->_row.get_table() != &_backingView.get_parent()) {
        @throw RLMException(@"Object type '%@' does not match RLMResults type '%@'.", object->_objectSchema.className, _objectClassName);
    }

    size_t object_ndx = object->_row.get_index();
    return RLMConvertNotFound(_backingView.find_by_source_ndx(object_ndx));
}

- (id)valueForKey:(NSString *)key {
    RLMResultsValidate(self);
    return RLMCollectionValueForKey(self, key);
}

- (void)setValue:(id)value forKey:(NSString *)key {
    RLMResultsValidateInWriteTransaction(self);
    RLMCollectionSetValueForKey(self, key, value);
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
    RLMCheckThread(_realm);

    // copy array and apply new predicate creating a new query and view
    auto query = [self cloneQuery];
    RLMUpdateQueryWithPredicate(query.get(), predicate, _realm.schema, _realm.schema[self.objectClassName]);
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                            query:move(query)
                                             sort:_sortOrder
                                            realm:_realm];
}

- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending {
    return [self sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:property ascending:ascending]]];
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties {
    RLMCheckThread(_realm);

    auto query = [self cloneQuery];
    return [RLMResults resultsWithObjectClassName:self.objectClassName
                                            query:move(query)
                                             sort:RLMSortOrderFromDescriptors(_objectSchema, properties)
                                            realm:_realm];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

template<typename TableType>
static id minOfProperty(TableType const& table, RLMRealm *realm, NSString *objectClassName, NSString *property) {
    if (table.size() == 0) {
        return nil;
    }

    NSUInteger colIndex = RLMValidatedColumnIndex(realm.schema[objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(table.get_column_type(colIndex));

    switch (colType) {
        case RLMPropertyTypeInt:
            return @(table.minimum_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(table.minimum_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(table.minimum_float(colIndex));
        case RLMPropertyTypeDate: {
            realm::DateTime dt = table.minimum_datetime(colIndex);
            return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
        }
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"minOfProperty only supported for int, float, double and date properties."
                                         userInfo:nil];
    }
}

- (id)minOfProperty:(NSString *)property {
    RLMResultsValidate(self);
    return minOfProperty(_backingView, _realm, _objectClassName, property);
}

template<typename TableType>
static id maxOfProperty(TableType const& table, RLMRealm *realm, NSString *objectClassName, NSString *property) {
    if (table.size() == 0) {
        return nil;
    }

    NSUInteger colIndex = RLMValidatedColumnIndex(realm.schema[objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(table.get_column_type(colIndex));

    switch (colType) {
        case RLMPropertyTypeInt:
            return @(table.maximum_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(table.maximum_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(table.maximum_float(colIndex));
        case RLMPropertyTypeDate: {
            realm::DateTime dt = table.maximum_datetime(colIndex);
            return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
        }
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"maxOfProperty only supported for int, float, double and date properties."
                                         userInfo:nil];
    }
}

- (id)maxOfProperty:(NSString *)property {
    RLMResultsValidate(self);
    return maxOfProperty(_backingView, _realm, _objectClassName, property);
}

template<typename TableType>
static NSNumber *sumOfProperty(TableType const& table, RLMRealm *realm, NSString *objectClassName, NSString *property) {
    if (table.size() == 0) {
        return @0;
    }

    NSUInteger colIndex = RLMValidatedColumnIndex(realm.schema[objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(table.get_column_type(colIndex));

    switch (colType) {
        case RLMPropertyTypeInt:
            return @(table.sum_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(table.sum_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(table.sum_float(colIndex));
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"sumOfProperty only supported for int, float and double properties."
                                         userInfo:nil];
    }
}

-(NSNumber *)sumOfProperty:(NSString *)property {
    RLMResultsValidate(self);
    return sumOfProperty(_backingView, _realm, _objectClassName, property);
}

template<typename TableType>
static NSNumber *averageOfProperty(TableType const& table, RLMRealm *realm, NSString *objectClassName, NSString *property) {
    if (table.size() == 0) {
        return nil;
    }

    NSUInteger colIndex = RLMValidatedColumnIndex(realm.schema[objectClassName], property);
    RLMPropertyType colType = RLMPropertyType(table.get_column_type(colIndex));

    switch (colType) {
        case RLMPropertyTypeInt:
            return @(table.average_int(colIndex));
        case RLMPropertyTypeDouble:
            return @(table.average_double(colIndex));
        case RLMPropertyTypeFloat:
            return @(table.average_float(colIndex));
        default:
            @throw [NSException exceptionWithName:@"RLMOperationNotSupportedException"
                                           reason:@"averageOfProperty only supported for int, float and double properties."
                                         userInfo:nil];
    }
}

-(NSNumber *)averageOfProperty:(NSString *)property {
    RLMResultsValidate(self);
    return averageOfProperty(_backingView, _realm, _objectClassName, property);
}

- (void)deleteObjectsFromRealm {
    RLMResultsValidateInWriteTransaction(self);

    RLMTrackDeletions(_realm, ^{
        // call clear to remove all from the realm
        _backingView.clear();
    });
}

- (NSString *)description {
    const NSUInteger maxObjects = 100;
    NSMutableString *mString = [NSMutableString stringWithFormat:@"RLMResults <0x%lx> (\n", (long)self];
    unsigned long index = 0, skipped = 0;
    for (id obj in self) {
        NSString *sub;
        if ([obj respondsToSelector:@selector(descriptionWithMaxDepth:)]) {
            sub = [obj descriptionWithMaxDepth:RLMDescriptionMaxDepth - 1];
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

- (std::unique_ptr<Query>)cloneQuery {
    return std::make_unique<realm::Query>(*_backingQuery, realm::Query::TCopyExpressionTag{});
}

- (NSUInteger)indexInSource:(NSUInteger)index {
    return _backingView.get_source_ndx(index);
}

- (realm::TableView)tableView {
    RLMResultsValidateAttached(self);
    // note: deliberately copies it
    return _backingView;
}

@end

@implementation RLMTableResults {
    realm::TableRef _table;
}

+ (RLMResults *)tableResultsWithObjectSchema:(RLMObjectSchema *)objectSchema realm:(RLMRealm *)realm {
    RLMTableResults *results = [self resultsWithObjectClassName:objectSchema.className
                                                          query:nullptr
                                                          realm:realm];
    results->_table.reset(objectSchema.table);
    return results;
}

- (NSUInteger)count {
    RLMCheckThread(_realm);
    return _table->size();
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    RLMCheckThread(_realm);
    if (object.invalidated) {
        @throw RLMException(@"RLMObject is no longer valid");
    }
    if (!object->_row) {
        return NSNotFound;
    }

    // check that object types align
    if (object->_row.get_table() != _table) {
        @throw RLMException(@"Object type '%@' does not match RLMResults type '%@'.", object->_objectSchema.className, _objectClassName);
    }

    return RLMConvertNotFound(object->_row.get_index());
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    RLMResultsValidate(self);

    Query query = _table->where();
    RLMUpdateQueryWithPredicate(&query, predicate, _realm.schema, _realm.schema[self.objectClassName]);
    return RLMConvertNotFound(query.find());
}

- (id)minOfProperty:(NSString *)property {
    RLMCheckThread(_realm);
    return minOfProperty(*_table, _realm, _objectClassName, property);
}

- (id)maxOfProperty:(NSString *)property {
    RLMCheckThread(_realm);
    return maxOfProperty(*_table, _realm, _objectClassName, property);
}

- (NSNumber *)sumOfProperty:(NSString *)property {
    RLMCheckThread(_realm);
    return sumOfProperty(*_table, _realm, _objectClassName, property);
}

- (NSNumber *)averageOfProperty:(NSString *)property {
    RLMCheckThread(_realm);
    return averageOfProperty(*_table, _realm, _objectClassName, property);
}

- (void)deleteObjectsFromRealm {
    RLMResultsValidateInWriteTransaction(self);
    RLMClearTable(self.objectSchema);
}

- (std::unique_ptr<Query>)cloneQuery {
    return std::make_unique<realm::Query>(_table->where(), realm::Query::TCopyExpressionTag{});
}

- (NSUInteger)indexInSource:(NSUInteger)index {
    return index;
}

- (realm::TableView)tableView {
    return _table->where().find_all();
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

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    return NSNotFound;
}

- (id)objectAtIndex:(NSUInteger)index {
    @throw RLMException(@"Index %@ is out of bounds.", @(index));
}

- (id)valueForKey:(NSString *)key {
    RLMResultsValidate(self);
    return @[];
}

- (void)setValue:(__unused id)value forKey:(__unused NSString *)key {
    RLMResultsValidateInWriteTransaction(self);
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
