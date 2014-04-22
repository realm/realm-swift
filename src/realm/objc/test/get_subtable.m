//
//  get_subtable.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>
#import <realm/objc/RLMContext.h>

REALM_TABLE_2(GetSubtable,
                Hired, Bool,
                Age,   Int)

REALM_TABLE_2(WrongNameTable,
                HiredFor, Bool,
                Ageing,   Int)


REALM_TABLE_2(WrongTypeTable,
                Hired, Int,
                Age,   Bool)


@interface MACTestGetSubtable: XCTestCase
@end
@implementation MACTestGetSubtable

- (void)testGetSubtable
{
    // Create table with all column types
    RLMTable* table = [[RLMTable alloc] init];
    RLMDescriptor * desc = table.descriptor;
    [desc addColumnWithName:@"Outer" type:RLMTypeBool];
    [desc addColumnWithName:@"Number" type:RLMTypeInt];
    RLMDescriptor * subdesc = [desc addColumnTable:@"GetSubtable"];
    [subdesc addColumnWithName:@"Hired" type:RLMTypeBool];
    [subdesc addColumnWithName:@"Age" type:RLMTypeInt];

    [table RLM_insertBool:0 ndx:0 value:NO];
    [table RLM_insertInt:1 ndx:0 value:10];
    [table RLM_insertSubtable:2 ndx:0];
    [table RLM_insertDone];

    RLMTable* subtable = [table RLM_tableInColumnWithIndex:2 atRowIndex:0];
    [subtable RLM_insertBool:0 ndx:0 value:YES];
    [subtable RLM_insertInt:1 ndx:0 value:42];
    [subtable RLM_insertDone];

    GetSubtable* testTable = [table RLM_tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[GetSubtable class]];
    GetSubtableRow* cursor = [testTable rowAtIndex:0];
    NSLog(@"Age in subtable: %lld", cursor.Age);
    XCTAssertEqual(cursor.Age, (int64_t)42, @"Sub table row should be 42");

    XCTAssertNil([table RLM_tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongNameTable class]], @"should return nil because wrong name");
    XCTAssertNil([table RLM_tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongTypeTable class]], @"should return nil because wrong type");
}


@end



