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
    __weak TightdbTable* m_table;

    TightdbCursor* m_tmp_cursor;
}

-(id)initWithTable:(TightdbTable*)table
{
    return [self initWithTable:table error:nil];
}

-(id)initWithTable:(TightdbTable*)table error:(NSError* __autoreleasing*)error
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

-(TightdbCursor*)getCursor:(long)ndx
{

    return m_tmp_cursor = [[TightdbCursor alloc] initWithTable:[self getTable] ndx:ndx];
}

-(long)getFastEnumStart
{
    return [self find:0];
}

-(long)incrementFastEnum:(long)ndx
{
    return [self find:ndx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id __unsafe_unretained*)stackbuf count:(NSUInteger)len
{
    (void)len;
    if(state->state == 0)
    {
        state->state = [self getFastEnumStart];
        state->mutationsPtr = (unsigned long*)objc_unretainedPointer(self);
        TightdbCursor* tmp = [self getCursor:state->state];
        *stackbuf = tmp;
    }
    if ((int)state->state != -1) {
        [((TightdbCursor*)*stackbuf) TDBSetNdx:state->state];
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

-(TightdbTable*)getTable
{
    return m_table;
}

-(TightdbQuery*)group
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->group();, self, &m_error);
    return self;
}
-(TightdbQuery*)or
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->Or();, self, &m_error);
    return self;
}
-(TightdbQuery*)endgroup
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(m_query->end_group();, self, &m_error);
    return self;
}
-(void)subtable:(NSUInteger)column
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



-(int64_t)minIntIntColumnWithIndex:(NSUInteger)col_ndx
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


-(int64_t)maxIntIntColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->maximum_int(col_ndx);
}

-(float)maxFloatIntColumnWithIndex:(NSUInteger)col_ndx
{
    return m_query->maximum_float(col_ndx);
}


-(double)maxDoubleIntColumnWithIndex:(NSUInteger)col_ndx
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



-(TightdbView*)findAll
{
    tightdb::TableView view = m_query->find_all();
    return [TightdbView viewWithTable:m_table andNativeView:view];
}

-(NSUInteger)find:(NSUInteger)last
{
    return [self find:last error:nil];
}
-(NSUInteger)find:(NSUInteger)last error:(NSError* __autoreleasing*)error
{
    if (m_error) {
        if (error) {
            *error = m_error;
            m_error = nil;
        }
        return size_t(-1);
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(return m_query->find(last);, size_t(-1));
}


// Conditions:


-(TightdbQuery*)column:(NSUInteger)colNdx isBetweenInt:(int64_t)from and_:(int64_t)to
{
    m_query->between(colNdx, from, to);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isBetweenFloat:(float)from and_:(float)to
{
    m_query->between(colNdx, from, to);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isBetweenDouble:(double)from and_:(double)to
{
    m_query->between(colNdx, from, to);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isBetweenDate:(time_t)from and_:(time_t)to
{
    m_query->between_datetime(colNdx, from, to);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToBool:(bool)value
{
    m_query->equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToInt:(int64_t)value
{
    m_query->equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToFloat:(float)value
{
    m_query->equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToDouble:(double)value
{
    m_query->equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToString:(NSString*)value
{
    m_query->equal(colNdx, ObjcStringAccessor(value));
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToString:(NSString*)value caseSensitive:(bool)caseSensitive
{
    m_query->equal(colNdx, ObjcStringAccessor(value), caseSensitive);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToDate:(time_t)value
{
    m_query->equal_datetime(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isEqualToBinary:(TightdbBinary*)value
{
    m_query->equal(colNdx, [value getNativeBinary]);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isNotEqualToInt:(int64_t)value
{
    m_query->not_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isNotEqualToFloat:(float)value
{
    m_query->not_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isNotEqualToDouble:(double)value
{
    m_query->not_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isNotEqualToString:(NSString*)value
{
    m_query->not_equal(colNdx, ObjcStringAccessor(value));
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isNotEqualToString:(NSString*)value caseSensitive:(bool)caseSensitive
{
    m_query->not_equal(colNdx, ObjcStringAccessor(value), caseSensitive);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isNotEqualToDate:(time_t)value
{
    m_query->not_equal_datetime(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isNotEqualToBinary:(TightdbBinary*)value
{
    m_query->not_equal(colNdx, [value getNativeBinary]);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanInt:(int64_t)value
{
    m_query->greater(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanFloat:(float)value
{
    m_query->greater(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanDouble:(double)value
{
    m_query->greater(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanDate:(time_t)value
{
    m_query->greater_datetime(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanOrEqualToInt:(int64_t)value
{
    m_query->greater_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanOrEqualToFloat:(float)value
{
    m_query->greater_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanOrEqualToDouble:(double)value
{
    m_query->greater_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isGreaterThanOrEqualToDate:(time_t)value
{
    m_query->greater_equal_datetime(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanInt:(int64_t)value
{
    m_query->less(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanFloat:(float)value
{
    m_query->less(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanDouble:(double)value
{
    m_query->less(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanDate:(time_t)value
{
    m_query->less_datetime(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanOrEqualToInt:(int64_t)value
{
    m_query->less_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanOrEqualToFloat:(float)value
{
    m_query->less_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanOrEqualToDouble:(double)value
{
    m_query->less_equal(colNdx, value);
    return self;
}

-(TightdbQuery*)column:(NSUInteger)colNdx isLessThanOrEqualToDate:(time_t)value
{
    m_query->less_equal_datetime(colNdx, value);
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

-(NSNumber*)minimum
{
    return [self minimumWithError:nil];
}
-(NSNumber*)minimumWithError:(NSError* __autoreleasing*)error
{
    return [_query minimumWithIntColumn:_column_ndx error:error];
}
-(NSNumber*)maximum
{
    return [self maximumWithError:nil];
}
-(NSNumber*)maximumWithError:(NSError* __autoreleasing*)error
{
    return [_query maximumWithIntColumn:_column_ndx error:error];
}

-(NSNumber*)sum
{
    return [self sumWithError:nil];
}
-(NSNumber*)sumWithError:(NSError* __autoreleasing*)error
{
    return [_query sumWithIntColumn:_column_ndx error:error];
}
-(NSNumber*)average
{
    return [self averageWithError:nil];
}
-(NSNumber*)averageWithError:(NSError* __autoreleasing*)error
{
    return [_query averageWithIntColumn:_column_ndx error:error];
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

-(NSNumber*)minimum
{
    return [self minimumWithError:nil];
}
-(NSNumber*)minimumWithError:(NSError* __autoreleasing*)error
{
    return [_query minimumWithFloatColumn:_column_ndx error:error];
}
-(NSNumber*)maximum
{
    return [self maximumWithError:nil];
}
-(NSNumber*)maximumWithError:(NSError* __autoreleasing*)error
{
    return [_query maximumWithFloatColumn:_column_ndx error:error];
}

-(NSNumber*)sum
{
    return [self sumWithError:nil];
}
-(NSNumber*)sumWithError:(NSError* __autoreleasing*)error
{
    return [_query sumWithFloatColumn:_column_ndx error:error];
}
-(NSNumber*)average
{
    return [self averageWithError:nil];
}
-(NSNumber*)averageWithError:(NSError* __autoreleasing*)error
{
    return [_query averageWithFloatColumn:_column_ndx error:error];
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

-(NSNumber*)minimum
{
    return [self minimumWithError:nil];
}
-(NSNumber*)minimumWithError:(NSError* __autoreleasing*)error
{
    return [_query minimumWithDoubleColumn:_column_ndx error:error];
}
-(NSNumber*)maximum
{
    return [self maximumWithError:nil];
}
-(NSNumber*)maximumWithError:(NSError* __autoreleasing*)error
{
    return [_query maximumWithDoubleColumn:_column_ndx error:error];
}

-(NSNumber*)sum
{
    return [self sumWithError:nil];
}
-(NSNumber*)sumWithError:(NSError* __autoreleasing*)error
{
    return [_query sumWithDoubleColumn:_column_ndx error:error];
}
-(NSNumber*)average
{
    return [self averageWithError:nil];
}
-(NSNumber*)averageWithError:(NSError* __autoreleasing*)error
{
    return [_query averageWithDoubleColumn:_column_ndx error:error];
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
-(TightdbQuery*)columnIsEqualTo:(TightdbBinary*)value
{
    [_query getNativeQuery].equal(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnIsNotEqualTo:(TightdbBinary*)value
{
    [_query getNativeQuery].not_equal(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnBeginsWith:(TightdbBinary*)value
{
    [_query getNativeQuery].begins_with(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnEndsWith:(TightdbBinary*)value
{
    [_query getNativeQuery].ends_with(_column_ndx, [value getNativeBinary]);
    return _query;
}
-(TightdbQuery*)columnContains:(TightdbBinary*)value
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

