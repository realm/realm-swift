//
//  query.mm
//  TightDB
//

#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/query.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import <tightdb/objc/query.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>
#import <tightdb/objc/cursor.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@interface TightdbView()
+(TightdbView *)tableViewWithTableView:(tightdb::TableView)table;
@end


@interface TightdbQuery()
{
    @public
    NSError *_error; // To enable the flow of multiple stacked queries, any error is kept until the last step.
}
@end


@implementation TightdbQuery
{
    tightdb::Query *_query;
    __weak TightdbTable *_table;

    TightdbCursor *tmpCursor;
}

-(id)initWithTable:(TightdbTable *)table
{
    return [self initWithTable:table error:nil];
}

-(id)initWithTable:(TightdbTable *)table error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {        
        _table = table;
        TIGHTDB_EXCEPTION_ERRHANDLER(
                                     _query = new tightdb::Query([_table getTable].where());
                                     , @"com.tightdb.query", nil);
    }
    return self;
}

-(TightdbCursor *)getCursor:(long)ndx
{

    return tmpCursor = [[TightdbCursor alloc] initWithTable:[self getTable] ndx:ndx];
}

-(long)getFastEnumStart
{
    return [self findNext:-1];
}

-(long)incrementFastEnum:(long)ndx
{
    return [self findNext:ndx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
    (void)len;
    if(state->state == 0)
    {
        state->state = [self getFastEnumStart];
        state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self);
        TightdbCursor *tmp = [self getCursor:state->state];
        *stackbuf = tmp;
    }
    if ((int)state->state != -1) {
        [((TightdbCursor *)*stackbuf) setNdx:state->state];
        state->itemsPtr = stackbuf;
        state->state = [self incrementFastEnum:state->state];
    } else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        return 0;
    }
    return 1;
}

// Due to cyclic ARC problems. You have to clear manually. (Must be called from client code)
-(void)clear
{
    _table = nil;
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"Query dealloc");
#endif
    delete _query;
}

-(tightdb::Query *)getQuery
{
    return _query;
}

-(TightdbTable *)getTable
{
    return _table;
}

-(TightdbQuery *)group
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                 _query->group();
                                 , @"com.tightdb.query", self, &_error);
    return self;
}
-(TightdbQuery *)or
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    _query->Or();
                                    , @"com.tightdb.query", self, &_error);
    return self;
}
-(TightdbQuery *)endgroup
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    _query->end_group();
                                    , @"com.tightdb.query", self, &_error);
    return self;
}
-(void)subtable:(size_t)column
{
    _query->subtable(column);
}
-(void)parent
{
    _query->end_subtable();
}

-(NSNumber *)count
{
    return [self countWithError:nil];
}
-(NSNumber *)countWithError:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber TIGHTDB_OBJC_SIZE_T_NUMBER_IN:_query->count()];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)remove
{
    return [self removeWithError:nil];
}

-(NSNumber *)removeWithError:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber TIGHTDB_OBJC_SIZE_T_NUMBER_IN:_query->remove()];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)minimumWithIntColumn:(size_t)col_ndx
{
    return [self minimumWithIntColumn:col_ndx error:nil];
}
-(NSNumber *)minimumWithIntColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithLongLong:_query->minimum(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)minimumWithFloatColumn:(size_t)col_ndx
{
    return [self minimumWithFloatColumn:col_ndx error:nil];
}
-(NSNumber *)minimumWithFloatColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithFloat:_query->minimum_float(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)minimumWithDoubleColumn:(size_t)col_ndx
{
    return [self minimumWithDoubleColumn:col_ndx error:nil];
}
-(NSNumber *)minimumWithDoubleColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithDouble:_query->minimum_double(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)maximumWithIntColumn:(size_t)col_ndx
{
    return [self maximumWithIntColumn:col_ndx error:nil];
}
-(NSNumber *)maximumWithIntColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithLongLong:_query->maximum(col_ndx)];
                                 , @"com.tightdb.query", nil);
}
-(NSNumber *)maximumWithFloatColumn:(size_t)col_ndx
{
    return [self maximumWithFloatColumn:col_ndx error:nil];
}
-(NSNumber *)maximumWithFloatColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithFloat:_query->maximum_float(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)maximumWithDoubleColumn:(size_t)col_ndx
{
    return [self maximumWithDoubleColumn:col_ndx error:nil];
}
-(NSNumber *)maximumWithDoubleColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithDouble:_query->maximum_double(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)sumWithIntColumn:(size_t)col_ndx
{
    return [self sumWithIntColumn:col_ndx error:nil];
}
-(NSNumber *)sumWithIntColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithLongLong:_query->sum(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)sumWithFloatColumn:(size_t)col_ndx
{
    return [self sumWithFloatColumn:col_ndx error:nil];
}
-(NSNumber *)sumWithFloatColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithFloat:_query->sum_float(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)sumWithDoubleColumn:(size_t)col_ndx
{
    return [self sumWithDoubleColumn:col_ndx error:nil];
}
-(NSNumber *)sumWithDoubleColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithDouble:_query->sum_double(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)averageWithIntColumn:(size_t)col_ndx
{
    return [self averageWithIntColumn:col_ndx error:nil];
}
-(NSNumber *)averageWithIntColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithDouble:_query->average(col_ndx)];
                                 , @"com.tightdb.query", nil);
}
-(NSNumber *)averageWithFloatColumn:(size_t)col_ndx
{
    return [self averageWithFloatColumn:col_ndx error:nil];
}
-(NSNumber *)averageWithFloatColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithDouble:_query->average_float(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(NSNumber *)averageWithDoubleColumn:(size_t)col_ndx
{
    return [self averageWithDoubleColumn:col_ndx error:nil];
}

-(NSNumber *)averageWithDoubleColumn:(size_t)col_ndx error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return [NSNumber numberWithDouble:_query->average_double(col_ndx)];
                                 , @"com.tightdb.query", nil);
}

-(tightdb::TableView)getTableView
{
    return _query->find_all();
}


-(TightdbView *)findAll {

    // jjepsen: please review this.
    return [[TightdbView alloc] initFromQuery:self];
}


-(size_t)findNext:(size_t)last
{
    return [self findNext:last error:nil];
}
-(size_t)findNext:(size_t)last error:(NSError *__autoreleasing *)error
{
    if (_error) {
        if (error) {
            *error = _error;
            _error = nil;
        }
        return size_t(-1);
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 return _query->find_next(last);
                                 , @"com.tightdb.query", size_t(-1));
}


// Conditions:


-(TightdbQuery *)column:(size_t)colNdx isBetweenInt:(int64_t)from and_:(int64_t)to
{
    _query->between(colNdx, from, to);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isBetweenFloat:(float)from and_:(float)to
{
    _query->between(colNdx, from, to);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isBetweenDouble:(double)from and_:(double)to
{
    _query->between(colNdx, from, to);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isBetweenDate:(time_t)from and_:(time_t)to
{
    _query->between_date(colNdx, from, to);
    return self;
}  

-(TightdbQuery *)column:(size_t)colNdx isEqualToBool:(bool)value
{
    _query->equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isEqualToInt:(int64_t)value
{
    _query->equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isEqualToFloat:(float)value 
{
    _query->equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isEqualToDouble:(double)value
{
    _query->equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isEqualToString:(NSString *)value
{
    _query->equal(colNdx, ObjcStringAccessor(value));
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isEqualToString:(NSString *)value caseSensitive:(bool)caseSensitive
{
    _query->equal(colNdx, ObjcStringAccessor(value), caseSensitive);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isEqualToDate:(time_t)value
{
    _query->equal_date(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isEqualToBinary:(TightdbBinary *)value
{
    _query->equal(colNdx, [value getBinary]);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToInt:(int64_t)value
{
    _query->not_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToFloat:(float)value 
{
    _query->not_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToDouble:(double)value
{
    _query->not_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToString:(NSString *)value
{
    _query->not_equal(colNdx, ObjcStringAccessor(value));
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToString:(NSString *)value caseSensitive:(bool)caseSensitive
{
    _query->not_equal(colNdx, ObjcStringAccessor(value), caseSensitive);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToDate:(time_t)value
{
    _query->not_equal_date(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToBinary:(TightdbBinary *)value
{
    _query->not_equal(colNdx, [value getBinary]);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanInt:(int64_t)value 
{
    _query->greater(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanFloat:(float)value
{
    _query->greater(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanDouble:(double)value
{
    _query->greater(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanDate:(time_t)value
{
    _query->greater_date(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToInt:(int64_t)value
{
    _query->greater_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToFloat:(float)value 
{
    _query->greater_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToDouble:(double)value
{
    _query->greater_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToDate:(time_t)value
{
    _query->greater_equal_date(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanInt:(int64_t)value 
{
    _query->less(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanFloat:(float)value
{
    _query->less(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanDouble:(double)value
{
    _query->less(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanDate:(time_t)value
{
    _query->less_date(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToInt:(int64_t)value
{
    _query->less_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToFloat:(float)value 
{
    _query->less_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToDouble:(double)value
{
    _query->less_equal(colNdx, value);
    return self;
}

-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToDate:(time_t)value
{
    _query->less_equal_date(colNdx, value);
    return self;
}











@end


@implementation TightdbQueryAccessorBool
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery *)columnIsEqualTo:(BOOL)value
{
    [_query getQuery]->equal(_column_ndx, (bool)value);
    return _query;
}
@end


@implementation TightdbQueryAccessorInt
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TightdbQuery *)columnIsEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    [_query getQuery]->equal(_column_ndx, value);
                                    , @"com.tightdb.queryaccessor", _query, &_query->_error);
    return _query;
}

-(TightdbQuery *)columnIsNotEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    [_query getQuery]->not_equal(_column_ndx, value);
                                    , @"com.tightdb.queryaccessor", _query, &_query->_error);
    return _query;
}

-(TightdbQuery *)columnIsGreaterThan:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    [_query getQuery]->greater(_column_ndx, value);
                                    , @"com.tightdb.queryaccessor", _query, &_query->_error);
    return _query;
}

-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    [_query getQuery]->greater_equal(_column_ndx, value);
                                    , @"com.tightdb.queryaccessor", _query, &_query->_error);
    return _query;
}

-(TightdbQuery *)columnIsLessThan:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    [_query getQuery]->less(_column_ndx, value);
                                    , @"com.tightdb.queryaccessor", _query, &_query->_error);
    return _query;
}

-(TightdbQuery *)columnIsLessThanOrEqualTo:(int64_t)value
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    [_query getQuery]->less_equal(_column_ndx, value);
                                    , @"com.tightdb.queryaccessor", _query, &_query->_error);
    return _query;
}

-(TightdbQuery *)columnIsBetween:(int64_t)from and_:(int64_t)to
{
    TIGHTDB_EXCEPTION_ERRHANDLER_EX(
                                    [_query getQuery]->between(_column_ndx, from, to);
                                    , @"com.tightdb.queryaccessor", _query, &_query->_error);
    return _query;
}

-(NSNumber *)minimum
{
    return [self minimumWithError:nil];
}
-(NSNumber *)minimumWithError:(NSError *__autoreleasing *)error
{
    return [_query minimumWithIntColumn:_column_ndx error:error];
}
-(NSNumber *)maximum
{
    return [self maximumWithError:nil];
}
-(NSNumber *)maximumWithError:(NSError *__autoreleasing *)error
{
    return [_query maximumWithIntColumn:_column_ndx error:error];
}

-(NSNumber *)sum
{
    return [self sumWithError:nil];
}
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error
{
    return [_query sumWithIntColumn:_column_ndx error:error];
}
-(NSNumber *)average
{
    return [self averageWithError:nil];
}
-(NSNumber *)averageWithError:(NSError *__autoreleasing *)error
{
    return [_query averageWithIntColumn:_column_ndx error:error];
}
@end


@implementation TightdbQueryAccessorFloat
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TightdbQuery *)columnIsEqualTo:(float)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsNotEqualTo:(float)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsGreaterThan:(float)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(float)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsLessThan:(float)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsLessThanOrEqualTo:(float)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsBetween:(float)from and_:(float)to
{
    [_query getQuery]->between(_column_ndx, from, to);
    return _query;
}

-(NSNumber *)minimum
{
    return [self minimumWithError:nil];
}
-(NSNumber *)minimumWithError:(NSError *__autoreleasing *)error
{
    return [_query minimumWithFloatColumn:_column_ndx error:error];
}
-(NSNumber *)maximum
{
    return [self maximumWithError:nil];
}
-(NSNumber *)maximumWithError:(NSError *__autoreleasing *)error
{
    return [_query maximumWithFloatColumn:_column_ndx error:error];
}

-(NSNumber *)sum
{
    return [self sumWithError:nil];
}
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error
{
    return [_query sumWithFloatColumn:_column_ndx error:error];
}
-(NSNumber *)average
{
    return [self averageWithError:nil];
}
-(NSNumber *)averageWithError:(NSError *__autoreleasing *)error
{
    return [_query averageWithFloatColumn:_column_ndx error:error];
}
@end


@implementation TightdbQueryAccessorDouble
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(TightdbQuery *)columnIsEqualTo:(double)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsNotEqualTo:(double)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsGreaterThan:(double)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(double)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsLessThan:(double)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsLessThanOrEqualTo:(double)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)columnIsBetween:(double)from and_:(double)to
{
    [_query getQuery]->between(_column_ndx, from, to);
    return _query;
}

-(NSNumber *)minimum
{
    return [self minimumWithError:nil];
}
-(NSNumber *)minimumWithError:(NSError *__autoreleasing *)error
{
    return [_query minimumWithDoubleColumn:_column_ndx error:error];
}
-(NSNumber *)maximum
{
    return [self maximumWithError:nil];
}
-(NSNumber *)maximumWithError:(NSError *__autoreleasing *)error
{
    return [_query maximumWithDoubleColumn:_column_ndx error:error];
}

-(NSNumber *)sum
{
    return [self sumWithError:nil];
}
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error
{
    return [_query sumWithDoubleColumn:_column_ndx error:error];
}
-(NSNumber *)average
{
    return [self averageWithError:nil];
}
-(NSNumber *)averageWithError:(NSError *__autoreleasing *)error
{
    return [_query averageWithDoubleColumn:_column_ndx error:error];
}
@end


@implementation TightdbQueryAccessorString
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery *)columnIsEqualTo:(NSString *)value
{
    [_query getQuery]->equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)columnIsEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)columnIsNotEqualTo:(NSString *)value
{
    [_query getQuery]->not_equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)columnIsNotEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->not_equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)columnBeginsWith:(NSString *)value
{
    [_query getQuery]->begins_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)columnBeginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->begins_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)columnEndsWith:(NSString *)value
{
    [_query getQuery]->ends_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)columnEndsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->ends_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)columnContains:(NSString *)value
{
    [_query getQuery]->contains(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)columnContains:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->contains(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
@end


@implementation TightdbQueryAccessorBinary
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery *)columnIsEqualTo:(TightdbBinary *)value
{
    [_query getQuery]->equal(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)columnIsNotEqualTo:(TightdbBinary *)value
{
    [_query getQuery]->not_equal(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)columnBeginsWith:(TightdbBinary *)value
{
    [_query getQuery]->begins_with(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)columnEndsWith:(TightdbBinary *)value
{
    [_query getQuery]->ends_with(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)columnContains:(TightdbBinary *)value
{
    [_query getQuery]->contains(_column_ndx, [value getBinary]);
    return _query;
}
@end


@implementation TightdbQueryAccessorDate
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(TightdbQuery *)columnIsEqualTo:(time_t)value
{
    [_query getQuery]->equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)columnIsNotEqualTo:(time_t)value
{
    [_query getQuery]->not_equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)columnIsGreaterThan:(time_t)value
{
    [_query getQuery]->greater_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(time_t)value
{
    [_query getQuery]->greater_equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)columnIsLessThan:(time_t)value
{
    [_query getQuery]->less_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)columnIsLessThanOrEqualTo:(time_t)value
{
    [_query getQuery]->less_equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)columnIsBetween:(time_t)from and_:(time_t)to
{
    [_query getQuery]->between_date(_column_ndx, from, to);
    return _query;
}
@end


@implementation TightdbQueryAccessorSubtable
{
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
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
    TightdbQuery *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end

