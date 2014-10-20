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

#import "RLMConstants.h"
#import "RLMSchema.h"
#import <objc/runtime.h>

#import <tightdb/table.hpp>
#import <tightdb/row.hpp>
#import <tightdb/string_data.hpp>
#import <tightdb/util/safe_int_ops.hpp>

@class RLMProperty;

// returns if the object can be inserted as the given type
BOOL RLMIsObjectValidForProperty(id obj, RLMProperty *prop);

// returns a validated object for an input object
// creates new objects for child objects and array literals as necessary
// throws if passed in literals are not compatible with prop
id RLMValidatedObjectForProperty(id obj, RLMProperty *prop, RLMSchema *schema);

// throws if the values in array are not valid for the given schema
// returns array with allocated child objects
NSArray *RLMValidatedArrayForObjectSchema(NSArray *array, RLMObjectSchema *objectSchema, RLMSchema *schema);

// throws if the values in dict or properties in a kvc object are not valid for the given schema
// inserts default values for missing properties when allowMissing is false
// throws for missing properties when allowMissing is false
// returns dictionary with default values and allocates child objects when applicable
NSDictionary *RLMValidatedDictionaryForObjectSchema(id value, RLMObjectSchema *objectSchema, RLMSchema *schema, bool allowMissing = false);

// C version of isKindOfClass
static inline BOOL RLMIsKindOfclass(Class class1, Class class2) {
    while (class1) {
        if (class1 == class2) return YES;
        class1 = class_getSuperclass(class1);
    }
    return NO;
}

// Determines if class1 descends from class2
static inline BOOL RLMIsSubclass(Class class1, Class class2) {
    class1 = class_getSuperclass(class1);
    return RLMIsKindOfclass(class1, class2);
}

template<typename T>
static inline T *RLMDynamicCast(__unsafe_unretained id obj) {
    if ([obj isKindOfClass:[T class]]) {
        return obj;
    }
    return nil;
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
static inline NSString * RLMStringDataToNSString(tightdb::StringData stringData) {
    static_assert(sizeof(NSUInteger) >= sizeof(size_t),
                  "Need runtime overflow check for size_t to NSUInteger conversion");
    return [[NSString alloc] initWithBytes:stringData.data()
                                    length:stringData.size()
                                  encoding:NSUTF8StringEncoding];
}

static inline tightdb::StringData RLMStringDataWithNSString(NSString *string) {
    static_assert(sizeof(size_t) >= sizeof(NSUInteger),
                  "Need runtime overflow check for NSUInteger to size_t conversion");
    return tightdb::StringData(string.UTF8String,
                               [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
}

// Binary convertion utilities
static inline tightdb::BinaryData RLMBinaryDataForNSData(NSData *data) {
    return tightdb::BinaryData(static_cast<const char *>(data.bytes), data.length);
}
