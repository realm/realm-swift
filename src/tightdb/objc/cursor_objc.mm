//
//  cursor.mm
//  TightDb

#include <tightdb/table.hpp>

#import <tightdb/objc/cursor.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>

#include <tightdb/objc/util.hpp>

using namespace std;


@interface TightdbCursor()
@property (nonatomic, weak) TightdbTable *table;
@property (nonatomic) size_t ndx;
@end
@implementation TightdbCursor
@synthesize table = _table;
@synthesize ndx = _ndx;

-(id)initWithTable:(TightdbTable *)table ndx:(size_t)ndx
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
    NSLog(@"TightdbCursor dealloc");
#endif
    _table = nil;
}
@end


@implementation TightdbAccessor
{
    __weak TightdbCursor *_cursor;
    size_t _columnId;
}

-(id)initWithCursor:(TightdbCursor *)cursor columnId:(size_t)columnId
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

-(BOOL)setBool:(BOOL)value
{
    return [self setBool:value error:nil];
}

-(BOOL)setBool:(BOOL)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setBool:_columnId ndx:_cursor.ndx value:value error:error];
}

-(int64_t)getInt
{
    return [_cursor.table get:_columnId ndx:_cursor.ndx];
}

-(BOOL)setInt:(int64_t)value
{
    return [self setInt:value error:nil];
}

-(BOOL)setInt:(int64_t)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table set:_columnId ndx:_cursor.ndx value:value error:error];
}

-(float)getFloat
{
    return [_cursor.table getFloat:_columnId ndx:_cursor.ndx];
}

-(BOOL)setFloat:(float)value
{
    return [self setFloat:value error:nil];
}

-(BOOL)setFloat:(float)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setFloat:_columnId ndx:_cursor.ndx value:value error:error];
}

-(double)getDouble
{
    return [_cursor.table getDouble:_columnId ndx:_cursor.ndx];
}

-(BOOL)setDouble:(double)value
{
    return [self setDouble:value error:nil];
}

-(BOOL)setDouble:(double)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setDouble:_columnId ndx:_cursor.ndx value:value error:error];
}

-(NSString *)getString
{
    return [_cursor.table getString:_columnId ndx:_cursor.ndx];
}

-(BOOL)setString:(NSString *)value
{
    return [self setString:value error:nil];
}

-(BOOL)setString:(NSString *)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setString:_columnId ndx:_cursor.ndx value:value error:error];
}

-(TightdbBinary *)getBinary
{
    return [_cursor.table getBinary:_columnId ndx:_cursor.ndx];
}

-(BOOL)setBinary:(TightdbBinary *)value
{
    return [self setBinary:value error:nil];
}

-(BOOL)setBinary:(TightdbBinary *)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setBinary:_columnId ndx:_cursor.ndx value:value error:error];
}

-(BOOL)setBinary:(const char *)data size:(size_t)size
{
    return [self setBinary:data size:size error:nil];
}

-(BOOL)setBinary:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setBinary:_columnId ndx:_cursor.ndx data:data size:size error:error];
}

-(time_t)getDate
{
    return [_cursor.table getDate:_columnId ndx:_cursor.ndx];
}

-(BOOL)setDate:(time_t)value
{
    return [self setDate:value error:nil];
}

-(BOOL)setDate:(time_t)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setDate:_columnId ndx:_cursor.ndx value:value error:error];
}

-(id)getSubtable:(Class)obj
{
    return [_cursor.table getSubtable:_columnId ndx:_cursor.ndx withClass:obj];
}

-(TightdbMixed *)getMixed
{
    return [_cursor.table getMixed:_columnId ndx:_cursor.ndx];
}

-(BOOL)setMixed:(TightdbMixed *)value
{
    return [self setMixed:value error:nil];
}

-(BOOL)setMixed:(TightdbMixed *)value error:(NSError *__autoreleasing *)error
{
    return [_cursor.table setMixed:_columnId ndx:_cursor.ndx value:value error:error];
}

@end
