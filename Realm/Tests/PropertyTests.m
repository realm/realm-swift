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

#import <objc/runtime.h>
#import "RLMObjectSchema_Private.h"
#import "RLMProperty_Private.h"
#import "RLMRealm_Dynamic.h"

@interface PropertyTests : RLMTestCase

@end

@implementation PropertyTests

- (void)testDescription {
    AllTypesObject *object = [[AllTypesObject alloc] init];
    RLMProperty *property = object.objectSchema[@"objectCol"];

    XCTAssertEqualObjects(property.description, @"objectCol {\n"
                                                @"\ttype = object;\n"
                                                @"\tobjectClassName = StringObject;\n"
                                                @"\tindexed = NO;\n"
                                                @"\tisPrimary = NO;\n"
                                                @"\toptional = YES;\n"
                                                @"}");
}

- (void)testEqualityFromObjectSchema {
    BOOL optionalsEnabled = YES;

    // Test all property types
    {
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[AllTypesObject class]];
        NSDictionary *expectedProperties = @{
                                             @"boolCol":   [[RLMProperty alloc] initWithName:@"boolCol"   type:RLMPropertyTypeBool   objectClassName:nil             indexed:NO optional:NO],
                                             @"intCol":    [[RLMProperty alloc] initWithName:@"intCol"    type:RLMPropertyTypeInt    objectClassName:nil             indexed:NO optional:NO],
                                             @"floatCol":  [[RLMProperty alloc] initWithName:@"floatCol"  type:RLMPropertyTypeFloat  objectClassName:nil             indexed:NO optional:NO],
                                             @"doubleCol": [[RLMProperty alloc] initWithName:@"doubleCol" type:RLMPropertyTypeDouble objectClassName:nil             indexed:NO optional:NO],
                                             @"stringCol": [[RLMProperty alloc] initWithName:@"stringCol" type:RLMPropertyTypeString objectClassName:nil             indexed:NO optional:optionalsEnabled],
                                             @"binaryCol": [[RLMProperty alloc] initWithName:@"binaryCol" type:RLMPropertyTypeData   objectClassName:nil             indexed:NO optional:optionalsEnabled],
                                             @"dateCol":   [[RLMProperty alloc] initWithName:@"dateCol"   type:RLMPropertyTypeDate   objectClassName:nil             indexed:NO optional:optionalsEnabled],
                                             @"cBoolCol":  [[RLMProperty alloc] initWithName:@"cBoolCol"  type:RLMPropertyTypeBool   objectClassName:nil             indexed:NO optional:NO],
                                             @"longCol":   [[RLMProperty alloc] initWithName:@"longCol"   type:RLMPropertyTypeInt    objectClassName:nil             indexed:NO optional:NO],
                                             @"mixedCol":  [[RLMProperty alloc] initWithName:@"mixedCol"  type:RLMPropertyTypeAny    objectClassName:nil             indexed:NO optional:NO],
                                             @"objectCol": [[RLMProperty alloc] initWithName:@"objectCol" type:RLMPropertyTypeObject objectClassName:@"StringObject" indexed:NO optional:YES]
                                             };
        XCTAssertEqual(objectSchema.properties.count, expectedProperties.allKeys.count);
        for (NSString *propertyName in expectedProperties) {
            RLMProperty *schemaProperty = objectSchema[propertyName];
            RLMProperty *expectedProperty = expectedProperties[propertyName];
            XCTAssertTrue([schemaProperty isEqualToProperty:expectedProperty]);
        }
    }
    // Test indexed property
    {
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[IndexedStringObject class]];
        RLMProperty *stringProperty = objectSchema[@"stringCol"];
        RLMProperty *expectedProperty = [[RLMProperty alloc] initWithName:@"stringCol" type:RLMPropertyTypeString objectClassName:nil indexed:YES optional:optionalsEnabled];
        XCTAssertTrue([stringProperty isEqualToProperty:expectedProperty]);
    }
    // Test primary key property
    {
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[PrimaryStringObject class]];
        RLMProperty *stringProperty = objectSchema[@"stringCol"];
        RLMProperty *expectedProperty = [[RLMProperty alloc] initWithName:@"stringCol" type:RLMPropertyTypeString objectClassName:nil indexed:YES optional:optionalsEnabled];
        expectedProperty.isPrimary = YES;
        XCTAssertTrue([stringProperty isEqualToProperty:expectedProperty]);
    }
}

- (void)testTwoPropertiesAreEqual {
    const char *name = "intCol";
    objc_property_t objcProperty1 = class_getProperty(AllTypesObject.class, name);
    RLMProperty *property1 = [[RLMProperty alloc] initWithName:@(name) indexed:YES property:objcProperty1];

    objc_property_t objcProperty2 = class_getProperty(IntObject.class, name);
    RLMProperty *property2 = [[RLMProperty alloc] initWithName:@(name) indexed:YES property:objcProperty2];

    XCTAssertTrue([property1 isEqualToProperty:property2]);
}

- (void)testTwoPropertiesAreUnequal {
    const char *name = "stringCol";
    objc_property_t objcProperty1 = class_getProperty(AllTypesObject.class, name);
    RLMProperty *property1 = [[RLMProperty alloc] initWithName:@(name) indexed:YES property:objcProperty1];

    name = "intCol";
    objc_property_t objcProperty2 = class_getProperty(IntObject.class, name);
    RLMProperty *property2 = [[RLMProperty alloc] initWithName:@(name) indexed:YES property:objcProperty2];

    XCTAssertFalse([property1 isEqualToProperty:property2]);
}

@end
