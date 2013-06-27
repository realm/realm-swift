//
//  query.mm
//  TightDB
//

#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/query.hpp>

#import <tightdb/objc/query.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>
#import <tightdb/objc/cursor.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@interface TightdbView()
+(TightdbView *)tableViewWithTableView:(tightdb::TableView)table;
@end


@implementation TightdbQuery
{
    tightdb::Query *_query;
    __weak TightdbTable *_table;
}


-(id)initWithTable:(TightdbTable *)table
{
    self = [super init];
    if (self) {
        _table = table;
        _query = new tightdb::Query([_table getTable].where());
    }
    return self;
}

-(TightdbCursor *)getCursor:(long)ndx
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

-(size_t)remove
{
    return _query->remove();
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
-(TightdbQuery *)betweenInt:(int64_t)from to:(int64_t)to colNdx:(size_t)colNdx
{
    _query->between(colNdx, from, to);
    return self;
}
-(TightdbQuery *)betweenFloat:(float)from to:(float)to colNdx:(size_t)colNdx
{
    _query->between(colNdx, from, to);
    return self;
}
-(TightdbQuery *)betweenDouble:(double)from to:(double)to colNdx:(size_t)colNdx
{
    _query->between(colNdx, from, to);
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
-(TightdbQuery *)equal:(BOOL)value
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

-(TightdbQuery *)equal:(int64_t)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)notEqual:(int64_t)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)greater:(int64_t)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)greaterEqual:(int64_t)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)less:(int64_t)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)lessEqual:(int64_t)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)between:(int64_t)from to:(int64_t)to
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

-(TightdbQuery *)equal:(float)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)notEqual:(float)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)greater:(float)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)greaterEqual:(float)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)less:(float)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)lessEqual:(float)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)between:(float)from to:(float)to
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

-(TightdbQuery *)equal:(double)value
{
    [_query getQuery]->equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)notEqual:(double)value
{
    [_query getQuery]->not_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)greater:(double)value
{
    [_query getQuery]->greater(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)greaterEqual:(double)value
{
    [_query getQuery]->greater_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)less:(double)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)lessEqual:(double)value
{
    [_query getQuery]->less_equal(_column_ndx, value);
    return _query;
}

-(TightdbQuery *)between:(double)from to:(double)to
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
-(TightdbQuery *)equal:(NSString *)value
{
    [_query getQuery]->equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)notEqual:(NSString *)value
{
    [_query getQuery]->not_equal(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->not_equal(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)beginsWith:(NSString *)value
{
    [_query getQuery]->begins_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->begins_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)endsWith:(NSString *)value
{
    [_query getQuery]->ends_with(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->ends_with(_column_ndx, ObjcStringAccessor(value), caseSensitive);
    return _query;
}
-(TightdbQuery *)contains:(NSString *)value
{
    [_query getQuery]->contains(_column_ndx, ObjcStringAccessor(value));
    return _query;
}
-(TightdbQuery *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive
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
-(TightdbQuery *)equal:(TightdbBinary *)value
{
    [_query getQuery]->equal(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)notEqual:(TightdbBinary *)value
{
    [_query getQuery]->not_equal(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)beginsWith:(TightdbBinary *)value
{
    [_query getQuery]->begins_with(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)endsWith:(TightdbBinary *)value
{
    [_query getQuery]->ends_with(_column_ndx, [value getBinary]);
    return _query;
}
-(TightdbQuery *)contains:(TightdbBinary *)value
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
-(TightdbQuery *)equal:(time_t)value
{
    [_query getQuery]->equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)notEqual:(time_t)value
{
    [_query getQuery]->not_equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)greater:(time_t)value
{
    [_query getQuery]->greater_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)greaterEqual:(time_t)value
{
    [_query getQuery]->greater_equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)less:(time_t)value
{
    [_query getQuery]->less_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)lessEqual:(time_t)value
{
    [_query getQuery]->less_equal_date(_column_ndx, value);
    return _query;
}
-(TightdbQuery *)between:(time_t)from to:(time_t)to
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

