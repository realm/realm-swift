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

#import <Foundation/Foundation.h>

#import <tightdb/objc/TDBTable.h>
#import <tightdb/objc/TDBTable_priv.h>
#import <tightdb/objc/TDBBinary.h>
#import <tightdb/objc/TDBBinary_priv.h>
#import <tightdb/objc/TDBMixed.h>
#import "TDBMixed_priv.h"
#import <tightdb/objc/util.hpp>

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/table.hpp>
#include <tightdb/lang_bind_helper.hpp>

@implementation TDBMixed
{
    tightdb::Mixed m_mixed;
    TDBTable* m_table;
}

+(TDBMixed*)mixedWithBool:(BOOL)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(bool(value));
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithInt64:(int64_t)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(value);
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithFloat:(float)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(value);
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithDouble:(double)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(value);
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithString:(NSString*)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(ObjcStringAccessor(value));
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithBinary:(TDBBinary*)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed([value getNativeBinary]);
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithBinary:(const char*)data size:(size_t)size
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(tightdb::BinaryData(data, size));
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithDate:(NSDate *)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(tightdb::DateTime([value timeIntervalSince1970]));
    mixed->m_table = nil;
    return mixed;
}

+(TDBMixed*)mixedWithTable:(TDBTable*)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = tightdb::Mixed(tightdb::Mixed::subtable_tag());
    mixed->m_table = value;
    return mixed;
}

+(TDBMixed*)mixedWithNativeMixed:(const tightdb::Mixed&)value
{
    TDBMixed* mixed = [[TDBMixed alloc] init];
    mixed->m_mixed = value;
    mixed->m_table = nil;
    return mixed;
}

-(tightdb::Mixed&)getNativeMixed
{
    return m_mixed;
}

-(BOOL)isEqual:(TDBMixed*)other
{
    tightdb::DataType type = m_mixed.get_type();
    if (type != other->m_mixed.get_type())
        return NO;
    switch (type) {
        case tightdb::type_Bool:
            return m_mixed.get_bool() == other->m_mixed.get_bool();
        case tightdb::type_Int:
            return m_mixed.get_int() == other->m_mixed.get_int();
        case tightdb::type_Float:
            return m_mixed.get_float() == other->m_mixed.get_float();
        case tightdb::type_Double:
            return m_mixed.get_double() == other->m_mixed.get_double();
        case tightdb::type_String:
            return m_mixed.get_string() == other->m_mixed.get_string();
        case tightdb::type_Binary:
            return m_mixed.get_binary() == other->m_mixed.get_binary();
        case tightdb::type_DateTime:
            return m_mixed.get_datetime() == other->m_mixed.get_datetime();
        case tightdb::type_Table:
            return [m_table getNativeTable] == [other->m_table getNativeTable]; // Compare table contents
        case tightdb::type_Mixed:
            TIGHTDB_ASSERT(false);
            break;
    }
    return NO;
}

-(TDBType)getType
{
    return TDBType(m_mixed.get_type());
}

-(BOOL)getBool
{
    return m_mixed.get_bool();
}

-(int64_t)getInt
{
    return m_mixed.get_int();
}

-(float)getFloat
{
    return m_mixed.get_float();
}

-(double)getDouble
{
    return m_mixed.get_double();
}

-(NSString*)getString
{
    return to_objc_string(m_mixed.get_string());
}

-(TDBBinary*)getBinary
{
    return [[TDBBinary alloc] initWithBinary:m_mixed.get_binary()];
}

-(NSDate *)getDate
{
    return [NSDate dateWithTimeIntervalSince1970: m_mixed.get_datetime().get_datetime()];
}

-(TDBTable*)getTable
{
    return m_table;
}
@end
