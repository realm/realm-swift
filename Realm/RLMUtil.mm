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
#import "RLMArray_Private.hpp"
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
            strcmp(data_type, @encode(unsigned long long)) == 0 ||
            // A double is like float if it fits within float bounds
            (strcmp(data_type, @encode(double)) == 0 && ABS([(NSNumber *)obj doubleValue]) <= FLT_MAX));
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
            Class cls = [obj class];
            return obj == nil || obj == NSNull.null
                || (RLMIsKindOfClass(cls, "RLMObject") && [[cls className] isEqualToString:property.objectClassName]);
        }
        case RLMPropertyTypeArray: {
            if (RLMIsKindOfClass([obj class], "RLMArray")) {
                return [[(RLMArray *)obj objectClassName] isEqualToString:property.objectClassName];
            }
            if ([obj isKindOfClass:NSArray.class]) {
                // check each element for compliance
                for (id el in obj) {
                    Class cls = [el class];
                    if (!RLMIsKindOfClass(cls, "RLMObject") || ![[cls className] isEqualToString:property.objectClassName]) {
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

id RLMValidatedObjectForProperty(id obj, RLMProperty *prop, RLMSchema *schema) {
    if (!RLMIsObjectValidForProperty(obj, prop)) {
        // check for object or array literals
        if (prop.type == RLMPropertyTypeObject) {
            // for object create and try to initialize with obj
            RLMObjectSchema *objSchema = schema[prop.objectClassName];
            return [[objSchema.objectClass alloc] initWithObject:obj];
        }
        else if (prop.type == RLMPropertyTypeArray && [obj isKindOfClass:NSArray.class]) {
            // for arrays, create objects for each literal object and return new array
            NSArray *arrayElements = obj;
            RLMObjectSchema *objSchema = schema[prop.objectClassName];
            RLMArray *objects = [RLMArray standaloneArrayWithObjectClassName:objSchema.className];
            for (id el in arrayElements) {
                [objects addObject:[[objSchema.objectClass alloc] initWithObject:el]];
            }
            return objects;
        }

        // if not a literal throw
        NSString *message = [NSString stringWithFormat:@"Invalid value '%@' for property '%@'", obj ?: @"nil", prop.name];
        @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
    }
    return obj;
}

NSDictionary *RLMValidatedDictionaryForObjectSchema(NSDictionary *dict, RLMObjectSchema *objectSchema, RLMSchema *schema) {
    NSArray *properties = objectSchema.properties;
    NSDictionary *defaults = [objectSchema.objectClass defaultPropertyValues];
    NSMutableDictionary *outDict = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    for (RLMProperty * prop in properties) {
        // set out object to validated input or default value
        id obj = dict[prop.name];
        obj = obj ?: defaults[prop.name];
        outDict[prop.name] = RLMValidatedObjectForProperty(obj, prop, schema);
    }
    return outDict;
}

NSArray *RLMValidatedArrayForObjectSchema(NSArray *array, RLMObjectSchema *objectSchema, RLMSchema *schema) {
    NSArray *props = objectSchema.properties;
    if (array.count != props.count) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Invalid array input. Number of array elements does not match number of properties."
                                     userInfo:nil];
    }

    // validate all values
    NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:props.count];
    for (NSUInteger i = 0; i < array.count; i++) {
        [outArray addObject:RLMValidatedObjectForProperty(array[i], props[i], schema)];
    }
    return outArray;
};

