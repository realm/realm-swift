//
//  cursor.mm
//  TightDb

#import <tightdb/table.hpp>

#import <tightdb/objc/cursor.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>

#pragma mark - CursorBase

@interface CursorBase()
@property (nonatomic, weak) Table *table;
@property (nonatomic) size_t ndx;
@end
@implementation CursorBase
@synthesize table = _table;
@synthesize ndx = _ndx;

-(id)initWithTable:(Table *)table ndx:(size_t)ndx
{
    self = [super init];
    if (self) {
        _table = table;
        _ndx = ndx;
    }
    return self;
}
-(void)setNdx:(size_t)ndx
{
    _ndx = ndx;
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"CursorBase dealloc");
#endif
    _table = nil;
}
@end

#pragma mark - OCAccessor

@implementation OCAccessor
{
    __weak CursorBase *_cursor;
    size_t _columnId;
}

-(id)initWithCursor:(CursorBase *)cursor columnId:(size_t)columnId
{
    self = [super init];
    if (self) {
        _cursor = cursor;
        _columnId = columnId;
    }
    return self;
}


-(BOOL)getBool
{
    return [_cursor.table getBool:_columnId ndx:_cursor.ndx];
}
-(void)setBool:(BOOL)value
{
    [_cursor.table setBool:_columnId ndx:_cursor.ndx value:value];
}

-(int64_t)getInt
{
    return [_cursor.table get:_columnId ndx:_cursor.ndx];
}
-(void)setInt:(int64_t)value
{
    [_cursor.table set:_columnId ndx:_cursor.ndx value:value];
}

-(float)getFloat
{
    return [_cursor.table getFloat:_columnId ndx:_cursor.ndx];
}
-(void)setFloat:(float)value
{
    [_cursor.table setFloat:_columnId ndx:_cursor.ndx value:value];
}

-(double)getDouble
{
    return [_cursor.table getDouble:_columnId ndx:_cursor.ndx];
}
-(void)setDouble:(double)value
{
    [_cursor.table setDouble:_columnId ndx:_cursor.ndx value:value];
}

-(NSString *)getString
{
    return [_cursor.table getString:_columnId ndx:_cursor.ndx];
}
-(void)setString:(NSString *)value
{
    [_cursor.table setString:_columnId ndx:_cursor.ndx value:value];
}

-(BinaryData *)getBinary
{
    return [_cursor.table getBinary:_columnId ndx:_cursor.ndx];
}
-(void)setBinary:(BinaryData *)value
{
    [_cursor.table setBinary:_columnId ndx:_cursor.ndx value:value];
}
-(void)setBinary:(const char *)data size:(size_t)size
{
    [_cursor.table setBinary:_columnId ndx:_cursor.ndx data:data size:size];
}

-(time_t)getDate
{
    return [_cursor.table getDate:_columnId ndx:_cursor.ndx];
}
-(void)setDate:(time_t)value
{
    [_cursor.table setDate:_columnId ndx:_cursor.ndx value:value];
}

-(id)getSubtable:(Class)obj
{
    return [_cursor.table getSubtable:_columnId ndx:_cursor.ndx withClass:obj];
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
