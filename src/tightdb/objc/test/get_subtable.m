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
    [s addColumn:tightdb_Bool name:@"Outer"];
    [s addColumn:tightdb_Int name:@"Number"];
NSLog(@"Hest-1");
    TightdbSpec *sub = [s addColumnTable:@"GetSubtable"];
    [sub addColumn:tightdb_Bool name:@"Hired"];
    [sub addColumn:tightdb_Int name:@"Age"];
    [table updateFromSpec];

NSLog(@"Hest-2");
    [table insertBool:0 ndx:0 value:NO];
    [table insertInt:1 ndx:0 value:10];
    [table insertSubtable:2 ndx:0];
    [table insertDone];

NSLog(@"Hest-3");
    TightdbTable *subtable = [table getSubtable:2 ndx:0];
    [subtable insertBool:0 ndx:0 value:YES];
    [subtable insertInt:1 ndx:0 value:42];
    [subtable insertDone];

NSLog(@"Hest-4");
    GetSubtable *testTable = [table getSubtable:2 ndx:0 withClass:[GetSubtable class]];
NSLog(@"Hest-5");
    GetSubtable_Cursor *cursor = [testTable objectAtIndex:0];
NSLog(@"Hest-6");
    NSLog(@"Age in subtable: %lld", cursor.Age);
NSLog(@"Hest-7");
    STAssertEquals(cursor.Age, (int64_t)42, @"Sub table row should be 42");

    STAssertNil([table getSubtable:2 ndx:0 withClass:[WrongNameTable class]], @"should return nil because wrong name");
    STAssertNil([table getSubtable:2 ndx:0 withClass:[WrongTypeTable class]], @"should return nil because wrong type");
}


@end



