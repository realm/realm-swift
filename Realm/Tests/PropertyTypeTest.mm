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

#import "RLMTestCase.h"
#import "RLMUtil.hpp"
#import  <realm/data_type.hpp>

@interface PropertyTypeTests : RLMTestCase
@end

@implementation PropertyTypeTests

- (void)testPropertyTypes
{
    // Primitive types
    XCTAssertEqual((int)RLMPropertyTypeInt,     (int)realm::type_Int,         @"Int");
    XCTAssertEqual((int)RLMPropertyTypeBool,    (int)realm::type_Bool,        @"Bool");
    XCTAssertEqual((int)RLMPropertyTypeFloat,   (int)realm::type_Float,       @"Float");
    XCTAssertEqual((int)RLMPropertyTypeDouble,  (int)realm::type_Double,      @"Double");
    
    // Object types
    XCTAssertEqual((int)RLMPropertyTypeString,  (int)realm::type_String,      @"String");
    XCTAssertEqual((int)RLMPropertyTypeData,    (int)realm::type_Binary,      @"Binary");
    XCTAssertEqual((int)RLMPropertyTypeAny,     (int)realm::type_Mixed,       @"Mixed");
    XCTAssertEqual((int)RLMPropertyTypeDate,    (int)realm::type_DateTime,    @"Date");
    
    // Array/Linked object types
    XCTAssertEqual((int)RLMPropertyTypeObject,  (int)realm::type_Link,        @"Link");
    XCTAssertEqual((int)RLMPropertyTypeArray,   (int)realm::type_LinkList,    @"Link list");
    
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeString),   @"string",  @"stringType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeInt),      @"int",     @"intType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeBool),     @"bool",    @"boolType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeDate),     @"date",    @"dateType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeData),     @"data",    @"dataType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeDouble),   @"double",  @"doubleType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeFloat),    @"float",   @"floatType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeAny),      @"any",     @"anyType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeObject),   @"object",  @"objectType");
    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyTypeArray),    @"array",   @"arrayType");

    XCTAssertEqualObjects(RLMTypeToString(RLMPropertyType(-1)),    @"Unknown",   @"Unknown type");
}

- (void)testIntSizes
{
    RLMRealm *realm = [self realmWithTestPath];

    int16_t v16 = 1 << 12;
    int32_t v32 = 1 << 30;
    int64_t v64 = 1LL << 40;

    AllIntSizesObject *obj = [AllIntSizesObject new];

    // Test standalone
    obj[@"int16"] = @(v16);
    XCTAssertEqual([obj[@"int16"] shortValue], v16);
    obj[@"int16"] = @(v32);
    XCTAssertNotEqual([obj[@"int16"] intValue], v32, @"should truncate");

    obj.int16 = 0;
    obj.int16 = v16;
    XCTAssertEqual(obj.int16, v16);

    obj[@"int32"] = @(v32);
    XCTAssertEqual([obj[@"int32"] intValue], v32);
    obj[@"int32"] = @(v64);
    XCTAssertNotEqual([obj[@"int32"] longLongValue], v64, @"should truncate");

    obj.int32 = 0;
    obj.int32 = v32;
    XCTAssertEqual(obj.int32, v32);

    obj[@"int64"] = @(v64);
    XCTAssertEqual([obj[@"int64"] longLongValue], v64);
    obj.int64 = 0;
    obj.int64 = v64;
    XCTAssertEqual(obj.int64, v64);

    // Test in realm
    [realm beginWriteTransaction];
    [realm addObject:obj];

    XCTAssertEqual(obj.int16, v16);
    XCTAssertEqual(obj.int32, v32);
    XCTAssertEqual(obj.int64, v64);

    obj.int16 = 0;
    obj.int32 = 0;
    obj.int64 = 0;

    obj[@"int16"] = @(v16);
    XCTAssertEqual([obj[@"int16"] shortValue], v16);
    obj[@"int16"] = @(v32);
    XCTAssertNotEqual([obj[@"int16"] intValue], v32, @"should truncate");

    obj.int16 = 0;
    obj.int16 = v16;
    XCTAssertEqual(obj.int16, v16);

    obj[@"int32"] = @(v32);
    XCTAssertEqual([obj[@"int32"] intValue], v32);
    obj[@"int32"] = @(v64);
    XCTAssertNotEqual([obj[@"int32"] longLongValue], v64, @"should truncate");

    obj.int32 = 0;
    obj.int32 = v32;
    XCTAssertEqual(obj.int32, v32);

    obj[@"int64"] = @(v64);
    XCTAssertEqual([obj[@"int64"] longLongValue], v64);
    obj.int64 = 0;
    obj.int64 = v64;
    XCTAssertEqual(obj.int64, v64);

    [realm commitWriteTransaction];
}

@end
