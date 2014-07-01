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

#import <Foundation/Foundation.h>
#import "RLMObjectSchema_Private.hpp"
#import "RLMUtil.hpp"
#import "RLMObject.h"
#import "RLMArray.h"
#import "RLMProperty.h"

inline bool nsnumber_is_like_bool(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    // @encode(BOOL) is 'B' on iOS 64 and 'c'
    // objcType is always 'c'. Therefore compare to "c".
    
    // FIXME: Need to support @(false) which returns a data_type of 'i'
    return data_type[0] == 'c';
}

inline bool nsnumber_is_like_integer(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
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
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
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
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
    return (strcmp(data_type, @encode(double)) == 0 ||
            strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

inline bool object_has_valid_type(id obj)
{
    return ([obj isKindOfClass:[NSString class]] ||
            [obj isKindOfClass:[NSNumber class]] ||
            [obj isKindOfClass:[NSDate class]] ||
            [obj isKindOfClass:[NSData class]]);
}

BOOL RLMIsObjectValidForProperty(id obj, RLMProperty *property) {
    switch (property.type) {
        case RLMPropertyTypeString:
            return [obj isKindOfClass:[NSString class]];
        case RLMPropertyTypeBool:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_bool(obj);
            }
            return NO;
        case RLMPropertyTypeDate:
            return [obj isKindOfClass:[NSDate class]];
        case RLMPropertyTypeInt:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_integer(obj);
            }
            return NO;
        case RLMPropertyTypeFloat:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_float(obj);
            }
            return NO;
        case RLMPropertyTypeDouble:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_double(obj);
            }
            return NO;
        case RLMPropertyTypeData:
            return [obj isKindOfClass:[NSData class]];
        case RLMPropertyTypeAny:
            return object_has_valid_type(obj);
        case RLMPropertyTypeObject: {
            // only NSNull, nil, or objects which derive from RLMObject and match the given
            // object class are valid
            BOOL isValidObject = RLMIsSubclass([obj class], [RLMObject class]) &&
                                 [[[obj class] className] isEqualToString:property.objectClassName];
            return isValidObject || obj == nil || obj == NSNull.null;
        }
        case RLMPropertyTypeArray: {
            if ([obj isKindOfClass:RLMArray.class]) {
                return [[(RLMArray *)obj objectClassName] isEqualToString:property.objectClassName];
            }
            if ([obj isKindOfClass:NSArray.class]) {
                // check each element for compliance
                for (id el in obj) {
                    if (![el isKindOfClass:property.objectClassName]) {
                        return NO;
                    }
                }
                return YES;
            }
            if (obj == NSNull.null) {
                return YES;
            }
            return NO;
        }
    }
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid RLMPropertyType specified" userInfo:nil];
}


NSDictionary *RLMValidatedDictionaryForObjectSchema(NSDictionary *dict, RLMObjectSchema *schema) {
    NSArray *properties = schema.properties;
    NSDictionary *defaults = [schema.objectClass defaultPropertyValues];
    NSMutableDictionary *outDict = [dict mutableCopy];
    for (RLMProperty * prop in properties) {
        // set defualt value if missing
        if (!outDict[prop.name]) {
            outDict[prop.name] = defaults[prop.name];
        }

        // validate
        if (!RLMIsObjectValidForProperty(outDict[prop.name], prop)) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"Invalid value type for %@", prop.name]
                                         userInfo:nil];
        }
    }
    return outDict;
}

void RLMValidateArrayAgainstObjectSchema(NSArray *array, RLMObjectSchema *schema) {
    NSArray *props = schema.properties;
    if (array.count != props.count) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Invalid array input. Number of array elements does not match number of properties."
                                     userInfo:nil];
    }

    // validate all values
    for (NSUInteger i = 0; i < array.count; i++) {
        if (!RLMIsObjectValidForProperty(array[i], props[i])) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"Invalid value type for %@", [props[i] name]]
                                         userInfo:nil];
        }
    }
};

