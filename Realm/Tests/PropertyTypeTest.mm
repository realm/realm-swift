////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"
#import  <tightdb/data_type.hpp>


@interface PropertyTypeTests : RLMTestCase

@end

@implementation PropertyTypeTests

- (void)testPropertyTypes
{
    // Primitive types
    XCTAssertEqual((int)RLMPropertyTypeInt,     (int)tightdb::type_Int,         @"Int");
    XCTAssertEqual((int)RLMPropertyTypeBool,    (int)tightdb::type_Bool,        @"Bool");
    XCTAssertEqual((int)RLMPropertyTypeFloat,   (int)tightdb::type_Float,       @"Float");
    XCTAssertEqual((int)RLMPropertyTypeDouble,  (int)tightdb::type_Double,      @"Double");
    
    // Object types
    XCTAssertEqual((int)RLMPropertyTypeString,  (int)tightdb::type_String,      @"String");
    XCTAssertEqual((int)RLMPropertyTypeData,    (int)tightdb::type_Binary,      @"Binary");
    XCTAssertEqual((int)RLMPropertyTypeAny,     (int)tightdb::type_Mixed,       @"Mixed");
    XCTAssertEqual((int)RLMPropertyTypeDate,    (int)tightdb::type_DateTime,    @"Date");
    
    // Array/Linked object types
    XCTAssertEqual((int)RLMPropertyTypeObject,  (int)tightdb::type_Link,        @"Link");
    XCTAssertEqual((int)RLMPropertyTypeArray,   (int)tightdb::type_LinkList,    @"Link list");
}

@end
