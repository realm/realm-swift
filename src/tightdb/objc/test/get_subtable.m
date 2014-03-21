//
//  get_subtable.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

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


@interface MACTestGetSubtable: SenTestCase
@end
@implementation MACTestGetSubtable

- (void)testGetSubtable
{
    // Create table with all column types
    TDBTable* table = [[TDBTable alloc] init];
    TDBDescriptor* desc = table.descriptor;
    [desc addColumnWithName:@"Outer" andType:TDBBoolType];
    [desc addColumnWithName:@"Number" andType:TDBIntType];
    TDBDescriptor* subdesc = [desc addColumnTable:@"GetSubtable"];
    [subdesc addColumnWithName:@"Hired" andType:TDBBoolType];
    [subdesc addColumnWithName:@"Age" andType:TDBIntType];

    [table TDBInsertBool:0 ndx:0 value:NO];
    [table TDBInsertInt:1 ndx:0 value:10];
    [table TDBInsertSubtable:2 ndx:0];
    [table TDBInsertDone];

    TDBTable* subtable = [table tableInColumnWithIndex:2 atRowIndex:0];
    [subtable TDBInsertBool:0 ndx:0 value:YES];
    [subtable TDBInsertInt:1 ndx:0 value:42];
    [subtable TDBInsertDone];

    GetSubtable* testTable = [table tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[GetSubtable class]];
    GetSubtableRow* cursor = [testTable rowAtIndex:0];
    NSLog(@"Age in subtable: %lld", cursor.Age);
    STAssertEquals(cursor.Age, (int64_t)42, @"Sub table row should be 42");

    STAssertNil([table tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongNameTable class]], @"should return nil because wrong name");
    STAssertNil([table tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongTypeTable class]], @"should return nil because wrong type");
}


@end



