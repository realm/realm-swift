//
//  table_delete_all.m
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/TDBTable.h>
#import <tightdb/objc/TDBDescriptor.h>
#import <tightdb/objc/TDBMixed.h>

@interface MACTestTableDeleteAll: SenTestCase
@end
@implementation MACTestTableDeleteAll

-(void)testTableDeleteAll
{
    // Create table with all column types
    TDBTable* table = [[TDBTable alloc] init];
    TDBDescriptor* desc = [table descriptor];
    [desc addColumnWithName:@"int" andType:TDBIntType];
    [desc addColumnWithName:@"bool" andType:TDBBoolType];
    [desc addColumnWithName:@"date" andType:TDBDateType];
    [desc addColumnWithName:@"string" andType:TDBStringType];
    [desc addColumnWithName:@"string_long" andType:TDBStringType];
    [desc addColumnWithName:@"string_enum" andType:TDBStringType];
    [desc addColumnWithName:@"binary" andType:TDBBinaryType];
    [desc addColumnWithName:@"mixed" andType:TDBMixedType];
    TDBDescriptor* subdesc = [desc addColumnTable:@"tables"];
    [subdesc addColumnWithName:@"sub_first" andType:TDBIntType];
    [subdesc addColumnWithName:@"sub_second" andType:TDBStringType];

    // Add some rows
    for (size_t i = 0; i < 15; ++i) {
        [table TDBInsertInt:0 ndx:i value:i];
        [table TDBInsertBool:1 ndx:i value:(i % 2 ? YES : NO)];
        [table TDBInsertDate:2 ndx:i value:[NSDate date]];
        [table TDBInsertString:3 ndx:i value:[NSString stringWithFormat:@"string %zu", i]];
        [table TDBInsertString:4 ndx:i value:@" Very long string.............."];

        switch (i % 3) {
            case 0:
                [table TDBInsertString:5 ndx:i value:@"test1"];
                break;
            case 1:
                [table TDBInsertString:5 ndx:i value:@"test2"];
                break;
            case 2:
                [table TDBInsertString:5 ndx:i value:@"test3"];
                break;
        }

        [table TDBInsertBinary:6 ndx:i data:"binary" size:7];
        switch (i % 3) {
            case 0:
                [table TDBInsertMixed:7 ndx:i value:[TDBMixed mixedWithBool:NO]];
                break;
            case 1:
                [table TDBInsertMixed:7 ndx:i value:[TDBMixed mixedWithInt64:i]];
                break;
            case 2:
                [table TDBInsertMixed:7 ndx:i value:[TDBMixed mixedWithString:@"string"]];
                break;
        }
        [table TDBInsertSubtable:8 ndx:i];
        [table TDBInsertDone];

        // Add sub-tables
        if (i == 2) {
            TDBTable* subtable = [table TDBtableInColumnWithIndex:8 atRowIndex:i];
            [subtable TDBInsertInt:0 ndx:0 value:42];
            [subtable TDBInsertString:1 ndx:0 value:@"meaning"];
            [subtable TDBInsertDone];
        }

    }

    // We also want a ColumnStringEnum
    [table optimize];

    // Test Deletes
    [table removeRowAtIndex:14];
    [table removeRowAtIndex:0];
    [table removeRowAtIndex:5];
    STAssertEquals([table rowCount], (size_t)12, @"Size should have been 12");

    // Test Clear
    [table removeAllRows];
    STAssertEquals([table rowCount], (size_t)0, @"Size should have been zero");

}

@end
