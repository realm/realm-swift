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
@end
@implementation OCCursorBase
@synthesize table = _table;
@synthesize ndx = _ndx;

-(id)initWithTable:(OCTable *)table ndx:(size_t)ndx
{
    self = [super init];
    if (self) {
        _table = table;
        _ndx = ndx;
    }
    return self;
}
@end

#pragma mark - OCAccessor

@implementation OCAccessor
{
    OCCursorBase *_cursor;
    size_t _columnId;
}

-(id)initWithCursor:(OCCursorBase *)cursor columnId:(size_t)columnId
{
    self = [super init];
    if (self) {
        _cursor = cursor;
        _columnId = columnId;
    }
    return self;
}

-(int64_t)getInt
{
    return [_cursor.table get:_columnId ndx:_cursor.ndx];
}
-(void)setInt:(int64_t)value
{
    [_cursor.table set:_columnId ndx:_cursor.ndx value:value];
}
-(BOOL)getBool
{
    return [_cursor.table getBool:_columnId ndx:_cursor.ndx];    
}
-(void)setBool:(BOOL)value
{
    [_cursor.table setBool:_columnId ndx:_cursor.ndx value:value];
    
}
-(time_t)getDate
{
    return [_cursor.table getDate:_columnId ndx:_cursor.ndx];

}
-(void)setDate:(time_t)value
{
    [_cursor.table setDate:_columnId ndx:_cursor.ndx value:value];
    
}
-(NSString *)getString
{
    return [_cursor.table getString:_columnId ndx:_cursor.ndx];
    
}
-(void)setString:(NSString *)value
{
    [_cursor.table setString:_columnId ndx:_cursor.ndx value:value];
    
}
-(OCMixed *)getMixed
{
    return [_cursor.table getMixed:_columnId ndx:_cursor.ndx];
    
}
-(void)setMixed:(OCMixed *)value
{
    [_cursor.table setMixed:_columnId ndx:_cursor.ndx value:value];
    
}

@end