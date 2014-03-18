//
//  data_type.mm
//  TightDB
//
// Check that data type enumeration values are in synch with the core library
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/type.h>
#import <tightdb/data_type.hpp>

@interface TestDataType: SenTestCase
@end
@implementation TestDataType

- (void)testDataType
{
    STAssertEquals((int)TDBBoolType,     (int)tightdb::type_Bool,   @"Bool");
    STAssertEquals((int)TDBIntType,      (int)tightdb::type_Int,    @"Int");
    STAssertEquals((int)TDBFloatType,    (int)tightdb::type_Float,  @"Float");
    STAssertEquals((int)TDBDoubleType,   (int)tightdb::type_Double, @"Double");
    STAssertEquals((int)TDBStringType,   (int)tightdb::type_String, @"String");
    STAssertEquals((int)TDBBinaryType,   (int)tightdb::type_Binary, @"Binary");
    STAssertEquals((int)TDBDateType,     (int)tightdb::type_DateTime,@"Date");
    STAssertEquals((int)TDBTableType,    (int)tightdb::type_Table,  @"Table");
    STAssertEquals((int)TDBMixedType,    (int)tightdb::type_Mixed,  @"Mixed");
}

@end
