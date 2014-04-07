//
//  get_subtable.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <XCTest/XCTest.h>

#import <tightdb/objc/Tightdb.h>
#import <tightdb/objc/TDBTransaction.h>
#import <tightdb/objc/TDBContext.h>

TIGHTDB_TABLE_2(GetSubtable,
                Hired, Bool,
                Age,   Int)

TIGHTDB_TABLE_2(WrongNameTable,
                HiredFor, Bool,
                Ageing,   Int)


TIGHTDB_TABLE_2(WrongTypeTable,
                Hired, Int,
                Age,   Bool)


@interface MACTestGetSubtable: XCTestCase
@end
@implementation MACTestGetSubtable

- (void)testGetSubtable
{
    // Create table with all column types
    TDBTable* table = [[TDBTable alloc] init];
    TDBDescriptor* desc = table.descriptor;
    [desc addColumnWithName:@"Outer" type:TDBBoolType];
    [desc addColumnWithName:@"Number" type:TDBIntType];
    TDBDescriptor* subdesc = [desc addColumnTable:@"GetSubtable"];
    [subdesc addColumnWithName:@"Hired" type:TDBBoolType];
    [subdesc addColumnWithName:@"Age" type:TDBIntType];

    [table TDB_insertBool:0 ndx:0 value:NO];
    [table TDB_insertInt:1 ndx:0 value:10];
    [table TDB_insertSubtable:2 ndx:0];
    [table TDB_insertDone];

    TDBTable* subtable = [table TDB_tableInColumnWithIndex:2 atRowIndex:0];
    [subtable TDB_insertBool:0 ndx:0 value:YES];
    [subtable TDB_insertInt:1 ndx:0 value:42];
    [subtable TDB_insertDone];

    GetSubtable* testTable = [table TDB_tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[GetSubtable class]];
    GetSubtableRow* cursor = [testTable rowAtIndex:0];
    NSLog(@"Age in subtable: %lld", cursor.Age);
    XCTAssertEqual(cursor.Age, (int64_t)42, @"Sub table row should be 42");

    XCTAssertNil([table TDB_tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongNameTable class]], @"should return nil because wrong name");
    XCTAssertNil([table TDB_tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongTypeTable class]], @"should return nil because wrong type");
}


@end



