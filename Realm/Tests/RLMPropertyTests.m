//
//  RLMPropertyTests.m
//  Realm
//
//  Created by Samuel Giddins on 2/2/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import "RLMTestCase.h"

#import <objc/runtime.h>
#import "RLMProperty_Private.h"
#import "RLMObject.h"

@interface RLMPropertyTests : RLMTestCase

@end

@implementation RLMPropertyTests

- (void)testDescription {
    AllTypesObject *object = [[AllTypesObject alloc] init];
    RLMProperty *property = object.objectSchema[@"objectCol"];

    XCTAssertEqualObjects(property.description, @"objectCol {\n"
                                                @"\ttype = object;\n"
                                                @"\tobjectClassName = StringObject;\n"
                                                @"\tindexed = NO;\n"
                                                @"\tisPrimary = NO;\n"
                                                @"}");
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
