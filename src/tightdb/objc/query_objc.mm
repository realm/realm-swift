//
//  query.mm
//  TightDB
//

#import <tightdb/table.hpp>
#import <tightdb/table_view.hpp>
#import <tightdb/query.hpp>

#import <tightdb/objc/query.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>
#import <tightdb/objc/cursor.h>

#pragma mark - TableView secrets

@interface TableView()
+(TableView *)tableViewWithTableView:(tightdb::TableView)table;
@end

#pragma mark - Query

@implementation Query
{
    tightdb::Query *_query;
    __weak Table *_table;
}


-(id)initWithTable:(Table *)table
{
    self = [super init];
    if (self) {
        _table = table;
        _query = new tightdb::Query([_table getTable].where());
    }
    return self;
}

-(CursorBase *)getCursor:(long)ndx
{
    (void)ndx;
    return nil; // Must be overridden in TightDb.h
}

-(long)getFastEnumStart
{
    return 0; // Must be overridden in TightDb.h
}
-(long)incrementFastEnum:(long)ndx
{
    (void)ndx;
    return ndx; // Must be overridden in TightDb.h
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
    (void)len;
    if(state->state == 0)
    {
        state->state = [self getFastEnumStart];
        state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self);
        CursorBase *tmp = [self getCursor:state->state];
        *stackbuf = tmp;
    }
    if ((int)state->state != -1) {
        [((CursorBase *)*stackbuf) setNdx:state->state];
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

-(Table *)getTable
{
    return _table;
}

-(void)group
{
    _query->group();
}
-(void)or
{
    _query->Or();
}
-(void)endgroup
{
    _query->end_group();
}
-(void)subtable:(size_t)column
{
    _query->subtable(column);
}
-(void)parent
{
    _query->end_subtable();
}

-(size_t)count
{
    return _query->count();
}

-(int64_t)minInt:(size_t)col_ndx
{
    return _query->minimum(col_ndx);
}
-(float)minFloat:(size_t)col_ndx
{
    return _query->minimum_float(col_ndx);
}
-(double)minDouble:(size_t)col_ndx
{
    return _query->minimum_double(col_ndx);
}

-(int64_t)maxInt:(size_t)col_ndx
{
    return _query->maximum(col_ndx);
}
-(float)maxFloat:(size_t)col_ndx
{
    return _query->maximum_float(col_ndx);
}
-(double)maxDouble:(size_t)col_ndx
{
    return _query->maximum_double(col_ndx);
}

-(int64_t)sumInt:(size_t)col_ndx
{
    return _query->sum(col_ndx);
}
-(double)sumFloat:(size_t)col_ndx
{
    return _query->sum_float(col_ndx);
}
-(double)sumDouble:(size_t)col_ndx
{
    return _query->sum_double(col_ndx);
}

-(double)avgInt:(size_t)col_ndx
{
    return _query->average(col_ndx);
}
-(double)avgFloat:(size_t)col_ndx
{
    return _query->average_float(col_ndx);
}
-(double)avgDouble:(size_t)col_ndx
{
    return _query->average_double(col_ndx);
}

-(tightdb::TableView)getTableView
{
    return _query->find_all();
}
-(size_t)findNext:(size_t)last
{
    return _query->find_next(last);
}
@end


#pragma mark - OCXQueryAccessorBool

@implementation OCXQueryAccessorBool
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(Query *)equal:(BOOL)value
{
    [_query getQuery]->equal(_column_ndx, (bool)value);
    return _query;
}
@end


#pragma mark - OCXQueryAccessorInt

@implementation OCXQueryAccessorInt
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(Query *)equal:(int64_t)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(Query *)notEqual:(int64_t)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(Query *)greater:(int64_t)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(Query *)greaterEqual:(int64_t)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(Query *)less:(int64_t)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(Query *)lessEqual:(int64_t)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(Query *)between:(int64_t)from to:(int64_t)to
{
    [_query getQuery]->between(_column_ndx, from, to);
    return _query;
}

-(int64_t)min
{
    return [_query minInt:_column_ndx];
}
-(int64_t)max
{
    return [_query maxInt:_column_ndx];
}
-(int64_t)sum
{
    return [_query sumInt:_column_ndx];
}
-(double)avg
{
    return [_query avgInt:_column_ndx];
}
@end


#pragma mark - OCXQueryAccessorFloat

@implementation OCXQueryAccessorFloat
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(Query *)equal:(float)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(Query *)notEqual:(float)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(Query *)greater:(float)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(Query *)greaterEqual:(float)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(Query *)less:(float)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(Query *)lessEqual:(float)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(Query *)between:(float)from to:(float)to
{
    [_query getQuery]->between(_column_ndx, from, to);
    return _query;
}

-(float)min
{
    return [_query minFloat:_column_ndx];
}
-(float)max
{
    return [_query maxFloat:_column_ndx];
}
-(double)sum
{
    return [_query sumFloat:_column_ndx];
}
-(double)avg
{
    return [_query avgFloat:_column_ndx];
}
@end


#pragma mark - OCXQueryAccessorDouble

@implementation OCXQueryAccessorDouble
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}

-(Query *)equal:(double)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(Query *)notEqual:(double)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(Query *)greater:(double)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(Query *)greaterEqual:(double)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(Query *)less:(double)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(Query *)lessEqual:(double)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(Query *)between:(double)from to:(double)to
{
    [_query getQuery]->between(_column_ndx, from, to);
    return _query;
}

-(double)min
{
    return [_query minDouble:_column_ndx];
}
-(double)max
{
    return [_query maxDouble:_column_ndx];
}
-(double)sum
{
    return [_query sumDouble:_column_ndx];
}
-(double)avg
{
    return [_query avgDouble:_column_ndx];
}
@end


#pragma mark - OCXQueryAccessorString

@implementation OCXQueryAccessorString
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(Query *)equal:(NSString *)value
{
    [_query getQuery]->equal(_column_ndx, [value UTF8String]);
    return _query;
}
-(Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->equal(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)notEqual:(NSString *)value
{
    [_query getQuery]->not_equal(_column_ndx, [value UTF8String]);
    return _query;
}
-(Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->not_equal(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)beginsWith:(NSString *)value
{
    [_query getQuery]->begins_with(_column_ndx, [value UTF8String]);
    return _query;
}
-(Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->begins_with(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)endsWith:(NSString *)value
{
    [_query getQuery]->ends_with(_column_ndx, [value UTF8String]);
    return _query;
}
-(Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->ends_with(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)contains:(NSString *)value
{
    [_query getQuery]->contains(_column_ndx, [value UTF8String]);
    return _query;
}
-(Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->contains(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
@end


#pragma mark - OCXQueryAccessorBinary

@implementation OCXQueryAccessorBinary
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end


#pragma mark - OCXQueryAccessorDate

@implementation OCXQueryAccessorDate
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
-(Query *)equal:(time_t)value
{
    [_query getQuery]->equal_date(_column_ndx, value);
    return _query;
}
-(Query *)notEqual:(time_t)value
{
    [_query getQuery]->not_equal_date(_column_ndx, value);
    return _query;
}
-(Query *)greater:(time_t)value
{
    [_query getQuery]->greater_date(_column_ndx, value);
    return _query;
}
-(Query *)greaterEqual:(time_t)value
{
    [_query getQuery]->greater_equal_date(_column_ndx, value);
    return _query;
}
-(Query *)less:(time_t)value
{
    [_query getQuery]->less_date(_column_ndx, value);
    return _query;
}
-(Query *)lessEqual:(time_t)value
{
    [_query getQuery]->less_equal_date(_column_ndx, value);
    return _query;
}
-(Query *)between:(time_t)from to:(time_t)to
{
    [_query getQuery]->between_date(_column_ndx, from, to);
    return _query;
}
@end


#pragma mark - OCXQueryAccessorSubtable

@implementation OCXQueryAccessorSubtable
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end


#pragma mark - OCXQueryAccessorMixed

@implementation OCXQueryAccessorMixed
{
    Query *_query;
    size_t _column_ndx;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _column_ndx = columnId;
    }
    return self;
}
@end

