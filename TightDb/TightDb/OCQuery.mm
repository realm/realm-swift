//
//  OCQuery.mm
//  TightDB
//

#import "OCQuery.h"
#import "OCTable.h"
#import "OCTablePriv.h"
#include "TightDb/query/QueryInterface.h"


#pragma mark - OCTableView secrets

@interface OCTableView()
+(OCTableView *)tableViewWithTableView:(tightdb::TableView)table;
@end

#pragma mark - OCQuery

@implementation OCQuery
{
    tightdb::Query *_query;
}


-(id)init
{
    self = [super init];
    if (self) {
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

-(size_t)count:(OCTable *)table
{
    return _query->Count(*[table getTable]);
}

-(double)avg:(OCTable *)table column:(size_t)columndId resultCount:(size_t *)resultCount
{
    return _query->Avg(*[table getTable], columndId, resultCount);
}

-(OCTableView *)findAll:(OCTable *)table
{
    return [OCTableView tableViewWithTableView:_query->FindAll(*[table getTable])];
}
@end


#pragma mark - OCXQueryAccessorInt

class XQueryAccessorIntOC : public tightdb::XQueryAccessorInt {
public:
    XQueryAccessorIntOC(size_t columnId, tightdb::Query *query) : XQueryAccessorInt(columnId)
{
    m_query = query;
}
};

@implementation OCXQueryAccessorInt
{
    OCQuery *_query;
    XQueryAccessorIntOC *_accessor;
}
-(id)initWithColumn:(size_t)columnId query:(OCQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _accessor = new XQueryAccessorIntOC(columnId, [_query getQuery]);
    }
    return self;
}
-(OCQuery *)equal:(int64_t)value
{
    _accessor->Equal(value);
    return _query;
}

-(OCQuery *)notEqual:(int64_t)value
{
    _accessor->NotEqual(value);
    return _query;
}

-(OCQuery *)greater:(int64_t)value
{
    _accessor->Greater(value);
    return _query;
}

-(OCQuery *)less:(int64_t)value
{
    _accessor->Less(value);
    return _query;
}

-(OCQuery *)between:(int64_t)from to:(int64_t)to
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
    OCQuery *_query;
    XQueryAccessorBoolOC *_accessor;
}
-(id)initWithColumn:(size_t)columnId query:(OCQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _accessor = new XQueryAccessorBoolOC(columnId, [_query getQuery]);
    }
    return self;
}
-(OCQuery *)equal:(BOOL)value
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
    OCQuery *_query;
    XQueryAccessorStringOC *_accessor;
}
-(id)initWithColumn:(size_t)columnId query:(OCQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        _accessor = new XQueryAccessorStringOC(columnId, [_query getQuery]);
    }
    return self;
}
-(OCQuery *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->Equal([value UTF8String], caseSensitive);
    return _query;
}
-(OCQuery *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->NotEqual([value UTF8String], caseSensitive);
    return _query;
}
-(OCQuery *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->BeginsWith([value UTF8String], caseSensitive);
    return _query;
}
-(OCQuery *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->EndsWith([value UTF8String], caseSensitive);
    return _query;
}
-(OCQuery *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive
{
    _accessor->Contains([value UTF8String], caseSensitive);
    return _query;
}
@end

