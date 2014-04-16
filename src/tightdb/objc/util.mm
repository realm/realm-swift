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

#include <vector>

#include <tightdb/descriptor.hpp>
#include <tightdb/binary_data.hpp>
#include <tightdb/string_data.hpp>

#import "TDBTable_noinst.h"
#import "util_noinst.hpp"
#import "NSData+RLMGetBinaryData.h"

using namespace tightdb;


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
        m.set_binary([(NSData *) value rlmBinaryData]);
        return;
    }
    if ([value isKindOfClass:[NSDate class]]) {
        m.set_datetime(DateTime(time_t([(NSDate *)value timeIntervalSince1970])));
        return;
    }
    if ([value isKindOfClass:[TDBTable class]])
        m = Mixed(Mixed::subtable_tag());
}


NSObject* get_cell(size_t col_ndx, size_t row_ndx, Table& table)
{
    DataType type = table.get_column_type(col_ndx);
    switch (type) {
        case type_String: {
            NSString *s = [NSString stringWithUTF8String:table.get_string(col_ndx, row_ndx).data()];
            return s;
        }
        case type_Int: {
            NSNumber *n = [NSNumber numberWithLongLong:table.get_int(col_ndx, row_ndx)];
            return n;
        }
        case type_Float: {
            NSNumber *n = [NSNumber numberWithFloat:table.get_float(col_ndx, row_ndx)];
            return n;
        }
        case type_Double: {
            NSNumber *n = [NSNumber numberWithDouble:table.get_double(col_ndx, row_ndx)];
            return n;
        }
        case type_Bool: {
            NSNumber *n = [NSNumber numberWithBool:table.get_bool(col_ndx, row_ndx)];
            return n;
        }
        case type_Binary: {
            BinaryData bd = table.get_binary(col_ndx, row_ndx);
            NSData *d = [NSData dataWithBytes:bd.data() length:bd.size()];
            return d;
        }
        case type_Table: {
            TDBTable *t = [[TDBTable alloc] init];
            TableRef table_ref = table.get_subtable(col_ndx, row_ndx);
            [t setNativeTable:table_ref.get()];
            return t;
        }
        case type_DateTime: {
            NSDate *d = [NSDate dateWithTimeIntervalSince1970:table.get_datetime(col_ndx, row_ndx).get_datetime()];
            return d;
        }
        case type_Mixed: {
            Mixed m = table.get_mixed(col_ndx, row_ndx);
            switch (m.get_type()) {
                case type_String: {
                    NSString *s = [NSString stringWithUTF8String:m.get_string().data()];
                    return s;
                }
                case type_Int: {
                    NSNumber *n = [NSNumber numberWithLongLong:m.get_int()];
                    return n;
                }
                case type_Float: {
                    NSNumber *n = [NSNumber numberWithFloat:m.get_float()];
                    return n;
                }
                case type_Double: {
                    NSNumber *n = [NSNumber numberWithDouble:m.get_double()];
                    return n;
                }
                case type_Bool: {
                    NSNumber *n = [NSNumber numberWithBool:m.get_bool()];
                    return n;
                }
                case type_Binary: {
                    BinaryData bd = m.get_binary();
                    NSData *d = [NSData dataWithBytes:bd.data() length:bd.size()];
                    return d;
                }
                case type_Table: {
                    TDBTable *t = [[TDBTable alloc] init];
                    TableRef table_ref = table.get_subtable(col_ndx, row_ndx);
                    [t setNativeTable:table_ref.get()];
                    return t;
                }
                case type_DateTime: {
                    NSDate *d = [NSDate dateWithTimeIntervalSince1970:m.get_datetime().get_datetime()];
                    return d;
                }
                case type_Mixed:
                    TIGHTDB_ASSERT(false);
            }
        }
    }
    TIGHTDB_ASSERT(false);
    return nil; // make clang happy
}


BOOL verify_object_is_type(id obj, DataType type) {
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
        default:
            TIGHTDB_ASSERT(false);
    }
    return YES;
}


BOOL verify_cell(const Descriptor& descr, size_t col_ndx, NSObject *obj)
{
    DataType type = descr.get_column_type(col_ndx);
    StringData name = descr.get_column_name(col_ndx);
    switch (type) {
        case type_Mixed:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_bool((NSNumber *)obj))
                    break;
                if (nsnumber_is_like_integer((NSNumber *)obj))
                    break;
                if (nsnumber_is_like_float((NSNumber *)obj))
                    break;
                if (nsnumber_is_like_double((NSNumber *)obj))
                    break;
                return NO;
            }
            if ([obj isKindOfClass:[NSString class]]) {
                break;
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                break;
            }
            if ([obj isKindOfClass:[NSData class]]) {
                break;
            }
            if ([obj isKindOfClass:[TDBTable class]]) { // subtables are inserted as TDBTable
                break;
            }
            return NO;
        case type_Table:
            if ([obj isKindOfClass:[NSArray class]]) {
                if ([(NSArray *)obj count] == 0)
                    break; // empty subtable
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
        default:
            return verify_object_is_type(obj, type);
    }
    return YES;
}


void verify_row(const Descriptor& descr, NSArray* data)
{
    if (descr.get_column_count() != [data count]) {
        @throw [NSException exceptionWithName:@"tightdb:wrong_column_count"
                                       reason:@"Number of columns do not match"
                                     userInfo:nil];
    }

    NSEnumerator *enumerator = [data objectEnumerator];
    id obj;

    size_t col_ndx = 0;
    while (obj = [enumerator nextObject]) {
        if (!verify_cell(descr, col_ndx, obj)) {
            @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                           reason:[NSString stringWithFormat: @"colName %@ with index: %lu is of type %u",
                                                            to_objc_string(descr.get_column_name(col_ndx)), col_ndx,
                                                                           descr.get_column_type(col_ndx) ]
                                         userInfo:nil];
        }
        ++col_ndx;
    }
}

void verify_row_with_labels(const Descriptor& descr, NSDictionary* data)
{
    size_t n = descr.get_column_count();
    for (size_t i = 0; i < n; ++i) {
        NSString *col_name = to_objc_string(descr.get_column_name(i));
        id value = [data valueForKey:col_name];
        if (value == nil)
            continue;
        if (!verify_cell(descr, i, value)) {
            @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                           reason:[NSString stringWithFormat:@"colName %@ with index: %lu is of type %u",
                                                   to_objc_string(descr.get_column_name(i)), i, descr.get_column_type(i) ]
                                         userInfo:nil];
        }
    }
}

void verify_row_from_object(const Descriptor& descr, NSObject* data)
{
    size_t count = descr.get_column_count();
    for (size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
        NSString *col_name = to_objc_string(descr.get_column_name(col_ndx));
        id value;
        @try {
            value = [data valueForKey:col_name];
        }
        @catch (NSException *exception) {
            continue;
        }
        if (!verify_cell(descr, col_ndx, value)) {
            @throw [NSException exceptionWithName: @"tightdb:wrong_column_type"
                                           reason: [NSString stringWithFormat:@"colName %@ with index: %lu is of type %u",
                                                    to_objc_string(descr.get_column_name(col_ndx)), col_ndx,
                                                                   descr.get_column_type(col_ndx) ]
                                         userInfo: nil];
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
                table.insert_binary(col_ndx, row_ndx, ((NSData *)obj).rlmBinaryData);
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
                table.insert_mixed(col_ndx, row_ndx, ((NSData *)obj).rlmBinaryData);
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
    NSEnumerator *enumerator = [data objectEnumerator];
    id obj;

    bool subtable_seen = false;
    // FIXME: handling of tightdb exceptions => return NO
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
                    // first element is the description
                    ++sub_ndx;
                    continue;
                }

                // Fill in data
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
    for (size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
        NSString *col_name = to_objc_string(table.get_column_name(col_ndx));

        // Do we have a matching label?
        // (missing values are ok, they will be filled out with default values)
        id value = [data valueForKey:col_name];
        subtables_seen = subtables_seen || insert_cell(col_ndx, row_ndx, table, value);
    }
    table.insert_done();

    if (subtables_seen) {
        for (size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
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

void insert_row_from_object(size_t row_ndx, Table& table, NSObject *data) {
    bool subtables_seen = false;

    size_t count = table.get_column_count();
    for (size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
        NSString *col_name = to_objc_string(table.get_column_name(col_ndx));
        id value;
        @try {
            value = [data valueForKey:col_name];
        }
        @catch (NSException *exception) {
            continue;
        }
        subtables_seen = subtables_seen || insert_cell(col_ndx, row_ndx, table, value);
    }
    table.insert_done();

    if (subtables_seen) {
        for (size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
            DataType type = table.get_column_type(col_ndx);
            if (type != type_Table && type != type_Mixed) {
                continue;
            }
            NSString *col_name = to_objc_string(table.get_column_name(col_ndx));
            id value;
            @try {
                value = [data valueForKey:col_name];
            }
            @catch (NSException *exception) {
                continue;
            }
            TableRef subtable = table.get_subtable(col_ndx, row_ndx);
            insert_row_from_object(row_ndx, *subtable, value);
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
            @throw [NSException exceptionWithName:@"tightdb:cannot insert subtable"
                                           reason:[NSString stringWithFormat:@"colName %@ with index: %lu is of type %u",
                                                            to_objc_string(table.get_column_name(col_ndx)), col_ndx,
                                                                           table.get_column_type(col_ndx) ]
                                         userInfo:nil];
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
            if ([obj isKindOfClass:[TDBTable class]]) {
                table.set_subtable(col_ndx, row_ndx, &[(TDBTable *)obj getNativeTable]);
                break;
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                table.set_mixed(col_ndx, row_ndx, DateTime(time_t([(NSDate *)obj timeIntervalSince1970])));
                break;
            }
            if ([obj isKindOfClass:[NSData class]]) {
                table.set_mixed(col_ndx, row_ndx, ((NSData *)obj).rlmBinaryData);
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
    for (size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
        NSString *col_name = to_objc_string(table.get_column_name(col_ndx));
        id value = [data valueForKey:col_name];
        set_cell(col_ndx, row_ndx, table, value);
    }
}

void set_row_from_object(size_t row_ndx, Table& table, NSObject *data) {
    size_t count = table.get_column_count();
    for (size_t col_ndx = 0; col_ndx < count; ++col_ndx) {
        NSString *col_name = to_objc_string(table.get_column_name(col_ndx));
        id value;
        @try {
            value = [data valueForKey:col_name];
        }
        @catch (NSException *) {
            continue;
        }
        set_cell(col_ndx, row_ndx, table, value);
    }
}

BOOL set_columns_aux(TableRef& parent, std::vector<size_t> path, NSArray *schema)
{
    size_t list_count = [schema count];
    if (list_count % 2 != 0) {
        //Error: "Invalid number of entries in schema"
        return NO;
    }

    for (size_t i = 0; i < list_count; i += 2) {
        NSString *key   = [schema objectAtIndex: i];
        id        value = [schema objectAtIndex: i+1];

        if (![key isKindOfClass:[NSString class]]) {
            // Error: "Column name must be a string"
            return NO;
        }

        try {
            DataType type;
            BOOL need_index = false;
            if ([value isKindOfClass:[NSString class]]) {
                if ([value isEqualToString:@"string"]) {
                    type = type_String;
                }
                else if ([value isEqualToString:@"string:indexed"]) {
                    type = type_String;
                    need_index = YES;
                }
                else if ([value isEqualToString:@"binary"]) {
                    type = type_Binary;
                }
                else if ([value isEqualToString:@"int"]) {
                    type = type_Int;
                }
                else if ([value isEqualToString:@"float"]) {
                    type = type_Float;
                }
                else if ([value isEqualToString:@"double"]) {
                    type = type_Double;
                }
                else if ([value isEqualToString:@"bool"]) {
                    type = type_Bool;
                }
                else if ([value isEqualToString:@"date"]) {
                    type = type_DateTime;
                }
                else if ([value isEqualToString:@"mixed"]) {
                    type = type_Mixed;
                }
                else {
                    // Error: "Invalid column type. Can be \"bool\", \"int\", \"date\", \"string\", \"binary\" or \"mixed\"."
                    return NO;
                }
            }
            else if ([value isKindOfClass:[NSArray class]]) {
                type = type_Table;
            }
            else {
                // Error:  "Invalid column type. Can be \"bool\", \"int\", \"date\", \"string\", \"binary\", \"mixed\" or \"[]\"."
                return NO;
            }

            size_t column_ndx;
            StringData column_name([(NSString *)key UTF8String]);
            if (path.size() > 0) {
                column_ndx = (*parent).add_subcolumn(path, type, column_name);
            }
            else {
                column_ndx = (*parent).add_column(type, column_name);
            }

            if (need_index) {
                (*parent).set_index(column_ndx);
            }

            if (type == type_Table) {
                path.push_back(column_ndx);
                if (!set_columns_aux(parent, path, value)) {
                    return false;
                }
                path.pop_back();
            }
        }
        catch (...) {
            // Error: "Exception during schema creation"
            return NO;
        }
    }
    return YES;
}

BOOL set_columns(TableRef& parent, NSArray *schema)
{
    std::vector<size_t> v;
    return set_columns_aux(parent, v, schema);
}
