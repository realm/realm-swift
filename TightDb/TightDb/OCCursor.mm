//
//  OCCursor.mm
//  TightDb

#import "OCCursor.h"
#import "OCTable.h"
#import "OCTablePriv.h"
#import "Table.h"

#pragma mark - OCCursorBase

@interface OCCursorBase()
@property (nonatomic, strong) OCTable *table;
@property (nonatomic) size_t ndx;
@property (nonatomic) CursorBase *cursor;
@end
@implementation OCCursorBase
@synthesize table = _table;
@synthesize ndx = _ndx;
@synthesize cursor = _cursor;

-(id)initWithTable:(OCTable *)table ndx:(size_t)ndx
{
    self = [super init];
    if (self) {
        _table = table;
        _ndx = ndx;
        _cursor = new CursorBase(*[table getTable], ndx);
    }
    return self;
}

-(void)dealloc
{
    delete _cursor;
}

@end

#pragma mark - OCAccessor

@implementation OCAccessor
{
    Accessor *_accessor;
    OCCursorBase *_cursor;
    size_t _columndId;
}

-(id)init
{
    self = [super init];
    if (self) {
        _accessor = new Accessor();
    }
    return self;
}

-(void)dealloc
{
    delete _accessor;
}

-(void)createWithCursor:(OCCursorBase *)cursor columnId:(size_t)columndId
{
    _accessor->Create(cursor.cursor, columndId);
    _columndId = columndId;
}

-(int64_t)get
{
    return [_cursor.table get:_columndId ndx:_cursor.ndx];
}
-(void)set:(int64_t)value
{
    [_cursor.table set:_columndId ndx:_cursor.ndx value:value];
}
-(BOOL)getBool
{
    return [_cursor.table getBool:_columndId ndx:_cursor.ndx];    
}
-(void)setBool:(BOOL)value
{
    [_cursor.table setBool:_columndId ndx:_cursor.ndx value:value];
    
}
-(time_t)getDate
{
    return [_cursor.table getDate:_columndId ndx:_cursor.ndx];

}
-(void)setDate:(time_t)value
{
    [_cursor.table setDate:_columndId ndx:_cursor.ndx value:value];
    
}
-(NSString *)getString
{
    return [_cursor.table getString:_columndId ndx:_cursor.ndx];
    
}
-(void)setString:(NSString *)value
{
    [_cursor.table setString:_columndId ndx:_cursor.ndx value:value];
    
}
-(OCMixed *)getMixed
{
    return [_cursor.table getMixed:_columndId ndx:_cursor.ndx];
    
}
-(void)setMixed:(OCMixed *)value
{
    [_cursor.table setMixed:_columndId ndx:_cursor.ndx value:value];
    
}

@end