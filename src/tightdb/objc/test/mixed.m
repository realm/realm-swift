//
//  mixed.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/group_shared.h>

TIGHTDB_TABLE_3(MixedTable,
                    Bool,   Hired,
                    Mixed, Other,
                    Int,    Age)

TIGHTDB_TABLE_2(SubMixedTable,
                    Bool,   Hired,
                    Int,    Age)


@interface MACTestMixed : SenTestCase
@end
@implementation MACTestMixed

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
    

    
    Group *group = [Group group];
    // Create new table in group
    MixedTable *table = [group getTable:@"MixedValues" withClass:[MixedTable class]];
    NSLog(@"Table: %@", table);
    // Add some rows
    OCMixed *mixedTable = [OCMixed mixedWithTable:tableSub];
    [table addHired:YES Other:[OCMixed mixedWithString:@"Jens"] Age:50];
    [table addHired:YES Other:[OCMixed mixedWithString:@"Aage"] Age:52];
    [table addHired:YES Other:[OCMixed mixedWithString:@"Joergen"] Age:53];
    [table addHired:YES Other:[OCMixed mixedWithString:@"Dave"] Age:54];
    [table addHired:YES Other:mixedTable Age:54];
    OCMixed *mixedDate = [OCMixed mixedWithDate:[[OCDate alloc] initWithDate:nowTime]];
    [table addHired:YES Other:mixedDate Age:54];
    
    // Test isequal
    OCMixed *mixedDate2 = [OCMixed mixedWithDate:[[OCDate alloc] initWithDate:nowTime]];
    OCMixed *mixedDate3 = [OCMixed mixedWithDate:[[OCDate alloc] initWithDate:nowTime+1]];
    STAssertEquals([mixedDate isEqual:mixedDate2], YES,@"Mixed dates should be equal");
    STAssertEquals([mixedDate isEqual:mixedDate3], NO,@"Mixed dates should not be equal");
    
    // Test cast and isClass
    Table *unknownTable = [mixedTable getTable];
    NSLog(@"Is SubMixedTable type: %i", [unknownTable isClass:[SubMixedTable class]]);
    STAssertEquals([unknownTable isClass:[SubMixedTable class]], YES,@"Unknown table should be of type SubMixedTable");
    tableSub = [unknownTable castClass:[SubMixedTable class]];
    NSLog(@"TableSub Size: %lu", [tableSub count]);
    STAssertEquals([tableSub count], (size_t)5,@"Subtable should have 5 rows");
    NSLog(@"Count int: %lu", [table countInt:2 target:50]);
    NSLog(@"Max: %lld", [table maximum:2]);
    NSLog(@"Avg: %.2f", [table average:2]);
    
    NSLog(@"MyTable Size: %lu", [table count]);
    int sumType = 0;
    for (size_t i = 0; i < [table count]; i++) {
        MixedTable_Cursor *cursor = [table objectAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Other);
        NSLog(@"Type: %i", [cursor.Other getType] );
        sumType += [cursor.Other getType];
        if ([cursor.Other getType] == COLUMN_TYPE_STRING)
            NSLog(@"StringMixed: %@", [cursor.Other getString]);
        else if ([cursor.Other getType] == COLUMN_TYPE_DATE) {
            NSLog(@"DateMixed: %ld", [[cursor.Other getDate] getDate]);
            STAssertEquals(nowTime, [[cursor.Other getDate] getDate],@"Date should match what went in");
        }
        else if ([cursor.Other getType] == COLUMN_TYPE_TABLE) {
            NSLog(@"TableMixed: %@", [cursor.Other getTable]);
        }
    }
    // 7 + 2 + 2 + 2 + 2
    STAssertEquals(sumType, 20,@"Sum of mixed types should be 20");
}


@end



