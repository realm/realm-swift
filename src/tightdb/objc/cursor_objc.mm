//
//  cursor.mm
//  TightDb

#include <tightdb/table.hpp>

#import <tightdb/objc/cursor.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/table_priv.h>

#include <tightdb/objc/util.hpp>

using namespace std;

// TODO: Concept for cursor invalidation (when table updates).

@interface TightdbCursor()
@property (nonatomic, weak) TightdbTable *table;
@property (nonatomic) size_t ndx;
@end
@implementation TightdbCursor
@synthesize table = _table;
@synthesize ndx = _ndx;

-(id)initWithTable:(TightdbTable *)table ndx:(size_t)ndx
{
    if (ndx >= [table count])
        return nil;

    self = [super init];
    if (self) {
        _table = table;
        _ndx = ndx;
    }
    return self;
}
-(size_t)index
{
    return _ndx;
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

-(int64_t)getIntInColumn:(size_t)colNdx
{
    return [_table get:colNdx ndx:_ndx];
}

-(NSString *)getStringInColumn:(size_t)colNdx
{
    return [_table getString:colNdx ndx:_ndx];
}

-(BOOL)getBoolInColumn:(size_t)colNdx
{
    return [_table getBool:colNdx ndx:_ndx];
}

-(float)getFloatInColumn:(size_t)colNdx
{
    return [_table getFloat:colNdx ndx:_ndx];
}

-(double)getDoubleInColumn:(size_t)colNdx
{
    return [_table getDouble:colNdx ndx:_ndx];
}

-(time_t)getDateInColumn:(size_t)colNdx
{
    return [_table getDate:colNdx ndx:_ndx];
}

-(TightdbBinary *)getBinaryInColumn:(size_t)colNdx
{
    return [_table getBinary:colNdx ndx:_ndx];
}

-(TightdbMixed *)getMixedInColumn:(size_t)colNdx
{
    return [_table getMixed:colNdx ndx:_ndx];
}

-(TightdbTable *)getTableInColumn:(size_t)colNdx
{
    return [_table getSubtable:colNdx ndx:_ndx];
}


-(BOOL)setInt:(int64_t)value inColumn:(size_t)colNdx
{
    return [self setInt:value inColumn:colNdx error:nil];
}

-(BOOL)setInt:(int64_t)value inColumn:(size_t)colNdx error:(NSError *__autoreleasing *)error
{
    return [_table set:colNdx ndx:_ndx value:value error:error];
}

-(BOOL)setString:(NSString *)value inColumn:(size_t)colNdx
{
    return [self setString:value inColumn:colNdx error:nil];
}

-(BOOL)setString:(NSString *)value inColumn:(size_t)colNdx error:(NSError *__autoreleasing *)error
{
    return [_table setString:colNdx ndx:_ndx value:value error:error];
}

-(BOOL)setBool:(BOOL)value inColumn:(size_t)colNdx
{
    return [self setBool:value inColumn:colNdx error:nil];
}

-(BOOL)setBool:(BOOL)value inColumn:(size_t)colNdx error:(NSError *__autoreleasing *)error
{
    return [_table setBool:colNdx ndx:_ndx value:value error:error];
}

-(BOOL)setFloat:(float)value inColumn:(size_t)colNdx
{
    return [self setFloat:value inColumn:colNdx error:nil];
}

-(BOOL)setFloat:(float)value inColumn:(size_t)colNdx error:(NSError *__autoreleasing *)error
{
    return [_table setFloat:colNdx ndx:_ndx value:value error:error];
}

-(BOOL)setDouble:(double)value inColumn:(size_t)colNdx
{
    return [self setDouble:value inColumn:colNdx error:nil];
}

-(BOOL)setDouble:(double)value inColumn:(size_t)colNdx error:(NSError *__autoreleasing *)error
{
    return [_table setDouble:colNdx ndx:_ndx value:value error:error];
}

-(BOOL)setDate:(time_t)value inColumn:(size_t)colNdx
{
    return [_table setDate:colNdx ndx:_ndx value:value];
}

-(BOOL)setBinary:(TightdbBinary *)value inColumn:(size_t)colNdx
{
    return [self setBinary:value inColumn:colNdx error:nil];
}

-(BOOL)setBinary:(TightdbBinary *)value inColumn:(size_t)colNdx error:(NSError *__autoreleasing *)error
{
    return [_table setBinary:colNdx ndx:_ndx value:value error:error];
}

-(BOOL)setMixed:(TightdbMixed *)value inColumn:(size_t)colNdx
{
    return [self setMixed:value inColumn:colNdx error:nil];
}

-(BOOL)setMixed:(TightdbMixed *)value inColumn:(size_t)colNdx error:(NSError *__autoreleasing *)error
{
    return [_table setMixed:colNdx ndx:_ndx value:value error:error];
}

-(BOOL)setTable:(TightdbTable *)value inColumn:(size_t)colNdx
{
    return [_table setSubtable:colNdx ndx:_ndx withTable:value];
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

-(BOOL)setSubtable:(TightdbTable *)subtable
{
    return [_cursor.table setSubtable:_columnId ndx:_cursor.ndx withTable:subtable];
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
