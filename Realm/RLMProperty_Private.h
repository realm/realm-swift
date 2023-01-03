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

#import <Realm/RLMProperty.h>

#import <objc/runtime.h>

@class RLMObjectBase;

RLM_HEADER_AUDIT_BEGIN(nullability)

BOOL RLMPropertyTypeIsComputed(RLMPropertyType propertyType);
FOUNDATION_EXTERN void RLMValidateSwiftPropertyName(NSString *name);

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
            return @"mixed";
        case RLMPropertyTypeObject:
            return @"object";
        case RLMPropertyTypeLinkingObjects:
            return @"linking objects";
        case RLMPropertyTypeDecimal128:
            return @"decimal128";
        case RLMPropertyTypeObjectId:
            return @"object id";
        case RLMPropertyTypeUUID:
            return @"uuid";
    }
    return @"Unknown";
}

// private property interface
@interface RLMProperty () {
@public
    RLMPropertyType _type;
}

- (instancetype)initWithName:(NSString *)name
                     indexed:(BOOL)indexed
      linkPropertyDescriptor:(nullable RLMPropertyDescriptor *)linkPropertyDescriptor
                    property:(objc_property_t)property;

- (instancetype)initSwiftPropertyWithName:(NSString *)name
                                  indexed:(BOOL)indexed
                   linkPropertyDescriptor:(nullable RLMPropertyDescriptor *)linkPropertyDescriptor
                                 property:(objc_property_t)property
                                 instance:(RLMObjectBase *)objectInstance;

- (void)updateAccessors;

// private setters
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite, assign) RLMPropertyType type;
@property (nonatomic, readwrite) BOOL indexed;
@property (nonatomic, readwrite) BOOL optional;
@property (nonatomic, readwrite) BOOL array;
@property (nonatomic, readwrite) BOOL set;
@property (nonatomic, readwrite) BOOL dictionary;
@property (nonatomic, copy, nullable) NSString *objectClassName;
@property (nonatomic, copy, nullable) NSString *linkOriginPropertyName;

// private properties
@property (nonatomic, readwrite, nullable) NSString *columnName;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) BOOL isPrimary;
@property (nonatomic, assign) BOOL isLegacy;
@property (nonatomic, assign) ptrdiff_t swiftIvar;
@property (nonatomic, assign, nullable) Class swiftAccessor;
@property (nonatomic, readwrite, assign) RLMPropertyType dictionaryKeyType;
@property (nonatomic, readwrite) BOOL customMappingIsOptional;

// getter and setter names
@property (nonatomic, copy) NSString *getterName;
@property (nonatomic, copy) NSString *setterName;
@property (nonatomic, nullable) SEL getterSel;
@property (nonatomic, nullable) SEL setterSel;

- (RLMProperty *)copyWithNewName:(NSString *)name;
- (NSString *)typeName;

@end

@interface RLMProperty (Dynamic)
/**
 This method is useful only in specialized circumstances, for example, in conjunction with
 +[RLMObjectSchema initWithClassName:objectClass:properties:]. If you are simply building an
 app on Realm, it is not recommended to use this method.

 Initialize an RLMProperty

 @warning This method is useful only in specialized circumstances.

 @param name            The property name.
 @param type            The property type.
 @param objectClassName The object type used for Object and Array types.
 @param linkOriginPropertyName The property name of the origin of a link. Used for linking objects properties.

 @return    An initialized instance of RLMProperty.
 */
- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(nullable NSString *)objectClassName
      linkOriginPropertyName:(nullable NSString *)linkOriginPropertyName
                     indexed:(BOOL)indexed
                    optional:(BOOL)optional;
@end

RLM_HEADER_AUDIT_END(nullability)
