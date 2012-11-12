//
//  Query.mm
//  TightDB
//

#import <tightdb/table.hpp>
#import <tightdb/table_view.hpp>
#import <tightdb/query.hpp>

#import <tightdb/objc/Query.h>
#import <tightdb/objc/Table.h>
#import <tightdb/objc/TablePriv.h>
#import <tightdb/objc/Cursor.h>

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
        _query = new tightdb::Query([_table getTable]->where());
    }
    return self;
}

-(CursorBase *)getCursor:(long)ndx
{
    return nil; // Must be overridden in TightDb.h
}

-(long)getFastEnumStart
{
    return 0; // Must be overridden in TightDb.h
}
-(long)incrementFastEnum:(long)ndx
{
    return ndx; // Must be overridden in TightDb.h
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len
{
    if(state->state == 0)
    {
        state->state = [self getFastEnumStart];
        state->mutationsPtr = (unsigned long *)objc_unretainedPointer(self);
        CursorBase *tmp = [self getCursor:state->state];
        *stackbuf = tmp;
    }
    if (state->state != -1) {
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

-(double)avgOnColumn:(size_t)columndId
{
    size_t resultCount;
    return _query->average(columndId, &resultCount);
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
-(double)avg
{
    return [_query avgOnColumn:_column_ndx];
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

-(Query *)less:(int64_t)value
{
    [_query getQuery]->less(_column_ndx, value);
    return _query;
}

-(Query *)between:(int64_t)from to:(int64_t)to
{
    [_query getQuery]->between(_column_ndx, from, to);
    return _query;
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
-(Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->equal(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->not_equal(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->begins_with(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->ends_with(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
-(Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    [_query getQuery]->contains(_column_ndx, [value UTF8String], caseSensitive);
    return _query;
}
@end

