#ifndef TIGHTDB_OBJC_UTIL_HPP
#define TIGHTDB_OBJC_UTIL_HPP

#include <cstddef>
#include <stdexcept>

#include <tightdb/safe_int_ops.hpp>
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
            if (int_cast_with_overflow_detect([s maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding], max_size)) throw runtime_error("String size overflow");
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

enum TightDbErr {
    TDBErrOk = 0,
    TDBErrFail = 1
};

inline NSError *makeTightDbError(NSString *domain, TightDbErr code, NSString *desc)
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:desc forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:domain code:code userInfo:details];
}

inline NSString* to_objc_string(tightdb::StringData s)
{
    using namespace std;
    using namespace tightdb;
    const char* data = s.data();
    NSUInteger size;
    if (int_cast_with_overflow_detect(s.size(), size)) throw runtime_error("String size overflow");
    return [[NSString alloc] initWithBytes:data length:size encoding:NSUTF8StringEncoding];
}

#endif // TIGHTDB_OBJC_UTIL_HPP
