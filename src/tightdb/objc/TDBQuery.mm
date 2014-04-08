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

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/util/file.hpp>
#include <tightdb/exceptions.hpp>
#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/query.hpp>

#import <tightdb/objc/TDBQuery.h>
#import <tightdb/objc/TDBTable.h>
#import <tightdb/objc/TDBTable_noinst.h>
#import <tightdb/objc/TDBView.h>
#import <tightdb/objc/TDBView_noinst.h>
#import <tightdb/objc/TDBRow.h>
#import "NSData+TDBGetBinaryData.h"
#import <tightdb/objc/PrivateTDB.h>

#include <tightdb/objc/util_noinst.hpp>


using namespace std;


@interface TDBQuery()
{
    @public
    NSError* m_error; // To enable the flow of multiple stacked queries, any error is kept until the last step.
}
@end


@implementation TDBQuery
{
    tightdb::util::UniquePtr<tightdb::Query> m_query;
    __weak TDBTable* m_table;

    TDBRow* m_tmp_row;
}

-(id)initWithTable:(TDBTable*)table
{
    return [self initWithTable:table error:nil];
}

-(id)initWithTable:(TDBTable*)table error:(NSError* __autoreleasing*)error
{
    self = [super init];
    if (self) {
        m_table = table;
        TIGHTDB_EXCEPTION_ERRHANDLER(
            m_query.reset(new tightdb::Query([table getNativeTable].where()));,
            nil);
    }
    return self;
}

-(void)setTableView:(tightdb::TableView&)tableView
{
    m_query->tableview(tableView);
}

-(TDBRow*)getRow:(long)ndx
{
    return m_tmp_row = [[TDBRow alloc] initWithTable:[self originTable] ndx:ndx];
}

-(long)getFastEnumStart
{
    return [self indexOfFirstMatchingRowFromIndex:0];
}

-(long)incrementFastEnum:(long)ndx
{
    return [self indexOfFirstMatchingRowFromIndex:ndx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id __unsafe_unretained*)stackbuf count:(NSUInteger)len
{
    static_cast<void>(len);
    if (state->state == 0) {
        state->state = [self getFastEnumStart];
        state->mutationsPtr = (unsigned long*)objc_unretainedPointer(self);
        TDBRow* tmp = [self getRow:state->state];
        *stackbuf = tmp;
    }
    if (state->state < [self originTable].rowCount && state->state != (NSUInteger)NSNotFound) {
        [((TDBRow*)*stackbuf) TDB_setNdx:state->state];
        state->itemsPtr = stackbuf;
        state->state = [self incrementFastEnum:state->state+1];
    } else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        return 0;
    }
    return 1;
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TDBQuery dealloc");
#endif
}

-(tightdb::Query&)getNativeQuery
{
    return *m_query;
}

-(TDBTable*)originTable
{
    return m_table;
}

-(TDBQuery*)group
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->group();, self, &m_error);
    return self;
}
-(TDBQuery*)Or
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->Or();, self, &m_error);
    return self;
}
-(TDBQuery*)endGroup
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->end_group();, self, &m_error);
    return self;
}
-(TDBQuery *)subtableInColumnWithIndex:(NSUInteger)column
{
    m_query->subtable(column);
    return self;
}
-(TDBQuery *)parent
{
    m_query->end_subtable();
    return self;
}

-(NSUInteger)countRows
{
    return m_query->count();
}


-(NSUInteger)removeRows
{
    if ([m_table isReadOnly]) {
        @throw [NSException exceptionWithName:@"tightdb:table_is_read_only"
                                       reason:@"You tried to modify an immutable table"
                                     userInfo:[NSMutableDictionary dictionary]];
    }
    return m_query->remove();
}

-(id)minInColumnWithIndex:(NSUInteger)colIndex
{
    TDBType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == TDBIntType) {
        return [NSNumber numberWithInteger:[self minIntInColumnWithIndex:colIndex]];
    }
    else if (colType == TDBDoubleType) {
        return [NSNumber numberWithDouble:[self minDoubleInColumnWithIndex:colIndex]];
    }
    else if (colType == TDBFloatType) {
        return [NSNumber numberWithDouble:[self minFloatInColumnWithIndex:colIndex]];
    }
    else if (colType == TDBDateType) {
        return [self minDateInColumnWithIndex:colIndex];
    }
    else {
        @throw [NSException exceptionWithName:@"tightdb:operation_not_supprted"
                                       reason:@"Min only supported on int, float, double and date columns."
                                     userInfo:nil];
    }
}

-(int64_t)minIntInColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->minimum_int(col_ndx);
}

-(float)minFloatInColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->minimum_float(col_ndx);
}

-(double)minDoubleInColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->minimum_double(col_ndx);
}

-(NSDate *)minDateInColumnWithIndex:(NSUInteger)col_ndx
{
    if (self.originTable.rowCount == 0) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970: m_query->minimum_int(col_ndx)];
}


-(id)maxInColumnWithIndex:(NSUInteger)colIndex
{
    TDBType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == TDBIntType) {
        return [NSNumber numberWithInteger:[self maxIntInColumnWithIndex:colIndex]];
    }
    else if (colType == TDBDoubleType) {
        return [NSNumber numberWithDouble:[self maxDoubleInColumnWithIndex:colIndex]];
    }
    else if (colType == TDBFloatType) {
        return [NSNumber numberWithDouble:[self maxFloatInColumnWithIndex:colIndex]];
    }
    else if (colType == TDBDateType) {
        return [self maxDateInColumnWithIndex:colIndex];
    }
    else {
        @throw [NSException exceptionWithName:@"tightdb:operation_not_supprted"
                                       reason:@"Max only supported on int, float, double and date columns."
                                     userInfo:nil];
    }
}

-(int64_t)maxIntInColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->maximum_int(col_ndx);
}

-(float)maxFloatInColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->maximum_float(col_ndx);
}

-(double)maxDoubleInColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->maximum_double(col_ndx);
}

-(NSDate *)maxDateInColumnWithIndex:(NSUInteger)col_ndx
{
    if (self.originTable.rowCount == 0) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970: m_query->maximum_int(col_ndx)];
}

-(NSNumber *)sumColumnWithIndex:(NSUInteger)colIndex
{
    TDBType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == TDBIntType) {
        return [NSNumber numberWithInteger:[self sumIntColumnWithIndex:colIndex]];
    }
    else if (colType == TDBDoubleType) {
        return [NSNumber numberWithDouble:[self sumDoubleColumnWithIndex:colIndex]];
    }
    else if (colType == TDBFloatType) {
        return [NSNumber numberWithDouble:[self sumFloatColumnWithIndex:colIndex]];
    }
    else {
        @throw [NSException exceptionWithName:@"tightdb:operation_not_supprted"
                                       reason:@"Sum only supported on int, float and double columns."
                                     userInfo:nil];
    }
}


-(int64_t)sumIntColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->sum_int(col_ndx);
}


-(double)sumFloatColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->sum_float(col_ndx);
}


-(double)sumDoubleColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->sum_double(col_ndx);
}

-(NSNumber *)avgColumnWithIndex:(NSUInteger)colIndex
{
    TDBType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == TDBIntType) {
        return [NSNumber numberWithDouble:[self avgIntColumnWithIndex:colIndex]];
    }
    else if (colType == TDBDoubleType) {
        return [NSNumber numberWithDouble:[self avgDoubleColumnWithIndex:colIndex]];
    }
    else if (colType == TDBFloatType) {
        return [NSNumber numberWithDouble:[self avgFloatColumnWithIndex:colIndex]];
    }
    else {
        @throw [NSException exceptionWithName:@"tightdb:operation_not_supprted"
                                       reason:@"Avg only supported on int, float and double columns."
                                     userInfo:nil];
    }
}

-(double)avgIntColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->average_int(col_ndx);
}

-(double)avgFloatColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->average_float(col_ndx);
}


-(double)avgDoubleColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->average_double(col_ndx);
}



-(TDBView*)findAllRows
{
    tightdb::TableView view = m_query->find_all();
    return [TDBView viewWithTable:m_table andNativeView:view];
}

-(NSUInteger)indexOfFirstMatchingRow
{
    return was_not_found(m_query->find(0));
}

-(NSUInteger)indexOfFirstMatchingRowFromIndex:(NSUInteger)rowIndex
{
    size_t n = m_query->find(size_t(rowIndex));
    NSUInteger m = was_not_found(n);
    return m;
}


// Conditions:
-(TDBQuery*)boolIsEqualTo:(bool)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aBool);
    return self;
}

-(TDBQuery*)intIsEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, anInt);
    return self;
}

-(TDBQuery*)floatIsEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aFloat);
    return self;
}

-(TDBQuery*)doubleIsEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aDouble);
    return self;
}

-(TDBQuery*)stringIsEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, ObjcStringAccessor(aString), true);
    return self;
}

-(TDBQuery*)stringIsCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, ObjcStringAccessor(aString), false);
    return self;
}


-(TDBQuery*)dateIsEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal_datetime(colIndex, [aDate timeIntervalSince1970]);
    return self;
}

-(TDBQuery*)binaryIsEqualTo:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aBinary.tdbBinaryData);
    return self;
}

// Not equal to

-(TDBQuery*)intIsNotEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(TDBQuery*)floatIsNotEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(TDBQuery*)doubleIsNotEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(TDBQuery*)stringIsNotEqualTo:(NSString*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, ObjcStringAccessor(value), true);
    return self;
}

-(TDBQuery*)stringIsNotCaseInsensitiveEqualTo:(NSString*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, ObjcStringAccessor(value), false);
    return self;
}

-(TDBQuery*)dateIsNotEqualTo:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

-(TDBQuery*)binaryIsNotEqualTo:(NSData*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value.tdbBinaryData);
    return self;
}

// Between

-(TDBQuery*)dateIsBetween:(NSDate *)lower :(NSDate *)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between_datetime(colIndex, lower.timeIntervalSince1970, upper.timeIntervalSince1970);
    return self;
}

-(TDBQuery*)intIsBetween:(int64_t)lower :(int64_t)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between(colIndex, lower, upper);
    return self;
}

-(TDBQuery*)floatIsBetween:(float)lower :(float)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between(colIndex, lower, upper);
    return self;
}

-(TDBQuery*)doubleIsBetween:(double)lower :(double)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between(colIndex, lower, upper);
    return self;
}

// Greater than

-(TDBQuery*)intIsGreaterThan:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(TDBQuery*)floatIsGreaterThan:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(TDBQuery*)doubleIsGreaterThan:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(TDBQuery*)dateIsGreaterThan:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

// Greater thanOrEqualTo

-(TDBQuery*)intIsGreaterThanOrEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(TDBQuery*)floatIsGreaterThanOrEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(TDBQuery*)doubleIsGreaterThanOrEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(TDBQuery*)dateIsGreaterThanOrEqualTo:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

// Less than

-(TDBQuery*)intIsLessThan:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(TDBQuery*)floatIsLessThan:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(TDBQuery*)doubleIsLessThan:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(TDBQuery*)dateIsLessThan:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

// Less thanOrEqualTo

-(TDBQuery*)intIsLessThanOrEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(TDBQuery*)floatIsLessThanOrEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(TDBQuery*)doubleIsLessThanOrEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(TDBQuery*)dateIsLessThanOrEqualTo:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

@end


@implementation TDBQueryAccessorBool
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TDBQuery*)columnIsEqualTo:(BOOL)value
{
    [_query getNativeQuery].equal(_column_ndx, bool(value));
    return _query;
}
@end


@implementation TDBQueryAccessorInt
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TDBQuery*)columnIsEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TDBQuery*)columnIsNotEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].not_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TDBQuery*)columnIsGreaterThan:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].greater(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TDBQuery*)columnIsGreaterThanOrEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].greater_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TDBQuery*)columnIsLessThan:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].less(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TDBQuery*)columnIsLessThanOrEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].less_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TDBQuery*)columnIsBetween:(int64_t)from :(int64_t)to
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].between(_column_ndx, from, to);,
        _query, &_query->m_error);
    return _query;
}

-(int64_t)min
{
    return [_query minIntInColumnWithIndex:_column_ndx];
}
-(int64_t)max
{
    return [_query maxIntInColumnWithIndex:_column_ndx];
}
-(int64_t)sum
{
    return [_query sumIntColumnWithIndex:_column_ndx];
}
-(double)avg
{
    return [_query avgIntColumnWithIndex:_column_ndx];
}

@end


@implementation TDBQueryAccessorFloat
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TDBQuery*)columnIsEqualTo:(float)value
{
    [_query getNativeQuery].equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsNotEqualTo:(float)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsGreaterThan:(float)value
{
    [_query getNativeQuery].greater(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsGreaterThanOrEqualTo:(float)value
{
    [_query getNativeQuery].greater_equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsLessThan:(float)value
{
    [_query getNativeQuery].less(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsLessThanOrEqualTo:(float)value
{
    [_query getNativeQuery].less_equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsBetween:(float)from :(float)to
{
    [_query getNativeQuery].between(_column_ndx, from, to);
    return _query;
}

-(float)min
{
    return [_query minFloatInColumnWithIndex:_column_ndx];
}
-(float)max
{
    return [_query maxFloatInColumnWithIndex:_column_ndx];
}
-(double)sum
{
    return [_query sumFloatColumnWithIndex:_column_ndx];
}
-(double)avg
{
    return [_query avgFloatColumnWithIndex:_column_ndx];
}
@end


@implementation TDBQueryAccessorDouble
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TDBQuery*)columnIsEqualTo:(double)value
{
    [_query getNativeQuery].equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsNotEqualTo:(double)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsGreaterThan:(double)value
{
    [_query getNativeQuery].greater(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsGreaterThanOrEqualTo:(double)value
{
    [_query getNativeQuery].greater_equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsLessThan:(double)value
{
    [_query getNativeQuery].less(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsLessThanOrEqualTo:(double)value
{
    [_query getNativeQuery].less_equal(_column_ndx, value);
    return _query;
}

-(TDBQuery*)columnIsBetween:(double)from :(double)to
{
    [_query getNativeQuery].between(_column_ndx, from, to);
    return _query;
}

-(double)min
{
    return [_query minDoubleInColumnWithIndex:_column_ndx];
}
-(double)max
{
    return [_query maxDoubleInColumnWithIndex:_column_ndx];
}

-(double)sum
{
    return [_query sumDoubleColumnWithIndex:_column_ndx];
}
-(double)avg
{
    return [_query avgDoubleColumnWithIndex:_column_ndx];
}
@end


@implementation TDBQueryAccessorString
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TDBQuery*)columnIsEqualTo:(NSString*)value
{
    [_query getNativeQuery].equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TDBQuery*)columnIsEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TDBQuery*)columnIsNotEqualTo:(NSString*)value
{
    [_query getNativeQuery].not_equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TDBQuery*)columnIsNotEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].not_equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TDBQuery*)columnBeginsWith:(NSString*)value
{
    [_query getNativeQuery].begins_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TDBQuery*)columnBeginsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].begins_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TDBQuery*)columnEndsWith:(NSString*)value
{
    [_query getNativeQuery].ends_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TDBQuery*)columnEndsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].ends_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TDBQuery*)columnContains:(NSString*)value
{
    [_query getNativeQuery].contains(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TDBQuery*)columnContains:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].contains(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
@end


@implementation TDBQueryAccessorBinary
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TDBQuery*)columnIsEqualTo:(NSData*)value
{
    [_query getNativeQuery].equal(_column_ndx, value.tdbBinaryData);
    return _query;
}
-(TDBQuery*)columnIsNotEqualTo:(NSData*)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value.tdbBinaryData);
    return _query;
}
-(TDBQuery*)columnBeginsWith:(NSData*)value
{
    [_query getNativeQuery].begins_with(_column_ndx, value.tdbBinaryData);
    return _query;
}
-(TDBQuery*)columnEndsWith:(NSData*)value
{
    [_query getNativeQuery].ends_with(_column_ndx, value.tdbBinaryData);
    return _query;
}
-(TDBQuery*)columnContains:(NSData*)value
{
    [_query getNativeQuery].contains(_column_ndx, value.tdbBinaryData);
    return _query;
}
@end


@implementation TDBQueryAccessorDate
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TDBQuery*)columnIsEqualTo:(NSDate *)value
{
    [_query getNativeQuery].equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(TDBQuery*)columnIsNotEqualTo:(NSDate *)value
{
    [_query getNativeQuery].not_equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(TDBQuery*)columnIsGreaterThan:(NSDate *)value
{
    [_query getNativeQuery].greater_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(TDBQuery*)columnIsGreaterThanOrEqualTo:(NSDate *)value
{
    [_query getNativeQuery].greater_equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(TDBQuery*)columnIsLessThan:(NSDate *)value
{
    [_query getNativeQuery].less_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(TDBQuery*)columnIsLessThanOrEqualTo:(NSDate *)value
{
    [_query getNativeQuery].less_equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(TDBQuery*)columnIsBetween:(NSDate *)from :(NSDate *)to
{
    [_query getNativeQuery].between_datetime(_column_ndx, [from timeIntervalSince1970], [to timeIntervalSince1970]);
    return _query;
}
@end


@implementation TDBQueryAccessorSubtable
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end


@implementation TDBQueryAccessorMixed
{
    __weak TDBQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end

