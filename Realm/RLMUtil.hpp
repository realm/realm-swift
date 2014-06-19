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
#import <objc/runtime.h>

#import <tightdb/table.hpp>
#import <tightdb/row.hpp>
#import <tightdb/string_data.hpp>
#import <tightdb/util/safe_int_ops.hpp>

@class RLMProperty;

// returns if the object can be inserted as the given type
BOOL RLMIsObjectValidForProperty(id obj, RLMProperty *prop);

// C version of isKindOfClass
inline BOOL RLMIsKindOfclass(Class class1, Class class2) {
    while (class1) {
        if (class1 == class2) return YES;
        class1 = class_getSuperclass(class1);
    }
    return NO;
}

// Determines if class1 descends from class2
inline BOOL RLMIsSubclass(Class class1, Class class2) {
    class1 = class_getSuperclass(class1);
    return RLMIsKindOfclass(class1, class2);
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

// Getter and Setter for RLMPropertyTypeAny properties
id RLMGetAnyProperty(tightdb::Row row, NSUInteger col_ndx);
void RLMSetAnyProperty(tightdb::Row row, NSUInteger col_ndx, id obj);


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
    return tightdb::StringData(string.UTF8String, string.length);
}

// Binary convertion utilities
inline tightdb::BinaryData RLMBinaryDataForNSData(NSData *data) {
    return tightdb::BinaryData(static_cast<const char *>(data.bytes), data.length);
}
