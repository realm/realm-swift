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
#import "RLMProperty_Private.h"

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
