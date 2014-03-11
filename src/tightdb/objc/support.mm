#import <Foundation/Foundation.h>

#include <tightdb/descriptor.hpp>

#import "table.h"

using namespace tightdb;

BOOL verify_row(const Descriptor& descr, NSArray * data)
{
    if (descr.get_column_count() != [data count]) {
        return NO;
    }

    NSEnumerator *enumerator = [data objectEnumerator];
    id obj;

    /* type encodings: http://nshipster.com/type-encodings/ */
    size_t col_ndx = 0;
    while (obj = [enumerator nextObject]) {
        DataType type = descr.get_column_type(col_ndx);
        switch (type) {
        case type_String:
            if (![obj isKindOfClass:[NSString class]])
                return NO;
            break;
        case type_Bool:
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char * data_type = [obj objCType];
                const char dt = data_type[0];
                if (dt == 'B' || dt == 'c')
                    break;
                return NO;
            }
            break;
        case type_DateTime:
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char * data_type = [obj objCType];
                const char dt = data_type[0];
                /* time_t is an integer */
                if (dt == 'i' || dt == 's' || dt == 'l' || dt == 'q' ||
                    dt == 'I' || dt == 'S' || dt == 'L' || dt == 'Q')
                    break;
                else {
                    return NO;
                }
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                break;
            }
            return NO;
        case type_Int:
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char * data_type = [obj objCType];
                const char dt = data_type[0];
                /* FIXME: what about: 'c', 'C'  */
                if (dt == 'i' || dt == 's' || dt == 'l' || dt == 'q' ||
                    dt == 'I' || dt == 'S' || dt == 'L' || dt == 'Q')
                    break;
                else
                    return NO;
            }
            else {
                return NO;
            }
            break;
        case type_Float:
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char * data_type = [obj objCType];
                const char dt = data_type[0];
                /* FIXME: what about: 'c', 'C'  */
                if (dt == 'i' || dt == 's' || dt == 'l' || dt == 'q' ||
                    dt == 'I' || dt == 'S' || dt == 'L' || dt == 'Q' ||
                    dt == 'f')
                    break;
                else
                    return NO;
            }
            else
                return NO;
            break; /* FIXME: remove */
        case type_Double:
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char * data_type = [obj objCType];
                const char dt = data_type[0];
                /* FIXME: what about: 'c', 'C'  */
                if (dt == 'i' || dt == 's' || dt == 'l' || dt == 'q' ||
                    dt == 'I' || dt == 'S' || dt == 'L' || dt == 'Q' ||
                    dt == 'f' || dt == 'd')
                    break;
                else
                    return NO;
            }
            else
                return NO;
            break; /* FIXME: remove */
        case type_Binary:
            if ([obj isKindOfClass:[TightdbBinary class]] || 
                [obj isKindOfClass:[NSData class]])
                break;
            return NO;
        case type_Mixed:
            break; /* everything goes */
        case type_Table:
            if ([obj isKindOfClass:[NSArray class]]) {
                if ([obj count] == 0)
                    break; /* empty subtable */
                id subobj;
                ConstDescriptorRef subdescr = descr.get_subdescriptor(col_ndx);
                NSEnumerator *subenumerator = [obj objectEnumerator];
                while (subobj = [subenumerator nextObject]) {
                    if (![subobj isKindOfClass:[NSArray class]])
                        return NO;
                    if (!verify_row(*subdescr, (NSArray *)subobj))
                        return NO;
                }
            }
            else {
                return NO;
            }
            break;
           
        }
        ++col_ndx;
    }
    return YES;
}

BOOL insert_row(size_t row_ndx, tightdb::Table& table, NSArray * data)
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
        DataType type = table.get_column_type(col_ndx);
        switch (type) {
        case type_Bool:
            table.insert_bool(col_ndx, row_ndx, bool([obj boolValue]));
            break;
        case type_DateTime:
            if ([obj isKindOfClass:[NSDate class]]) {
                table.insert_datetime(col_ndx, row_ndx, time_t([obj timeIntervalSince1970]));
            }
            else {
                table.insert_datetime(col_ndx, row_ndx, time_t([obj longValue]));
            }
            break;
        case type_Int:
            table.insert_int(col_ndx, row_ndx, int64_t([obj longValue]));
            break;
        case type_Float:
            table.insert_float(col_ndx, row_ndx, float([obj floatValue]));
            break;
        case type_Double:
            table.insert_double(col_ndx, row_ndx, double([obj doubleValue]));
            break;
        case type_String: 
            {
                StringData sd([obj UTF8String]);
                table.insert_string(col_ndx, row_ndx, sd);
            }
            break;
        case type_Binary:
            if ([obj isKindOfClass:[TightdbBinary class]]) {
                BinaryData bd([obj getData], [obj getSize]);
                table.insert_binary(col_ndx, row_ndx, bd);
            }
            else { /* NSData */
                const void *data = [obj bytes];
                BinaryData bd(static_cast<const char *>(data), [obj length]);
                table.insert_binary(col_ndx, row_ndx, bd);
            }
            break;
        case type_Table:
            subtable_seen = true;
            table.insert_subtable(col_ndx, row_ndx);
            break;
        case type_Mixed:
            if ([obj isKindOfClass:[NSString class]]) {
                StringData sd([obj UTF8String]);
                table.insert_mixed(col_ndx, row_ndx, sd);
                break;
            }
            if ([obj isKindOfClass:[NSArray class]]) {
                table.insert_mixed(col_ndx, row_ndx, Mixed::subtable_tag());
                subtable_seen = true;
                break;
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                table.insert_mixed(col_ndx, row_ndx, DateTime(time_t([obj timeIntervalSince1970])));
                break;
            }
            if ([obj isKindOfClass:[TightdbBinary class]]) {
                BinaryData bd([obj getData], [obj getSize]);
                table.insert_mixed(col_ndx, row_ndx, bd);
                break;
            }
            if ([obj isKindOfClass:[NSNumber class]]) {
                const char *data_type = [obj objCType];
                const char dt = data_type[0];
                switch (dt) {
                case 'i':
                case 's':
                case 'l':
                    table.insert_mixed(col_ndx, row_ndx, (int64_t)[obj longValue]);
                    break;
                case 'f':
                    table.insert_mixed(col_ndx, row_ndx, [obj floatValue]);
                    break;
                case 'd':
                    table.insert_mixed(col_ndx, row_ndx, [obj doubleValue]);
                    break;
                case 'B':
                case 'c':
                    table.insert_mixed(col_ndx, row_ndx, [obj boolValue] == YES);
                    break;
                }
                break;
            }
            return NO;
        }
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
                if (!insert_row(subtable->size(), *subtable, subobj)) {
                    return NO;
                }
                ++sub_ndx;
            }
        }
    }
    
    return YES;
}
