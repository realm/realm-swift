////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#include <tightdb/table.hpp>
#include <tightdb/lang_bind_helper.hpp>


#import "RLMRow.h"
#import "RLMObjectDescriptor.h"
#import "RLMTable_noinst.h"
#import "RLMPrivate.h"
#import "RLMRowFast.h"
#import "util_noinst.hpp"
#import "NSData+RLMGetBinaryData.h"

using namespace std;


// TODO: Concept for row invalidation (when table updates).

@implementation RLMRow

tightdb::TableRef m_table;
BOOL m_read_only;



+(Class)subtableObjectClassForProperty:(NSString *)columnName {
    @throw [NSException exceptionWithName:@"RLMException"
                                   reason:@"Must specify sub-table object type"
                                 userInfo:@{@"columnName": columnName}];
}

// make sure users don't create these without a table
-(id)init {
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Cannot create standalone row outside of tables" userInfo:nil];
}

-(id)initWithTable:(tightdb::TableRef)table ndx:(NSUInteger)ndx readOnly:(BOOL)readOnly
{

    self = [super init];
    if (self) {
        m_table = table;
        _ndx = ndx;
        m_read_only = readOnly;
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

-(tightdb::TableRef)nativeTable{
    return m_table;
}

-(void)dealloc
{
#ifdef REALM_DEBUG
    // NSLog(@"RLMRow dealloc");
#endif
    //_table = nil;
}

- (NSString *)description {
    NSMutableString *mString = [NSMutableString stringWithFormat:@"%@ {\n", NSStringFromClass([self class])];
    
    size_t columnCount = m_table->get_column_count();
    
    for (size_t colIndex = 0; colIndex < columnCount; colIndex++) {
        NSString *columnName = to_objc_string(m_table->get_column_name(colIndex));
        NSString *columnObject = [self[colIndex] description];
        [mString appendFormat:@"\t%@ = %@;\n",
                              columnName,
                              columnObject];
    }
    [mString appendString:@"}"];
    return [mString copy];
}

-(id)objectAtIndexedSubscript:(NSUInteger)colIndex
{
    return get_cell(colIndex, _ndx, *m_table);
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    NSUInteger colNdx = m_table->get_column_index(ObjcStringAccessor((NSString *)key));
    return get_cell(colNdx, _ndx, *m_table);
}

-(void)setObject:(id)obj atIndexedSubscript:(NSUInteger)colIndex
{
    tightdb::Table& t = *m_table;
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
    NSUInteger colNdx = m_table->get_column_index(ObjcStringAccessor((NSString *)key));
    [self setObject:obj atIndexedSubscript:colNdx];
}


// Getters
-(int64_t)intInColumnWithIndex:(NSUInteger)colNdx
{
    return m_table->get_int(colNdx, _ndx);
}

-(NSString *)stringInColumnWithIndex:(NSUInteger)colNdx
{
    return to_objc_string(m_table->get_string(colNdx, _ndx));
}

-(NSData *)binaryInColumnWithIndex:(NSUInteger)colNdx
{
    tightdb::BinaryData bd = m_table->get_binary(colNdx, _ndx);
    return [[NSData alloc] initWithBytes:static_cast<const void *>(bd.data()) length:bd.size()];
}

-(BOOL)boolInColumnWithIndex:(NSUInteger)colNdx
{
    return m_table->get_bool(colNdx, _ndx);
}

-(float)floatInColumnWithIndex:(NSUInteger)colNdx
{
    return m_table->get_float(colNdx, _ndx);
}

-(double)doubleInColumnWithIndex:(NSUInteger)colNdx
{
    return m_table->get_double(colNdx, _ndx);
}

-(NSDate *)dateInColumnWithIndex:(NSUInteger)colNdx
{
    return [NSDate dateWithTimeIntervalSince1970: m_table->get_datetime(colNdx, _ndx).get_datetime()];
}

-(RLMTable *)tableInColumnWithIndex:(NSUInteger)colNdx
{
    tightdb::DataType type = m_table->get_column_type(colNdx);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = m_table->get_subtable(colNdx, _ndx);
    if (!table)
        return nil;
    RLMTable * tableObj = [[RLMTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    return tableObj;}

-(id)mixedInColumnWithIndex:(NSUInteger)colNdx
{
    tightdb::Mixed mixed = m_table->get_mixed(colNdx, _ndx);
    if (mixed.get_type() != tightdb::type_Table)
        return to_objc_object(mixed);
    
    tightdb::TableRef table = m_table->get_subtable(colNdx, _ndx);
    TIGHTDB_ASSERT(table);
    RLMTable * tableObj = [[RLMTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    if (![tableObj _checkType])
        return nil;
    
    return tableObj;}

// Setters
-(void)setInt:(int64_t)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_int(colNdx, _ndx, value);
}

-(void)setString:(NSString *)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_string(colNdx, _ndx, ObjcStringAccessor(value));
}

-(void)setBinary:(NSData *)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_binary(colNdx, _ndx, ((NSData *)value).rlmBinaryData);
}

-(void)setBool:(BOOL)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_bool(colNdx, _ndx, value);
}

-(void)setFloat:(float)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_float(colNdx, _ndx, value);
}

-(void)setDouble:(double)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_double(colNdx, _ndx, value);
}

-(void)setDate:(NSDate *)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_datetime(colNdx, _ndx, tightdb::DateTime((time_t)[value timeIntervalSince1970]));
}

-(void)setTable:(RLMTable *)value inColumnWithIndex:(NSUInteger)colNdx
{
    m_table->set_subtable(colNdx, _ndx, &[value getNativeTable]);
}

-(void)setMixed:(id)value inColumnWithIndex:(NSUInteger)colNdx
{
    tightdb::Mixed mixed;
    to_mixed(value, mixed);
    RLMTable * subtable = mixed.get_type() == tightdb::type_Table ? (RLMTable *)value : nil;
                                    if (subtable) {
                                        tightdb::LangBindHelper::set_mixed_subtable(*m_table, colNdx, _ndx,
                                                                                    [subtable getNativeTable]);
                                    }
                                    else {
                                        m_table->set_mixed(colNdx, _ndx, mixed);
                                    }
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
    return [_row nativeTable]->get_bool(_columnId,_row.ndx);
}

-(void)setBool:(BOOL)value
{
    [_row nativeTable]->set_bool(_columnId, _row.ndx, value);
}

-(int64_t)getInt
{
    return [_row nativeTable]->get_int(_columnId, _row.ndx);
}

-(void)setInt:(int64_t)value
{
    [_row nativeTable]->set_int(_columnId, _row.ndx, value);
}

-(float)getFloat
{
    return [_row nativeTable]->get_float(_columnId, _row.ndx);
}

-(void)setFloat:(float)value
{
    [_row nativeTable]->set_float(_columnId, _row.ndx, value);
}

-(double)getDouble
{
    return [_row nativeTable]->get_double(_columnId, _row.ndx);
}

-(void)setDouble:(double)value
{
    [_row nativeTable]->set_double(_columnId, _row.ndx, value);
}

-(NSString *)getString
{
    return to_objc_string([_row nativeTable]->get_string(_columnId, _row.ndx));
}

-(void)setString:(NSString *)value
{
    [_row nativeTable]->set_string(_columnId, _row.ndx, ObjcStringAccessor(value));
}

-(NSData *)getBinary
{
    tightdb::BinaryData bd = [_row nativeTable]->get_binary(_columnId, _row.ndx);
    return [[NSData alloc] initWithBytes:static_cast<const void *>(bd.data()) length:bd.size()];}

-(void)setBinary:(NSData *)value
{
    [_row nativeTable]->set_binary(_columnId, _row.ndx, ((NSData *)value).rlmBinaryData);}
// FIXME: should it be setBinaryWithBuffer / setBinaryWithBinary ?
// -(BOOL)setBinary:(const char *)data size:(size_t)size
// {
//    return [_row.table setBinary:_columnId ndx:_cursor.ndx data:data size:size error:error];
// }

-(NSDate *)getDate
{
    return [NSDate dateWithTimeIntervalSince1970: [_row nativeTable]->get_datetime(_columnId, _row.ndx).get_datetime()];
}

-(void)setDate:(NSDate *)value
{
    [_row nativeTable]->set_datetime(_columnId, _row.ndx, tightdb::DateTime((time_t)[value timeIntervalSince1970]));}

-(id)getSubtable:(Class)obj
{
    tightdb::DataType type = [_row nativeTable]->get_column_type(_columnId);
    if (type != tightdb::type_Table)
        return nil;
    tightdb::TableRef table = [_row nativeTable]->get_subtable(_columnId, _row.ndx);
    TIGHTDB_ASSERT(table);
    RLMTable * tableObj = [[obj alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    if (![tableObj _checkType])
        return nil;
    return tableObj;}

-(void)setSubtable:(RLMTable *)value
{
    [_row nativeTable]->set_subtable(_columnId, _row.ndx, &[value getNativeTable]);}

-(id)getMixed
{
    tightdb::Mixed mixed = [_row nativeTable]->get_mixed(_columnId, _row.ndx);
    if (mixed.get_type() != tightdb::type_Table)
        return to_objc_object(mixed);
    
    tightdb::TableRef table = [_row nativeTable]->get_subtable(_columnId, _row.ndx);
    TIGHTDB_ASSERT(table);
    RLMTable * tableObj = [[RLMTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    if (![tableObj _checkType])
        return nil;
    
    return tableObj;
}

-(void)setMixed:(id)value
{
    tightdb::Mixed mixed;
    to_mixed(value, mixed);
    RLMTable * subtable = mixed.get_type() == tightdb::type_Table ? (RLMTable *)value : nil;
                                    if (subtable) {
                                        tightdb::LangBindHelper::set_mixed_subtable(*m_table, _columnId, _row.ndx,
                                                                                    [subtable getNativeTable]);
                                    }
                                    else {
                                        m_table->set_mixed(_columnId, _row.ndx, mixed);
                                    }
}

@end
