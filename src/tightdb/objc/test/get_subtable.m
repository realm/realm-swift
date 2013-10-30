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
    TightdbTable *table = [[TightdbTable alloc] init];
    TightdbSpec *s = [table getSpec];
    [s addColumnWithType:tightdb_Bool andName:@"Outer"];
    [s addColumnWithType:tightdb_Int andName:@"Number"];
    TightdbSpec *sub = [s addColumnTable:@"GetSubtable"];
    [sub addColumnWithType:tightdb_Bool andName:@"Hired"];
    [sub addColumnWithType:tightdb_Int andName:@"Age"];
    [table updateFromSpec];

    [table insertBool:0 ndx:0 value:NO];
    [table insertInt:1 ndx:0 value:10];
    [table insertSubtable:2 ndx:0];
    [table insertDone];

    TightdbTable *subtable = [table getTableInColumn:2 atRow:0];
    [subtable insertBool:0 ndx:0 value:YES];
    [subtable insertInt:1 ndx:0 value:42];
    [subtable insertDone];

    GetSubtable *testTable = [table getTableInColumn:2 atRow:0 withClass:[GetSubtable class]];
    GetSubtable_Cursor *cursor = [testTable cursorAtIndex:0];
    NSLog(@"Age in subtable: %lld", cursor.Age);
    STAssertEquals(cursor.Age, (int64_t)42, @"Sub table row should be 42");

    STAssertNil([table getTableInColumn:2 atRow:0 withClass:[WrongNameTable class]], @"should return nil because wrong name");
    STAssertNil([table getTableInColumn:2 atRow:0 withClass:[WrongTypeTable class]], @"should return nil because wrong type");
}


@end



