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

#import "RLMUtil.hpp"

#import "RLMArray_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMProperty_Private.h"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"

#if !defined(REALM_COCOA_VERSION)
#import "RLMVersion.h"
#endif

static inline bool nsnumber_is_like_integer(NSNumber *obj)
{
    const char *data_type = [obj objCType];
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
    return (strcmp(data_type, @encode(short)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned short)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

static inline bool nsnumber_is_like_bool(NSNumber *obj)
{
    // @encode(BOOL) is 'B' on iOS 64 and 'c'
    // objcType is always 'c'. Therefore compare to "c".
    if ([obj objCType][0] == 'c') {
        return true;
    }

    if (nsnumber_is_like_integer(obj)) {
        int value = [obj intValue];
        return value == 0 || value == 1;
    }

    return false;
}

static inline bool nsnumber_is_like_float(NSNumber *obj)
{
    const char *data_type = [obj objCType];
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
    return (strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(short)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned short)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0 ||
            // A double is like float if it fits within float bounds
            (strcmp(data_type, @encode(double)) == 0 && ABS([obj doubleValue]) <= FLT_MAX));
}

static inline bool nsnumber_is_like_double(NSNumber *obj)
{
    const char *data_type = [obj objCType];
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
    return (strcmp(data_type, @encode(double)) == 0 ||
            strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(short)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned short)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

static inline bool object_has_valid_type(id obj)
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
            if (NSNumber *number = RLMDynamicCast<NSNumber>(obj)) {
                return nsnumber_is_like_integer(number);
            }
            return NO;
        case RLMPropertyTypeFloat:
            if (NSNumber *number = RLMDynamicCast<NSNumber>(obj)) {
                return nsnumber_is_like_float(number);
            }
            return NO;
        case RLMPropertyTypeDouble:
            if (NSNumber *number = RLMDynamicCast<NSNumber>(obj)) {
                return nsnumber_is_like_double(number);
            }
            return NO;
        case RLMPropertyTypeData:
            return [obj isKindOfClass:[NSData class]];
        case RLMPropertyTypeAny:
            return object_has_valid_type(obj);
        case RLMPropertyTypeObject: {
            // only NSNull, nil, or objects which derive from RLMObject and match the given
            // object class are valid
            if (obj == nil || obj == NSNull.null) {
                return YES;
            }
            RLMObjectBase *objBase = RLMDynamicCast<RLMObjectBase>(obj);
            return objBase && [objBase->_objectSchema.className isEqualToString:property.objectClassName];
        }
        case RLMPropertyTypeArray: {
            if (RLMArray *array = RLMDynamicCast<RLMArray>(obj)) {
                return [array.objectClassName isEqualToString:property.objectClassName];
            }
            if (NSArray *array = RLMDynamicCast<NSArray>(obj)) {
                // check each element for compliance
                for (id el in array) {
                    RLMObjectBase *obj = RLMDynamicCast<RLMObjectBase>(el);
                    if (!obj || ![obj->_objectSchema.className isEqualToString:property.objectClassName]) {
                        return NO;
                    }
                }
                return YES;
            }
            if (!obj || obj == NSNull.null) {
                return YES;
            }
            return NO;
        }
    }
    @throw RLMException(@"Invalid RLMPropertyType specified");
}

id RLMValidatedObjectForProperty(id obj, RLMProperty *prop, RLMSchema *schema) {
    if (!RLMIsObjectValidForProperty(obj, prop)) {
        // check for object or array literals
        if (prop.type == RLMPropertyTypeObject) {
            // for object create and try to initialize with obj
            RLMObjectSchema *objSchema = schema[prop.objectClassName];
            return [[objSchema.objectClass alloc] initWithValue:obj schema:schema];
        }
        else if (prop.type == RLMPropertyTypeArray && [obj conformsToProtocol:@protocol(NSFastEnumeration)]) {
            // for arrays, create objects for each literal object and return new array
            RLMObjectSchema *objSchema = schema[prop.objectClassName];
            RLMArray *objects = [[RLMArray alloc] initWithObjectClassName: objSchema.className standalone:YES];
            for (id el in obj) {
                [objects addObject:[[objSchema.objectClass alloc] initWithValue:el schema:schema]];
            }
            return objects;
        }

        // if not a literal throw
        NSString *message = [NSString stringWithFormat:@"Invalid value '%@' for property '%@'", obj ?: @"nil", prop.name];
        @throw RLMException(message);
    }
    return obj;
}

NSDictionary *RLMDefaultValuesForObjectSchema(RLMObjectSchema *objectSchema) {
    if (!objectSchema.isSwiftClass) {
        return [objectSchema.objectClass defaultPropertyValues];
    }

    NSMutableDictionary *defaults = nil;
    if ([objectSchema.objectClass isSubclassOfClass:RLMObject.class]) {
        defaults = [NSMutableDictionary dictionaryWithDictionary:[objectSchema.objectClass defaultPropertyValues]];
    }
    else {
        defaults = [NSMutableDictionary dictionary];
    }
    RLMObject *defaultObject = [[objectSchema.objectClass alloc] init];
    for (RLMProperty *prop in objectSchema.properties) {
        if (!defaults[prop.name] && defaultObject[prop.name]) {
            defaults[prop.name] = defaultObject[prop.name];
        }
    }
    return defaults;
}

NSDictionary *RLMValidatedDictionaryForObjectSchema(id value, RLMObjectSchema *objectSchema, RLMSchema *schema, bool allowMissing) {
    NSArray *properties = objectSchema.properties;
    NSMutableDictionary *outDict = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    NSDictionary *defaultValues = nil;
    for (RLMProperty *prop in properties) {
        id obj = [value valueForKey:prop.name];

        // get default for nil object
        if (!obj && !allowMissing) {
            if (!defaultValues) {
                defaultValues = RLMDefaultValuesForObjectSchema(objectSchema);
            }
            obj = defaultValues[prop.name];
        }

        // validate if object is not nil, or for nil if we don't allow missing values
        if (obj || !allowMissing) {
            if (!obj) {
                obj = NSNull.null;
            }
            outDict[prop.name] = RLMValidatedObjectForProperty(obj, prop, schema);
        }
    }
    return outDict;
}

NSArray *RLMValidatedArrayForObjectSchema(NSArray *array, RLMObjectSchema *objectSchema, RLMSchema *schema) {
    NSArray *props = objectSchema.properties;
    if (array.count != props.count) {
        @throw RLMException(@"Invalid array input. Number of array elements does not match number of properties.");
    }

    // validate all values
    NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:props.count];
    for (NSUInteger i = 0; i < array.count; i++) {
        [outArray addObject:RLMValidatedObjectForProperty(array[i], props[i], schema)];
    }
    return outArray;
};

NSArray *RLMCollectionValueForKey(NSString *key, RLMRealm *realm, RLMObjectSchema *objectSchema, size_t count, size_t (^indexGenerator)(size_t)) {
    if (count == 0) {
        return @[];
    }

    NSMutableArray *results = [NSMutableArray arrayWithCapacity:count];

    if ([key isEqualToString:@"self"]) {
        for (size_t i = 0; i < count; i++) {
            size_t rowIndex = indexGenerator(i);
            [results addObject:RLMCreateObjectAccessor(realm, objectSchema, rowIndex) ?: NSNull.null];
        }
        return results;
    }

    RLMObjectBase *accessor = [[objectSchema.accessorClass alloc] initWithRealm:realm schema:objectSchema];
    realm::Table *table = objectSchema.table;
    for (size_t i = 0; i < count; i++) {
        size_t rowIndex = indexGenerator(i);
        accessor->_row = (*table)[rowIndex];
        RLMInitializeSwiftListAccessor(accessor);
        [results addObject:[accessor valueForKey:key] ?: NSNull.null];
    }

    return results;
}

void RLMCollectionSetValueForKey(id value, NSString *key, RLMRealm *realm, RLMObjectSchema *objectSchema, size_t count, size_t (^indexGenerator)(size_t)) {
    if (count == 0) {
        return;
    }
    RLMObjectBase *accessor = [[objectSchema.accessorClass alloc] initWithRealm:realm schema:objectSchema];
    realm::Table *table = objectSchema.table;
    for (size_t i = 0; i < count; i++) {
        size_t rowIndex = indexGenerator(i);
        accessor->_row = (*table)[rowIndex];
        RLMInitializeSwiftListAccessor(accessor);
        [accessor setValue:value forKey:key];
    }
}

NSException *RLMException(NSString *reason, NSDictionary *userInfo) {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    [info addEntriesFromDictionary:@{
                                     RLMRealmVersionKey : REALM_COCOA_VERSION,
                                     RLMRealmCoreVersionKey : @REALM_VERSION
                                     }];

    return [NSException exceptionWithName:RLMExceptionName reason:reason userInfo:info];
}

NSException *RLMException(std::exception const& exception) {
    return RLMException(@(exception.what()));
}

NSError *RLMMakeError(RLMError code, std::exception const& exception) {
    return [NSError errorWithDomain:RLMErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      @"Error Code": @(code)}];
}

void RLMSetErrorOrThrow(NSError *error, NSError **outError) {
    if (outError) {
        *outError = error;
    }
    else {
        @throw RLMException(error.localizedDescription, error.userInfo);
    }
}

// Determines if class1 descends from class2
static inline BOOL RLMIsSubclass(Class class1, Class class2) {
    class1 = class_getSuperclass(class1);
    return RLMIsKindOfClass(class1, class2);
}

BOOL RLMIsObjectSubclass(Class klass) {
    return RLMIsSubclass(class_getSuperclass(klass), RLMObjectBase.class);
}
