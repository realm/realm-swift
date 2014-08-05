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

// throws if the values in dict are not valid for the given schema
// inserts default values for missing properties
// returns dictionary with default values and allocates child objects when applicable
NSDictionary *RLMValidatedDictionaryForObjectSchema(NSDictionary *dict, RLMObjectSchema *objectSchema, RLMSchema *schema);

// C version of isKindOfClass
inline BOOL RLMIsKindOfClass(Class cls, const char *name) {
    while (cls) {
        if (strcmp(class_getName(cls), name) == 0) return YES;
        cls = class_getSuperclass(cls);
    }
    return NO;
}

inline BOOL RLMIsObjectClass(Class cls) {
    return strcmp(class_getName(cls), "RLMObject") == 0;
}

// Determines if a class is a subclass of a class named RLMObject
inline BOOL RLMIsObjectSubclass(Class cls) {
    return RLMIsObjectClass(class_getSuperclass(cls));
}

// Translate an rlmtype to a string representation
inline NSString *RLMTypeToString(RLMPropertyType type) {
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
inline NSString * RLMStringDataToNSString(tightdb::StringData stringData) {
    if (tightdb::util::int_cast_has_overflow<NSUInteger>(stringData.size())) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"String size overflow" userInfo:nil];
        
    }
    return [[NSString alloc] initWithBytes:stringData.data()
                                    length:stringData.size()
                                  encoding:NSUTF8StringEncoding];
}

inline tightdb::StringData RLMStringDataWithNSString(NSString *string) {
    if (tightdb::util::int_cast_has_overflow<size_t>(string.length)) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"String size overflow" userInfo:nil];
        
    }
    return tightdb::StringData(string.UTF8String,
                               [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
}

// Binary convertion utilities
inline tightdb::BinaryData RLMBinaryDataForNSData(NSData *data) {
    return tightdb::BinaryData(static_cast<const char *>(data.bytes), data.length);
}
