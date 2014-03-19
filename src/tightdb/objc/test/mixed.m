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
#import <tightdb/objc/transaction.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/context.h>

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
    NSDate *nowTime = [NSDate date];
    NSDate *nowTime1 = [[NSDate date] dateByAddingTimeInterval:1];

    TDBMixed *mixedBool1 = [TDBMixed mixedWithBool:YES];
    TDBMixed *mixedBool2 = [TDBMixed mixedWithBool:NO];
    TDBMixed *mixedBool3 = [TDBMixed mixedWithBool:NO];
    STAssertEquals([mixedBool1 isEqual:mixedBool1], YES, @"Same mixed should be equal (1)");
    STAssertEquals([mixedBool2 isEqual:mixedBool2], YES, @"Same mixed should be equal (2)");
    STAssertEquals([mixedBool2 isEqual:mixedBool3], YES,  @"Mixed with same bools should be equal");
    STAssertEquals([mixedBool1 isEqual:mixedBool2], NO,  @"Mixed with different bools should be different");

    TDBMixed *mixedInt1 = [TDBMixed mixedWithInt64:10001];
    TDBMixed *mixedInt2 = [TDBMixed mixedWithInt64:20002];
    TDBMixed *mixedInt3 = [TDBMixed mixedWithInt64:20002];
    STAssertEquals([mixedInt1 isEqual:mixedInt1], YES, @"Same mixed should be equal (3)");
    STAssertEquals([mixedInt2 isEqual:mixedInt2], YES, @"Same mixed should be equal (4)");
    STAssertEquals([mixedInt2 isEqual:mixedInt3], YES, @"Mixed with same ints should be equal");
    STAssertEquals([mixedInt1 isEqual:mixedInt2], NO,  @"Mixed with different ints should be different");

    TDBMixed *mixedString1 = [TDBMixed mixedWithString:@"Hello"];
    TDBMixed *mixedString2 = [TDBMixed mixedWithString:@"Goodbye"];
    TDBMixed *mixedString3 = [TDBMixed mixedWithString:@"Goodbye"];
    STAssertEquals([mixedString1 isEqual:mixedString1], YES, @"Same mixed should be equal (5)");
    STAssertEquals([mixedString2 isEqual:mixedString2], YES, @"Same mixed should be equal (6)");
    STAssertEquals([mixedString2 isEqual:mixedString3], YES, @"Mixed with same strings should be equal");
    STAssertEquals([mixedString1 isEqual:mixedString2], NO,  @"Mixed with different strings should be different");

    const char* str1 = "Hello";
    const char* str2 = "Goodbye";
    TDBMixed *mixedBinary1 = [TDBMixed mixedWithBinary:str1 size:strlen(str1)];
    TDBMixed *mixedBinary2 = [TDBMixed mixedWithBinary:str2 size:strlen(str2)];
    TDBMixed *mixedBinary3 = [TDBMixed mixedWithBinary:str2 size:strlen(str2)];
    STAssertEquals([mixedBinary1 isEqual:mixedBinary1], YES, @"Same mixed should be equal (7)");
    STAssertEquals([mixedBinary2 isEqual:mixedBinary2], YES, @"Same mixed should be equal (8)");
    STAssertEquals([mixedBinary2 isEqual:mixedBinary3], YES, @"Mixed with same binary data should be equal");
    STAssertEquals([mixedBinary1 isEqual:mixedBinary2], NO,  @"Mixed with different binary data should be different");

    TDBMixed *mixedDate1 = [TDBMixed mixedWithDate:nowTime];
    TDBMixed *mixedDate2 = [TDBMixed mixedWithDate:nowTime1];
    TDBMixed *mixedDate3 = [TDBMixed mixedWithDate:nowTime1];
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
    TDBMixed *mixedTable1 = [TDBMixed mixedWithTable:table1];
    TDBMixed *mixedTable2 = [TDBMixed mixedWithTable:table2];
    TDBMixed *mixedTable3 = [TDBMixed mixedWithTable:table3];
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
    NSDate *nowTime = [NSDate date];
    NSDate *nowTime1 = [[NSDate date] dateByAddingTimeInterval:1];

    SubMixedTable *tableSub = [[SubMixedTable alloc] init];

    // Add some rows
    [tableSub addHired:YES Age:20];
    [tableSub addHired:NO Age:21];
    [tableSub addHired:YES Age:22];
    [tableSub addHired:NO Age:43];
    [tableSub addHired:YES Age:54];

    TDBTransaction *group = [TDBTransaction group];
    // Create new table in group
    MixedTable *table = [group getOrCreateTableWithName:@"MixedValues" asTableClass:[MixedTable class]];
    NSLog(@"Table: %@", table);
    // Add some rows
    TDBMixed *mixedTable = [TDBMixed mixedWithTable:tableSub];
    [table addHired:YES Other:[TDBMixed mixedWithString:@"Jens"] Age:50];
    [table addHired:YES Other:[TDBMixed mixedWithString:@"Aage"] Age:52];
    [table addHired:YES Other:[TDBMixed mixedWithString:@"Joergen"] Age:53];
    [table addHired:YES Other:[TDBMixed mixedWithString:@"Dave"] Age:54];
    [table addHired:YES Other:mixedTable Age:54];
    TDBMixed *mixedDate = [TDBMixed mixedWithDate:nowTime];
    [table addHired:YES Other:mixedDate Age:54];

    // Test isequal
    TDBMixed *mixedDate2 = [TDBMixed mixedWithDate:nowTime];
    TDBMixed *mixedDate3 = [TDBMixed mixedWithDate:nowTime1];
    STAssertEquals([mixedDate isEqual:mixedDate2], YES,@"Mixed dates should be equal");
    STAssertEquals([mixedDate isEqual:mixedDate3], NO,@"Mixed dates should not be equal");

    // Test cast and isClass
    TDBTable *unknownTable = [mixedTable getTable];
    NSLog(@"Is SubMixedTable type: %i", [unknownTable hasSameDescriptorAs:[SubMixedTable class]]);
    STAssertEquals([unknownTable hasSameDescriptorAs:[SubMixedTable class]], YES,@"Unknown table should be of type SubMixedTable");
    tableSub = [unknownTable castClass:[SubMixedTable class]];
    NSLog(@"TableSub Size: %lu", [tableSub rowCount]);
    STAssertEquals([tableSub rowCount], (size_t)5,@"Subtable should have 5 rows");
    NSLog(@"Count int: %lu", [table countRowsWithInt:50 inColumnWithIndex:2]);
    NSLog(@"Max: %lld", [table maxIntInColumnWithIndex:2]);
    NSLog(@"Avg: %.2f", [table avgIntColumnWithIndex:2]);

    NSLog(@"MyTable Size: %lu", [table rowCount]);
    int sumType = 0;
    for (size_t i = 0; i < [table rowCount]; i++) {
        MixedTable_Row *cursor = [table rowAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Other);
        NSLog(@"Type: %i", [cursor.Other getType] );
        sumType += [cursor.Other getType];
        if ([cursor.Other getType] == TDBStringType)
            NSLog(@"StringMixed: %@", [cursor.Other getString]);
        else if ([cursor.Other getType] == TDBDateType) {
            NSLog(@"DateMixed: %@", [cursor.Other getDate]);
            // STAssertEqualObjects(nowTime, [cursor.Other getDate],@"Date should match what went in");
        }
        else if ([cursor.Other getType] == TDBTableType) {
            NSLog(@"TableMixed: %@", [cursor.Other getTable]);
        }
    }
    // 7 + 2 + 2 + 2 + 2
    STAssertEquals(sumType, 20,@"Sum of mixed types should be 20");
}


@end
