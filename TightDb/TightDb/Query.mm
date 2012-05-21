//
//  Query.mm
//  TightDB
//

#include "../src/query.hpp"
#import "Query.h"
#import "Table.h"
#import "TablePriv.h"


#pragma mark - TableView secrets

@interface TableView()
+(TableView *)tableViewWithTableView:(tightdb::TableView)table;
@end

#pragma mark - Query

@implementation Query
{
    tightdb::Query *_query;
    Table *_table;
}


-(id)initWithTable:(Table *)table
{
    self = [super init];
    if (self) {
        _table = table;
        _query = new tightdb::Query();
    }
    return self;
}

-(tightdb::Query *)getQuery
{
    return _query;
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
    _query->parent();
}

-(size_t)count
{
    return _query->count(*[_table getTable]);
}

-(double)avgOnColumn:(size_t)columndId
{
    size_t resultCount;
    return _query->average(*[_table getTable], columndId, &resultCount);
}

-(TableView *)findAll
{
    return [TableView tableViewWithTableView:_query->find_all(*[_table getTable])];
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

