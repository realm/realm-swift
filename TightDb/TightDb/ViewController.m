//
//  ViewController.m
//  Tightdb
//
//  Created by Thomas Andersen on 18/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "ViewController.h"
#import "OCGroup.h"
#include "TightDb.h"
TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)

#define TIGHT_IMPL
#include "TightDb.h"

TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)




@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self testGroup];
    [self testTableDeleteAll];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


- (NSString *) pathForDataFile:(NSString *)filename {
    NSArray*	documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*	path = nil;
 	
    if (documentDir) {
        path = [documentDir objectAtIndex:0];    
    }
 	
    return [NSString stringWithFormat:@"%@/%@", path, filename];
}



- (void)testGroup
{
    // Create empty group and serialize to disk
    OCGroup *toDisk = [OCGroup group];
    [toDisk write:[self pathForDataFile:@"table_test.tbl"]];
    
	// Load the group
    OCGroup *fromDisk = [OCGroup groupWithFilename:[self pathForDataFile:@"table_test.tbl"]];
    if (![fromDisk isValid])
        return;
    
	// Create new table in group
	TestTableGroup *t = (TestTableGroup *)[fromDisk getTable:@"test" withClass:[TestTableGroup class]];
    
    NSLog(@"Columns: %zu", [t getColumnCount]);
    if ([t getColumnCount] != 2)
        return;
    if ([t count] != 0)
        return;
	// Modify table
    [t addFirst:@"Test" Second:YES];
    NSLog(@"Size: %lu", [t count]);
    
    if ([t count] != 1)
        return;
    t = nil;
    
}

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
    [table updateFromSpec:[s getRef]];
	
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
            OCTable *subtable = [table getTable:8 ndx:i];
            [subtable insertInt:0 ndx:0 value:42];
            [subtable insertString:1 ndx:0 value:@"meaning"];
            [subtable insertDone];
		}
        
	}
	
	// We also want a ColumnStringEnum
    [table optimize];
	UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.text = [NSString stringWithFormat:@"Count: %zu", [table count]];
    [self.view addSubview:label];
    
	// Test Deletes
    [table deleteRow:14];
    [table deleteRow:0];
    [table deleteRow:5];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:[NSString stringWithFormat:@"Count: %zu", [table count]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
#ifdef _DEBUG
    [table verify];
#endif //_DEBUG
	
	// Test Clear
    [table clear];
	
#ifdef _DEBUG
    [table verify];
#endif //_DEBUG
}

@end
