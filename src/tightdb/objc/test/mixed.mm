//
//  mixed.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#include <time.h>
#include <string.h>

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/Tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/TDBTable_priv.h>

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

    NSNumber *mixedBool1 = [NSNumber numberWithBool:YES];
    NSNumber *mixedBool2 = [NSNumber numberWithBool:NO];
    NSNumber *mixedBool3 = [NSNumber numberWithBool:NO];
    STAssertEquals([mixedBool1 isEqual:mixedBool1], YES, @"Same mixed should be equal (1)");
    STAssertEquals([mixedBool2 isEqual:mixedBool2], YES, @"Same mixed should be equal (2)");
    STAssertEquals([mixedBool2 isEqual:mixedBool3], YES,  @"Mixed with same bools should be equal");
    STAssertEquals([mixedBool1 isEqual:mixedBool2], NO,  @"Mixed with different bools should be different");

    NSNumber *mixedInt1 = [NSNumber numberWithLongLong:10001];
    NSNumber *mixedInt2 = [NSNumber numberWithLongLong:20002];
    NSNumber *mixedInt3 = [NSNumber numberWithLongLong:20002];
    STAssertEquals([mixedInt1 isEqual:mixedInt1], YES, @"Same mixed should be equal (3)");
    STAssertEquals([mixedInt2 isEqual:mixedInt2], YES, @"Same mixed should be equal (4)");
    STAssertEquals([mixedInt2 isEqual:mixedInt3], YES, @"Mixed with same ints should be equal");
    STAssertEquals([mixedInt1 isEqual:mixedInt2], NO,  @"Mixed with different ints should be different");

    NSString *mixedString1 = [NSString stringWithUTF8String:"Hello"];
    NSString *mixedString2 = [NSString stringWithUTF8String:"Goodbye"];
    NSString *mixedString3 = [NSString stringWithUTF8String:"Goodbye"];
    STAssertEquals([mixedString1 isEqual:mixedString1], YES, @"Same mixed should be equal (5)");
    STAssertEquals([mixedString2 isEqual:mixedString2], YES, @"Same mixed should be equal (6)");
    STAssertEquals([mixedString2 isEqual:mixedString3], YES, @"Mixed with same strings should be equal");
    STAssertEquals([mixedString1 isEqual:mixedString2], NO,  @"Mixed with different strings should be different");

    const char* str1 = "Hello";
    const char* str2 = "Goodbye";
    NSData *mixedBinary1 = [NSData dataWithBytes:(const void *)str1 length:strlen(str1)];
    NSData *mixedBinary2 = [NSData dataWithBytes:(const void *)str2 length:strlen(str2)];
    NSData *mixedBinary3 = [NSData dataWithBytes:(const void *)str2 length:strlen(str2)];
    STAssertEquals([mixedBinary1 isEqual:mixedBinary1], YES, @"Same mixed should be equal (7)");
    STAssertEquals([mixedBinary2 isEqual:mixedBinary2], YES, @"Same mixed should be equal (8)");
    STAssertEquals([mixedBinary2 isEqual:mixedBinary3], YES, @"Mixed with same binary data should be equal");
    STAssertEquals([mixedBinary1 isEqual:mixedBinary2], NO,  @"Mixed with different binary data should be different");

    NSDate *mixedDate1 = nowTime;
    NSDate *mixedDate2 = nowTime1;
    NSDate *mixedDate3 = nowTime1;
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
    TDBTable *mixedTable1 = table1;
    TDBTable *mixedTable2 = table2;
    TDBTable *mixedTable3 = table3;
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

//    STAssertEquals([mixedTable1 isEqual:mixedBool1],   NO, @"Mixed with different types should be different (26)");
//    STAssertEquals([mixedTable1 isEqual:mixedInt1],    NO, @"Mixed with different types should be different (27)");
//    STAssertEquals([mixedTable1 isEqual:mixedString1], NO, @"Mixed with different types should be different (28)");
//    STAssertEquals([mixedTable1 isEqual:mixedBinary1], NO, @"Mixed with different types should be different (29)");
//    STAssertEquals([mixedTable1 isEqual:mixedDate1],   NO, @"Mixed with different types should be different (30)");
}


- (void)testMixed
{
    NSDate *nowTime = [NSDate date];

    SubMixedTable *tableSub = [[SubMixedTable alloc] init];

    // Add some rows
    [tableSub addHired:YES Age:20];
    [tableSub addHired:NO Age:21];
    [tableSub addHired:YES Age:22];
    [tableSub addHired:NO Age:43];
    [tableSub addHired:YES Age:54];

    TDBTransaction *group = [TDBTransaction group];
    // Create new table in group
    MixedTable *table = [group createTableWithName:@"MixedValues" asTableClass:[MixedTable class]];
    NSLog(@"Table: %@", table);
    // Add some rows
 //   TDBMixed *mixedTable = [TDBMixed mixedWithTable:tableSub];
    [table addHired:YES Other:[NSString stringWithUTF8String:"Jens"] Age:50];
    [table addHired:YES Other:[NSString stringWithUTF8String:"Aage"] Age:52];
    [table addHired:YES Other:[NSString stringWithUTF8String:"Joergen"] Age:53];
    [table addHired:YES Other:[NSString stringWithUTF8String:"Dave"] Age:54];
    [table addHired:YES Other:tableSub Age:54];
    NSDate *mixedDate = [NSDate date];
    [table addHired:YES Other:mixedDate Age:54];

    // Test cast and isClass
    //TDBTable *unknownTable = [mixedTable getTable];
    NSLog(@"Is SubMixedTable type: %i", [tableSub hasSameDescriptorAs:[SubMixedTable class]]);
    STAssertEquals([tableSub hasSameDescriptorAs:[SubMixedTable class]], YES,@"Unknown table should be of type SubMixedTable");
    tableSub = [tableSub castClass:[SubMixedTable class]];
    NSLog(@"TableSub Size: %lu", [tableSub rowCount]);
    STAssertEquals([tableSub rowCount], (size_t)5,@"Subtable should have 5 rows");
    NSLog(@"Count int: %lu", [table countRowsWithInt:50 inColumnWithIndex:2]);
    NSLog(@"Max: %lld", [table maxIntInColumnWithIndex:2]);
    NSLog(@"Avg: %.2f", [table avgIntColumnWithIndex:2]);

    NSLog(@"MyTable Size: %lu", [table rowCount]);
    for (size_t i = 0; i < [table rowCount]; i++) {
        MixedTableRow *cursor = [table rowAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Other);
        if ([cursor.Other isKindOfClass:[NSDate class]]) {
            STAssertEqualsWithAccuracy([(NSDate *)cursor.Other timeIntervalSince1970], [nowTime timeIntervalSince1970], 0.999, @"Date should almost match what went in");
        }
    }

}


@end
