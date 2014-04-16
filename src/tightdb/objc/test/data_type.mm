//
//  data_type.mm
//  TightDB
//
// Check that data type enumeration values are in synch with the core library
//

#import <XCTest/XCTest.h>

#import <tightdb/objc/TDBType.h>
#import <tightdb/data_type.hpp>

@interface TestDataType: XCTestCase
@end
@implementation TestDataType

- (void)testDataType
{
    XCTAssertEqual((int)TDBBoolType,     (int)tightdb::type_Bool,   @"Bool");
    XCTAssertEqual((int)TDBIntType,      (int)tightdb::type_Int,    @"Int");
    XCTAssertEqual((int)TDBFloatType,    (int)tightdb::type_Float,  @"Float");
    XCTAssertEqual((int)TDBDoubleType,   (int)tightdb::type_Double, @"Double");
    XCTAssertEqual((int)TDBStringType,   (int)tightdb::type_String, @"String");
    XCTAssertEqual((int)TDBBinaryType,   (int)tightdb::type_Binary, @"Binary");
    XCTAssertEqual((int)TDBDateType,     (int)tightdb::type_DateTime,@"Date");
    XCTAssertEqual((int)TDBTableType,    (int)tightdb::type_Table,  @"Table");
    XCTAssertEqual((int)TDBMixedType,    (int)tightdb::type_Mixed,  @"Mixed");
}

@end
