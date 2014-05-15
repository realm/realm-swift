/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import "RLMArray.h"
#import "RLMPrivate.hpp"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.h"

@implementation RLMArray {
    tightdb::util::UniquePtr<tightdb::Query> _backingQuery;
}

@dynamic backingQuery;
@synthesize realm = _realm;
@synthesize objectIndex = _objectIndex;
@synthesize backingTableIndex = _backingTableIndex;
@synthesize backingTable = _backingTable;
@synthesize writable = _writable;

- (instancetype)initWithObjectClass:(Class)objectClass {
    self = [super init];
    if (self) {
        self.objectClass = objectClass;
        self.accessorClass = RLMAccessorClassForObjectClass(objectClass);
    }
    return self;
}

// construct/populate accessor object
inline RLMObject *RLMCreateAccessor(RLMArray *self, NSUInteger index) {
    RLMObject *accessor = [[self->_accessorClass alloc] init];
    accessor.realm = self->_realm;
    accessor.backingTable = self->_backingTable;
    accessor.backingTableIndex = self->_backingTableIndex;
    accessor.objectIndex = self->_backingView.get_source_ndx(index);
    [self->_realm registerAcessor:accessor];
    return accessor;
}

- (NSUInteger)count {
    return _backingView.size();
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    NSUInteger batchCount = 0, index = state->state, count = self.count;
    while (index < count && batchCount < len) {
        buffer[batchCount++] = RLMCreateAccessor(self, index++);
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
    return RLMCreateAccessor(self, index);
}

- (id)firstObject {
    if (self.count) {
        return RLMCreateAccessor(self, 0);
    }
    return nil;
}

- (id)lastObject {
    NSUInteger count = self.count;
    if (count) {
        return RLMCreateAccessor(self, count-1);
    }
    return nil;
}

- (void)addObject:(RLMObject *)object {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)addObjectsFromArray:(id)objects {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)insertObject:(RLMObject *)anObject atIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)removeLastObject {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)removeAllObjects {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (NSUInteger)indexOfObjectWhere:(id)predicate, ... {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

- (void)setBackingQuery:(tightdb::Query *)backingQuery {
    _backingQuery.reset(backingQuery);
}

- (tightdb::Query *)backingQuery {
    return _backingQuery.get();
}

- (RLMArray *)copy {
    RLMArray *array = [[RLMArray alloc] initWithObjectClass:_objectClass];
    array.realm = _realm;
    array.backingTable = _backingTable;
    array.backingTableIndex = _backingTableIndex;
    array.backingView = _backingView;
    array.backingQuery = new tightdb::Query(*_backingQuery);
    [_realm registerAcessor:array];
    return array;
}

- (RLMArray *)objectsWhere:(id)predicate, ... {
    // validate predicate
    NSPredicate *outPred;
    RLM_PREDICATE(predicate, outPred);
    
    // copy array and apply new predicate creating a new query and view
    RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:_objectClass];
    RLMArray *array = [self copy];
    RLMUpdateQueryWithPredicate(array.backingQuery, predicate, desc);;
    array.backingView = array.backingQuery->find_all();
    return array;
}

- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ... {
    // validate predicate
    NSPredicate *outPred;
    RLM_PREDICATE(predicate, outPred);
    
    // copy array and apply new predicate
    RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:_objectClass];
    RLMArray *array = [self copy];
    RLMUpdateQueryWithPredicate(array.backingQuery, predicate, desc);
    tightdb::TableView view = array.backingQuery->find_all();
    
    // apply order
    RLMUpdateViewWithOrder(view, order, desc);
    array.backingView = view;
    return array;
}

-(id)minOfProperty:(NSString *)property {
    NSUInteger colIndex = RLMValidatedColumnIndex([RLMObjectDescriptor descriptorForObjectClass:_objectClass], property);
    
    tightdb::TableView table = self.backingQuery->find_all();
    RLMType colType = RLMType(table.get_column_type(colIndex));
    
    switch (colType) {
            case RLMTypeInt:
                return @(table.minimum_int(colIndex));
            case RLMTypeDouble:
                return @(table.minimum_double(colIndex));
            case RLMTypeFloat:
                return @(table.minimum_float(colIndex));
            case RLMTypeDate:
                @throw [NSException exceptionWithName:@"realm:operation_not_supported"
                                           reason:@"Minimum not supported on date columns yet"
                                         userInfo:nil];
        default:
            @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
                                           reason:@"Sum only supported on int, float and double columns."
                                         userInfo:nil];
    }
}

-(id)maxOfProperty:(NSString *)property {
    NSUInteger colIndex = RLMValidatedColumnIndex([RLMObjectDescriptor descriptorForObjectClass:_objectClass], property);
    
    tightdb::TableView table = self.backingQuery->find_all();
    RLMType colType = RLMType(table.get_column_type(colIndex));
    
    switch (colType) {
            case RLMTypeInt:
                return @(table.maximum_int(colIndex));
            case RLMTypeDouble:
                return @(table.maximum_double(colIndex));
            case RLMTypeFloat:
                return @(table.maximum_float(colIndex));
            case RLMTypeDate:
                @throw [NSException exceptionWithName:@"realm:operation_not_supported"
                                           reason:@"Maximum not supported on date columns yet"
                                         userInfo:nil];
            
        default:
            @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
                                           reason:@"Maximum only supported on int, float and double columns."
                                         userInfo:nil];
    }
}

-(NSNumber *)sumOfProperty:(NSString *)property {
    NSUInteger colIndex = RLMValidatedColumnIndex([RLMObjectDescriptor descriptorForObjectClass:_objectClass], property);
    
    tightdb::TableView table = self.backingQuery->find_all();
    RLMType colType = RLMType(table.get_column_type(colIndex));
    
    switch (colType) {
            case RLMTypeInt:
                return @(table.sum_int(colIndex));
            case RLMTypeDouble:
                return @(table.sum_double(colIndex));
            case RLMTypeFloat:
                return @(table.sum_float(colIndex));
            
        default:
            @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
                                           reason:@"Maximum only supported on int, float and double columns."
                                         userInfo:nil];
    }
}

-(NSNumber *)averageOfProperty:(NSString *)property {
    NSUInteger colIndex = RLMValidatedColumnIndex([RLMObjectDescriptor descriptorForObjectClass:_objectClass], property);
    
    tightdb::TableView table = self.backingQuery->find_all();
    RLMType colType = RLMType(table.get_column_type(colIndex));
    
    switch (colType) {
            case RLMTypeInt:
                return @(table.average_int(colIndex));
            case RLMTypeDouble:
                return @(table.average_double(colIndex));
            case RLMTypeFloat:
                return @(table.average_float(colIndex));
            
        default:
            @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
                                           reason:@"Sum only supported on int, float and double columns."
                                         userInfo:nil];
    }
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