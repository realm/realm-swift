////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import <Realm/RLMConstants.h>
#import <Realm/RLMSwiftValueStorage.h>
#import <Realm/RLMValue.h>

#import <realm/array.hpp>
#import <realm/binary_data.hpp>
#import <realm/object-store/object.hpp>
#import <realm/string_data.hpp>
#import <realm/timestamp.hpp>
#import <realm/util/file.hpp>

#import <objc/runtime.h>
#import <os/lock.h>

namespace realm {
class Decimal128;
class Exception;
class Mixed;
}

class RLMClassInfo;

@class RLMObjectSchema;
@class RLMProperty;

__attribute__((format(NSString, 1, 2)))
NSException *RLMException(NSString *fmt, ...);
NSException *RLMException(std::exception const& exception);
NSException *RLMException(realm::Exception const& exception);

void RLMSetErrorOrThrow(NSError *error, NSError **outError);

RLM_HIDDEN_BEGIN

// returns if the object can be inserted as the given type
BOOL RLMIsObjectValidForProperty(id obj, RLMProperty *prop);
// throw an exception if the object is not a valid value for the property
void RLMValidateValueForProperty(id obj, RLMObjectSchema *objectSchema,
                                 RLMProperty *prop, bool validateObjects=false);
id RLMValidateValue(id value, RLMPropertyType type, bool optional, bool collection,
                    NSString *objectClassName);

void RLMThrowTypeError(id obj, RLMObjectSchema *objectSchema, RLMProperty *prop);

// gets default values for the given schema (+defaultPropertyValues)
// merges with native property defaults if Swift class
NSDictionary *RLMDefaultValuesForObjectSchema(RLMObjectSchema *objectSchema);

BOOL RLMIsDebuggerAttached();
BOOL RLMIsRunningInPlayground();

// C version of isKindOfClass
static inline BOOL RLMIsKindOfClass(Class class1, Class class2) {
    while (class1) {
        if (class1 == class2) return YES;
        class1 = class_getSuperclass(class1);
    }
    return NO;
}

template<typename T>
static inline T *RLMDynamicCast(__unsafe_unretained id obj) {
    if ([obj isKindOfClass:[T class]]) {
        return obj;
    }
    return nil;
}

static inline id RLMCoerceToNil(__unsafe_unretained id obj) {
    if (static_cast<id>(obj) == NSNull.null) {
        return nil;
    }
    else if (__unsafe_unretained auto optional = RLMDynamicCast<RLMSwiftValueStorage>(obj)) {
        return RLMCoerceToNil(RLMGetSwiftValueStorage(optional));
    }
    return obj;
}

template<typename T>
static inline T RLMCoerceToNil(__unsafe_unretained T obj) {
    return RLMCoerceToNil(static_cast<id>(obj));
}

id<NSFastEnumeration> RLMAsFastEnumeration(id obj);
id RLMBridgeSwiftValue(id obj);

bool RLMIsSwiftObjectClass(Class cls);

// String conversion utilities
static inline NSString *RLMStringDataToNSString(realm::StringData stringData) {
    static_assert(sizeof(NSUInteger) >= sizeof(size_t),
                  "Need runtime overflow check for size_t to NSUInteger conversion");
    if (stringData.is_null()) {
        return nil;
    }
    else {
        return [[NSString alloc] initWithBytes:stringData.data()
                                        length:stringData.size()
                                      encoding:NSUTF8StringEncoding];
    }
}

static inline NSString *RLMStringViewToNSString(std::string_view stringView) {
    if (stringView.size() == 0) {
        return nil;
    }
    return [[NSString alloc] initWithBytes:stringView.data()
                                    length:stringView.size()
                                  encoding:NSUTF8StringEncoding];
}

static inline realm::StringData RLMStringDataWithNSString(__unsafe_unretained NSString *const string) {
    static_assert(sizeof(size_t) >= sizeof(NSUInteger),
                  "Need runtime overflow check for NSUInteger to size_t conversion");
    return realm::StringData(string.UTF8String,
                             [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
}

// Binary conversion utilities
static inline NSData *RLMBinaryDataToNSData(realm::BinaryData binaryData) {
    return binaryData ? [NSData dataWithBytes:binaryData.data() length:binaryData.size()] : nil;
}

static inline realm::BinaryData RLMBinaryDataForNSData(__unsafe_unretained NSData *const data) {
    // this is necessary to ensure that the empty NSData isn't treated by core as the null realm::BinaryData
    // because data.bytes == 0 when data.length == 0
    // the casting bit ensures that we create a data with a non-null pointer
    auto bytes = static_cast<const char *>(data.bytes) ?: static_cast<char *>((__bridge void *)data);
    return realm::BinaryData(bytes, data.length);
}

// Date conversion utilities
// These use the reference date and shift the seconds rather than just getting
// the time interval since the epoch directly to avoid losing sub-second precision
static inline NSDate *RLMTimestampToNSDate(realm::Timestamp ts) NS_RETURNS_RETAINED {
    if (ts.is_null())
        return nil;
    auto timeInterval = ts.get_seconds() - NSTimeIntervalSince1970 + ts.get_nanoseconds() / 1'000'000'000.0;
    return [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:timeInterval];
}

static inline realm::Timestamp RLMTimestampForNSDate(__unsafe_unretained NSDate *const date) {
    if (!date)
        return {};
    auto timeInterval = date.timeIntervalSinceReferenceDate;
    if (isnan(timeInterval))
        return {0, 0}; // Arbitrary choice

    // Clamp dates that we can't represent as a Timestamp to the maximum value
    if (timeInterval >= std::numeric_limits<int64_t>::max() - NSTimeIntervalSince1970)
        return {std::numeric_limits<int64_t>::max(), 1'000'000'000 - 1};
    if (timeInterval - NSTimeIntervalSince1970 < std::numeric_limits<int64_t>::min())
        return {std::numeric_limits<int64_t>::min(), -1'000'000'000 + 1};

    auto seconds = static_cast<int64_t>(timeInterval);
    auto nanoseconds = static_cast<int32_t>((timeInterval - seconds) * 1'000'000'000.0);
    seconds += static_cast<int64_t>(NSTimeIntervalSince1970);

    // Seconds and nanoseconds have to have the same sign
    if (nanoseconds < 0 && seconds > 0) {
        nanoseconds += 1'000'000'000;
        --seconds;
    }
    return {seconds, nanoseconds};
}

static inline NSUInteger RLMConvertNotFound(size_t index) {
    return index == realm::not_found ? NSNotFound : index;
}

static inline void RLMNSStringToStdString(std::string &out, NSString *in) {
    if (!in)
        return;
    
    out.resize([in maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    if (out.empty()) {
        return;
    }

    NSUInteger size = out.size();
    [in getBytes:&out[0]
       maxLength:size
      usedLength:&size
        encoding:NSUTF8StringEncoding
         options:0 range:{0, in.length} remainingRange:nullptr];
    out.resize(size);
}
realm::Mixed RLMObjcToMixed(__unsafe_unretained id const value,
                            __unsafe_unretained RLMRealm *const realm=nil,
                            realm::CreatePolicy createPolicy={});
realm::Mixed RLMObjcToMixedPrimitives(__unsafe_unretained id const value,
                                      __unsafe_unretained RLMRealm *const realm,
                                      realm::CreatePolicy createPolicy);
id RLMMixedToObjc(realm::Mixed const& value,
                  __unsafe_unretained RLMRealm *realm=nil,
                  RLMClassInfo *classInfo=nullptr,
                  RLMProperty *property=nullptr,
                  realm::Obj obj={});

realm::Decimal128 RLMObjcToDecimal128(id value);
realm::UUID RLMObjcToUUID(__unsafe_unretained id const value);

// Given a bundle identifier, return the base directory on the disk within which Realm database and support files should
// be stored.
FOUNDATION_EXTERN RLM_VISIBLE
NSString *RLMDefaultDirectoryForBundleIdentifier(NSString *bundleIdentifier);

// Get a NSDateFormatter for ISO8601-formatted strings
NSDateFormatter *RLMISO8601Formatter();

template<typename Fn>
static auto RLMTranslateError(Fn&& fn) {
    try {
        return fn();
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

static inline bool numberIsInteger(__unsafe_unretained NSNumber *const obj) {
    char data_type = [obj objCType][0];
    return data_type == *@encode(bool) ||
           data_type == *@encode(char) ||
           data_type == *@encode(short) ||
           data_type == *@encode(int) ||
           data_type == *@encode(long) ||
           data_type == *@encode(long long) ||
           data_type == *@encode(unsigned short) ||
           data_type == *@encode(unsigned int) ||
           data_type == *@encode(unsigned long) ||
           data_type == *@encode(unsigned long long);
}

static inline bool numberIsBool(__unsafe_unretained NSNumber *const obj) {
    // @encode(BOOL) is 'B' on iOS 64 and 'c'
    // objcType is always 'c'. Therefore compare to "c".
    if ([obj objCType][0] == 'c') {
        return true;
    }

    if (numberIsInteger(obj)) {
        int value = [obj intValue];
        return value == 0 || value == 1;
    }

    return false;
}

static inline bool numberIsFloat(__unsafe_unretained NSNumber *const obj) {
    char data_type = [obj objCType][0];
    return data_type == *@encode(float) ||
           data_type == *@encode(short) ||
           data_type == *@encode(int) ||
           data_type == *@encode(long) ||
           data_type == *@encode(long long) ||
           data_type == *@encode(unsigned short) ||
           data_type == *@encode(unsigned int) ||
           data_type == *@encode(unsigned long) ||
           data_type == *@encode(unsigned long long) ||
           // A double is like float if it fits within float bounds or is NaN.
           (data_type == *@encode(double) && (ABS([obj doubleValue]) <= FLT_MAX || isnan([obj doubleValue])));
}

static inline bool numberIsDouble(__unsafe_unretained NSNumber *const obj) {
    char data_type = [obj objCType][0];
    return data_type == *@encode(double) ||
           data_type == *@encode(float) ||
           data_type == *@encode(short) ||
           data_type == *@encode(int) ||
           data_type == *@encode(long) ||
           data_type == *@encode(long long) ||
           data_type == *@encode(unsigned short) ||
           data_type == *@encode(unsigned int) ||
           data_type == *@encode(unsigned long) ||
           data_type == *@encode(unsigned long long);
}

class RLMUnfairMutex {
public:
    RLMUnfairMutex() = default;

    void lock() noexcept {
        os_unfair_lock_lock(&_lock);
    }

    bool try_lock() noexcept {
        return os_unfair_lock_trylock(&_lock);
    }

    void unlock() noexcept {
        os_unfair_lock_unlock(&_lock);
    }

private:
    os_unfair_lock _lock = OS_UNFAIR_LOCK_INIT;
    RLMUnfairMutex(RLMUnfairMutex const&) = delete;
    RLMUnfairMutex& operator=(RLMUnfairMutex const&) = delete;
};

RLM_HIDDEN_END
