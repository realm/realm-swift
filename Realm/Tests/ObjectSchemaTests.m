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

#pragma mark - Test Objects

@interface IndexedObject : RLMObject
@property NSString *stringCol;
@property NSInteger integerCol;
@property int intCol;
@property long longCol;
@property long long longlongCol;
@property BOOL boolCol;
@property NSDate *dateCol;
@property NSNumber<RLMInt> *optionalIntCol;
@property NSNumber<RLMBool> *optionalBoolCol;

@property float floatCol;
@property double doubleCol;
@property NSData *dataCol;
@property NSNumber<RLMFloat> *optionalFloatCol;
@property NSNumber<RLMDouble> *optionalDoubleCol;
@end

@implementation IndexedObject
+ (NSArray *)indexedProperties {
    return @[@"stringCol", @"integerCol", @"intCol", @"longCol", @"longlongCol",
             @"boolCol", @"dateCol", @"optionalIntCol", @"optionalBoolCol"];
}
@end

#pragma mark - Tests

@interface ObjectSchemaTests : RLMTestCase
@end

@implementation ObjectSchemaTests

- (void)testDescription {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[PrimaryStringObject class]];
    XCTAssertEqualObjects(objectSchema.description, @"PrimaryStringObject {\n"
                                                    @"\tstringCol {\n"
                                                    @"\t\ttype = string;\n"
                                                    @"\t\tobjectClassName = (null);\n"
                                                    @"\t\tlinkOriginPropertyName = (null);\n"
                                                    @"\t\tindexed = YES;\n"
                                                    @"\t\tisPrimary = YES;\n"
                                                    @"\t\tarray = NO;\n"
                                                    @"\t\toptional = NO;\n"
                                                    @"\t}\n"
                                                    @"\tintCol {\n"
                                                    @"\t\ttype = int;\n"
                                                    @"\t\tobjectClassName = (null);\n"
                                                    @"\t\tlinkOriginPropertyName = (null);\n"
                                                    @"\t\tindexed = NO;\n"
                                                    @"\t\tisPrimary = NO;\n"
                                                    @"\t\tarray = NO;\n"
                                                    @"\t\toptional = NO;\n"
                                                    @"\t}\n"
                                                    @"}");
}

- (void)testObjectForKeyedSubscript {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[PrimaryStringObject class]];
    XCTAssertEqualObjects(objectSchema[@"stringCol"].name, @"stringCol");
    XCTAssertEqualObjects(objectSchema[@"intCol"].name, @"intCol");
    XCTAssertNil(objectSchema[@"missing"]);
}

- (void)testPrimaryKeyProperty {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[PrimaryStringObject class]];
    XCTAssertEqualObjects(objectSchema.primaryKeyProperty.name, @"stringCol");

    objectSchema = [RLMObjectSchema schemaForObjectClass:[StringObject class]];
    XCTAssertNil(objectSchema.primaryKeyProperty);
}

#pragma mark - Schema Discovery

- (void)testIgnoredUnsupportedProperty {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[IgnoredURLObject class]];
    XCTAssertEqual(1U, objectSchema.properties.count);
    XCTAssertEqualObjects(objectSchema.properties[0].name, @"name");
}

- (void)testReadOnlyPropertiesImplicitlyIgnored {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:[ReadOnlyPropertyObject class]];
    XCTAssertEqual(1U, objectSchema.properties.count);
    XCTAssertEqualObjects(objectSchema.properties[0].name, @"readOnlyPropertyMadeReadWriteInClassExtension");
}

- (void)testIndex {
    RLMObjectSchema *schema = [RLMObjectSchema schemaForObjectClass:[IndexedObject class]];

    XCTAssertTrue(schema[@"stringCol"].indexed);
    XCTAssertTrue(schema[@"integerCol"].indexed);
    XCTAssertTrue(schema[@"intCol"].indexed);
    XCTAssertTrue(schema[@"longCol"].indexed);
    XCTAssertTrue(schema[@"longlongCol"].indexed);
    XCTAssertTrue(schema[@"boolCol"].indexed);
    XCTAssertTrue(schema[@"dateCol"].indexed);
    XCTAssertTrue(schema[@"optionalIntCol"].indexed);
    XCTAssertTrue(schema[@"optionalBoolCol"].indexed);

    XCTAssertFalse(schema[@"floatCol"].indexed);
    XCTAssertFalse(schema[@"doubleCol"].indexed);
    XCTAssertFalse(schema[@"dataCol"].indexed);
    XCTAssertFalse(schema[@"optionalFloatCol"].indexed);
    XCTAssertFalse(schema[@"optionalDoubleCol"].indexed);
}

@end
