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

#import "RLMArray_Private.hpp"
#import "RLMArrayAccessor.h"

#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.h"
#import "RLMConstants.h"

#import <objc/runtime.h>

#import <tightdb/util/unique_ptr.hpp>

//
// Private properties
//
@interface RLMArray ()
@property (nonatomic, assign) tightdb::Query *backingQuery;
// When getting the backingView using dot notation, the tableview is copied in core. Use _backingView instead when accessing.
@property (nonatomic, assign) tightdb::TableView backingView;
@property (nonatomic, copy) NSString *objectClassName;
@end

//
// RLMArray implementation
//
@implementation RLMArray {
    tightdb::util::UniquePtr<tightdb::Query> _backingQuery;
}

@dynamic backingQuery;
@synthesize realm = _realm;
@synthesize objectIndex = _objectIndex;
@synthesize backingTableIndex = _backingTableIndex;
@synthesize backingTable = _backingTable;
@synthesize writable = _writable;

- (instancetype)initWithObjectClassName:(NSString *)objectClassName
                                  query:(tightdb::Query *)query
                                   view:(tightdb::TableView &)view {
    self = [super init];
    if (self) {
        self.objectClassName = objectClassName;
        self.backingQuery = query;
        _backingView = view;
    }
    return self;
}

- (instancetype)initWithObjectClassName:(NSString *)objectClassName {
    self = [super init];
    if (self) {
        self.objectClassName = objectClassName;
    }
    return self;
}

- (void)setWritable:(BOOL)writable {
    if (writable) {
        object_setClass(self, RLMArray.class);
    }
    else {
        object_setClass(self, RLMArrayReadOnly.class);
    }
    _writable = writable;
}

- (NSUInteger)count {
    return _backingView.size();
}

inline id RLMCreateAccessorForArrayIndex(RLMArray *array, NSUInteger index) {
    return RLMCreateObjectAccessor(array->_realm,
                                   array->_objectClassName,
                                   array->_backingView.get_source_ndx(index));
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

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
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
#pragma GCC diagnostic pop

- (void)setBackingQuery:(tightdb::Query *)backingQuery {
    _backingQuery.reset(backingQuery);
}

- (tightdb::Query *)backingQuery {
    return _backingQuery.get();
}

- (RLMArray *)copy {
    RLMArray *array = [[RLMArray alloc] initWithObjectClassName:_objectClassName];
    array.realm = _realm;
    array.backingTable = _backingTable;
    array.backingTableIndex = _backingTableIndex;
    array.backingQuery = new tightdb::Query(*_backingQuery);
    array.backingView = array.backingTable->where(&_backingView).find_all();
    [_realm registerAccessor:array];
    return array;
}

- (RLMArray *)objectsWhere:(id)predicate, ... {
    // validate predicate
    NSPredicate *outPred;
    RLM_PREDICATE(predicate, outPred);
    
    // copy array and apply new predicate creating a new query and view
    RLMArray *array = [self copy];
    RLMUpdateQueryWithPredicate(array.backingQuery, predicate, array.realm.schema[_objectClassName]);
    array.backingView = array.backingQuery->find_all();
    return array;
}

- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ... {
    // validate predicate
    NSPredicate *outPred;
    RLM_PREDICATE(predicate, outPred);
    
    // copy array and apply new predicate
    RLMArray *array = [self copy];
    RLMObjectSchema *schema = array.realm.schema[_objectClassName];
    RLMUpdateQueryWithPredicate(array.backingQuery, predicate, schema);
    tightdb::TableView view = array.backingQuery->find_all();
    
    // apply order
    RLMUpdateViewWithOrder(view, order, schema);
    array.backingView = view;
    return array;
}

-(id)minOfProperty:(NSString *)property {
    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[_objectClassName], property);
    
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
    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[_objectClassName], property);
    
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
    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[_objectClassName], property);
    
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
    NSUInteger colIndex = RLMValidatedColumnIndex(_realm.schema[_objectClassName], property);
    
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

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (void)setObject:(id)newValue atIndexedSubscript:(NSUInteger)index {
    [self replaceObjectAtIndex:index withObject:newValue];
}

#pragma mark - Superclass Overrides

- (NSString *)description
{
    NSMutableString *mString = [NSMutableString stringWithString:@"RLMArray (\n"];
    NSUInteger index = 0;
    NSUInteger skippedObjects = 0;
    for (RLMObject *object in self) {
        // Only display the first 1000 objects
        if (index == 1000) {
            skippedObjects = [self count] - 1000;
            break;
        }
        
        // Indent child objects
        NSString *objDescription = [object.description stringByReplacingOccurrencesOfString:@"\n"
                                                                                 withString:@"\n\t"];
        [mString appendFormat:@"\t[%lu] %@,\n", (unsigned long)index, objDescription];
        index++;
    }
    // Remove last comma and newline characters
    [mString deleteCharactersInRange:NSMakeRange(mString.length-2, 2)];
    if (skippedObjects > 0) {
        [mString appendFormat:@"\n\t... %lu objects skipped.", (unsigned long)skippedObjects];
    }
    [mString appendFormat:@"\n)"];
    return [NSString stringWithString:mString];
}

@end
