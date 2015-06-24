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
#import <objc/runtime.h>

#import <realm/array.hpp>
#import <realm/binary_data.hpp>
#import <realm/string_data.hpp>

@class RLMObjectSchema;
@class RLMProperty;
@class RLMRealm;
@class RLMSchema;

NSException *RLMException(NSString *message, NSDictionary *userInfo = nil);
NSException *RLMException(std::exception const& exception);

NSError *RLMMakeError(RLMError code, std::exception const& exception);
NSError *RLMMakeError(NSException *exception);

void RLMSetErrorOrThrow(NSError *error, NSError **outError);

// returns if the object can be inserted as the given type
BOOL RLMIsObjectValidForProperty(id obj, RLMProperty *prop);

// gets default values for the given schema (+defaultPropertyValues)
// merges with native property defaults if Swift class
NSDictionary *RLMDefaultValuesForObjectSchema(RLMObjectSchema *objectSchema);

NSArray *RLMCollectionValueForKey(NSString *key, RLMRealm *realm, RLMObjectSchema *objectSchema, size_t count, size_t (^indexGenerator)(size_t index));

void RLMCollectionSetValueForKey(id value, NSString *key, RLMRealm *realm, RLMObjectSchema *objectSchema, size_t count, size_t (^indexGenerator)(size_t index));

BOOL RLMIsDebuggerAttached();

// C version of isKindOfClass
static inline BOOL RLMIsKindOfClass(Class class1, Class class2) {
    while (class1) {
        if (class1 == class2) return YES;
        class1 = class_getSuperclass(class1);
    }
    return NO;
}

// Returns whether the class is an indirect descendant of RLMObjectBase
BOOL RLMIsObjectSubclass(Class klass);

template<typename T>
static inline T *RLMDynamicCast(__unsafe_unretained id obj) {
    if ([obj isKindOfClass:[T class]]) {
        return obj;
    }
    return nil;
}

template<typename T>
static inline T *RLMNSNullToNil(T *obj) {
    if (obj == NSNull.null) {
        return nil;
    }
    return obj;
}

// Translate an rlmtype to a string representation
static inline NSString *RLMTypeToString(RLMPropertyType type) {
    switch (type) {
        case RLMPropertyTypeString:
            return @"string";
        case RLMPropertyTypeInt:
            return @"int";
        case RLMPropertyTypeBool:
            return @"bool";
        case RLMPropertyTypeDate:
            return @"date";
        case RLMPropertyTypeData:
            return @"data";
        case RLMPropertyTypeDouble:
            return @"double";
        case RLMPropertyTypeFloat:
            return @"float";
        case RLMPropertyTypeAny:
            return @"any";
        case RLMPropertyTypeObject:
            return @"object";
        case RLMPropertyTypeArray:
            return @"array";
    }
    return @"Unknown";
}

// String conversion utilities
static inline NSString * RLMStringDataToNSString(realm::StringData stringData) {
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

static inline realm::StringData RLMStringDataWithNSString(__unsafe_unretained NSString *const string) {
    static_assert(sizeof(size_t) >= sizeof(NSUInteger),
                  "Need runtime overflow check for NSUInteger to size_t conversion");
    return realm::StringData(string.UTF8String,
                               [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
}

// Binary convertion utilities
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

static inline NSUInteger RLMConvertNotFound(size_t index) {
    return index == realm::not_found ? NSNotFound : index;
}
