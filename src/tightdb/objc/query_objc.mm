//
//  query.mm
//  TightDB
//

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/util/file.hpp>
#include <tightdb/exceptions.hpp>
#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/query.hpp>

#import <tightdb/objc/query.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>
#import <tightdb/objc/cursor.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@interface TightdbQuery()
{
    @public
    NSError* m_error; // To enable the flow of multiple stacked queries, any error is kept until the last step.
}
@end


@implementation TightdbQuery
{
    tightdb::util::UniquePtr<tightdb::Query> m_query;
    __weak TDBTable* m_table;

    TDBRow* m_tmp_cursor;
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

-(TDBRow*)getCursor:(long)ndx
{

    return m_tmp_cursor = [[TDBRow alloc] initWithTable:[self originTable] ndx:ndx];
}

-(long)getFastEnumStart
{
    return [self findFromRowIndex:0];
}

-(long)incrementFastEnum:(long)ndx
{
    return [self findFromRowIndex:ndx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id __unsafe_unretained*)stackbuf count:(NSUInteger)len
{
    (void)len;
    if(state->state == 0)
    {
        state->state = [self getFastEnumStart];
        state->mutationsPtr = (unsigned long*)objc_unretainedPointer(self);
        TDBRow* tmp = [self getCursor:state->state];
        *stackbuf = tmp;
    }
    if ((int)state->state != -1) {
        [((TDBRow*)*stackbuf) TDBSetNdx:state->state];
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
    NSLog(@"TightdbQuery dealloc");
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

-(TightdbQuery*)group
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->group();, self, &m_error);
    return self;
}
-(TightdbQuery*)Or
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->Or();, self, &m_error);
    return self;
}
-(TightdbQuery*)endGroup
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->end_group();, self, &m_error);
    return self;
}
-(void)subtableInColumnWithIndex:(NSUInteger)column
{
    m_query->subtable(column);
}
-(void)parent
{
    m_query->end_subtable();
}

-(NSUInteger)countRows
{
    return m_query->count();
}


-(NSUInteger)removeRows
{
    return m_query->remove();
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

-(NSUInteger)findFromRowIndex:(NSUInteger)rowIndex
{
    return m_query->find(rowIndex);
}



// Conditions:




-(TightdbQuery*)boolIsEqualTo:(bool)aBool inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aBool);
    return self;
}

-(TightdbQuery*)intIsEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, anInt);
    return self;
}

-(TightdbQuery*)floatIsEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aFloat);
    return self;
}

-(TightdbQuery*)doubleIsEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, aDouble);
    return self;
}

-(TightdbQuery*)stringIsEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, ObjcStringAccessor(aString), true);
    return self;
}

-(TightdbQuery*)stringIsCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, ObjcStringAccessor(aString), false);
    return self;
}



-(TightdbQuery*)dateIsEqualTo:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal_datetime(colIndex, aDate);
    return self;
}

-(TightdbQuery*)binaryIsEqualTo:(TDBBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->equal(colIndex, [aBinary getNativeBinary]);
    return self;
}

// Not equal to

-(TightdbQuery*)intIsNotEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)floatIsNotEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)doubleIsNotEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)stringIsNotEqualTo:(NSString*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, ObjcStringAccessor(value), true);
    return self;
}

-(TightdbQuery*)stringIsNotCaseInsensitiveEqualTo:(NSString*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, ObjcStringAccessor(value), false);
    return self;
}

-(TightdbQuery*)dateIsNotEqualTo:(time_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal_datetime(colIndex, value);
    return self;
}

-(TightdbQuery*)binaryIsNotEqualTo:(TDBBinary*)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->not_equal(colIndex, [value getNativeBinary]);
    return self;
}

// Greater than

-(TightdbQuery*)intIsGreaterThan:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(TightdbQuery*)floatIsGreaterThan:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(TightdbQuery*)doubleIsGreaterThan:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater(colIndex, value);
    return self;
}

-(TightdbQuery*)dateIsGreaterThan:(time_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_datetime(colIndex, value);
    return self;
}

// Greater thanOrEqualTo

-(TightdbQuery*)intIsGreaterThanOrEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)floatIsGreaterThanOrEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)doubleIsGreaterThanOrEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)dateIsGreaterThanOrEqualTo:(time_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->greater_equal_datetime(colIndex, value);
    return self;
}

// Less than

-(TightdbQuery*)intIsLessThan:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(TightdbQuery*)floatIsLessThan:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(TightdbQuery*)doubleIsLessThan:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less(colIndex, value);
    return self;
}

-(TightdbQuery*)dateIsLessThan:(time_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_datetime(colIndex, value);
    return self;
}

// Less thanOrEqualTo

-(TightdbQuery*)intIsLessThanOrEqualTo:(int64_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)floatIsLessThanOrEqualTo:(float)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)doubleIsLessThanOrEqualTo:(double)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal(colIndex, value);
    return self;
}

-(TightdbQuery*)dateIsLessThanOrEqualTo:(time_t)value inColumnWithIndex:(NSUInteger)colIndex
{
    m_query->less_equal_datetime(colIndex, value);
    return self;
}











@end


@implementation TightdbQueryAccessorBool
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery*)columnIsEqualTo:(BOOL)value
{
    [_query getNativeQuery].equal(_column_ndx, bool(value));
    return _query;
}
@end


@implementation TightdbQueryAccessorInt
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TightdbQuery*)columnIsEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TightdbQuery*)columnIsNotEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].not_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TightdbQuery*)columnIsGreaterThan:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].greater(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TightdbQuery*)columnIsGreaterThanOrEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].greater_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TightdbQuery*)columnIsLessThan:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].less(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TightdbQuery*)columnIsLessThanOrEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
        [_query getNativeQuery].less_equal(_column_ndx, value);,
        _query, &_query->m_error);
    return _query;
}

-(TightdbQuery*)columnIsBetween:(int64_t)from and_:(int64_t)to
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


@implementation TightdbQueryAccessorFloat
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TightdbQuery*)columnIsEqualTo:(float)value
{
    [_query getNativeQuery].equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsNotEqualTo:(float)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsGreaterThan:(float)value
{
    [_query getNativeQuery].greater(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsGreaterThanOrEqualTo:(float)value
{
    [_query getNativeQuery].greater_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsLessThan:(float)value
{
    [_query getNativeQuery].less(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsLessThanOrEqualTo:(float)value
{
    [_query getNativeQuery].less_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsBetween:(float)from and_:(float)to
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


@implementation TightdbQueryAccessorDouble
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TightdbQuery*)columnIsEqualTo:(double)value
{
    [_query getNativeQuery].equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsNotEqualTo:(double)value
{
    [_query getNativeQuery].not_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsGreaterThan:(double)value
{
    [_query getNativeQuery].greater(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsGreaterThanOrEqualTo:(double)value
{
    [_query getNativeQuery].greater_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsLessThan:(double)value
{
    [_query getNativeQuery].less(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsLessThanOrEqualTo:(double)value
{
    [_query getNativeQuery].less_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery*)columnIsBetween:(double)from and_:(double)to
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


@implementation TightdbQueryAccessorString
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery*)columnIsEqualTo:(NSString*)value
{
    [_query getNativeQuery].equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery*)columnIsEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery*)columnIsNotEqualTo:(NSString*)value
{
    [_query getNativeQuery].not_equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery*)columnIsNotEqualTo:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].not_equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery*)columnBeginsWith:(NSString*)value
{
    [_query getNativeQuery].begins_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery*)columnBeginsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].begins_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery*)columnEndsWith:(NSString*)value
{
    [_query getNativeQuery].ends_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery*)columnEndsWith:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].ends_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery*)columnContains:(NSString*)value
{
    [_query getNativeQuery].contains(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery*)columnContains:(NSString*)value caseSensitive:(BOOL)caseSensitive
{
    [_query getNativeQuery].contains(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
@end


@implementation TightdbQueryAccessorBinary
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery*)columnIsEqualTo:(TDBBinary*)value
{
    [_query getNativeQuery].equal(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnIsNotEqualTo:(TDBBinary*)value
{
    [_query getNativeQuery].not_equal(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnBeginsWith:(TDBBinary*)value
{
    [_query getNativeQuery].begins_with(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnEndsWith:(TDBBinary*)value
{
    [_query getNativeQuery].ends_with(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnContains:(TDBBinary*)value
{
    [_query getNativeQuery].contains(_column_ndx, [value getNativeBinary]);
    return _query;
}
@end


@implementation TightdbQueryAccessorDate
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery*)columnIsEqualTo:(time_t)value
{
    [_query getNativeQuery].equal_datetime(_column_ndx, value);
    return _query;
}
-(TightdbQuery*)columnIsNotEqualTo:(time_t)value
{
    [_query getNativeQuery].not_equal_datetime(_column_ndx, value);
    return _query;
}
-(TightdbQuery*)columnIsGreaterThan:(time_t)value
{
    [_query getNativeQuery].greater_datetime(_column_ndx, value);
    return _query;
}
-(TightdbQuery*)columnIsGreaterThanOrEqualTo:(time_t)value
{
    [_query getNativeQuery].greater_equal_datetime(_column_ndx, value);
    return _query;
}
-(TightdbQuery*)columnIsLessThan:(time_t)value
{
    [_query getNativeQuery].less_datetime(_column_ndx, value);
    return _query;
}
-(TightdbQuery*)columnIsLessThanOrEqualTo:(time_t)value
{
    [_query getNativeQuery].less_equal_datetime(_column_ndx, value);
    return _query;
}
-(TightdbQuery*)columnIsBetween:(time_t)from and_:(time_t)to
{
    [_query getNativeQuery].between_datetime(_column_ndx, from, to);
    return _query;
}
@end


@implementation TightdbQueryAccessorSubtable
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end


@implementation TightdbQueryAccessorMixed
{
    __weak TightdbQuery* _query;
    NSUInteger _column_ndx;
}
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery*)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end

