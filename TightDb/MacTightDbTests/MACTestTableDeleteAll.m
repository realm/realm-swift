//
//  MACTestTableDeleteAll.m
//  TightDB
//

#import "MACTestTableDeleteAll.h"
#import "Table.h"

@implementation MACTestTableDeleteAll

-(void)testTableDeleteAll
{
    // Create table with all column types
    OCTopLevelTable *table = [[OCTopLevelTable alloc] init];
    OCSpec *s = [table getSpec];
    [s addColumn:COLUMN_TYPE_INT name:@"int"];
    [s addColumn:COLUMN_TYPE_BOOL name:@"bool"];
    [s addColumn:COLUMN_TYPE_DATE name:@"date"];
    [s addColumn:COLUMN_TYPE_STRING name:@"string"];
    [s addColumn:COLUMN_TYPE_STRING name:@"string_long"];
    [s addColumn:COLUMN_TYPE_STRING name:@"string_enum"];
    [s addColumn:COLUMN_TYPE_BINARY name:@"binary"];
    [s addColumn:COLUMN_TYPE_MIXED name:@"mixed"];
    OCSpec *sub = [s addColumnTable:@"tables"];
    [sub addColumn:COLUMN_TYPE_INT name:@"sub_first"];
    [sub addColumn:COLUMN_TYPE_STRING name:@"sub_second"];
    [table updateFromSpec];
	
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

		[table insertBinary:6 ndx:i value:"binary" len:7];
		switch (i % 3) {
			case 0:
                [table insertMixed:7 ndx:i value:[OCMixed mixedWithBool:NO]];
				break;
			case 1:
                [table insertMixed:7 ndx:i value:[OCMixed mixedWithInt64:i]];
				break;
			case 2:
                [table insertMixed:7 ndx:i value:[OCMixed mixedWithString:@"string"]];
				break;
		}
		[table insertTable:8 ndx:i];
        [table insertDone];
		
		// Add sub-tables
		if (i == 2) {
            Table *subtable = [table getTable:8 ndx:i];
            [subtable insertInt:0 ndx:0 value:42];
            [subtable insertString:1 ndx:0 value:@"meaning"];
            [subtable insertDone];
		}
 
	}
	
	// We also want a ColumnStringEnum
    [table optimize];
	
	// Test Deletes
    [table deleteRow:14];
    [table deleteRow:0];
    [table deleteRow:5];
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
