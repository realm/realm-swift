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

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/exceptions.hpp>
#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/query.hpp>

#import "RLMQuery.h"
#import "RLMTable_noinst.h"
#import "RLMView_noinst.h"
#import "RLMRow.h"
#import "NSData+RLMGetBinaryData.h"
#import "PrivateRLM.h"
#import "util_noinst.hpp"

using namespace std;


@interface RLMQuery ()
{
    @public
    NSError* m_error; // To enable the flow of multiple stacked queries, any error is kept until the last step.
}
@end


@implementation RLMQuery
{
    tightdb::util::UniquePtr<tightdb::Query> m_query;
    __weak RLMTable * m_table;

    RLMRow * m_tmp_row;
}

-(id)initWithTable:(RLMTable *)table
{
    return [self initWithTable:table error:nil];
}

-(id)initWithTable:(RLMTable *)table error:(NSError* __autoreleasing*)error
{
    self = [super init];
    if (self) {
        m_table = table;
        REALM_EXCEPTION_ERRHANDLER(
            m_query.reset(new tightdb::Query([table getNativeTable].where()));,
            nil);
    }
    return self;
}

-(void)setTableView:(tightdb::TableView&)tableView
{
    m_query->tableview(tableView);
}

-(RLMRow *)getRow:(long)ndx
{
    return m_tmp_row = [[RLMRow alloc] initWithTable:[self originTable] ndx:ndx];
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
        RLMRow * tmp = [self getRow:state->state];
        *stackbuf = tmp;
    }
    if (state->state < [self originTable].rowCount && state->state != (NSUInteger)NSNotFound) {
        [((RLMRow *) *stackbuf) RLM_setNdx:state->state];
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
#ifdef REALM_DEBUG
    // NSLog(@"RLMQuery dealloc");
#endif
}

-(tightdb::Query&)getNativeQuery
{
    return *m_query;
}

-(RLMTable *)originTable
{
    return m_table;
}

-(RLMQuery *)group
{
    REALM_EXCEPTION_ERRHANDLER_EX(m_query->group();, self, &m_error);
    return self;
}
-(RLMQuery *)Or
{
    REALM_EXCEPTION_ERRHANDLER_EX(m_query->Or();, self, &m_error);
    return self;
}
-(RLMQuery *)endGroup
{
    REALM_EXCEPTION_ERRHANDLER_EX(m_query->end_group();, self, &m_error);
    return self;
}
-(RLMQuery *)subtableInColumnWithIndex:(NSUInteger)column
{
    m_query->subtable(column);
    return self;
}
-(RLMQuery *)parent
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
        @throw [NSException exceptionWithName:@"realm:table_is_read_only"
                                       reason:@"You tried to modify an immutable table"
                                     userInfo:nil];
    }
    return m_query->remove();
}

-(id)minInColumnWithIndex:(NSUInteger)colIndex
{
    RLMType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == RLMTypeInt) {
        return [NSNumber numberWithInteger:[self minIntInColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeDouble) {
        return [NSNumber numberWithDouble:[self minDoubleInColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeFloat) {
        return [NSNumber numberWithDouble:[self minFloatInColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeDate) {
        return [self minDateInColumnWithIndex:colIndex];
    }
    else {
        @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
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
    RLMType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == RLMTypeInt) {
        return [NSNumber numberWithInteger:[self maxIntInColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeDouble) {
        return [NSNumber numberWithDouble:[self maxDoubleInColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeFloat) {
        return [NSNumber numberWithDouble:[self maxFloatInColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeDate) {
        return [self maxDateInColumnWithIndex:colIndex];
    }
    else {
        @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
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
    RLMType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == RLMTypeInt) {
        return [NSNumber numberWithInteger:[self sumIntColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeDouble) {
        return [NSNumber numberWithDouble:[self sumDoubleColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeFloat) {
        return [NSNumber numberWithDouble:[self sumFloatColumnWithIndex:colIndex]];
    }
    else {
        @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
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
    RLMType colType = [[self originTable] columnTypeOfColumnWithIndex:colIndex];
    if (colType == RLMTypeInt) {
        return [NSNumber numberWithDouble:[self avgIntColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeDouble) {
        return [NSNumber numberWithDouble:[self avgDoubleColumnWithIndex:colIndex]];
    }
    else if (colType == RLMTypeFloat) {
        return [NSNumber numberWithDouble:[self avgFloatColumnWithIndex:colIndex]];
    }
    else {
        @throw [NSException exceptionWithName:@"realm:operation_not_supprted"
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


-(RLMView *)findAllRows
{
    tightdb::TableView view = m_query->find_all();
    return [RLMView viewWithTable:m_table andNativeView:view];
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
-(RLMQuery *)boolIsEqualTo:(bool)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aBool);
    return self;
}

-(RLMQuery *)intIsEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, anInt);
    return self;
}

-(RLMQuery *)floatIsEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aFloat);
    return self;
}

-(RLMQuery *)doubleIsEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aDouble);
    return self;
}

-(RLMQuery *)stringIsEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, ObjcStringAccessor(aString), true);
    return self;
}

-(RLMQuery *)stringIsCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, ObjcStringAccessor(aString), false);
    return self;
}


-(RLMQuery *)dateIsEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal_datetime(colIndex, [aDate timeIntervalSince1970]);
    return self;
}

-(RLMQuery *)binaryIsEqualTo:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aBinary.rlmBinaryData);
    return self;
}

// Not equal to

-(RLMQuery *)intIsNotEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(RLMQuery *)floatIsNotEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(RLMQuery *)doubleIsNotEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(RLMQuery *)stringIsNotEqualTo:(NSString*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, ObjcStringAccessor(value), true);
    return self;
}

-(RLMQuery *)stringIsNotCaseInsensitiveEqualTo:(NSString*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, ObjcStringAccessor(value), false);
    return self;
}

-(RLMQuery *)dateIsNotEqualTo:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

-(RLMQuery *)binaryIsNotEqualTo:(NSData*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value.rlmBinaryData);
    return self;
}

// Between

-(RLMQuery *)dateIsBetween:(NSDate *)lower :(NSDate *)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between_datetime(colIndex, lower.timeIntervalSince1970, upper.timeIntervalSince1970);
    return self;
}

-(RLMQuery *)intIsBetween:(int64_t)lower :(int64_t)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between(colIndex, lower, upper);
    return self;
}

-(RLMQuery *)floatIsBetween:(float)lower :(float)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between(colIndex, lower, upper);
    return self;
}

-(RLMQuery *)doubleIsBetween:(double)lower :(double)upper inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->between(colIndex, lower, upper);
    return self;
}

// Greater than

-(RLMQuery *)intIsGreaterThan:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(RLMQuery *)floatIsGreaterThan:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(RLMQuery *)doubleIsGreaterThan:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(RLMQuery *)dateIsGreaterThan:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

// Greater thanOrEqualTo

-(RLMQuery *)intIsGreaterThanOrEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(RLMQuery *)floatIsGreaterThanOrEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(RLMQuery *)doubleIsGreaterThanOrEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(RLMQuery *)dateIsGreaterThanOrEqualTo:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

// Less than

-(RLMQuery *)intIsLessThan:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(RLMQuery *)floatIsLessThan:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(RLMQuery *)doubleIsLessThan:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(RLMQuery *)dateIsLessThan:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

// Less thanOrEqualTo

-(RLMQuery *)intIsLessThanOrEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(RLMQuery *)floatIsLessThanOrEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(RLMQuery *)doubleIsLessThanOrEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(RLMQuery *)dateIsLessThanOrEqualTo:(NSDate *)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal_datetime(colIndex, [value timeIntervalSince1970]);
    return self;
}

@end


@implementation RLMQueryAccessorBool
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(RLMQuery *)columnIsEqualTo:(BOOL)value
{
    [_query getNativeQuery].equal(_column_ndx, bool(value));
    return _query;
}

@end


@implementation RLMQueryAccessorInt
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(RLMQuery *)columnIsEqualTo:(int64_t)value
{
    REALM_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(RLMQuery *)columnIsNotEqualTo:(int64_t)value
{
    REALM_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].not_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(RLMQuery *)columnIsGreaterThan:(int64_t)value
{
    REALM_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].greater(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(RLMQuery *)columnIsGreaterThanOrEqualTo:(int64_t)value
{
    REALM_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].greater_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(RLMQuery *)columnIsLessThan:(int64_t)value
{
    REALM_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].less(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(RLMQuery *)columnIsLessThanOrEqualTo:(int64_t)value
{
    REALM_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].less_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(RLMQuery *)columnIsBetween:(int64_t)from :(int64_t)to
{
    REALM_EXCEPTION_ERRHANDLER_EX(
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


@implementation RLMQueryAccessorFloat

{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(RLMQuery *)columnIsEqualTo:(float)value
{
    [_query getNativeQuery].equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsNotEqualTo:(float)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsGreaterThan:(float)value
{
    [_query getNativeQuery].greater(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsGreaterThanOrEqualTo:(float)value
{
    [_query getNativeQuery].greater_equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsLessThan:(float)value
{
    [_query getNativeQuery].less(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsLessThanOrEqualTo:(float)value
{
    [_query getNativeQuery].less_equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsBetween:(float)from :(float)to
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


@implementation RLMQueryAccessorDouble
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(RLMQuery *)columnIsEqualTo:(double)value
{
    [_query getNativeQuery].equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsNotEqualTo:(double)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsGreaterThan:(double)value
{
    [_query getNativeQuery].greater(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsGreaterThanOrEqualTo:(double)value
{
    [_query getNativeQuery].greater_equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsLessThan:(double)value
{
    [_query getNativeQuery].less(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsLessThanOrEqualTo:(double)value
{
    [_query getNativeQuery].less_equal(_column_ndx, value);
    return _query;
}

-(RLMQuery *)columnIsBetween:(double)from :(double)to
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


@implementation RLMQueryAccessorString
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(RLMQuery *)columnIsEqualTo:(NSString*)value
{
    [_query getNativeQuery].equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(RLMQuery *)columnIsEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(RLMQuery *)columnIsNotEqualTo:(NSString*)value
{
    [_query getNativeQuery].not_equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(RLMQuery *)columnIsNotEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].not_equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(RLMQuery *)columnBeginsWith:(NSString*)value
{
    [_query getNativeQuery].begins_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(RLMQuery *)columnBeginsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].begins_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(RLMQuery *)columnEndsWith:(NSString*)value
{
    [_query getNativeQuery].ends_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(RLMQuery *)columnEndsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].ends_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(RLMQuery *)columnContains:(NSString*)value
{
    [_query getNativeQuery].contains(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(RLMQuery *)columnContains:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].contains(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}

@end


@implementation RLMQueryAccessorBinary
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(RLMQuery *)columnIsEqualTo:(NSData*)value
{
    [_query getNativeQuery].equal(_column_ndx, value.rlmBinaryData);
    return _query;
}
-(RLMQuery *)columnIsNotEqualTo:(NSData*)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value.rlmBinaryData);
    return _query;
}
-(RLMQuery *)columnBeginsWith:(NSData*)value
{
    [_query getNativeQuery].begins_with(_column_ndx, value.rlmBinaryData);
    return _query;
}
-(RLMQuery *)columnEndsWith:(NSData*)value
{
    [_query getNativeQuery].ends_with(_column_ndx, value.rlmBinaryData);
    return _query;
}
-(RLMQuery *)columnContains:(NSData*)value
{
    [_query getNativeQuery].contains(_column_ndx, value.rlmBinaryData);
    return _query;
}

@end


@implementation RLMQueryAccessorDate
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(RLMQuery *)columnIsEqualTo:(NSDate *)value
{
    [_query getNativeQuery].equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(RLMQuery *)columnIsNotEqualTo:(NSDate *)value
{
    [_query getNativeQuery].not_equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(RLMQuery *)columnIsGreaterThan:(NSDate *)value
{
    [_query getNativeQuery].greater_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(RLMQuery *)columnIsGreaterThanOrEqualTo:(NSDate *)value
{
    [_query getNativeQuery].greater_equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(RLMQuery *)columnIsLessThan:(NSDate *)value
{
    [_query getNativeQuery].less_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(RLMQuery *)columnIsLessThanOrEqualTo:(NSDate *)value
{
    [_query getNativeQuery].less_equal_datetime(_column_ndx, [value timeIntervalSince1970]);
    return _query;
}
-(RLMQuery *)columnIsBetween:(NSDate *)from :(NSDate *)to
{
    [_query getNativeQuery].between_datetime(_column_ndx, [from timeIntervalSince1970], [to timeIntervalSince1970]);
    return _query;
}
@end


@implementation RLMQueryAccessorSubtable
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

@end


@implementation RLMQueryAccessorMixed
{
    __weak RLMQuery * _query;
    NSUInteger _column_ndx;
}

-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

@end
