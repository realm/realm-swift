////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMTestCase.h"

#import "RLMObjectSchema_Private.h"
#import "RLMProperty_Private.h"
#import "RLMRealm_Dynamic.h"

#import <objc/runtime.h>

@interface PropertyTests : RLMTestCase
@end

@implementation PropertyTests

- (void)testDescription {
    AllTypesObject *object = [[AllTypesObject alloc] init];
    RLMProperty *property = object.objectSchema[@"objectCol"];

    XCTAssertEqualObjects(property.description, @"objectCol {\n"
                                                @"\ttype = object;\n"
                                                @"\tobjectClassName = StringObject;\n"
                                                @"\tlinkOriginPropertyName = (null);\n"
                                                @"\tindexed = NO;\n"
                                                @"\tisPrimary = NO;\n"
                                                @"\tarray = NO;\n"
                                                @"\tset = NO;\n"
                                                @"\tdictionary = NO;\n"
                                                @"\toptional = YES;\n"
                                                @"}");
}

static RLMProperty *makeProperty(NSString *name, RLMPropertyType type, NSString *objectClassName, BOOL optional) {
    return [[RLMProperty alloc] initWithName:name type:type objectClassName:objectClassName
                      linkOriginPropertyName:nil indexed:NO optional:optional];
}

- (void)testEqualityFromObjectSchema {
    { // Test non-optional property types
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[AllTypesObject class]];
        NSDictionary *expectedProperties = @{
            @"boolCol":     makeProperty(@"boolCol", RLMPropertyTypeBool, nil, NO),
            @"intCol":      makeProperty(@"intCol", RLMPropertyTypeInt, nil, NO),
            @"floatCol":    makeProperty(@"floatCol", RLMPropertyTypeFloat, nil, NO),
            @"doubleCol":   makeProperty(@"doubleCol", RLMPropertyTypeDouble, nil, NO),
            @"stringCol":   makeProperty(@"stringCol", RLMPropertyTypeString, nil, NO),
            @"binaryCol":   makeProperty(@"binaryCol", RLMPropertyTypeData, nil, NO),
            @"dateCol":     makeProperty(@"dateCol", RLMPropertyTypeDate, nil, NO),
            @"cBoolCol":    makeProperty(@"cBoolCol", RLMPropertyTypeBool, nil, NO),
            @"longCol":     makeProperty(@"longCol", RLMPropertyTypeInt, nil, NO),
            @"objectIdCol": makeProperty(@"objectIdCol", RLMPropertyTypeObjectId, nil, NO),
            @"decimalCol":  makeProperty(@"decimalCol", RLMPropertyTypeDecimal128, nil, NO),
            @"objectCol":   makeProperty(@"objectCol", RLMPropertyTypeObject, @"StringObject", YES),
            @"uuidCol":     makeProperty(@"uuidCol", RLMPropertyTypeUUID, nil, NO),
            @"anyCol":      makeProperty(@"anyCol", RLMPropertyTypeAny, nil, NO),
            @"mixedObjectCol": makeProperty(@"mixedObjectCol", RLMPropertyTypeObject, @"MixedObject", YES),
        };
        XCTAssertEqual(objectSchema.properties.count, expectedProperties.allKeys.count);
        for (NSString *propertyName in expectedProperties) {
            XCTAssertEqualObjects(objectSchema[propertyName], expectedProperties[propertyName]);
        }
    }
    { // Test optional property types
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[AllOptionalTypes class]];
        NSDictionary *expectedProperties = @{
            @"intObj":    makeProperty(@"intObj", RLMPropertyTypeInt, nil, YES),
            @"floatObj":  makeProperty(@"floatObj", RLMPropertyTypeFloat, nil, YES),
            @"doubleObj": makeProperty(@"doubleObj", RLMPropertyTypeDouble, nil, YES),
            @"boolObj":   makeProperty(@"boolObj", RLMPropertyTypeBool, nil, YES),
            @"string":    makeProperty(@"string", RLMPropertyTypeString, nil, YES),
            @"data":      makeProperty(@"data", RLMPropertyTypeData, nil, YES),
            @"date":      makeProperty(@"date", RLMPropertyTypeDate, nil, YES),
            @"objectId":  makeProperty(@"objectId", RLMPropertyTypeObjectId, nil, YES),
            @"decimal":   makeProperty(@"decimal", RLMPropertyTypeDecimal128, nil, YES),
            @"uuidCol":   makeProperty(@"uuidCol", RLMPropertyTypeUUID, nil, YES),
        };
        XCTAssertEqual(objectSchema.properties.count, expectedProperties.allKeys.count);
        for (NSString *propertyName in expectedProperties) {
            XCTAssertEqualObjects(objectSchema[propertyName], expectedProperties[propertyName]);
        }
    }
    { // Test indexed property
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[IndexedStringObject class]];
        RLMProperty *stringProperty = objectSchema[@"stringCol"];
        RLMProperty *expectedProperty = [[RLMProperty alloc] initWithName:@"stringCol" type:RLMPropertyTypeString objectClassName:nil linkOriginPropertyName:nil indexed:YES optional:YES];
        XCTAssertEqualObjects(stringProperty, expectedProperty);
    }
    { // Test primary key property
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[PrimaryStringObject class]];
        RLMProperty *stringProperty = objectSchema[@"stringCol"];
        RLMProperty *expectedProperty = [[RLMProperty alloc] initWithName:@"stringCol"
                                                                     type:RLMPropertyTypeString
                                                          objectClassName:nil
                                                   linkOriginPropertyName:nil
                                                                  indexed:YES
                                                                 optional:NO];
        expectedProperty.isPrimary = YES;
        XCTAssertEqualObjects(stringProperty, expectedProperty);
    }
}

- (void)testTwoPropertiesAreEqual {
    const char *name = "intCol";
    objc_property_t objcProperty1 = class_getProperty(AllTypesObject.class, name);
    RLMProperty *property1 = [[RLMProperty alloc] initWithName:@(name) indexed:YES linkPropertyDescriptor:nil property:objcProperty1];

    objc_property_t objcProperty2 = class_getProperty(IntObject.class, name);
    RLMProperty *property2 = [[RLMProperty alloc] initWithName:@(name) indexed:YES linkPropertyDescriptor:nil property:objcProperty2];

    XCTAssertEqualObjects(property1, property2);
}

- (void)testTwoPropertiesAreUnequal {
    const char *name = "stringCol";
    objc_property_t objcProperty1 = class_getProperty(AllTypesObject.class, name);
    RLMProperty *property1 = [[RLMProperty alloc] initWithName:@(name) indexed:YES linkPropertyDescriptor:nil property:objcProperty1];

    name = "intCol";
    objc_property_t objcProperty2 = class_getProperty(IntObject.class, name);
    RLMProperty *property2 = [[RLMProperty alloc] initWithName:@(name) indexed:YES linkPropertyDescriptor:nil property:objcProperty2];

    XCTAssertNotEqualObjects(property1, property2);
}

- (void)testSwiftPropertyNameValidation {
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"alloc"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"_alloc"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"allocOject"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"_allocOject"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"alloc_object"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"_alloc_object"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"new"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"copy"));
    RLMAssertThrows(RLMValidateSwiftPropertyName(@"mutableCopy"));

    // Swift doesn't infer family from `init`
    XCTAssertNoThrow(RLMValidateSwiftPropertyName(@"init"));
    XCTAssertNoThrow(RLMValidateSwiftPropertyName(@"_init"));
    XCTAssertNoThrow(RLMValidateSwiftPropertyName(@"initWithValue"));

    // Lowercase letter after family name
    XCTAssertNoThrow(RLMValidateSwiftPropertyName(@"allocate"));

    XCTAssertNoThrow(RLMValidateSwiftPropertyName(@"__alloc"));
}

- (void)testTypeToString {
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeString),   @"string");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeInt),      @"int");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeBool),     @"bool");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeDate),     @"date");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeData),     @"data");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeDouble),   @"double");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeFloat),    @"float");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeObject),   @"object");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeLinkingObjects), @"linking objects");

    XCTAssertEqualObjects(RLMTypeToString((RLMPropertyType)-1),     @"Unknown");
}

@end
