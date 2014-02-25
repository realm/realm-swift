//
//  table_delete_all.m
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/table.h>

@interface MACTestTableDeleteAll: SenTestCase
@end
@implementation MACTestTableDeleteAll

-(void)testTableDeleteAll
{
    // Create table with all column types
    TightdbTable* table = [[TightdbTable alloc] init];
    TightdbDescriptor* desc = [table getDescriptor];
    [desc addColumnWithType:tightdb_Int andName:@"int"];
    [desc addColumnWithType:tightdb_Bool andName:@"bool"];
    [desc addColumnWithType:tightdb_Date andName:@"date"];
    [desc addColumnWithType:tightdb_String andName:@"string"];
    [desc addColumnWithType:tightdb_String andName:@"string_long"];
    [desc addColumnWithType:tightdb_String andName:@"string_enum"];
    [desc addColumnWithType:tightdb_Binary andName:@"binary"];
    [desc addColumnWithType:tightdb_Mixed andName:@"mixed"];
    TightdbDescriptor* subdesc = [desc addColumnTable:@"tables"];
    [subdesc addColumnWithType:tightdb_Int andName:@"sub_first"];
    [subdesc addColumnWithType:tightdb_String andName:@"sub_second"];

    // Add some rows
    for (size_t i = 0; i < 15; ++i) {
        [table insertInt:0 ndx:i value:i];
        [table insertBool:1 ndx:i value:(i % 2 ? YES : NO)];
        [table insertDate:2 ndx:i value:12345];
        [table insertString:3 ndx:i value:[NSString stringWithFormat:@"string %zu", i]];
        [table insertString:4 ndx:i value:@" Very long string.............."];

        switch (i % 3) {
            case 0:
                [table insertString:5 ndx:i value:@"test1"];
                break;
            case 1:
                [table insertString:5 ndx:i value:@"test2"];
                break;
            case 2:
                [table insertString:5 ndx:i value:@"test3"];
                break;
        }

        [table insertBinary:6 ndx:i data:"binary" size:7];
        switch (i % 3) {
            case 0:
                [table insertMixed:7 ndx:i value:[TightdbMixed mixedWithBool:NO]];
                break;
            case 1:
                [table insertMixed:7 ndx:i value:[TightdbMixed mixedWithInt64:i]];
                break;
            case 2:
                [table insertMixed:7 ndx:i value:[TightdbMixed mixedWithString:@"string"]];
                break;
        }
        [table insertSubtable:8 ndx:i];
        [table insertDone];

        // Add sub-tables
        if (i == 2) {
            TightdbTable* subtable = [table getTableInColumn:8 atRow:i];
            [subtable insertInt:0 ndx:0 value:42];
            [subtable insertString:1 ndx:0 value:@"meaning"];
            [subtable insertDone];
        }

    }

    // We also want a ColumnStringEnum
    [table optimize];

    // Test Deletes
    [table removeRowAtIndex:14];
    [table removeRowAtIndex:0];
    [table removeRowAtIndex:5];
    STAssertEquals([table count], (size_t)12, @"Size should have been 12");
#ifdef TIGHTDB_DEBUG
    [table verify];
#endif

    // Test Clear
    [table clear];
    STAssertEquals([table count], (size_t)0, @"Size should have been zero");

#ifdef TIGHTDB_DEBUG
    [table verify];
#endif
}

@end
