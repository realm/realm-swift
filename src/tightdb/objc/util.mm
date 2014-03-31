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

#include <tightdb/descriptor.hpp>
#include <tightdb/binary_data.hpp>
#include <tightdb/string_data.hpp>

#import "TDBTable.h"
#import "TDBTable_noinst.h"
#import "util_noinst.hpp"
#import "NSData+TDBGetBinaryData.h"

using namespace tightdb;

inline bool nsnumber_is_like_bool(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    /* @encode(BOOL) is 'B' on iOS 64 and 'c'
     objcType is always 'c'. Therefore compare to "c".
     */
    return data_type[0] == 'c';
}

inline bool nsnumber_is_like_integer(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    return (strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

inline bool nsnumber_is_like_float(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    return (strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

inline bool nsnumber_is_like_double(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    return (strcmp(data_type, @encode(double)) == 0 ||
            strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}


void to_mixed(id value, Mixed& m)
{
    if ([value isKindOfClass:[NSString class]]) {
        StringData s([(NSString *)value UTF8String], [(NSString *)value length]);
        m.set_string(s);
        return;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        if (nsnumber_is_like_bool(value)) {
            m.set_bool([(NSNumber *)value boolValue]);
            return;
        }
        if (nsnumber_is_like_integer(value)) {
            m.set_int(int64_t([(NSNumber *)value longLongValue]));
            return;
        }
        if (nsnumber_is_like_float(value)) {
            m.set_float([(NSNumber *)value floatValue]);
            return;
        }
        if (nsnumber_is_like_double(value)) {
            m.set_double([(NSNumber *)value doubleValue]);
            return;
        }
    }
    if ([value isKindOfClass:[NSData class]]) {
        m.set_binary([(NSData *)value tdbBinaryData]);
        return;
    }
    if ([value isKindOfClass:[NSDate class]]) {
        m.set_datetime(DateTime(time_t([(NSDate *)value timeIntervalSince1970])));
        return;
    }
    if ([value isKindOfClass:[TDBTable class]])
        m = Mixed(Mixed::subtable_tag());
}


BOOL verify_cell(const Descriptor& descr, size_t col_ndx, NSObject *obj)
{
    DataType type = descr.get_column_type(col_ndx);
    StringData name = descr.get_column_name(col_ndx);
    switch (type) {
        case type_String:
            if (![obj isKindOfClass:[NSString class]])
                return NO;
            break;
        case type_Bool:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_bool(obj))
                    break;
                return NO;
            }
            break;
        case type_DateTime:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_integer(obj))
                    break;
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                break;
            }
            return NO;
        case type_Int:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_integer(obj))
                    break;
            }
            return NO;
        case type_Float:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_float(obj))
                    break;
            }
            return NO;
        case type_Double:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_double(obj))
                    break;
            }
            return NO;
        case type_Binary:
            if ([obj isKindOfClass:[NSData class]])
                break;
            return NO;
        case type_Mixed:
            // FIXME: Do a proper check!
            /*            if ([obj isKindOfClass:[NSArray class]]) {
             TableRef t = Table::create();
             NSEnumerator *subobj = [obj objectEnumerator];
             size_t subndx = 0;
             while ([subobj nextObject]) {
             if (subndx == 0) {
             if (!set_columns(*t, subobj))
             return NO;
             }
             else {
             ConstDescriptorRef subdescr = t->get_descriptor();
             if (!verify_row(*subdescr, (NSArray *)subobj))
             return NO;
             }
             }
             }
             else
             return NO;
             */
            break; /* everything goes */
        case type_Table:
            if ([obj isKindOfClass:[NSArray class]]) {
                if ([(NSArray *)obj count] == 0)
                    break; /* empty subtable */
                id subobj;
                ConstDescriptorRef subdescr = descr.get_subdescriptor(col_ndx);
                NSEnumerator *subenumerator = [(NSArray *)obj objectEnumerator];
                while (subobj = [subenumerator nextObject]) {
                    if (![subobj isKindOfClass:[NSArray class]])
                        return NO;
                    verify_row(*subdescr, (NSArray *)subobj);
                }
                break;
            }
            if ([obj isKindOfClass:[TDBTable class]])
                break;
            return NO;
    }
    return YES;
}


void verify_row(const Descriptor& descr, NSArray* data)
{
    if (descr.get_column_count() != [data count]) {
        NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_count"
                                                         reason:@"Number of columns do not match"
                                                       userInfo:[NSMutableDictionary dictionary]];
        [exception raise];
    }

    NSEnumerator *enumerator = [data objectEnumerator];
    id obj;

    size_t col_ndx = 0;
    while (obj = [enumerator nextObject]) {
        if (!verify_cell(descr, col_ndx, obj)) {
            NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                             reason:[NSString stringWithFormat:@"colName %@ with index: %lu is of type %u",
                                                                     to_objc_string(descr.get_column_name(col_ndx)), col_ndx, descr.get_column_type(col_ndx) ]
                                                           userInfo:[NSMutableDictionary dictionary]];
            [exception raise];
        }
        ++col_ndx;
    }
}

void verify_row_with_labels(const Descriptor& descr, NSDictionary* data)
{
    size_t n = descr.get_column_count();
    for (size_t i = 0; i != n; ++i) {
        NSString *col_name = to_objc_string(descr.get_column_name(i));
        id value = [data valueForKey:col_name];
        if (value == nil)
            continue;
        if (!verify_cell(descr, i, value)) {
            NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                             reason:[NSString stringWithFormat:@"colName %@ with index: %lu is of type %u",
                                                                     to_objc_string(descr.get_column_name(i)), i, descr.get_column_type(i) ]
                                                           userInfo:[NSMutableDictionary dictionary]];
            [exception raise];
        }
    }
}

bool insert_cell(size_t col_ndx, size_t row_ndx, Table& table, NSObject *obj)
{
    BOOL subtable_seen = NO;
    DataType type = table.get_column_type(col_ndx);
    switch (type) {
        case type_Bool:
            if (obj == nil)
                table.insert_bool(col_ndx, row_ndx, false);
            else
                table.insert_bool(col_ndx, row_ndx, bool([(NSNumber *)obj boolValue]));
            break;
        case type_DateTime:
            if (obj == nil) {
                table.insert_datetime(col_ndx, row_ndx, time_t(0));
            }
            else {
                if ([obj isKindOfClass:[NSDate class]]) {
                    table.insert_datetime(col_ndx, row_ndx, time_t([(NSDate *)obj timeIntervalSince1970]));
                }
                else {
                    table.insert_datetime(col_ndx, row_ndx, time_t([(NSNumber *)obj longValue]));
                }
            }
            break;
        case type_Int:
            if (obj == nil)
                table.insert_int(col_ndx, row_ndx, 0);
            else
                table.insert_int(col_ndx, row_ndx, int64_t([(NSNumber *)obj longValue]));
            break;
        case type_Float:
            if (obj == nil)
                table.insert_float(col_ndx, row_ndx, 0.0);
            else
                table.insert_float(col_ndx, row_ndx, float([(NSNumber *)obj floatValue]));
            break;
        case type_Double:
            if (obj == nil)
                table.insert_double(col_ndx, row_ndx, 0.0);
            else
                table.insert_double(col_ndx, row_ndx, double([(NSNumber *)obj doubleValue]));
            break;
        case type_String:
            if (obj == nil) {
                StringData sd("");
                table.insert_string(col_ndx, row_ndx, sd);
            }
            else {
                StringData sd([(NSString *)obj UTF8String]);
                table.insert_string(col_ndx, row_ndx, sd);
            }
            break;
        case type_Binary:
            if (obj == nil) {
                BinaryData bd("", 0);
                table.insert_binary(col_ndx, row_ndx, bd);
            }
            else {
                table.insert_binary(col_ndx, row_ndx, ((NSData *)obj).tdbBinaryData);
            }
            break;
        case type_Table:
            subtable_seen = YES;
            table.insert_subtable(col_ndx, row_ndx);
            break;
        case type_Mixed:
            if (obj == nil) {
                table.insert_bool(col_ndx, row_ndx, false);
                break;
            }
            if ([obj isKindOfClass:[NSString class]]) {
                StringData sd([(NSString *)obj UTF8String]);
                table.insert_mixed(col_ndx, row_ndx, sd);
                break;
            }
            if ([obj isKindOfClass:[NSArray class]]) {
                table.insert_mixed(col_ndx, row_ndx, Mixed::subtable_tag());
                subtable_seen = true;
                break;
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                table.insert_mixed(col_ndx, row_ndx, DateTime(time_t([(NSDate *)obj timeIntervalSince1970])));
                break;
            }
            if ([obj isKindOfClass:[NSData class]]) {
                table.insert_mixed(col_ndx, row_ndx, ((NSData *)obj).tdbBinaryData);
                break;
            }
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char *data_type = [(NSNumber *)obj objCType];
                const char dt = data_type[0];
                switch (dt) {
                    case 'i':
                    case 's':
                    case 'l':
                        table.insert_mixed(col_ndx, row_ndx, (int64_t)[(NSNumber *)obj longValue]);
                        break;
                    case 'f':
                        table.insert_mixed(col_ndx, row_ndx, [(NSNumber *)obj floatValue]);
                        break;
                    case 'd':
                        table.insert_mixed(col_ndx, row_ndx, [(NSNumber *)obj doubleValue]);
                        break;
                    case 'B':
                    case 'c':
                        table.insert_mixed(col_ndx, row_ndx, [(NSNumber *)obj boolValue] == YES);
                        break;
                }
                break;
            }
            return NO;
    }
    return subtable_seen;
}


void insert_row(size_t row_ndx, tightdb::Table& table, NSArray * data)
{
    /*
       Assumption:
       - data has been validated by verify_row
    */

    NSEnumerator *enumerator = [data objectEnumerator];
    id obj;

    bool subtable_seen = false;
    /* FIXME: handling of tightdb exceptions => return NO */
    size_t col_ndx = 0;
    while (obj = [enumerator nextObject]) {
        subtable_seen = subtable_seen || insert_cell(col_ndx, row_ndx, table, obj);
        ++col_ndx;
    }
    table.insert_done();
    
    if (subtable_seen) {
        NSEnumerator *enumerator = [data objectEnumerator];
        size_t col_ndx = 0;
        id obj;
        while (obj = [enumerator nextObject]) {
            DataType datatype = table.get_column_type(col_ndx);
            if (datatype != type_Table && datatype != type_Mixed) {
                ++col_ndx;
                continue;
            }
            if (obj == nil) {
                ++col_ndx;
                continue;
            }
            
            TableRef subtable = table.get_subtable(col_ndx, row_ndx);
            NSEnumerator *subenumerator = [obj objectEnumerator];
            id subobj;
            size_t sub_ndx = 0;
            while (subobj = [subenumerator nextObject]) {
                if (datatype == type_Mixed && sub_ndx == 0) {
                    /* first element is the description */
                    ++sub_ndx;
                    continue;
                }
                
                /* Fill in data */
                insert_row(subtable->size(), *subtable, subobj);
                ++sub_ndx;
            }
        }
    }
}

void insert_row_with_labels(size_t row_ndx, Table& table, NSDictionary *data)
{
    bool subtables_seen = false;
    
    size_t count = table.get_column_count();
    for (size_t col_ndx = 0; col_ndx != count; ++col_ndx) {
        NSString *col_name = to_objc_string(table.get_column_name(col_ndx));
        
        // Do we have a matching label?
        // (missing values are ok, they will be filled out with default values)
        id value = [data valueForKey:col_name];
        subtables_seen = subtables_seen || insert_cell(col_ndx, row_ndx, table, value);
    }
    table.insert_done();
    
    if (subtables_seen) {
        for(size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
            DataType type = table.get_column_type(col_ndx);
            if (type != type_Table && type != type_Mixed) {
                continue;
            }
            NSString *col_name = to_objc_string(table.get_column_name(col_ndx));
            id value = [data valueForKey:col_name];
            if (value == nil) {
                continue;
            }
            
            TableRef subtable = table.get_subtable(col_ndx, row_ndx);
            
            /* fill in data */
            insert_row_with_labels(row_ndx, *subtable, (NSDictionary *)value);
        }
    }
}

BOOL set_cell(size_t col_ndx, size_t row_ndx, Table& table, NSObject *obj)
{
    DataType type = table.get_column_type(col_ndx);
    switch (type) {
        case type_Bool:
            if (obj == nil)
                table.set_bool(col_ndx, row_ndx, false);
            else
                table.set_bool(col_ndx, row_ndx, bool([(NSNumber *)obj boolValue]));
            break;
        case type_DateTime:
            if (obj == nil) {
                table.set_datetime(col_ndx, row_ndx, time_t(0));
            }
            else {
                if ([obj isKindOfClass:[NSDate class]]) {
                    table.set_datetime(col_ndx, row_ndx, time_t([(NSDate *)obj timeIntervalSince1970]));
                }
                else {
                    table.set_datetime(col_ndx, row_ndx, time_t([(NSNumber *)obj longValue]));
                }
            }
            break;
        case type_Int:
            if (obj == nil)
                table.set_int(col_ndx, row_ndx, 0);
            else
                table.set_int(col_ndx, row_ndx, int64_t([(NSNumber *)obj longValue]));
            break;
        case type_Float:
            if (obj == nil)
                table.set_float(col_ndx, row_ndx, 0.0);
            else
                table.set_float(col_ndx, row_ndx, float([(NSNumber *)obj floatValue]));
            break;
        case type_Double:
            if (obj == nil)
                table.set_double(col_ndx, row_ndx, 0.0);
            else
                table.set_double(col_ndx, row_ndx, double([(NSNumber *)obj doubleValue]));
            break;
        case type_String:
            if (obj == nil) {
                StringData sd("");
                table.set_string(col_ndx, row_ndx, sd);
            }
            else {
                StringData sd([(NSString *)obj UTF8String]);
                table.set_string(col_ndx, row_ndx, sd);
            }
            break;
        case type_Binary:
            if (obj == nil) {
                BinaryData bd("", 0);
                table.set_binary(col_ndx, row_ndx, bd);
            }
            else {
                const void *data = [(NSData *)obj bytes];
                BinaryData bd(static_cast<const char *>(data), [(NSData *)obj length]);
                table.set_binary(col_ndx, row_ndx, bd);
            }
            break;
        case type_Table: {
            table.clear_subtable(col_ndx, row_ndx);
            if ([obj isKindOfClass:[NSArray class]]) {
                table.clear_subtable(col_ndx, row_ndx);
                if ([(NSArray *)obj count] > 0) {
                    table.insert_subtable(col_ndx, row_ndx);
                    TableRef subtable = table.get_subtable(col_ndx, row_ndx);
                    NSEnumerator *enumerator = [(NSArray *)obj objectEnumerator];
                    id subobj;
                    while (subobj = [enumerator nextObject]) {
                        set_row(row_ndx, *subtable, (NSArray *)subobj);
                    }
                }
                break;
            }
            if ([obj isKindOfClass:[TDBTable class]]) {
                table.set_subtable(col_ndx, row_ndx, &[(TDBTable *)obj getNativeTable]);
                break;
            }
            NSException* exception = [NSException exceptionWithName:@"tightdb:cannot insert subtable"
                                                                reason:[NSString stringWithFormat:@"colName %@ with index: %lu is of type %u",
                                                                        to_objc_string(table.get_column_name(col_ndx)), col_ndx, table.get_column_type(col_ndx) ]
                                                                userInfo:[NSMutableDictionary dictionary]];
            [exception raise];
        }
        case type_Mixed:
            if (obj == nil) {
                table.set_bool(col_ndx, row_ndx, false);
                break;
            }
            if ([obj isKindOfClass:[NSString class]]) {
                StringData sd([(NSString *)obj UTF8String]);
                table.set_mixed(col_ndx, row_ndx, sd);
                break;
            }
            if ([obj isKindOfClass:[NSArray class]]) {
                // FIXME: implement
                // table.set_mixed(col_ndx, row_ndx, Mixed::subtable_tag());
                break;
            }
            if ([obj isKindOfClass:[TDBTable class]]) {
                table.set_subtable(col_ndx, row_ndx, &[(TDBTable *)obj getNativeTable]);
                break;
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                table.set_mixed(col_ndx, row_ndx, DateTime(time_t([(NSDate *)obj timeIntervalSince1970])));
                break;
            }
            if ([obj isKindOfClass:[NSData class]]) {
                table.set_mixed(col_ndx, row_ndx, ((NSData *)obj).tdbBinaryData);
                break;
            }
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char *data_type = [(NSNumber *)obj objCType];
                const char dt = data_type[0];
                switch (dt) {
                    case 'i':
                    case 's':
                    case 'l':
                        table.set_mixed(col_ndx, row_ndx, (int64_t)[(NSNumber *)obj longValue]);
                        break;
                    case 'f':
                        table.set_mixed(col_ndx, row_ndx, [(NSNumber *)obj floatValue]);
                        break;
                    case 'd':
                        table.set_mixed(col_ndx, row_ndx, [(NSNumber *)obj doubleValue]);
                        break;
                    case 'B':
                    case 'c':
                        table.set_mixed(col_ndx, row_ndx, [(NSNumber *)obj boolValue] == YES);
                        break;
                }
                break;
            }
            return NO;
    }
    return YES;
}


void set_row(size_t row_ndx, Table& table, NSArray *data)
{
    NSEnumerator *enumerator = [data objectEnumerator];
    id obj;

    size_t col_ndx = 0;
    while (obj = [enumerator nextObject]) {
        set_cell(col_ndx, row_ndx, table, obj);
        ++col_ndx;
    }
}

void set_row_with_labels(size_t row_ndx, Table& table, NSDictionary *data)
{
    size_t count = table.get_column_count();
    for (size_t col_ndx = 0; col_ndx != count; ++col_ndx) {
        NSString *col_name = to_objc_string(table.get_column_name(col_ndx));
        id value = [data valueForKey:col_name];
        set_cell(col_ndx, row_ndx, table, value);
    }
}