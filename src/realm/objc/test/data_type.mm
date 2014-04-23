//
//  data_type.mm
//  TightDB
//
// Check that data type enumeration values are in synch with the core library
//

#import "RLMTestCase.h"

#import <realm/objc/RLMType.h>
#include <tightdb/data_type.hpp>

@interface TestDataType: RLMTestCase
@end
@implementation TestDataType

- (void)testDataType
{
    XCTAssertEqual((int)RLMTypeBool,     (int)tightdb::type_Bool,   @"Bool");
    XCTAssertEqual((int)RLMTypeInt,      (int)tightdb::type_Int,    @"Int");
    XCTAssertEqual((int)RLMTypeFloat,    (int)tightdb::type_Float,  @"Float");
    XCTAssertEqual((int)RLMTypeDouble,   (int)tightdb::type_Double, @"Double");
    XCTAssertEqual((int)RLMTypeString,   (int)tightdb::type_String, @"String");
    XCTAssertEqual((int)RLMTypeBinary,   (int)tightdb::type_Binary, @"Binary");
    XCTAssertEqual((int)RLMTypeDate,     (int)tightdb::type_DateTime,@"Date");
    XCTAssertEqual((int)RLMTypeTable,    (int)tightdb::type_Table,  @"Table");
    XCTAssertEqual((int)RLMTypeMixed,    (int)tightdb::type_Mixed,  @"Mixed");
}

@end
