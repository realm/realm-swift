//
//  cursor.mm
//  TightDb

#include <tightdb/table.hpp>

#import <tightdb/objc/TDBRow.h>
#import <tightdb/objc/TDBTable.h>
#import <tightdb/objc/TDBTable_priv.h>

#include <tightdb/objc/util.hpp>

using namespace std;

// TODO: Concept for cursor invalidation (when table updates).

@interface TDBRow()
@property (nonatomic, weak) TDBTable *table;
@property (nonatomic) NSUInteger ndx;
@end
@implementation TDBRow
@synthesize table = _table;
@synthesize ndx = _ndx;

-(id)initWithTable:(TDBTable *)table ndx:(NSUInteger)ndx
{
    if (ndx >= [table rowCount])
        return nil;

    self = [super init];
    if (self) {
        _table = table;
        _ndx = ndx;
    }
    return self;
}
-(NSUInteger)TDBIndex
{
    return _ndx;
}
-(void)TDBSetNdx:(NSUInteger)ndx
{
    _ndx = ndx;
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    NSLog(@"TDBRow dealloc");
#endif
    _table = nil;
}

-(id)objectAtIndexedSubscript:(NSUInteger)colNdx
{
    TDBType columnType = [_table columnTypeOfColumn:colNdx];
    switch (columnType) {
        case TDBBoolType:
            return [NSNumber numberWithBool:[_table boolInColumnWithIndex:colNdx atRowIndex:_ndx]];
        case TDBIntType:
            return [NSNumber numberWithLongLong:[_table intInColumnWithIndex:colNdx atRowIndex:_ndx]];
        case TDBFloatType:
            return [NSNumber numberWithFloat:[_table floatInColumnWithIndex:colNdx atRowIndex:_ndx]];
        case TDBDoubleType:
            return [NSNumber numberWithLongLong:[_table doubleInColumnWithIndex:colNdx atRowIndex:_ndx]];
        case TDBStringType:
            return [_table stringInColumnWithIndex:colNdx atRowIndex:_ndx];
        case TDBDateType:
            return [_table dateInColumnWithIndex:colNdx atRowIndex:_ndx];
        case TDBBinaryType:
            return [_table binaryInColumnWithIndex:colNdx atRowIndex:_ndx];
        case TDBTableType:
            return [_table tableInColumnWithIndex:colNdx atRowIndex:_ndx];
        case TDBMixedType:
            return [_table mixedInColumnWithIndex:colNdx atRowIndex:_ndx];
    }
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    NSUInteger colNdx = [_table indexOfColumnWithName:(NSString *)key];
    return [self objectAtIndexedSubscript:colNdx];
}

-(void)setObject:(id)obj atIndexedSubscript:(NSUInteger)colNdx
{
    TDBType columnType = [_table columnTypeOfColumn:colNdx];
    
    // TODO: Verify obj type
    
    switch (columnType) {
        case TDBBoolType:
            [_table setBool:[obj boolValue] inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBIntType:
            [_table setInt:[obj longLongValue] inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBFloatType:
            [_table setFloat:[obj floatValue] inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBDoubleType:
            [_table setDouble:[obj doubleValue] inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBStringType:
            if (![obj isKindOfClass:[NSString class]])
                [NSException raise:@"TypeException" format:@"Inserting non-string obj into string column"];
            [_table setString:(NSString*)obj inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBDateType:
            if ([obj isKindOfClass:[NSDate class]])
                [NSException raise:@"TypeException" format:@"Inserting non-date obj into date column"];
            [_table setDate:(NSDate *)obj inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBBinaryType:
            [_table setBinary:(TDBBinary *)obj inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBTableType:
            [_table setTable:(TDBTable *)obj inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
        case TDBMixedType:
            [_table setMixed:(TDBMixed *)obj inColumnWithIndex:colNdx atRowIndex:_ndx];
            break;
    }
}

-(void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    NSUInteger colNdx = [_table indexOfColumnWithName:(NSString*)key];
    [self setObject:obj atIndexedSubscript:colNdx];
}


-(int64_t)intInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table intInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSString *)stringInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table stringInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(TDBBinary *)binaryInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table binaryInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(BOOL)boolInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table boolInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(float)floatInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table floatInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(double)doubleInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table doubleInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSDate *)dateInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table dateInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(TDBTable *)tableInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table tableInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(TDBMixed *)mixedInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table mixedInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setInt:(int64_t)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setInt:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setString:(NSString *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setString:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setBinary:(TDBBinary *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setBinary:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setBool:(BOOL)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setBool:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setFloat:(float)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setFloat:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setDouble:(double)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setDouble:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setDate:(NSDate *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setDate:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setTable:(TDBTable *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setTable:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setMixed:(TDBMixed *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table setMixed:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

@end


@implementation TDBAccessor
{
    __weak TDBRow *_cursor;
    size_t _columnId;
}

-(id)initWithRow:(TDBRow *)cursor columnId:(NSUInteger)columnId
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
    return [_cursor.table boolInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setBool:(BOOL)value
{
    [_cursor.table setBool:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(int64_t)getInt
{
    return [_cursor.table intInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setInt:(int64_t)value
{
    [_cursor.table setInt:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(float)getFloat
{
    return [_cursor.table floatInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setFloat:(float)value
{
    [_cursor.table setFloat:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(double)getDouble
{
    return [_cursor.table doubleInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setDouble:(double)value
{
    [_cursor.table setDouble:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(NSString *)getString
{
    return [_cursor.table stringInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setString:(NSString *)value
{
    [_cursor.table setString:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(TDBBinary *)getBinary
{
    return [_cursor.table binaryInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setBinary:(TDBBinary *)value
{
    [_cursor.table setBinary:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}
// FIXME: should it be setBinaryWithBuffer / setBinaryWithBinary ?
// -(BOOL)setBinary:(const char *)data size:(size_t)size
// {
//    return [_cursor.table setBinary:_columnId ndx:_cursor.ndx data:data size:size error:error];
// }

-(NSDate *)getDate
{
    return [_cursor.table dateInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setDate:(NSDate *)value
{
    [_cursor.table setDate:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(id)getSubtable:(Class)obj
{
    return [_cursor.table tableInColumnWithIndex:_columnId atRowIndex:_cursor.ndx asTableClass:obj];
}

-(void)setSubtable:(TDBTable *)value
{
    [_cursor.table setTable:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(TDBMixed *)getMixed
{
    return [_cursor.table mixedInColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

-(void)setMixed:(TDBMixed *)value
{
    [_cursor.table setMixed:value inColumnWithIndex:_columnId atRowIndex:_cursor.ndx];
}

@end
