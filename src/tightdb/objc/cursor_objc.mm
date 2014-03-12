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
@property (nonatomic) NSUInteger ndx;
@end
@implementation TightdbCursor
@synthesize table = _table;
@synthesize ndx = _ndx;

-(id)initWithTable:(TightdbTable *)table ndx:(NSUInteger)ndx
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
-(NSUInteger)index
{
    return _ndx;
}
-(void)setNdx:(NSUInteger)ndx
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

-(id)objectAtIndexedSubscript:(NSUInteger)colNdx
{
    TightdbType columnType = [_table getColumnType:colNdx];
    switch (columnType) {
        case tightdb_Bool:
            return [NSNumber numberWithBool:[_table getBoolInColumn:colNdx atRow:_ndx]];
        case tightdb_Int:
            return [NSNumber numberWithLongLong:[_table getIntInColumn:colNdx atRow:_ndx]];
        case tightdb_Float:
            return [NSNumber numberWithFloat:[_table getFloatInColumn:colNdx atRow:_ndx]];
        case tightdb_Double:
            return [NSNumber numberWithLongLong:[_table getDoubleInColumn:colNdx atRow:_ndx]];
        case tightdb_String:
            return [_table getStringInColumn:colNdx atRow:_ndx];
        case tightdb_Date:
            return [NSDate dateWithTimeIntervalSince1970:[_table getDateInColumn:colNdx atRow:_ndx]];
        case tightdb_Binary:
            return [_table getBinaryInColumn:colNdx atRow:_ndx];
        case tightdb_Table:
            return [_table getTableInColumn:colNdx atRow:_ndx];
        case tightdb_Mixed:
            return [_table getMixedInColumn:colNdx atRow:_ndx];
    }
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    NSUInteger colNdx = [_table getColumnIndex:(NSString*)key];
    return [self objectAtIndexedSubscript:colNdx];
}

-(void)setObject:(id)obj atIndexedSubscript:(NSUInteger)colNdx
{
    TightdbType columnType = [_table getColumnType:colNdx];

    // TODO: Verify obj type

    switch (columnType) {
        case tightdb_Bool:
            [_table setBool:[obj boolValue] inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_Int:
            [_table setInt:[obj longLongValue] inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_Float:
            [_table setFloat:[obj floatValue] inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_Double:
            [_table setDouble:[obj doubleValue] inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_String:
            if (![obj isKindOfClass:[NSString class]])
                [NSException raise:@"TypeException" format:@"Inserting non-string obj into string column"];
            [_table setString:(NSString*)obj inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_Date:
            if ([obj isKindOfClass:[NSDate class]])
                [NSException raise:@"TypeException" format:@"Inserting non-date obj into date column"];
            [_table setDate:time_t([obj timeIntervalSince1970]) inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_Binary:
            [_table setBinary:(TightdbBinary *)obj inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_Table:
            [_table setTable:(TightdbTable *)obj inColumn:colNdx atRow:_ndx];
            break;
        case tightdb_Mixed:
            [_table setMixed:(TightdbMixed *)obj inColumn:colNdx atRow:_ndx];
            break;
    }
}

-(void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    NSUInteger colNdx = [_table getColumnIndex:(NSString*)key];
    [self setObject:obj atIndexedSubscript:colNdx];
}

-(int64_t)getIntInColumn:(NSUInteger)colNdx
{
    return [_table getIntInColumn:colNdx atRow:_ndx];
}

-(NSString *)getStringInColumn:(NSUInteger)colNdx
{
    return [_table getStringInColumn:colNdx atRow:_ndx];
}

-(TightdbBinary *)getBinaryInColumn:(NSUInteger)colNdx
{
    return [_table getBinaryInColumn:colNdx atRow:_ndx];
}

-(BOOL)getBoolInColumn:(NSUInteger)colNdx
{
    return [_table getBoolInColumn:colNdx atRow:_ndx];
}

-(float)getFloatInColumn:(NSUInteger)colNdx
{
    return [_table getFloatInColumn:colNdx atRow:_ndx];
}

-(double)getDoubleInColumn:(NSUInteger)colNdx
{
    return [_table getDoubleInColumn:colNdx atRow:_ndx];
}

-(time_t)getDateInColumn:(NSUInteger)colNdx
{
    return [_table getDateInColumn:colNdx atRow:_ndx];
}

-(TightdbTable *)getTableInColumn:(NSUInteger)colNdx
{
    return [_table getTableInColumn:colNdx atRow:_ndx];
}

-(TightdbMixed *)getMixedInColumn:(NSUInteger)colNdx
{
    return [_table getMixedInColumn:colNdx atRow:_ndx];
}

-(void)setInt:(int64_t)value inColumn:(NSUInteger)colNdx
{
    [_table setInt:value inColumn:colNdx atRow:_ndx];
}

-(void)setString:(NSString *)value inColumn:(NSUInteger)colNdx
{
    [_table setString:value inColumn:colNdx atRow:_ndx];
}

-(void)setBinary:(TightdbBinary *)value inColumn:(NSUInteger)colNdx
{
    [_table setBinary:value inColumn:colNdx atRow:_ndx];
}

-(void)setBool:(BOOL)value inColumn:(NSUInteger)colNdx
{
    [_table setBool:value inColumn:colNdx atRow:_ndx];
}

-(void)setFloat:(float)value inColumn:(NSUInteger)colNdx
{
    [_table setFloat:value inColumn:colNdx atRow:_ndx];
}

-(void)setDouble:(double)value inColumn:(NSUInteger)colNdx
{
    [_table setDouble:value inColumn:colNdx atRow:_ndx];
}

-(void)setDate:(time_t)value inColumn:(NSUInteger)colNdx
{
    [_table setDate:value inColumn:colNdx atRow:_ndx];
}

-(void)setTable:(TightdbTable *)value inColumn:(NSUInteger)colNdx
{
    [_table setTable:value inColumn:colNdx atRow:_ndx];
}

-(void)setMixed:(TightdbMixed *)value inColumn:(NSUInteger)colNdx
{
    [_table setMixed:value inColumn:colNdx atRow:_ndx];
}

@end


@implementation TightdbAccessor
{
    __weak TightdbCursor *_cursor;
    size_t _columnId;
}

-(id)initWithCursor:(TightdbCursor *)cursor columnId:(NSUInteger)columnId
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
    return [_cursor.table getBoolInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setBool:(BOOL)value
{
    [_cursor.table setBool:value inColumn:_columnId atRow:_cursor.ndx];
}

-(int64_t)getInt
{
    return [_cursor.table getIntInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setInt:(int64_t)value
{
    [_cursor.table setInt:value inColumn:_columnId atRow:_cursor.ndx];
}

-(float)getFloat
{
    return [_cursor.table getFloatInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setFloat:(float)value
{
    [_cursor.table setFloat:value inColumn:_columnId atRow:_cursor.ndx];
}

-(double)getDouble
{
    return [_cursor.table getDoubleInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setDouble:(double)value
{
    [_cursor.table setDouble:value inColumn:_columnId atRow:_cursor.ndx];
}

-(NSString *)getString
{
    return [_cursor.table getStringInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setString:(NSString *)value
{
    [_cursor.table setString:value inColumn:_columnId atRow:_cursor.ndx];
}

-(TightdbBinary *)getBinary
{
    return [_cursor.table getBinaryInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setBinary:(TightdbBinary *)value
{
    [_cursor.table setBinary:value inColumn:_columnId atRow:_cursor.ndx];
}
// FIXME: should it be setBinaryWithBuffer / setBinaryWithBinary ?
// -(BOOL)setBinary:(const char *)data size:(size_t)size
// {
//    return [_cursor.table setBinary:_columnId ndx:_cursor.ndx data:data size:size error:error];
// }

-(time_t)getDate
{
    return [_cursor.table getDateInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setDate:(time_t)value
{
    [_cursor.table setDate:value inColumn:_columnId atRow:_cursor.ndx];
}

-(id)getSubtable:(Class)obj
{
    return [_cursor.table getTableInColumn:_columnId atRow:_cursor.ndx withClass:obj];
}

-(void)setSubtable:(TightdbTable *)value
{
    [_cursor.table setTable:value inColumn:_columnId atRow:_cursor.ndx];
}

-(TightdbMixed *)getMixed
{
    return [_cursor.table getMixedInColumn:_columnId atRow:_cursor.ndx];
}

-(void)setMixed:(TightdbMixed *)value
{
    [_cursor.table setMixed:value inColumn:_columnId atRow:_cursor.ndx];
}

@end
