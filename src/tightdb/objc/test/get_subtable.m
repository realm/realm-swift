//
//  get_subtable.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/group_shared.h>

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
    TightdbTable* table = [[TightdbTable alloc] init];
    TightdbDescriptor* desc = table.descriptor;
    [desc addColumnWithType:tightdb_Bool andName:@"Outer"];
    [desc addColumnWithType:tightdb_Int andName:@"Number"];
    TightdbDescriptor* subdesc = [desc addColumnTable:@"GetSubtable"];
    [subdesc addColumnWithType:tightdb_Bool andName:@"Hired"];
    [subdesc addColumnWithType:tightdb_Int andName:@"Age"];

    [table TDBInsertBool:0 ndx:0 value:NO];
    [table TDBInsertInt:1 ndx:0 value:10];
    [table TDBInsertSubtable:2 ndx:0];
    [table TDBInsertDone];

    TightdbTable* subtable = [table tableInColumnWithIndex:2 atRowIndex:0];
    [subtable TDBInsertBool:0 ndx:0 value:YES];
    [subtable TDBInsertInt:1 ndx:0 value:42];
    [subtable TDBInsertDone];

    GetSubtable* testTable = [table tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[GetSubtable class]];
    GetSubtable_Cursor* cursor = [testTable cursorAtIndex:0];
    NSLog(@"Age in subtable: %lld", cursor.Age);
    STAssertEquals(cursor.Age, (int64_t)42, @"Sub table row should be 42");

    STAssertNil([table tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongNameTable class]], @"should return nil because wrong name");
    STAssertNil([table tableInColumnWithIndex:2 atRowIndex:0 asTableClass:[WrongTypeTable class]], @"should return nil because wrong type");
}


@end



