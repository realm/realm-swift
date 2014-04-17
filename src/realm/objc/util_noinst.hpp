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

#ifndef TIGHTDB_OBJC_UTIL_HPP
#define TIGHTDB_OBJC_UTIL_HPP

#include <cstddef>
#include <stdexcept>

#include <tightdb/util/safe_int_ops.hpp>
#include <tightdb/util/file.hpp>
#include <tightdb/string_data.hpp>
#include <tightdb/mixed.hpp>
#include <tightdb/descriptor.hpp>
#include <tightdb/table.hpp>
#include <tightdb/table_ref.hpp>

struct ObjcStringAccessor {
    ObjcStringAccessor(const NSString* s)
    {
        using namespace std;
        using namespace tightdb;
        NSUInteger size = [s length];
        if (size == 0) {
            m_data = 0;
            m_size = 0;
        }
        else {
            size_t max_size;
            if (util::int_cast_with_overflow_detect([s maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding], max_size))
                throw runtime_error("String size overflow");
            char* data = new char[max_size];
            NSUInteger used;
            NSRange range = NSMakeRange(0, size);
            NSRange remaining_range;
            BOOL at_leat_one = [s getBytes:data maxLength:max_size usedLength:&used encoding:NSUTF8StringEncoding options:0 range:range remainingRange:&remaining_range];
            if (!at_leat_one || remaining_range.length != 0) {
                delete[] data;
                throw runtime_error("String transcoding failed");
            }
            m_data = data;
            m_size = used;
        }
    }

    ~ObjcStringAccessor()
    {
        delete[] m_data;
    }

    operator tightdb::StringData() const TIGHTDB_NOEXCEPT { return tightdb::StringData(m_data, m_size); }

private:
    const char* m_data;
    std::size_t m_size;
};

inline NSString* to_objc_string(tightdb::StringData s)
{
    using namespace std;
    using namespace tightdb;
    const char* data = s.data();
    NSUInteger size;
    if (util::int_cast_with_overflow_detect(s.size(), size))
        throw runtime_error("String size overflow");
    return [[NSString alloc] initWithBytes:data length:size encoding:NSUTF8StringEncoding];
}

inline NSObject* to_objc_object(tightdb::Mixed m)
{
    switch (m.get_type()) {
        case tightdb::type_Bool:
            return [NSNumber numberWithBool:m.get_bool()];
        case tightdb::type_Int:
            return [NSNumber numberWithLongLong:m.get_int()];
        case tightdb::type_Float:
            return [NSNumber numberWithFloat:m.get_float()];
        case tightdb::type_Double:
            return [NSNumber numberWithDouble:m.get_double()];
        case tightdb::type_DateTime:
            return [NSDate dateWithTimeIntervalSince1970:m.get_datetime().get_datetime()];
        case tightdb::type_String:
            return to_objc_string(m.get_string());
        case tightdb::type_Binary: {
            tightdb::BinaryData bd = m.get_binary();
            return [NSData dataWithBytes:bd.data() length:bd.size()];
        }
        case tightdb::type_Mixed:
            TIGHTDB_ASSERT(false); /* we should never get here */
        case tightdb::type_Table:
            TIGHTDB_ASSERT(false);
    }
    return nil;
}


inline NSUInteger was_not_found(size_t n)
{
    if (n == tightdb::not_found)
        return (NSUInteger)NSNotFound;
    return (NSUInteger)n;
}

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

void to_mixed(id value, tightdb::Mixed& m);

BOOL set_cell(size_t col_ndx, size_t row_ndx, tightdb::Table& table, NSObject *obj);
BOOL verify_object_is_type(id obj, tightdb::DataType type);
BOOL verify_cell(const tightdb::Descriptor& descr, size_t col_ndx, NSObject *obj);
NSObject* get_cell(size_t col_ndx, size_t row_ndx, tightdb::Table& table);

void verify_row(const tightdb::Descriptor& descr, NSArray * data);
void insert_row(size_t ndx, tightdb::Table& table, NSArray * data);
void set_row(size_t ndx, tightdb::Table& table, NSArray *data);

void verify_row_with_labels(const tightdb::Descriptor& descr, NSDictionary* data);
void insert_row_with_labels(size_t row_ndx, tightdb::Table& table, NSDictionary *data);
void set_row_with_labels(size_t row_ndx, tightdb::Table& table, NSDictionary *data);

void verify_row_from_object(const tightdb::Descriptor& descr, NSObject* data);
void insert_row_from_object(size_t row_ndx, tightdb::Table& table, NSObject *data);
void set_row_from_object(size_t row_ndx, tightdb::Table& table, NSObject *data);


BOOL set_columns(tightdb::TableRef& parent, NSArray *schema);

// Still used in the new error strategy. Perhaps it should be public?
enum TightdbErr {
    tdb_err_Ok                    = 0,
    tdb_err_Fail                  = 1,
    tdb_err_FailRdOnly            = 2,
    tdb_err_File_AccessError      = 3,
    tdb_err_File_PermissionDenied = 4,
    tdb_err_File_Exists           = 5,
    tdb_err_File_NotFound         = 6,
    tdb_err_Rollback              = 7,
    tdb_err_InvalidDatabase       = 8,
    tdb_err_TableNotFound         = 9
};

inline NSError* make_realm_error(TightdbErr code, NSString* desc)
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:desc forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"com.tightdb" code:code userInfo:details];
}

#define REALM_OBJC_SIZE_T_NUMBER_IN numberWithUnsignedLong
#define REALM_OBJC_SIZE_T_NUMBER_OUT unsignedLongValue

#define REALM_EXCEPTION_ERRHANDLER(action, fail_return_value) \
REALM_EXCEPTION_ERRHANDLER_EX(action, fail_return_value, error)

// This is the old macro, which should be phased out.
#define REALM_EXCEPTION_ERRHANDLER_EX(action, fail_return_value, err_var) \
try { action } \
catch (tightdb::util::File::AccessError& ex) { \
    if (err_var) \
        *err_var = make_realm_error(tdb_err_File_AccessError, [NSString stringWithUTF8String:ex.what()]); \
        return fail_return_value; \
} \
catch (std::exception& ex) { \
    if (err_var) \
        *err_var = make_realm_error(tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]); \
        return fail_return_value; \
}

// This macro is part of the new error strategy, specifically for table value setters.
#define REALM_EXCEPTION_HANDLER_SETTERS(action, datatype) \
if (m_read_only) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:table_is_read_only" \
                                          reason:@"You tried to modify an immutable table" \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \
if (col_ndx >= self.columnCount) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:column_index_out_of_bounds" \
                                          reason:@"The specified column index is not within the table bounds" \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \
if ([self columnTypeOfColumnWithIndex:col_ndx] != datatype) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:illegal_type" \
                                          reason:@"The supplied type is not compatible with the column type" \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \
if (row_ndx >= self.rowCount) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:row_index_out_of_bounds" \
                                          reason:@"The specified row index is not within the table bounds" \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \
try { action } \
catch(std::exception& ex) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:core_exception" \
                                          reason:[NSString stringWithUTF8String:ex.what()] \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
}

#define REALM_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(columnIndex) \
if (columnIndex >= self.columnCount) { \
                        NSException* exception = [NSException exceptionWithName:@"tightdb:column_index_out_of_bounds" \
                                reason:@"The specified column index is not within the table bounds" \
                                userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \

#define REALM_EXCEPTION_HANDLER_CORE_EXCEPTION(action) \
try { action } \
catch(std::exception& ex) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:core_exception" \
                                          reason:[NSString stringWithUTF8String:ex.what()] \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
}


#endif // TIGHTDB_OBJC_UTIL_HPP
