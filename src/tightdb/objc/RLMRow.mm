/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#include <tightdb/table.hpp>

#import "RLMRow.h"
#import "TDBTable_noinst.h"
#import "PrivateTDB.h"
#import "RLMRowFast.h"
#import "util_noinst.hpp"

using namespace std;


// TODO: Concept for row invalidation (when table updates).

@interface RLMRow ()
@property (nonatomic, weak) TDBTable *table;
@property (nonatomic) NSUInteger ndx;
@end
@implementation RLMRow
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
-(NSUInteger)TDB_index
{
    return _ndx;
}
-(void)TDB_setNdx:(NSUInteger)ndx
{
    _ndx = ndx;
}
-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    // NSLog(@"RLMRow dealloc");
#endif
    _table = nil;
}

-(id)objectAtIndexedSubscript:(NSUInteger)colIndex
{
    return get_cell(colIndex, _ndx, [_table getNativeTable]);
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    NSUInteger colNdx = [_table indexOfColumnWithName:(NSString *)key];
    return get_cell(colNdx, _ndx, [_table getNativeTable]);
}

-(void)setObject:(id)obj atIndexedSubscript:(NSUInteger)colIndex
{
    tightdb::Table& t = [_table getNativeTable];
    tightdb::ConstDescriptorRef descr = t.get_descriptor();
    if (!verify_cell(*descr, size_t(colIndex), (NSObject *)obj)) {
        @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                            reason:[NSString stringWithFormat:@"colName %@ with index: %lu is of type %u",
                            to_objc_string(t.get_column_name(colIndex)), (unsigned long)colIndex, t.get_column_type(colIndex)]
                            userInfo:nil];
    }
    set_cell(size_t(colIndex), size_t(_ndx), t, (NSObject *)obj);
}

-(void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    NSUInteger colNdx = [_table indexOfColumnWithName:(NSString*)key];
    [self setObject:obj atIndexedSubscript:colNdx];
}


/* Getters */
-(int64_t)intInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_intInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSString *)stringInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_stringInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSData *)binaryInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_binaryInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(BOOL)boolInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_boolInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(float)floatInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_floatInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(double)doubleInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_doubleInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSDate *)dateInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_dateInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(TDBTable *)tableInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_tableInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(id)mixedInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table TDB_mixedInColumnWithIndex:colNdx atRowIndex:_ndx];
}

/* Setters */
-(void)setInt:(int64_t)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setInt:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setString:(NSString *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setString:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setBinary:(NSData *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setBinary:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setBool:(BOOL)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setBool:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setFloat:(float)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setFloat:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setDouble:(double)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setDouble:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setDate:(NSDate *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setDate:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setTable:(TDBTable *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setTable:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setMixed:(id)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table TDB_setMixed:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

@end


@implementation TDBAccessor
{
    __weak RLMRow *_row;
    size_t _columnId;
}

-(id)initWithRow:(RLMRow *)row columnId:(NSUInteger)columnId
{
    self = [super init];
    if (self) {
        _row = row;
        _columnId = columnId;
    }
    return self;
}

-(BOOL)getBool
{
    return [_row.table TDB_boolInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setBool:(BOOL)value
{
    [_row.table TDB_setBool:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(int64_t)getInt
{
    return [_row.table TDB_intInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setInt:(int64_t)value
{
    [_row.table TDB_setInt:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(float)getFloat
{
    return [_row.table TDB_floatInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setFloat:(float)value
{
    [_row.table TDB_setFloat:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(double)getDouble
{
    return [_row.table TDB_doubleInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setDouble:(double)value
{
    [_row.table TDB_setDouble:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(NSString *)getString
{
    return [_row.table TDB_stringInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setString:(NSString *)value
{
    [_row.table TDB_setString:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(NSData *)getBinary
{
    return [_row.table TDB_binaryInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setBinary:(NSData *)value
{
    [_row.table TDB_setBinary:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}
// FIXME: should it be setBinaryWithBuffer / setBinaryWithBinary ?
// -(BOOL)setBinary:(const char *)data size:(size_t)size
// {
//    return [_row.table setBinary:_columnId ndx:_cursor.ndx data:data size:size error:error];
// }

-(NSDate *)getDate
{
    return [_row.table TDB_dateInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setDate:(NSDate *)value
{
    [_row.table TDB_setDate:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(id)getSubtable:(Class)obj
{
    return [_row.table TDB_tableInColumnWithIndex:_columnId atRowIndex:_row.ndx asTableClass:obj];
}

-(void)setSubtable:(TDBTable *)value
{
    [_row.table TDB_setTable:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(id)getMixed
{
    return [_row.table TDB_mixedInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setMixed:(id)value
{
    [_row.table TDB_setMixed:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

@end
