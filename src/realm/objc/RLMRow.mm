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
#import "RLMObjectDescriptor.h"
#import "RLMTable_noinst.h"
#import "RLMPrivate.h"
#import "RLMRowFast.h"
#import "util_noinst.hpp"

using namespace std;


// TODO: Concept for row invalidation (when table updates).

@implementation RLMRow

+(Class)subtableObjectClassForProperty:(NSString *)columnName {
    RLMObjectDescriptor * descriptor = [RLMObjectDescriptor descriptorForObjectClass:self];
    return descriptor[columnName].subtableObjectClass;
}

// make sure users don't create these without a table
-(id)init {
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Must initialize row with table and index" userInfo:nil];
}

-(id)initWithTable:(RLMTable *)table ndx:(NSUInteger)ndx
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
-(NSUInteger)RLM_index
{
    return _ndx;
}
-(void)RLM_setNdx:(NSUInteger)ndx
{
    _ndx = ndx;
}
-(void)dealloc
{
#ifdef REALM_DEBUG
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
        @throw [NSException exceptionWithName:@"realm:wrong_column_type"
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
    return [_table RLM_intInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSString *)stringInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_stringInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSData *)binaryInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_binaryInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(BOOL)boolInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_boolInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(float)floatInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_floatInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(double)doubleInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_doubleInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(NSDate *)dateInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_dateInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(RLMTable *)tableInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_tableInColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(id)mixedInColumnWithIndex:(NSUInteger)colNdx
{
    return [_table RLM_mixedInColumnWithIndex:colNdx atRowIndex:_ndx];
}

/* Setters */
-(void)setInt:(int64_t)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setInt:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setString:(NSString *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setString:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setBinary:(NSData *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setBinary:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setBool:(BOOL)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setBool:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setFloat:(float)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setFloat:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setDouble:(double)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setDouble:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setDate:(NSDate *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setDate:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setTable:(RLMTable *)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setTable:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

-(void)setMixed:(id)value inColumnWithIndex:(NSUInteger)colNdx
{
    [_table RLM_setMixed:value inColumnWithIndex:colNdx atRowIndex:_ndx];
}

@end


@implementation RLMAccessor
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
    return [_row.table RLM_boolInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setBool:(BOOL)value
{
    [_row.table RLM_setBool:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(int64_t)getInt
{
    return [_row.table RLM_intInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setInt:(int64_t)value
{
    [_row.table RLM_setInt:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(float)getFloat
{
    return [_row.table RLM_floatInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setFloat:(float)value
{
    [_row.table RLM_setFloat:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(double)getDouble
{
    return [_row.table RLM_doubleInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setDouble:(double)value
{
    [_row.table RLM_setDouble:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(NSString *)getString
{
    return [_row.table RLM_stringInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setString:(NSString *)value
{
    [_row.table RLM_setString:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(NSData *)getBinary
{
    return [_row.table RLM_binaryInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setBinary:(NSData *)value
{
    [_row.table RLM_setBinary:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}
// FIXME: should it be setBinaryWithBuffer / setBinaryWithBinary ?
// -(BOOL)setBinary:(const char *)data size:(size_t)size
// {
//    return [_row.table setBinary:_columnId ndx:_cursor.ndx data:data size:size error:error];
// }

-(NSDate *)getDate
{
    return [_row.table RLM_dateInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setDate:(NSDate *)value
{
    [_row.table RLM_setDate:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(id)getSubtable:(Class)obj
{
    return [_row.table RLM_tableInColumnWithIndex:_columnId atRowIndex:_row.ndx asTableClass:obj];
}

-(void)setSubtable:(RLMTable *)value
{
    [_row.table RLM_setTable:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(id)getMixed
{
    return [_row.table RLM_mixedInColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

-(void)setMixed:(id)value
{
    [_row.table RLM_setMixed:value inColumnWithIndex:_columnId atRowIndex:_row.ndx];
}

@end
