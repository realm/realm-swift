////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMConstants.h"
#import <objc/runtime.h>

#import <tightdb/table.hpp>

// returns if the object can be inserted as the given type
BOOL RLMIsObjectOfType(id obj, RLMPropertyType type);

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

inline NSString *rlmtype_to_string(RLMPropertyType type) {
    switch (type) {
        case RLMPropertyTypeNone:
            return @"None";
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
        case RLMPropertyTypeTable:
            return @"table";
        case RLMPropertyTypeObject:
            return @"object";
    }
    return @"Unknown";
}

// Getter and Setter for RLMPropertyTypeAny properties
id RLMGetAnyProperty(tightdb::Table &table, NSUInteger row_ndx, NSUInteger col_ndx);
void RLMSetAnyProperty(tightdb::Table &table, NSUInteger row_ndx, NSUInteger col_ndx, id obj);
