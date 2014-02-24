#ifndef TIGHTDB_OBJC_UTIL_HPP
#define TIGHTDB_OBJC_UTIL_HPP

#include <cstddef>
#include <stdexcept>

#include <tightdb/util/safe_int_ops.hpp>
#include <tightdb/string_data.hpp>

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

inline NSError* make_tightdb_error(TightdbErr code, NSString* desc)
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:desc forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"com.tightdb" code:code userInfo:details];
}

#define TIGHTDB_OBJC_SIZE_T_NUMBER_IN numberWithUnsignedLong
#define TIGHTDB_OBJC_SIZE_T_NUMBER_OUT unsignedLongValue

#define TIGHTDB_EXCEPTION_ERRHANDLER(action, fail_return_value) \
TIGHTDB_EXCEPTION_ERRHANDLER_EX(action, fail_return_value, error)

// This is the old macro, which should be phased out.
#define TIGHTDB_EXCEPTION_ERRHANDLER_EX(action, fail_return_value, err_var) \
try { action } \
catch (tightdb::util::File::AccessError& ex) { \
    if (err_var) \
        *err_var = make_tightdb_error(tdb_err_File_AccessError, [NSString stringWithUTF8String:ex.what()]); \
        return fail_return_value; \
} \
catch (std::exception& ex) { \
    if (err_var) \
        *err_var = make_tightdb_error(tdb_err_Fail, [NSString stringWithUTF8String:ex.what()]); \
        return fail_return_value; \
}

// This macro is part of the new error strategy, specifically for table value setters.
#define TIGHTDB_EXCEPTION_HANDLER_SETTERS(action, datatype) \
if (_readOnly) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:table_is_read_only" \
                                          reason:@"You tried to modify an immutable table" \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \
if (col_ndx >= [self getColumnCount]) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:column_index_out_of_bounds" \
                                          reason:@"The specified column index is not within the table bounds" \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \
if ([self getColumnType:col_ndx] != datatype) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:illegal_type" \
                                          reason:@"The supplied type is not compatible with the column type" \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
} \
if (row_ndx >= [self count]) { \
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

#define TIGHTDB_EXCEPTION_HANDLER_CORE_EXCEPTION(action) \
try { action } \
catch(std::exception& ex) { \
    NSException* exception = [NSException exceptionWithName:@"tightdb:core_exception" \
                                          reason:[NSString stringWithUTF8String:ex.what()] \
                                          userInfo:[NSMutableDictionary dictionary]]; \
    [exception raise]; \
}

#endif // TIGHTDB_OBJC_UTIL_HPP
