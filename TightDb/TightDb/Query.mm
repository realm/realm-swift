//
//  Query.mm
//  TightDB
//

#include "TightDb/query/QueryInterface.h"
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
    _query->LeftParan();
}
-(void)or
{
    _query->Or();
}
-(void)endgroup
{
    _query->RightParan();
}
-(void)subtable:(size_t)column
{
    _query->Subtable(column);
}
-(void)parent
{
    _query->Parent();
}

-(size_t)count
{
    return _query->Count(*[_table getTable]);
}

-(double)avgOnColumn:(size_t)columndId
{
    size_t resultCount;
    return _query->Avg(*[_table getTable], columndId, &resultCount);
}

-(TableView *)findAll
{
    return [TableView tableViewWithTableView:_query->FindAll(*[_table getTable])];
}
@end


#pragma mark - OCXQueryAccessorInt

class XQueryAccessorIntOC : public tightdb::XQueryAccessorInt {
public:
    XQueryAccessorIntOC(size_t columnId, tightdb::Query *query) : XQueryAccessorInt(columnId)
{    
    m_query = query;
}
    size_t getCol() const { return m_column_id;};
};

@implementation OCXQueryAccessorInt
{
    Query *_query;
    XQueryAccessorIntOC *_accessor;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _accessor = new XQueryAccessorIntOC(columnId, [_query getQuery]);
    }
    return self;
}
-(double)avg
{
    return [_query avgOnColumn:_accessor->getCol()];
}

-(Query *)equal:(int64_t)value
{
    _accessor->Equal(value);
    return _query;
}

-(Query *)notEqual:(int64_t)value
{
    _accessor->NotEqual(value);
    return _query;
}

-(Query *)greater:(int64_t)value
{
    _accessor->Greater(value);
    return _query;
}

-(Query *)less:(int64_t)value
{
    _accessor->Less(value);
    return _query;
}

-(Query *)between:(int64_t)from to:(int64_t)to
{
    _accessor->Between(from, to);
    return _query;
}
@end

#pragma mark - OCXQueryAccessorBool

class XQueryAccessorBoolOC : public tightdb::XQueryAccessorBool {
public:
XQueryAccessorBoolOC(size_t columnId, tightdb::Query *query) : XQueryAccessorBool(columnId)
{
    m_query = query;
}
};

@implementation OCXQueryAccessorBool
{
    Query *_query;
    XQueryAccessorBoolOC *_accessor;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _accessor = new XQueryAccessorBoolOC(columnId, [_query getQuery]);
    }
    return self;
}
-(Query *)equal:(BOOL)value
{
    _accessor->Equal(value);
    return _query;
}
@end

#pragma mark - OCXQueryAccessorString

class XQueryAccessorStringOC : public tightdb::XQueryAccessorString {
public:
XQueryAccessorStringOC(size_t columnId, tightdb::Query *query) : XQueryAccessorString(columnId)
{
    m_query = query;
}
};

@implementation OCXQueryAccessorString
{
    Query *_query;
    XQueryAccessorStringOC *_accessor;
}
-(id)initWithColumn:(size_t)columnId query:(Query *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _accessor = new XQueryAccessorStringOC(columnId, [_query getQuery]);
    }
    return self;
}
-(Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->Equal([value UTF8String], caseSensitive);
    return _query;
}
-(Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->NotEqual([value UTF8String], caseSensitive);
    return _query;
}
-(Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->BeginsWith([value UTF8String], caseSensitive);
    return _query;
}
-(Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->EndsWith([value UTF8String], caseSensitive);
    return _query;
}
-(Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->Contains([value UTF8String], caseSensitive);
    return _query;
}
@end

