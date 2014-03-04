#import <Foundation/Foundation.h>

#include <tightdb/descriptor.hpp>

using namespace tightdb;

BOOL verify_row(const Descriptor& descr, NSArray * data)
{
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
                if (dt != 'B')
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
            else {
                return NO;
            }
            break;
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
        case type_Mixed:
            break; /* everything goes */
        /* FIXME: type_Binary, type_Date, type_Table */
           
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

    /* FIXME: handling of tightdb exceptions => return NO */
    size_t col_ndx = 0;
    while (obj = [enumerator nextObject]) {
        DataType type = table.get_column_type(col_ndx);
        switch (type) {
        case type_Bool:
            table.insert_bool(col_ndx, row_ndx, bool([obj boolValue]));
            break;
        case type_DateTime:
            table.insert_datetime(col_ndx, row_ndx, time_t([obj longValue]));
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
        }
        ++col_ndx;
    }
    table.insert_done();

    /* FIXME: subtables */

    return YES;
}
