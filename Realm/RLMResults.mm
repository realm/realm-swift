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
                                      sort:(RowIndexes::Sorter const&)sorter
                                      view:(realm::TableView &&)view
                                     realm:(RLMRealm *)realm {
    RLMResults *ar = [[RLMResults alloc] initPrivate];
    ar->_objectClassName = objectClassName;
    ar->_viewCreated = YES;
    ar->_backingView = std::move(view);
    ar->_backingQuery = move(query);
    ar->_sortOrder = sorter;
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
        // FIXME: mutationsPtr should be pointing to a value updated by core
        // whenever the results are changed rather than doing this check
        if (state->extra[1] != self.count) {
            @throw RLMException(@"Collection was mutated while being enumerated.");
        }
        items = (__bridge id)(void *)state->extra[0];
        [items resize:len];
    }

    NSUInteger batchCount = 0, index = state->state, count = state->extra[1];

    Class accessorClass = _objectSchema.accessorClass;
    while (index < count && batchCount < len) {
        // get acessor fot the object class
        RLMObject *accessor = [[accessorClass alloc] initWithRealm:_realm schema:_objectSchema];
        accessor->_row = (*_objectSchema.table)[[self indexInSource:index++]];
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
        @throw RLMException(@"Index is out of bounds.", @{@"index": @(index)});
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
        NSString *message = [NSString stringWithFormat:@"Object type '%@' does not match RLMResults type '%@'.", object->_objectSchema.className, _objectClassName];
        @throw RLMException(message);
    }

    size_t object_ndx = object->_row.get_index();
    return RLMConvertNotFound(_backingView.find_by_source_ndx(object_ndx));
}

- (id)valueForKey:(NSString *)key {
    RLMResultsValidate(self);
    const size_t size = _backingView.size();
    return RLMCollectionValueForKey(key, _realm, _objectSchema, size, ^size_t(size_t index) {
        return _backingView.get_source_ndx(index);
    });
}

- (void)setValue:(id)value forKey:(NSString *)key {
    RLMResultsValidateInWriteTransaction(self);
    const size_t size = _backingView.size();
    RLMCollectionSetValueForKey(value, key, _realm, _objectSchema, size, ^size_t(size_t index) {
        return _backingView.get_source_ndx(index);
    });
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

namespace {
    struct RealmCreation {
        NSString *path;
        NSData *key;
        BOOL readOnly;
        BOOL inMemory;
        BOOL dynamic;
        RLMSchema *schema;
    };

    RLMRealm *createWithRealmCreation(RealmCreation realmCreation, SharedGroup::VersionID version, NSError **error) {
        try {
            RLMRealm *realm = [RLMRealm realmWithPath:realmCreation.path key:realmCreation.key readOnly:realmCreation.readOnly inMemory:realmCreation.inMemory dynamic:realmCreation.dynamic schema:realmCreation.schema error:error];
            [realm refresh];
            [realm getOrCreateGroupAtVersion:version];
            return realm;
        }
        catch (std::exception const& ex) {
            RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, ex), error);
            return nil;
        }
    }

    void deliverQuery(dispatch_queue_t queryQueue, dispatch_queue_t deliveryQueue, RealmCreation realmCreation,
                      NSString *objectClassName, SharedGroup::Handover<Query> *queryHandoverPtr,
                      SharedGroup::Handover<TableView> *tableViewHandoverPtr,
                      RowIndexes::Sorter sort, void (^resultsBlock)(RLMResults * __nullable, NSError  * __nullable));

    void queryOnBackgroundQueue(dispatch_queue_t queryQueue, dispatch_queue_t deliveryQueue, RealmCreation realmCreation,
                                NSString *objectClassName, std::unique_ptr<SharedGroup::Handover<Query>> queryHandover,
                                RowIndexes::Sorter sort, void (^resultsBlock)(RLMResults * __nullable, NSError  * __nullable)) {
        SharedGroup::Handover<Query> *queryHandoverPtr = queryHandover.release();
        dispatch_async(queryQueue, ^{
            @autoreleasepool {
                std::unique_ptr<SharedGroup::Handover<Query>> queryHandover(queryHandoverPtr);
                NSError *realmCreationError = nil;
                RLMRealm *realm = createWithRealmCreation(realmCreation, queryHandover->version, &realmCreationError);
                if (!realm) {
                    dispatch_async(deliveryQueue, ^{
                        resultsBlock(nil, realmCreationError);
                    });
                    return;
                }
                auto querySharedGroup = realm.sharedGroup;
                std::unique_ptr<Query> query = querySharedGroup->import_from_handover(std::move(queryHandover));
                auto tableView = query->find_all();
                tableView.sort(sort.m_column_indexes, sort.m_ascending);
                SharedGroup::Handover<TableView> *tableViewHandoverPtr = querySharedGroup->export_for_handover(tableView, MutableSourcePayload::Move).release();
                SharedGroup::Handover<Query> *innerQueryHandoverPtr = querySharedGroup->export_for_handover(*query, ConstSourcePayload::Stay).release();
                deliverQuery(queryQueue, deliveryQueue, realmCreation, objectClassName, innerQueryHandoverPtr, tableViewHandoverPtr, sort, resultsBlock);
            }
        });
    }

    void deliverQuery(dispatch_queue_t queryQueue, dispatch_queue_t deliveryQueue, RealmCreation realmCreation,
                      NSString *objectClassName, SharedGroup::Handover<Query> *queryHandoverPtr,
                      SharedGroup::Handover<TableView> *tableViewHandoverPtr,
                      RowIndexes::Sorter sort, void (^resultsBlock)(RLMResults * __nullable, NSError  * __nullable)) {
        dispatch_async(deliveryQueue, ^{
            @autoreleasepool {
                std::unique_ptr<SharedGroup::Handover<Query>> queryHandover(queryHandoverPtr);
                std::unique_ptr<SharedGroup::Handover<TableView>> tableViewHandover(tableViewHandoverPtr);
                NSError *realmCreationError = nil;
                RLMRealm *realm = createWithRealmCreation(realmCreation, queryHandover->version, &realmCreationError);
                if (!realm) {
                    dispatch_async(deliveryQueue, ^{
                        resultsBlock(nil, realmCreationError);
                    });
                    return;
                }
                auto resultsSharedGroup = realm.sharedGroup;
                if (!resultsSharedGroup || resultsSharedGroup->get_version_of_current_transaction() != queryHandover->version) {
                    queryOnBackgroundQueue(queryQueue, deliveryQueue, realmCreation, objectClassName, std::move(queryHandover), sort, resultsBlock);
                    return;
                }
                std::unique_ptr<Query> query = resultsSharedGroup->import_from_handover(std::move(queryHandover));
                std::unique_ptr<TableView> tableView = resultsSharedGroup->import_from_handover(std::move(tableViewHandover));
                RLMResults *results = [RLMResults resultsWithObjectClassName:objectClassName query:move(query) sort:sort view:std::move(*tableView) realm:realm];
                resultsBlock(results, nil);
            }
        });
    }
}

- (void)deliverOnQueue:(dispatch_queue_t)queue block:(void (^)(RLMResults RLM_GENERIC_PARAMETER(RLMObject) * __nullable, NSError  * __nullable))block {
    [self deliverOnQueue:queue queryQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) block:block];
}

- (void)deliverOnQueue:(dispatch_queue_t)queue queryQueue:(dispatch_queue_t)queryQueue block:(void (^)(RLMResults * __nullable, NSError  * __nullable))block {
    RLMCheckThread(_realm);
    if (_realm.readOnly) {
        @throw RLMException(@"Cannot perform query delivery on read-only realms.");
    }

    RealmCreation realmCreation {
        _realm.path, nil, _realm.readOnly, _realm.inMemory, _realm.dynamic, _realm.dynamic ? _realm.schema : nil
    };

    auto sharedGroup = _realm.sharedGroup;
    try {
        std::unique_ptr<SharedGroup::Handover<Query>> queryHandover = sharedGroup->export_for_handover(*[self cloneQuery], ConstSourcePayload::Stay);
        if (_viewCreated) {
            auto tableViewHandoverPtr = sharedGroup->export_for_handover(_backingView, ConstSourcePayload::Stay).release();
            deliverQuery(queryQueue, queryQueue, realmCreation, _objectClassName, queryHandover.release(), tableViewHandoverPtr, _sortOrder, block);
        }
        else {
            queryOnBackgroundQueue(queryQueue, queue, realmCreation, _objectClassName, std::move(queryHandover), _sortOrder, block);
        }
    }
    catch (std::exception const& exception) {
        @throw RLMException(exception);
    }
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

- (id)valueForKey:(NSString *)key {
    RLMResultsValidate(self);
    const size_t size = _table->size();
    return RLMCollectionValueForKey(key, _realm, _objectSchema, size, ^size_t(size_t index) {
        return index;
    });
}

- (void)setValue:(id)value forKey:(NSString *)key {
    RLMResultsValidateInWriteTransaction(self);
    const size_t size = _table->size();
    RLMCollectionSetValueForKey(value, key, _realm, _objectSchema, size, ^size_t(size_t index) {
        return index;
    });
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
        NSString *message = [NSString stringWithFormat:@"Object type '%@' does not match RLMResults type '%@'.", object->_objectSchema.className, _objectClassName];
        @throw RLMException(message);
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
    RLMClearTable(_objectSchema);
}

- (std::unique_ptr<Query>)cloneQuery {
    return std::make_unique<realm::Query>(_table->where(), realm::Query::TCopyExpressionTag{});
}

- (NSUInteger)indexInSource:(NSUInteger)index {
    return index;
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
    @throw RLMException(@"Index is out of bounds.", @{@"index": @(index)});
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
