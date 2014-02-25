//
//  mixed.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#include <time.h>
#include <string.h>

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/group_shared.h>

TIGHTDB_TABLE_3(MixedTable,
                Hired, Bool,
                Other, Mixed,
                Age,   Int)

TIGHTDB_TABLE_2(SubMixedTable,
                Hired, Bool,
                Age,   Int)


@interface MACTestMixed: SenTestCase
@end
@implementation MACTestMixed

- (void)testMixedEqual
{
    time_t nowTime = [[NSDate date] timeIntervalSince1970];

    TightdbMixed *mixedBool1 = [TightdbMixed mixedWithBool:YES];
    TightdbMixed *mixedBool2 = [TightdbMixed mixedWithBool:NO];
    TightdbMixed *mixedBool3 = [TightdbMixed mixedWithBool:NO];
    STAssertEquals([mixedBool1 isEqual:mixedBool1], YES, @"Same mixed should be equal (1)");
    STAssertEquals([mixedBool2 isEqual:mixedBool2], YES, @"Same mixed should be equal (2)");
    STAssertEquals([mixedBool2 isEqual:mixedBool3], YES,  @"Mixed with same bools should be equal");
    STAssertEquals([mixedBool1 isEqual:mixedBool2], NO,  @"Mixed with different bools should be different");

    TightdbMixed *mixedInt1 = [TightdbMixed mixedWithInt64:10001];
    TightdbMixed *mixedInt2 = [TightdbMixed mixedWithInt64:20002];
    TightdbMixed *mixedInt3 = [TightdbMixed mixedWithInt64:20002];
    STAssertEquals([mixedInt1 isEqual:mixedInt1], YES, @"Same mixed should be equal (3)");
    STAssertEquals([mixedInt2 isEqual:mixedInt2], YES, @"Same mixed should be equal (4)");
    STAssertEquals([mixedInt2 isEqual:mixedInt3], YES, @"Mixed with same ints should be equal");
    STAssertEquals([mixedInt1 isEqual:mixedInt2], NO,  @"Mixed with different ints should be different");

    TightdbMixed *mixedString1 = [TightdbMixed mixedWithString:@"Hello"];
    TightdbMixed *mixedString2 = [TightdbMixed mixedWithString:@"Goodbye"];
    TightdbMixed *mixedString3 = [TightdbMixed mixedWithString:@"Goodbye"];
    STAssertEquals([mixedString1 isEqual:mixedString1], YES, @"Same mixed should be equal (5)");
    STAssertEquals([mixedString2 isEqual:mixedString2], YES, @"Same mixed should be equal (6)");
    STAssertEquals([mixedString2 isEqual:mixedString3], YES, @"Mixed with same strings should be equal");
    STAssertEquals([mixedString1 isEqual:mixedString2], NO,  @"Mixed with different strings should be different");

    const char* str1 = "Hello";
    const char* str2 = "Goodbye";
    TightdbMixed *mixedBinary1 = [TightdbMixed mixedWithBinary:str1 size:strlen(str1)];
    TightdbMixed *mixedBinary2 = [TightdbMixed mixedWithBinary:str2 size:strlen(str2)];
    TightdbMixed *mixedBinary3 = [TightdbMixed mixedWithBinary:str2 size:strlen(str2)];
    STAssertEquals([mixedBinary1 isEqual:mixedBinary1], YES, @"Same mixed should be equal (7)");
    STAssertEquals([mixedBinary2 isEqual:mixedBinary2], YES, @"Same mixed should be equal (8)");
    STAssertEquals([mixedBinary2 isEqual:mixedBinary3], YES, @"Mixed with same binary data should be equal");
    STAssertEquals([mixedBinary1 isEqual:mixedBinary2], NO,  @"Mixed with different binary data should be different");

    TightdbMixed *mixedDate1 = [TightdbMixed mixedWithDate:nowTime];
    TightdbMixed *mixedDate2 = [TightdbMixed mixedWithDate:nowTime+1];
    TightdbMixed *mixedDate3 = [TightdbMixed mixedWithDate:nowTime+1];
    STAssertEquals([mixedDate1 isEqual:mixedDate1], YES, @"Same mixed should be equal (9)");
    STAssertEquals([mixedDate2 isEqual:mixedDate2], YES, @"Same mixed should be equal (10)");
    STAssertEquals([mixedDate2 isEqual:mixedDate3], YES, @"Mixed with same timestamps should be equal");
    STAssertEquals([mixedDate1 isEqual:mixedDate2], NO,  @"Mixed with different timestamps should be different");

    MixedTable    *table1 = [[MixedTable    alloc] init];
    SubMixedTable *table2 = [[SubMixedTable alloc] init];
    SubMixedTable *table3 = [[SubMixedTable alloc] init];
    [table1 addHired:YES Other:mixedBool1 Age:54];
    [table2 addHired:YES                  Age:54];
    [table3 addHired:YES                  Age:54];
    TightdbMixed *mixedTable1 = [TightdbMixed mixedWithTable:table1];
    TightdbMixed *mixedTable2 = [TightdbMixed mixedWithTable:table2];
    TightdbMixed *mixedTable3 = [TightdbMixed mixedWithTable:table3];
    STAssertEquals([mixedTable1 isEqual:mixedTable1], YES, @"Same mixed should be equal (11)");
    STAssertEquals([mixedTable2 isEqual:mixedTable2], YES, @"Same mixed should be equal (12)");
    STAssertEquals([mixedTable2 isEqual:mixedTable3], YES, @"Mixed with same tables should be equal");
    STAssertEquals([mixedTable1 isEqual:mixedTable2], NO,  @"Mixed with different tables should be different");


    STAssertEquals([mixedBool1 isEqual:mixedInt1],    NO, @"Mixed with different types should be different (1)");
    STAssertEquals([mixedBool1 isEqual:mixedString1], NO, @"Mixed with different types should be different (2)");
    STAssertEquals([mixedBool1 isEqual:mixedBinary1], NO, @"Mixed with different types should be different (3)");
    STAssertEquals([mixedBool1 isEqual:mixedDate1],   NO, @"Mixed with different types should be different (4)");
    STAssertEquals([mixedBool1 isEqual:mixedTable1],  NO, @"Mixed with different types should be different (5)");

    STAssertEquals([mixedInt1 isEqual:mixedBool1],   NO, @"Mixed with different types should be different (6)");
    STAssertEquals([mixedInt1 isEqual:mixedString1], NO, @"Mixed with different types should be different (7)");
    STAssertEquals([mixedInt1 isEqual:mixedBinary1], NO, @"Mixed with different types should be different (8)");
    STAssertEquals([mixedInt1 isEqual:mixedDate1],   NO, @"Mixed with different types should be different (9)");
    STAssertEquals([mixedInt1 isEqual:mixedTable1],  NO, @"Mixed with different types should be different (10)");

    STAssertEquals([mixedString1 isEqual:mixedBool1],   NO, @"Mixed with different types should be different (11)");
    STAssertEquals([mixedString1 isEqual:mixedInt1],    NO, @"Mixed with different types should be different (12)");
    STAssertEquals([mixedString1 isEqual:mixedBinary1], NO, @"Mixed with different types should be different (13)");
    STAssertEquals([mixedString1 isEqual:mixedDate1],   NO, @"Mixed with different types should be different (14)");
    STAssertEquals([mixedString1 isEqual:mixedTable1],  NO, @"Mixed with different types should be different (15)");

    STAssertEquals([mixedBinary1 isEqual:mixedBool1],   NO, @"Mixed with different types should be different (16)");
    STAssertEquals([mixedBinary1 isEqual:mixedInt1],    NO, @"Mixed with different types should be different (17)");
    STAssertEquals([mixedBinary1 isEqual:mixedString1], NO, @"Mixed with different types should be different (18)");
    STAssertEquals([mixedBinary1 isEqual:mixedDate1],   NO, @"Mixed with different types should be different (19)");
    STAssertEquals([mixedBinary1 isEqual:mixedTable1],  NO, @"Mixed with different types should be different (20)");

    STAssertEquals([mixedDate1 isEqual:mixedBool1],   NO, @"Mixed with different types should be different (21)");
    STAssertEquals([mixedDate1 isEqual:mixedInt1],    NO, @"Mixed with different types should be different (22)");
    STAssertEquals([mixedDate1 isEqual:mixedString1], NO, @"Mixed with different types should be different (23)");
    STAssertEquals([mixedDate1 isEqual:mixedBinary1], NO, @"Mixed with different types should be different (24)");
    STAssertEquals([mixedDate1 isEqual:mixedTable1],  NO, @"Mixed with different types should be different (25)");

    STAssertEquals([mixedTable1 isEqual:mixedBool1],   NO, @"Mixed with different types should be different (26)");
    STAssertEquals([mixedTable1 isEqual:mixedInt1],    NO, @"Mixed with different types should be different (27)");
    STAssertEquals([mixedTable1 isEqual:mixedString1], NO, @"Mixed with different types should be different (28)");
    STAssertEquals([mixedTable1 isEqual:mixedBinary1], NO, @"Mixed with different types should be different (29)");
    STAssertEquals([mixedTable1 isEqual:mixedDate1],   NO, @"Mixed with different types should be different (30)");
}


- (void)testMixed
{
    time_t nowTime = [[NSDate date] timeIntervalSince1970];

    SubMixedTable *tableSub = [[SubMixedTable alloc] init];

    // Add some rows
    [tableSub addHired:YES Age:20];
    [tableSub addHired:NO Age:21];
    [tableSub addHired:YES Age:22];
    [tableSub addHired:NO Age:43];
    [tableSub addHired:YES Age:54];

    TightdbGroup *group = [TightdbGroup group];
    // Create new table in group
    MixedTable *table = [group getTable:@"MixedValues" withClass:[MixedTable class] error:nil];
    NSLog(@"Table: %@", table);
    // Add some rows
    TightdbMixed *mixedTable = [TightdbMixed mixedWithTable:tableSub];
    [table addHired:YES Other:[TightdbMixed mixedWithString:@"Jens"] Age:50];
    [table addHired:YES Other:[TightdbMixed mixedWithString:@"Aage"] Age:52];
    [table addHired:YES Other:[TightdbMixed mixedWithString:@"Joergen"] Age:53];
    [table addHired:YES Other:[TightdbMixed mixedWithString:@"Dave"] Age:54];
    [table addHired:YES Other:mixedTable Age:54];
    TightdbMixed *mixedDate = [TightdbMixed mixedWithDate:nowTime];
    [table addHired:YES Other:mixedDate Age:54];

    // Test isequal
    TightdbMixed *mixedDate2 = [TightdbMixed mixedWithDate:nowTime];
    TightdbMixed *mixedDate3 = [TightdbMixed mixedWithDate:nowTime+1];
    STAssertEquals([mixedDate isEqual:mixedDate2], YES,@"Mixed dates should be equal");
    STAssertEquals([mixedDate isEqual:mixedDate3], NO,@"Mixed dates should not be equal");

    // Test cast and isClass
    TightdbTable *unknownTable = [mixedTable getTable];
    NSLog(@"Is SubMixedTable type: %i", [unknownTable isClass:[SubMixedTable class]]);
    STAssertEquals([unknownTable isClass:[SubMixedTable class]], YES,@"Unknown table should be of type SubMixedTable");
    tableSub = [unknownTable castClass:[SubMixedTable class]];
    NSLog(@"TableSub Size: %lu", [tableSub count]);
    STAssertEquals([tableSub count], (size_t)5,@"Subtable should have 5 rows");
    NSLog(@"Count int: %lu", [table countWithIntColumn:2 andValue:50]);
    NSLog(@"Max: %lld", [table maximumWithIntColumn:2]);
    NSLog(@"Avg: %.2f", [table averageWithIntColumn:2]);

    NSLog(@"MyTable Size: %lu", [table count]);
    int sumType = 0;
    for (size_t i = 0; i < [table count]; i++) {
        MixedTable_Cursor *cursor = [table cursorAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Other);
        NSLog(@"Type: %i", [cursor.Other getType] );
        sumType += [cursor.Other getType];
        if ([cursor.Other getType] == tightdb_String)
            NSLog(@"StringMixed: %@", [cursor.Other getString]);
        else if ([cursor.Other getType] == tightdb_Date) {
            NSLog(@"DateMixed: %ld", [cursor.Other getDate]);
            STAssertEquals(nowTime, [cursor.Other getDate],@"Date should match what went in");
        }
        else if ([cursor.Other getType] == tightdb_Table) {
            NSLog(@"TableMixed: %@", [cursor.Other getTable]);
        }
    }
    // 7 + 2 + 2 + 2 + 2
    STAssertEquals(sumType, 20,@"Sum of mixed types should be 20");
}


@end
