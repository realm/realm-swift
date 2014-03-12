/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/NSException.h>

#import <tightdb/objc/tightdb.h>


@interface TightdbDynamicTableTests: SenTestCase
  // Intentionally left blank.
  // No new public instance methods need be defined.
@end

@implementation TightdbDynamicTableTests

- (void)testTable
{
    TightdbTable* _table = [[TightdbTable alloc] init];
    NSLog(@"Table: %@", _table);
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithType:tightdb_Int andName:@"first"];
    [_table addColumnWithType:tightdb_Int andName:@"second"];

    // Verify
    STAssertEquals(tightdb_Int, [_table getColumnType:0], @"First column not int");
    STAssertEquals(tightdb_Int, [_table getColumnType:1], @"Second column not int");
    if (![[_table getColumnName:0] isEqualToString:@"first"])
        STFail(@"First not equal to first");
    if (![[_table getColumnName:1] isEqualToString:@"second"])
        STFail(@"Second not equal to second");

    // 2. Add a row with data

    //const size_t ndx = [_table addEmptyRow];
    //[_table set:0 ndx:ndx value:0];
    //[_table set:1 ndx:ndx value:10];

    TightdbCursor* cursor = [_table addEmptyRow];
    size_t ndx = [cursor index];
    [cursor setInt:0 inColumn:0];
    [cursor setInt:10 inColumn:1];

    // Verify
    if ([_table getIntInColumn:0 atRow:ndx] != 0)
        STFail(@"First not zero");
    if ([_table getIntInColumn:1 atRow:ndx] != 10)
        STFail(@"Second not 10");
}

-(void)testAddColumn
{
    TightdbTable *t = [[TightdbTable alloc] init];
    NSUInteger stringColIndex = [t addColumnWithType:tightdb_String andName:@"stringCol"];
    TightdbCursor *row = [t addEmptyRow];
    [row setString:@"val" inColumn:stringColIndex];
    
    
}

-(void)testAppendRowsIntColumn
{
    // Add row using object literate
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    if (![t appendRow:@[ @1 ]])
        STFail(@"Impossible!");
    if ([t count] != 1)
        STFail(@"Expected 1 row");
    if (![t appendRow:@[ @2 ]])
        STFail(@"Impossible!");
    if ([t count] != 2)
        STFail(@"Expected 2 rows");
    if ([t getIntInColumn:0 atRow:0] != 1)
        STFail(@"Value 1 expected");
    if ([t getIntInColumn:0 atRow:1] != 2)
        STFail(@"Value 2 expected");
    if ([t appendRow:@[@"Hello"]])
        STFail(@"Wrong type");
    if ([t appendRow:@[@1, @"Hello"]])
        STFail(@"Wrong number of columns");
}

-(void)testInsertRowsIntColumn
{
    // Add row using object literate
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    if (![t insertRow:0 andData:@[ @1 ]])
        STFail(@"Impossible!");
    if ([t count] != 1)
        STFail(@"Expected 1 row");
    if (![t insertRow:0 andData:@[ @2 ]])
        STFail(@"Impossible!");
    if ([t count] != 2)
        STFail(@"Expected 2 rows");
    if ([t getIntInColumn:0 atRow:1] != 1)
        STFail(@"Value 1 expected");
    if ([t getIntInColumn:0 atRow:0] != 2)
        STFail(@"Value 2 expected");
    if ([t insertRow:0 andData:@[@"Hello"]])
        STFail(@"Wrong type");
    if ([t insertRow:0 andData: @[@1, @"Hello"]])
        STFail(@"Wrong number of columns");
}

-(void)testAppendRowWithLabelsIntColumn
{
    // Add row using object literate
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    
    if (![t appendRow:@{ @"first": @1 }])
        STFail(@"Impossible!");
    if ([t count] != 1)
        STFail(@"Expected 1 row");

    if (![t appendRow:@{ @"first": @2 }])
        STFail(@"Impossible!");
    if ([t count] != 2)
        STFail(@"Expected 2 rows");

    if ([t getIntInColumn:0 atRow:0] != 1)
        STFail(@"Value 1 expected");
    if ([t getIntInColumn:0 atRow:1] != 2)
        STFail(@"Value 2 expected");

    if ([t appendRow:@{ @"first": @"Hello" }])
        STFail(@"Wrong type");
    if ([t count] != 2)
        STFail(@"Expected 2 rows");

    if (![t appendRow:@{ @"first": @1, @"second": @"Hello"}])
        STFail(@"Has 'first'");
    if ([t count] != 3)
        STFail(@"Expected 3 rows");


    if (![t appendRow:@{ @"second": @1 }])
        STFail(@"This is impossible");
    if ([t count] != 4)
        STFail(@"Expected 4 rows");
    if ([t getIntInColumn:0 atRow:3] != 0)
        STFail(@"Value 0 expected");
}

-(void)testInsertRowWithLabelsIntColumn
{
    // Add row using object literate
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    
    if (![t insertRow:0 andData:@{ @"first": @1 }])
        STFail(@"Impossible!");
    if ([t count] != 1)
        STFail(@"Expected 1 row");
    
    if (![t insertRow:0 andData:@{ @"first": @2 }])
        STFail(@"Impossible!");
    if ([t count] != 2)
        STFail(@"Expected 2 rows");
    
    if ([t getIntInColumn:0 atRow:1] != 1)
        STFail(@"Value 1 expected");
    if ([t getIntInColumn:0 atRow:0] != 2)
        STFail(@"Value 2 expected");
    
    if ([t insertRow:0 andData:@{ @"first": @"Hello" }])
        STFail(@"Wrong type");
    if ([t count] != 2)
        STFail(@"Expected 2 rows");
    
    if (![t insertRow:0 andData:@{ @"first": @3, @"second": @"Hello"}])
        STFail(@"Has 'first'");
    if ([t count] != 3)
        STFail(@"Expected 3 rows");
    
    
    if (![t insertRow:0 andData:@{ @"second": @4 }])
        STFail(@"This is impossible");
    if ([t count] != 4)
        STFail(@"Expected 4 rows");
    if ([t getIntInColumn:0 atRow:0] != 0)
        STFail(@"Value 0 expected");
}


-(void)testAppendRowsIntStringColumns
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    [t addColumnWithType:tightdb_String andName:@"second"];
    if (![t appendRow:@[@1, @"Hello"]])
        STFail(@"appendRow 1");
    if ([t count] != 1)
        STFail(@"1 row expected");
    if ([t getIntInColumn:0 atRow:0] != 1)
        STFail(@"Value 1 expected");
    if (![[t getStringInColumn:1 atRow:0] isEqualToString:@"Hello"])
        STFail(@"Value 'Hello' expected");
    if ([t appendRow:@[@1, @2]])
        STFail(@"appendRow 2");
}


-(void)testAppendRowWithLabelsIntStringColumns
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    [t addColumnWithType:tightdb_String andName:@"second"];
    if (![t appendRow:@{@"first": @1, @"second": @"Hello"}])
        STFail(@"appendRowWithLabels 1");
    if ([t count] != 1)
        STFail(@"1 row expected");
    if ([t getIntInColumn:0 atRow:0] != 1)
        STFail(@"Value 1 expected");
    if (![[t getStringInColumn:1 atRow:0] isEqualToString:@"Hello"])
        STFail(@"Value 'Hello' expected");
    if ([t appendRow:@{@"first": @1, @"second": @2}])
        STFail(@"appendRowWithLabels 2");
}


-(void)testAppendRowsDoubleColumn
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Double andName:@"first"];
    if (![t appendRow:@[@3.14]])  /* double is default */
        STFail(@"Cannot insert 'double'");
    if ([t count] != 1)
        STFail(@"1 row expected");
}

-(void)testAppendRowWithLabelsDoubleColumn
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Double andName:@"first"];
    if (![t appendRow:@{@"first": @3.14}])  /* double is default */
        STFail(@"Cannot insert 'double'");
    if ([t count] != 1)
        STFail(@"1 row expected");
}

-(void)testAppendRowsFloatColumn
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Float andName:@"first"];
    if (![t appendRow:@[@3.14F]])  /* F == float */
        STFail(@"Cannot insert 'float'");
    if ([t count] != 1)
        STFail(@"1 row expected");
}

-(void)testAppendRowWithLabelsFloatColumn
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Float andName:@"first"];
    if (![t appendRow:@{@"first": @3.14F}])  /* F == float */
        STFail(@"Cannot insert 'float'");
    if ([t count] != 1)
        STFail(@"1 row expected");
}

-(void)testAppendRowsDateColumn
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Date andName:@"first"];
    if (![t appendRow:@[@1000000000]])  /* 2001-09-09 01:46:40 */
        STFail(@"Cannot insert 'time_t'");
    if ([t count] != 1)
        STFail(@"1 row expected");

    NSDate *d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
    if (![t appendRow:@[d]])
        STFail(@"Cannot insert 'NSDate'");
    if ([t count] != 2)
        STFail(@"2 rows excepted");
}

-(void)testAppendRowWithLabelsDateColumn
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Date andName:@"first"];

    if (![t appendRow:@{@"first": @1000000000}])  /* 2001-09-09 01:46:40 */
        STFail(@"Cannot insert 'time_t'");
    if ([t count] != 1)
        STFail(@"1 row expected");
    
    NSDate *d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
    if (![t appendRow:@{@"first": d}])
        STFail(@"Cannot insert 'NSDate'");
    if ([t count] != 2)
        STFail(@"2 rows excepted");
}

-(void)testAppendRowsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Binary andName:@"first"];
    
    if (![t appendRow:@[bin2]])
        STFail(@"Cannot insert 'binary'");
    if ([t count] != 1)
        STFail(@"1 row expected");
    
    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    if (![t appendRow:@[nsd]])
        STFail(@"Cannot insert 'NSData'");
    if ([t count] != 2)
        STFail(@"2 rows excepted");
}


-(void)testAppendRowWithLabelsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Binary andName:@"first"];

    if (![t appendRow:@{@"first": bin2}])
        STFail(@"Cannot insert 'binary'");
    if ([t count] != 1)
        STFail(@"1 row expected");

    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    if (![t appendRow:@{@"first": nsd}])
        STFail(@"Cannot insert 'NSData'");
    if ([t count] != 2)
        STFail(@"2 rows excepted");
}

-(void)testAppendRowsTooManyItems
{
    TightdbTable *t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    STAssertFalse(([t appendRow:@[@1, @1]]), @"Too many items for a row.");
}

-(void)testAppendRowsTooFewItems
{
    TightdbTable *t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    STAssertFalse(([t appendRow:@[]]), @"Too few items for a row.");
}

-(void)testAppendRowsWrongType
{
    TightdbTable *t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    STAssertFalse(([t appendRow:@[@YES]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@""]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@3.5]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@3.5F]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@[]]]), @"Wrong type for column.");
}

-(void)testAppendRowsBoolColumn
{
    TightdbTable *t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Bool andName:@"first"];
    STAssertTrue(([t appendRow:@[@YES]]), @"Cannot append bool column.");
    STAssertTrue(([t appendRow:@[@NO]]), @"Cannot append bool column.");
    STAssertEquals((size_t)2, [t count], @"2 rows expected");
}

-(void)testAppendRowWithLabelsBoolColumn
{
    TightdbTable *t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Bool andName:@"first"];
    STAssertTrue(([t appendRow:@{@"first": @YES}]), @"Cannot append bool column.");
    STAssertTrue(([t appendRow:@{@"first": @NO}]), @"Cannot append bool column.");
    STAssertEquals((size_t)2, [t count], @"2 rows expected");
}

-(void)testAppendRowsIntSubtableColumns
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"first"];
    TightdbDescriptor* descr = [t getDescriptor];
    TightdbDescriptor* subdescr = [descr addColumnTable:@"second"];
    [subdescr addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];
    if (![t appendRow:@[@1, @[]]])
        STFail(@"1 row excepted");
    if ([t count] != 1)
        STFail(@"1 row expected");
    if (![t appendRow:@[@2, @[@[@3]]]])
        STFail(@"Cannot insert subtable");
    if ([t count] != 2)
        STFail(@"2 rows expected");
}

-(void)testAppendRowsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];

    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Mixed andName:@"first"];
    if (![t appendRow:@[@1]])
        STFail(@"Cannot insert 'int'");
    if ([t count] != 1)
        STFail(@"1 row excepted");
    if (![t appendRow:@[@"Hello"]])
        STFail(@"Cannot insert 'string'");
    if ([t count] != 2)
        STFail(@"2 rows excepted");
    if (![t appendRow:@[@3.14f]])
        STFail(@"Cannot insert 'float'");
    if ([t count] != 3)
        STFail(@"3 rows excepted");
    if (![t appendRow:@[@3.14]])
        STFail(@"Cannot insert 'double'");
    if ([t count] != 4)
        STFail(@"4 rows excepted");
    if (![t appendRow:@[@YES]])
        STFail(@"Cannot insert 'bool'");
    if ([t count] != 5)
        STFail(@"5 rows excepted");
    if (![t appendRow:@[bin2]])
        STFail(@"Cannot insert 'binary'");
    if ([t count] != 6)
        STFail(@"6 rows excepted");

    TightdbTable* _table10 = [[TightdbTable alloc] init];
    [_table10 addColumnWithType:tightdb_Bool andName:@"first"];
    if (![_table10 appendRow:@[@YES]])
        STFail(@"Cannot insert 'bool'");
    if ([_table10 count] != 1)
        STFail(@"1 row excepted");
}

-(void)testAppendRowWithLabelsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    
    TightdbTable* t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Mixed andName:@"first"];
    if (![t appendRow:@{@"first": @1}])
        STFail(@"Cannot insert 'int'");
    if ([t count] != 1)
        STFail(@"1 row excepted");
    if (![t appendRow:@{@"first": @"Hello"}])
        STFail(@"Cannot insert 'string'");
    if ([t count] != 2)
        STFail(@"2 rows excepted");
    if (![t appendRow:@{@"first": @3.14f}])
        STFail(@"Cannot insert 'float'");
    if ([t count] != 3)
        STFail(@"3 rows excepted");
    if (![t appendRow:@{@"first": @3.14}])
        STFail(@"Cannot insert 'double'");
    if ([t count] != 4)
        STFail(@"4 rows excepted");
    if (![t appendRow:@{@"first": @YES}])
        STFail(@"Cannot insert 'bool'");
    if ([t count] != 5)
        STFail(@"5 rows excepted");
    if (![t appendRow:@{@"first": bin2}])
        STFail(@"Cannot insert 'binary'");
    if ([t count] != 6)
        STFail(@"6 rows excepted");
    }

-(void)testRemoveColumns
{
    
    TightdbTable *t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"col0"];
    STAssertTrue([t getColumnCount] == 1,@"1 column added" );
    
    [t removeColumnWithIndex:0];
    STAssertTrue([t getColumnCount] == 0, @"Colum removed");
    
    for (int i=0;i<10;i++) {
        [t addColumnWithType:tightdb_Int andName:@"name"];
    }
    
    STAssertThrows([t removeColumnWithIndex:10], @"Out of bounds");
    STAssertThrows([t removeColumnWithIndex:-1], @"Less than zero colIndex");

    STAssertTrue([t getColumnCount] == 10, @"10 columns added");

    for (int i=0;i<10;i++) {
        [t removeColumnWithIndex:0];
    }
    
    STAssertTrue([t getColumnCount] == 0, @"Colums removed");
    
    STAssertThrows([t removeColumnWithIndex:1], @"No columns added");
    STAssertThrows([t removeColumnWithIndex:-1], @"Less than zero colIndex");

    
}

/*
- (void)testColumnlessCount
{
    TightdbTable* t = [[TightdbTable alloc] init];
    STAssertEquals((size_t)0, [t count], @"Columnless table has 0 rows.");     
}

- (void)testColumnlessIsEmpty
{
    TightdbTable* t = [[TightdbTable alloc] init];
    STAssertTrue([t isEmpty], @"Columnless table is empty.");
}

- (void)testColumnlessClear
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t clear];
}

- (void)testColumnlessOptimize
{
    TightdbTable* t = [[TightdbTable alloc] init];
    [t optimize];
}

- (void)testColumnlessIsEqual
{
    TightdbTable* t1 = [[TightdbTable alloc] init];
    TightdbTable* t2 = [[TightdbTable alloc] init];
    STAssertTrue([t1 isEqual:t1], @"Columnless table is equal to itself.");
    STAssertTrue([t1 isEqual:t2], @"Columnless table is equal to another columnless table.");
    STAssertTrue([t2 isEqual:t1], @"Columnless table is equal to another columnless table.");
}

- (void)testColumnlessGetColumnCount
{
    TightdbTable* t = [[TightdbTable alloc] init];
    STAssertEquals((size_t)0, [t getColumnCount], @"Columnless table has column count 0.");
}

- (void)testColumnlessGetColumnName
{
    TightdbTable* t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t getColumnName:((size_t)-1)],
        NSException, NSRangeException,
        @"Columnless table has no column names.");
    STAssertThrowsSpecific([t getColumnName:((size_t)0)],
        NSException, NSRangeException,
        @"Columnless table has no column names.");
    STAssertThrowsSpecific([t getColumnName:((size_t)1)],
        NSException, NSRangeException,
        @"Columnless table has no column names.");
}

- (void)testColumnlessGetColumnType
{
    TightdbTable* t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t getColumnType:((size_t)-1)],
        NSException, NSRangeException,
        @"Columnless table has no column types.");
    STAssertThrowsSpecific([t getColumnType:((size_t)0)],
        NSException, NSRangeException,
        @"Columnless table has no column types.");
    STAssertThrowsSpecific([t getColumnType:((size_t)1)],
        NSException, NSRangeException,
        @"Columnless table has no column types.");
}

- (void)testColumnlessCursorAtIndex
{
    TightdbTable* t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t cursorAtIndex:((size_t)-1)],
        NSException, NSRangeException,
        @"Columnless table has no cursors.");
    STAssertThrowsSpecific([t cursorAtIndex:((size_t)0)],
        NSException, NSRangeException,
        @"Columnless table has no cursors.");
    STAssertThrowsSpecific([t cursorAtIndex:((size_t)1)],
        NSException, NSRangeException,
        @"Columnless table has no cursors.");
}

- (void)testColumnlessCursorAtLastIndex
{
    TightdbTable* t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t cursorAtLastIndex],
        NSException, NSRangeException,
        @"Columnless table has no cursors."); 
}

- (void)testRemoveRowAtIndex
{
    TightdbTable *t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t removeRowAtIndex:((size_t)-1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    STAssertThrowsSpecific([t removeRowAtIndex:((size_t)0)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    STAssertThrowsSpecific([t removeRowAtIndex:((size_t)1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}

- (void)testColumnlessRemoveLastRow
{
    TightdbTable *t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t removeLastRow],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}

- (void)testColumnlessGetTableSize
{
    TightdbTable *t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t getTableSize:((size_t)0) ndx:((size_t)-1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    STAssertThrowsSpecific([t getTableSize:((size_t)0) ndx:((size_t)0)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    STAssertThrowsSpecific([t getTableSize:((size_t)0) ndx:((size_t)1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}

- (void)testColumnlessClearSubtable
{
    TightdbTable *t = [[TightdbTable alloc] init];
    STAssertThrowsSpecific([t clearSubtable:((size_t)0) ndx:((size_t)-1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    STAssertThrowsSpecific([t clearSubtable:((size_t)0) ndx:((size_t)0)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    STAssertThrowsSpecific([t clearSubtable:((size_t)0) ndx:((size_t)1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}
*/
- (void)testColumnlessSetIndex
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t setIndex:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t setIndex:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t setIndex:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessHasIndex
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t hasIndex:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t hasIndex:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t hasIndex:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithIntColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t countWithIntColumn:((size_t)-1) andValue: 0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithIntColumn:((size_t)0) andValue: 0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithIntColumn:((size_t)1) andValue: 0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithFloatColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t countWithFloatColumn:((size_t)-1) andValue: 0.0f],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithFloatColumn:((size_t)0) andValue: 0.0f],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithFloatColumn:((size_t)1) andValue: 0.0f],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithDoubleColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t countWithDoubleColumn:((size_t)-1) andValue: 0.0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithDoubleColumn:((size_t)0) andValue: 0.0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithDoubleColumn:((size_t)1) andValue: 0.0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithStringColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t countWithStringColumn:((size_t)-1) andValue: @""],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithStringColumn:((size_t)0) andValue: @""],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t countWithStringColumn:((size_t)1) andValue: @""],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessSumWithIntColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t sumWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t sumWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t sumWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessSumWithFloatColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t sumWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t sumWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t sumWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessSumWithDoubleColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t sumWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t sumWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t sumWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMaximumWithIntColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t maximumWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t maximumWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t maximumWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMaximumWithFloatColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t maximumWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t maximumWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t maximumWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMaximumWithDoubleColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t maximumWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t maximumWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t maximumWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMinimumWithIntColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t minimumWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t minimumWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t minimumWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMinimumWithFloatColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t minimumWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t minimumWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t minimumWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMinimumWithDoubleColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t minimumWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t minimumWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t minimumWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessAverageWithIntColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t averageWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t averageWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t averageWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessAverageWithFloatColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t averageWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t averageWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t averageWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessAverageWithDoubleColumn
{
// SEGFAULT
//    TightdbTable *t = [[TightdbTable alloc] init];
//    STAssertThrowsSpecific([t averageWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t averageWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    STAssertThrowsSpecific([t averageWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testDataTypes_Dynamic
{
    TightdbTable* table = [[TightdbTable alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    TightdbDescriptor* desc = [table getDescriptor];

    [desc addColumnWithType:tightdb_Bool   andName:@"BoolCol"];    const size_t BoolCol = 0;
    [desc addColumnWithType:tightdb_Int    andName:@"IntCol"];     const size_t IntCol = 1;
    [desc addColumnWithType:tightdb_Float  andName:@"FloatCol"];   const size_t FloatCol = 2;
    [desc addColumnWithType:tightdb_Double andName:@"DoubleCol"];  const size_t DoubleCol = 3;
    [desc addColumnWithType:tightdb_String andName:@"StringCol"];  const size_t StringCol = 4;
    [desc addColumnWithType:tightdb_Binary andName:@"BinaryCol"];  const size_t BinaryCol = 5;
    [desc addColumnWithType:tightdb_Date   andName:@"DateCol"];    const size_t DateCol = 6;
    TightdbDescriptor* subdesc = [desc addColumnTable:@"TableCol"]; const size_t TableCol = 7;
    [desc addColumnWithType:tightdb_Mixed  andName:@"MixedCol"];   const size_t MixedCol = 8;

    [subdesc addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];

    // Verify column types
    STAssertEquals(tightdb_Bool,   [table getColumnType:0], @"First column not bool");
    STAssertEquals(tightdb_Int,    [table getColumnType:1], @"Second column not int");
    STAssertEquals(tightdb_Float,  [table getColumnType:2], @"Third column not float");
    STAssertEquals(tightdb_Double, [table getColumnType:3], @"Fourth column not double");
    STAssertEquals(tightdb_String, [table getColumnType:4], @"Fifth column not string");
    STAssertEquals(tightdb_Binary, [table getColumnType:5], @"Sixth column not binary");
    STAssertEquals(tightdb_Date,   [table getColumnType:6], @"Seventh column not date");
    STAssertEquals(tightdb_Table,  [table getColumnType:7], @"Eighth column not table");
    STAssertEquals(tightdb_Mixed,  [table getColumnType:8], @"Ninth column not mixed");


    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    time_t timeNow = [[NSDate date] timeIntervalSince1970];



    TightdbTable* subtab1 = [[TightdbTable alloc] init];
    [subtab1 addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];

    TightdbTable* subtab2 = [[TightdbTable alloc] init];
    [subtab2 addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];


    TightdbCursor* cursor;



    cursor = [subtab1 addEmptyRow];
    [cursor setInt:200 inColumn:0];



    cursor = [subtab2 addEmptyRow];
    [cursor setInt:100 inColumn:0];



    TightdbMixed* mixInt1   = [TightdbMixed mixedWithInt64:1];
    TightdbMixed* mixSubtab = [TightdbMixed mixedWithTable:subtab2];

    TightdbCursor* c;



    c = [table addEmptyRow];



    [c setBool:    NO        inColumn:BoolCol];
    [c setInt:     54        inColumn:IntCol];
    [c setFloat:   0.7       inColumn:FloatCol];
    [c setDouble:  0.8       inColumn:DoubleCol];
    [c setString:  @"foo"    inColumn:StringCol];
    [c setBinary:  bin1      inColumn:BinaryCol];
    [c setDate:    0         inColumn:DateCol];
    [c setTable:   subtab1   inColumn:TableCol];
    [c setMixed:   mixInt1   inColumn:MixedCol];

    c = [table addEmptyRow];

    [c setBool:    YES       inColumn:BoolCol];
    [c setInt:     506       inColumn:IntCol];
    [c setFloat:   7.7       inColumn:FloatCol];
    [c setDouble:  8.8       inColumn:DoubleCol];
    [c setString:  @"banach" inColumn:StringCol];
    [c setBinary:  bin2      inColumn:BinaryCol];
    [c setDate:    timeNow   inColumn:DateCol];
    [c setTable:   subtab2   inColumn:TableCol];
    [c setMixed:   mixSubtab inColumn:MixedCol];

    TightdbCursor* row1 = [table cursorAtIndex:0];
    TightdbCursor* row2 = [table cursorAtIndex:1];

    STAssertEquals([row1 getBoolInColumn:BoolCol], NO, @"row1.BoolCol");
    STAssertEquals([row2 getBoolInColumn:BoolCol], YES,                @"row2.BoolCol");
    STAssertEquals([row1 getIntInColumn:IntCol], (int64_t)54,         @"row1.IntCol");
    STAssertEquals([row2 getIntInColumn:IntCol], (int64_t)506,        @"row2.IntCol");
    STAssertEquals([row1 getFloatInColumn:FloatCol], 0.7f,              @"row1.FloatCol");
    STAssertEquals([row2 getFloatInColumn:FloatCol], 7.7f,              @"row2.FloatCol");
    STAssertEquals([row1 getDoubleInColumn:DoubleCol], 0.8,              @"row1.DoubleCol");
    STAssertEquals([row2 getDoubleInColumn:DoubleCol], 8.8,              @"row2.DoubleCol");
    STAssertTrue([[row1 getStringInColumn:StringCol] isEqual:@"foo"],    @"row1.StringCol");
    STAssertTrue([[row2 getStringInColumn:StringCol] isEqual:@"banach"], @"row2.StringCol");
    STAssertTrue([[row1 getBinaryInColumn:BinaryCol] isEqual:bin1],      @"row1.BinaryCol");
    STAssertTrue([[row2 getBinaryInColumn:BinaryCol] isEqual:bin2],      @"row2.BinaryCol");
    STAssertEquals([row1 getDateInColumn:DateCol], (time_t)0,          @"row1.DateCol");
    STAssertEquals([row2 getDateInColumn:DateCol], timeNow,            @"row2.DateCol");
    STAssertTrue([[row1 getTableInColumn:TableCol] isEqual:subtab1],    @"row1.TableCol");
    STAssertTrue([[row2 getTableInColumn:TableCol] isEqual:subtab2],    @"row2.TableCol");
    STAssertTrue([[row1 getMixedInColumn:MixedCol] isEqual:mixInt1],    @"row1.MixedCol");
    STAssertTrue([[row2 getMixedInColumn:MixedCol] isEqual:mixSubtab],  @"row2.MixedCol");

    STAssertEquals([table minimumWithIntColumn:IntCol], (int64_t)54,                 @"IntCol min");
    STAssertEquals([table maximumWithIntColumn:IntCol], (int64_t)506,                @"IntCol max");
    STAssertEquals([table sumWithIntColumn:IntCol], (int64_t)560,                @"IntCol sum");
    STAssertEquals([table averageWithIntColumn:IntCol], 280.0,                       @"IntCol avg");

    STAssertEquals([table minimumWithFloatColumn:FloatCol], 0.7f,                      @"FloatCol min");
    STAssertEquals([table maximumWithFloatColumn:FloatCol], 7.7f,                      @"FloatCol max");
    STAssertEquals([table sumWithFloatColumn:FloatCol], (double)0.7f + 7.7f,       @"FloatCol sum");
    STAssertEquals([table averageWithFloatColumn:FloatCol], ((double)0.7f + 7.7f) / 2, @"FloatCol avg");

    STAssertEquals([table minimumWithDoubleColumn:DoubleCol], 0.8,                      @"DoubleCol min");
    STAssertEquals([table maximumWithDoubleColumn:DoubleCol], 8.8,                      @"DoubleCol max");
    STAssertEquals([table sumWithDoubleColumn:DoubleCol], 0.8 + 8.8,                @"DoubleCol sum");
    STAssertEquals([table averageWithDoubleColumn:DoubleCol], (0.8 + 8.8) / 2,          @"DoubleCol avg");
}

- (void)testTableDynamic_Subscripting
{
    TightdbTable* _table = [[TightdbTable alloc] init];
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithType:tightdb_Int andName:@"first"];
    [_table addColumnWithType:tightdb_String andName:@"second"];

    TightdbCursor* c;

    // Add some rows
    c = [_table addEmptyRow];
    [c setInt: 506 inColumn:0];
    [c setString: @"test" inColumn:1];

    c = [_table addEmptyRow];
    [c setInt: 4 inColumn:0];
    [c setString: @"more test" inColumn:1];

    // Get cursor by object subscripting
    c = _table[0];
    STAssertEquals([c getIntInColumn:0], (int64_t)506, @"table[0].first");
    STAssertTrue([[c getStringInColumn:1] isEqual:@"test"], @"table[0].second");

    // Same but used directly
    STAssertEquals([_table[0] getIntInColumn:0], (int64_t)506, @"table[0].first");
    STAssertTrue([[_table[0] getStringInColumn:1] isEqual:@"test"], @"table[0].second");
}

- (void)testTableDynamic_Cursor_Subscripting
{
    TightdbTable* _table = [[TightdbTable alloc] init];
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithType:tightdb_Int andName:@"first"];
    [_table addColumnWithType:tightdb_String andName:@"second"];

    TightdbCursor* c;

    // Add some rows
    c = [_table addEmptyRow];
    c[0] = @506;
    c[1] = @"test";

    c = [_table addEmptyRow];
    c[@"first"]  = @4;
    c[@"second"] = @"more test";

    // Get values from cursor by object subscripting
    c = _table[0];
    STAssertTrue([c[0] isEqual:@506], @"table[0].first");
    STAssertTrue([c[1] isEqual:@"test"], @"table[0].second");

    // Same but used with column name
    STAssertTrue([c[@"first"]  isEqual:@506], @"table[0].first");
    STAssertTrue([c[@"second"] isEqual:@"test"], @"table[0].second");

    // Combine with subscripting for rows
    STAssertTrue([_table[0][0] isEqual:@506], @"table[0].first");
    STAssertTrue([_table[0][1] isEqual:@"test"], @"table[0].second");
    STAssertTrue([_table[0][@"first"] isEqual:@506], @"table[0].first");
    STAssertTrue([_table[0][@"second"] isEqual:@"test"], @"table[0].second");

    STAssertTrue([_table[1][0] isEqual:@4], @"table[1].first");
    STAssertTrue([_table[1][1] isEqual:@"more test"], @"table[1].second");
    STAssertTrue([_table[1][@"first"] isEqual:@4], @"table[1].first");
    STAssertTrue([_table[1][@"second"] isEqual:@"more test"], @"table[1].second");
}

@end
