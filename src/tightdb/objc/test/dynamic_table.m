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

#import <tightdb/objc/Tightdb.h>


@interface TDBDynamicTableTests: SenTestCase
  // Intentionally left blank.
  // No new public instance methods need be defined.
@end

@implementation TDBDynamicTableTests

- (void)testTable
{
    TDBTable* _table = [[TDBTable alloc] init];
    NSLog(@"Table: %@", _table);
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithName:@"first" andType:TDBIntType];
    [_table addColumnWithName:@"second" andType:TDBIntType];

    // Verify
    STAssertEquals(TDBIntType, [_table columnTypeOfColumn:0], @"First column not int");
    STAssertEquals(TDBIntType, [_table columnTypeOfColumn:1], @"Second column not int");
    STAssertTrue(([[_table columnNameOfColumn:0] isEqualToString:@"first"]), @"First not equal to first");
    STAssertTrue(([[_table columnNameOfColumn:1] isEqualToString:@"second"]), @"Second not equal to second");

    // 2. Add a row with data

    //const size_t ndx = [_table addEmptyRow];
    //[_table set:0 ndx:ndx value:0];
    //[_table set:1 ndx:ndx value:10];

    TDBRow* cursor = [_table addEmptyRow];
    size_t ndx = [cursor TDBIndex];
    [cursor setInt:0 inColumnWithIndex:0];
    [cursor setInt:10 inColumnWithIndex:1];

    // Verify
    STAssertEquals((int64_t)0, ([_table intInColumnWithIndex:0 atRowIndex:ndx]), @"First not zero");
    STAssertEquals((int64_t)10, ([_table intInColumnWithIndex:1 atRowIndex:ndx]), @"Second not 10");
}

-(void)testAddColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger stringColIndex = [t addColumnWithName:@"stringCol" andType:TDBStringType];
    TDBRow *row = [t addEmptyRow];
    [row setString:@"val" inColumnWithIndex:stringColIndex];
}

-(void)testAppendRowsIntColumn
{
    // Add row using object literate
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    STAssertTrue([t appendRow:@[ @1 ]], @"Impossible!");
    STAssertEquals((size_t)1, [t rowCount], @"Expected 1 row");
    STAssertTrue([t appendRow:@[ @2 ]], @"Impossible!");
    STAssertEquals((size_t)2, [t rowCount], @"Expected 2 rows");
    STAssertEquals((int64_t)1, [t intInColumnWithIndex:0 atRowIndex:0], @"Value 1 expected");
    STAssertEquals((int64_t)2, [t intInColumnWithIndex:0 atRowIndex:1], @"Value 2 expected");
    STAssertFalse([t appendRow:@[@"Hello"]], @"Wrong type");
    STAssertFalse(([t appendRow:@[@1, @"Hello"]]), @"Wrong number of columns");
}

-(void)testInsertRowsIntColumn
{
    // Add row using object literate
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    STAssertTrue([t insertRow:@[ @1 ] atRowIndex:0], @"Impossible!");
    STAssertEquals((size_t)1, [t rowCount], @"Expected 1 row");
    STAssertTrue([t insertRow:@[ @2 ] atRowIndex:0], @"Impossible!");
    STAssertEquals((size_t)2, [t rowCount], @"Expected 2 rows");
    STAssertEquals((int64_t)1, [t intInColumnWithIndex:0 atRowIndex:1], @"Value 1 expected");
    STAssertEquals((int64_t)2, [t intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
    STAssertFalse([t insertRow:@[@"Hello"] atRowIndex:0], @"Wrong type");
    STAssertFalse(([t insertRow:@[@1, @"Hello"] atRowIndex:0]), @"Wrong number of columns");
}

-(void)testUpdateRowIntColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    [t insertRow:@[@1] atRowIndex:0];
    t[0] = @[@2];
    STAssertEquals((int64_t)2, [t intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
}

-(void)testUpdateRowWithLabelsIntColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    [t insertRow:@[@1] atRowIndex:0];
    t[0] = @{@"first": @2};
    STAssertEquals((int64_t)2, [t intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
}


-(void)testAppendRowWithLabelsIntColumn
{
    // Add row using object literate
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];

    STAssertTrue([t appendRow:@{ @"first": @1 }], @"Impossible!");
    STAssertEquals((size_t)1, [t rowCount], @"Expected 1 row");

    STAssertTrue([t appendRow:@{ @"first": @2 }], @"Impossible!");
    STAssertEquals((size_t)2, [t rowCount], @"Expected 2 rows");

    STAssertEquals((int64_t)1, [t intInColumnWithIndex:0 atRowIndex:0], @"Value 1 expected");
    STAssertEquals((int64_t)2, [t intInColumnWithIndex:0 atRowIndex:1], @"Value 2 expected");

    STAssertFalse([t appendRow:@{ @"first": @"Hello" }], @"Wrong type");
    STAssertEquals((size_t)2, [t rowCount], @"Expected 2 rows");

    STAssertTrue(([t appendRow:@{ @"first": @1, @"second": @"Hello" }]), @"dh");
    STAssertEquals((size_t)3, [t rowCount], @"Expected 3 rows");

    STAssertTrue(([t appendRow:@{ @"second": @1 }]), @"This is impossible");
    STAssertEquals((size_t)4, [t rowCount], @"Expected 4 rows");

    STAssertEquals((int64_t)0, [t intInColumnWithIndex:0 atRowIndex:3], @"Value 0 expected");
}

-(void)testInsertRowWithLabelsIntColumn
{
    // Add row using object literate
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    
    STAssertTrue(([t insertRow:@{ @"first": @1 } atRowIndex:0]), @"Impossible!");
    STAssertEquals((size_t)1, [t rowCount], @"Expected 1 row");
    
    STAssertTrue(([t insertRow:@{ @"first": @2 } atRowIndex:0]), @"Impossible!");
    STAssertEquals((size_t)2, [t rowCount], @"Expected 2 rows");
    
    STAssertEquals((int64_t)1, ([t intInColumnWithIndex:0 atRowIndex:1]), @"Value 1 expected");
    STAssertEquals((int64_t)2, ([t intInColumnWithIndex:0 atRowIndex:0]), @"Value 2 expected");
    
    STAssertFalse(([t insertRow:@{ @"first": @"Hello" } atRowIndex:0]), @"Wrong type");
    STAssertEquals((size_t)2, ([t rowCount]), @"Expected 2 rows");
    
    STAssertTrue(([t insertRow:@{ @"first": @3, @"second": @"Hello"} atRowIndex:0]), @"Has 'first'");
    STAssertEquals((size_t)3, [t rowCount], @"Expected 3 rows");
    
    STAssertTrue(([t insertRow:@{ @"second": @4 } atRowIndex:0]), @"This is impossible");
    STAssertEquals((size_t)4, [t rowCount], @"Expected 4 rows");
    STAssertTrue((int64_t)0 == ([t intInColumnWithIndex:0 atRowIndex:0]), @"Value 0 expected");
}


-(void)testAppendRowsIntStringColumns
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    [t addColumnWithName:@"second" andType:TDBStringType];

    STAssertTrue(([t appendRow:@[@1, @"Hello"]]), @"appendRow 1");
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
    STAssertEquals((int64_t)1, ([t intInColumnWithIndex:0 atRowIndex:0]), @"Value 1 expected");
    STAssertTrue(([[t stringInColumnWithIndex:1 atRowIndex:0] isEqualToString:@"Hello"]), @"Value 'Hello' expected");
    STAssertFalse(([t appendRow:@[@1, @2]]), @"appendRow 2");
}


-(void)testAppendRowWithLabelsIntStringColumns
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    [t addColumnWithName:@"second" andType:TDBStringType];
    STAssertTrue(([t appendRow:@{@"first": @1, @"second": @"Hello"}]), @"appendRowWithLabels 1");
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
    STAssertEquals((int64_t)1, ([t intInColumnWithIndex:0 atRowIndex:0]), @"Value 1 expected");
    STAssertTrue(([[t stringInColumnWithIndex:1 atRowIndex:0] isEqualToString:@"Hello"]), @"Value 'Hello' expected");
    STAssertFalse(([t appendRow:@{@"first": @1, @"second": @2}]), @"appendRowWithLabels 2");
}


-(void)testAppendRowsDoubleColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBDoubleType];
    STAssertTrue(([t appendRow:@[@3.14]]), @"Cannot insert 'double'");  /* double is default */
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowWithLabelsDoubleColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBDoubleType];
    STAssertTrue(([t appendRow:@{@"first": @3.14}]), @"Cannot insert 'double'");   /* double is default */
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowsFloatColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBFloatType];
    STAssertTrue(([t appendRow:@[@3.14F]]), @"Cannot insert 'float'"); /* F == float */
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowWithLabelsFloatColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBFloatType];
    STAssertTrue(([t appendRow:@{@"first": @3.14F}]), @"Cannot insert 'float'");   /* F == float */
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowsDateColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBDateType];
    STAssertTrue(([t appendRow:@[@1000000000]]), @"Cannot insert 'time_t'"); /* 2001-09-09 01:46:40 */
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");

    NSDate *d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
    STAssertTrue(([t appendRow:@[d]]), @"Cannot insert 'NSDate'");
    STAssertEquals((size_t)2, ([t rowCount]), @"2 rows excepted");
}

-(void)testAppendRowWithLabelsDateColumn
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBDateType];

    STAssertTrue(([t appendRow:@{@"first": @1000000000}]), @"Cannot insert 'time_t'");   /* 2001-09-09 01:46:40 */
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
    
    NSDate *d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
    STAssertTrue(([t appendRow:@{@"first": d}]), @"Cannot insert 'NSDate'");
    STAssertEquals((size_t)2, ([t rowCount]), @"2 rows excepted");
}

-(void)testAppendRowsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBBinaryType];
    STAssertTrue(([t appendRow:@[bin2]]), @"Cannot insert 'binary'");
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");

    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    STAssertTrue(([t appendRow:@[nsd]]), @"Cannot insert 'NSData'");
    STAssertEquals((size_t)2, ([t rowCount]), @"2 rows excepted");
}


-(void)testAppendRowWithLabelsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBBinaryType];

    STAssertTrue(([t appendRow:@{@"first": bin2}]), @"Cannot insert 'binary'");
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");

    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    STAssertTrue(([t appendRow:@{@"first": nsd}]), @"Cannot insert 'NSData'");
    STAssertEquals((size_t)2, ([t rowCount]), @"2 rows excepted");
}

-(void)testAppendRowsTooManyItems
{
    TDBTable *t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    STAssertFalse(([t appendRow:@[@1, @1]]), @"Too many items for a row.");
}

-(void)testAppendRowsTooFewItems
{
    TDBTable *t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    STAssertFalse(([t appendRow:@[]]), @"Too few items for a row.");
}

-(void)testAppendRowsWrongType
{
    TDBTable *t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    STAssertFalse(([t appendRow:@[@YES]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@""]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@3.5]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@3.5F]]), @"Wrong type for column.");
    STAssertFalse(([t appendRow:@[@[]]]), @"Wrong type for column.");
}

-(void)testAppendRowsBoolColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBBoolType];
    STAssertTrue(([t appendRow:@[@YES]]), @"Cannot append bool column.");
    STAssertTrue(([t appendRow:@[@NO]]), @"Cannot append bool column.");
    STAssertEquals((size_t)2, [t rowCount], @"2 rows expected");
}

-(void)testAppendRowWithLabelsBoolColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBBoolType];
    STAssertTrue(([t appendRow:@{@"first": @YES}]), @"Cannot append bool column.");
    STAssertTrue(([t appendRow:@{@"first": @NO}]), @"Cannot append bool column.");
    STAssertEquals((size_t)2, [t rowCount], @"2 rows expected");
}

-(void)testAppendRowsIntSubtableColumns
{
    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBIntType];
    TDBDescriptor* descr = [t descriptor];
    TDBDescriptor* subdescr = [descr addColumnTable:@"second"];
    [subdescr addColumnWithName:@"TableCol_IntCol" andType:TDBIntType];
    STAssertTrue(([t appendRow:@[@1, @[]]]), @"1 row excepted");
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row expected");
    STAssertTrue(([t appendRow:@[@2, @[@[@3]]]]), @"Cannot insert subtable");
    STAssertEquals((size_t)2, ([t rowCount]), @"2 rows expected");
}

-(void)testAppendRowsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];

    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBMixedType];
    STAssertTrue(([t appendRow:@[@1]]), @"Cannot insert 'int'");
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row excepted");
    STAssertTrue(([t appendRow:@[@"Hello"]]), @"Cannot insert 'string'");
    STAssertEquals((size_t)2, ([t rowCount]), @"2 rows excepted");
    STAssertTrue(([t appendRow:@[@3.14f]]), @"Cannot insert 'float'");
    STAssertEquals((size_t)3, ([t rowCount]), @"3 rows excepted");
    STAssertTrue(([t appendRow:@[@3.14]]), @"Cannot insert 'double'");
    STAssertEquals((size_t)4, ([t rowCount]), @"4 rows excepted");
    STAssertTrue(([t appendRow:@[@YES]]), @"Cannot insert 'bool'");
    STAssertEquals((size_t)5, ([t rowCount]), @"5 rows excepted");
    STAssertTrue(([t appendRow:@[bin2]]), @"Cannot insert 'binary'");
    STAssertEquals((size_t)6, ([t rowCount]), @"6 rows excepted");
}

-(void)testAppendRowWithLabelsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];

    TDBTable* t = [[TDBTable alloc] init];
    [t addColumnWithName:@"first" andType:TDBMixedType];
    STAssertTrue(([t appendRow:@{@"first": @1}]), @"Cannot insert 'int'");
    STAssertEquals((size_t)1, ([t rowCount]), @"1 row excepted");
    STAssertTrue(([t appendRow:@{@"first": @"Hello"}]), @"Cannot insert 'string'$");
    STAssertEquals((size_t)2, ([t rowCount]), @"2 rows excepted");
    STAssertTrue(([t appendRow:@{@"first": @3.14f}]), @"Cannot insert 'float'");
    STAssertEquals((size_t)3, ([t rowCount]), @"3 rows excepted");
    STAssertTrue(([t appendRow:@{@"first": @3.14}]), @"Cannot insert 'double'");
    STAssertEquals((size_t)4, ([t rowCount]), @"4 rows excepted");
    STAssertTrue(([t appendRow:@{@"first": @YES}]), @"Cannot insert 'bool'");
    STAssertEquals((size_t)5, ([t rowCount]), @"5 rows excepted");
    STAssertTrue(([t appendRow:@{@"first": bin2}]), @"Cannot insert 'binary'");
    STAssertEquals((size_t)6, ([t rowCount]), @"6 rows excepted");
}

-(void)testRemoveColumns
{

    TDBTable *t = [[TDBTable alloc] init];
    [t addColumnWithName:@"col0" andType:TDBIntType];
    STAssertTrue([t columnCount] == 1,@"1 column added" );

    [t removeColumnWithIndex:0];
    STAssertTrue([t columnCount] == 0, @"Colum removed");

    for (int i=0;i<10;i++) {
        [t addColumnWithName:@"name" andType:TDBIntType];
    }

    STAssertThrows([t removeColumnWithIndex:10], @"Out of bounds");
    STAssertThrows([t removeColumnWithIndex:-1], @"Less than zero colIndex");

    STAssertTrue([t columnCount] == 10, @"10 columns added");

    for (int i=0;i<10;i++) {
        [t removeColumnWithIndex:0];
    }

    STAssertTrue([t columnCount] == 0, @"Colums removed");
    STAssertThrows([t removeColumnWithIndex:1], @"No columns added");
    STAssertThrows([t removeColumnWithIndex:-1], @"Less than zero colIndex");
}

/*
- (void)testColumnlessCount
{
    TDBTable* t = [[TDBTable alloc] init];
    STAssertEquals((size_t)0, [t count], @"Columnless table has 0 rows.");     
}

- (void)testColumnlessIsEmpty
{
    TDBTable* t = [[TDBTable alloc] init];
    STAssertTrue([t isEmpty], @"Columnless table is empty.");
}

- (void)testColumnlessClear
{
    TDBTable* t = [[TDBTable alloc] init];
    [t clear];
}

- (void)testColumnlessOptimize
{
    TDBTable* t = [[TDBTable alloc] init];
    [t optimize];
}

- (void)testColumnlessIsEqual
{
    TDBTable* t1 = [[TDBTable alloc] init];
    TDBTable* t2 = [[TDBTable alloc] init];
    STAssertTrue([t1 isEqual:t1], @"Columnless table is equal to itself.");
    STAssertTrue([t1 isEqual:t2], @"Columnless table is equal to another columnless table.");
    STAssertTrue([t2 isEqual:t1], @"Columnless table is equal to another columnless table.");
}

- (void)testColumnlessGetColumnCount
{
    TDBTable* t = [[TDBTable alloc] init];
    STAssertEquals((size_t)0, [t getColumnCount], @"Columnless table has column count 0.");
}

- (void)testColumnlessGetColumnName
{
    TDBTable* t = [[TDBTable alloc] init];
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
    TDBTable* t = [[TDBTable alloc] init];
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
    TDBTable* t = [[TDBTable alloc] init];
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
    TDBTable* t = [[TDBTable alloc] init];
    STAssertThrowsSpecific([t cursorAtLastIndex],
        NSException, NSRangeException,
        @"Columnless table has no cursors."); 
}

- (void)testRemoveRowAtIndex
{
    TDBTable *t = [[TDBTable alloc] init];
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
    TDBTable *t = [[TDBTable alloc] init];
    STAssertThrowsSpecific([t removeLastRow],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}

- (void)testColumnlessGetTableSize
{
    TDBTable *t = [[TDBTable alloc] init];
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
    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
//    TDBTable *t = [[TDBTable alloc] init];
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
    TDBTable* table = [[TDBTable alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    TDBDescriptor* desc = [table descriptor];

    [desc addColumnWithName:@"BoolCol" andType:TDBBoolType];    const size_t BoolCol = 0;
    [desc addColumnWithName:@"IntCol" andType:TDBIntType];     const size_t IntCol = 1;
    [desc addColumnWithName:@"FloatCol" andType:TDBFloatType];   const size_t FloatCol = 2;
    [desc addColumnWithName:@"DoubleCol" andType:TDBDoubleType];  const size_t DoubleCol = 3;
    [desc addColumnWithName:@"StringCol" andType:TDBStringType];  const size_t StringCol = 4;
    [desc addColumnWithName:@"BinaryCol" andType:TDBBinaryType];  const size_t BinaryCol = 5;
    [desc addColumnWithName:@"DateCol" andType:TDBDateType];    const size_t DateCol = 6;
    TDBDescriptor* subdesc = [desc addColumnTable:@"TableCol"]; const size_t TableCol = 7;
    [desc addColumnWithName:@"MixedCol" andType:TDBMixedType];   const size_t MixedCol = 8;

    [subdesc addColumnWithName:@"TableCol_IntCol" andType:TDBIntType];

    // Verify column types
    STAssertEquals(TDBBoolType,   [table columnTypeOfColumn:0], @"First column not bool");
    STAssertEquals(TDBIntType,    [table columnTypeOfColumn:1], @"Second column not int");
    STAssertEquals(TDBFloatType,  [table columnTypeOfColumn:2], @"Third column not float");
    STAssertEquals(TDBDoubleType, [table columnTypeOfColumn:3], @"Fourth column not double");
    STAssertEquals(TDBStringType, [table columnTypeOfColumn:4], @"Fifth column not string");
    STAssertEquals(TDBBinaryType, [table columnTypeOfColumn:5], @"Sixth column not binary");
    STAssertEquals(TDBDateType,   [table columnTypeOfColumn:6], @"Seventh column not date");
    STAssertEquals(TDBTableType,  [table columnTypeOfColumn:7], @"Eighth column not table");
    STAssertEquals(TDBMixedType,  [table columnTypeOfColumn:8], @"Ninth column not mixed");


    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate date];

    TDBTable* subtab1 = [[TDBTable alloc] init];
    [subtab1 addColumnWithName:@"TableCol_IntCol" andType:TDBIntType];

    TDBTable* subtab2 = [[TDBTable alloc] init];
    [subtab2 addColumnWithName:@"TableCol_IntCol" andType:TDBIntType];

    TDBRow* cursor;
    cursor = [subtab1 addEmptyRow];
    [cursor setInt:200 inColumnWithIndex:0];

    cursor = [subtab2 addEmptyRow];
    [cursor setInt:100 inColumnWithIndex:0];

    TDBMixed* mixInt1   = [TDBMixed mixedWithInt64:1];
    TDBMixed* mixSubtab = [TDBMixed mixedWithTable:subtab2];

    TDBRow* c;
    c = [table addEmptyRow];
    [c setBool:    NO        inColumnWithIndex:BoolCol];
    [c setInt:     54        inColumnWithIndex:IntCol];
    [c setFloat:   0.7       inColumnWithIndex:FloatCol];
    [c setDouble:  0.8       inColumnWithIndex:DoubleCol];
    [c setString:  @"foo"    inColumnWithIndex:StringCol];
    [c setBinary:  bin1      inColumnWithIndex:BinaryCol];
    [c setDate:    0         inColumnWithIndex:DateCol];
    [c setTable:   subtab1   inColumnWithIndex:TableCol];
    [c setMixed:   mixInt1   inColumnWithIndex:MixedCol];

    c = [table addEmptyRow];

    [c setBool:    YES       inColumnWithIndex:BoolCol];
    [c setInt:     506       inColumnWithIndex:IntCol];
    [c setFloat:   7.7       inColumnWithIndex:FloatCol];
    [c setDouble:  8.8       inColumnWithIndex:DoubleCol];
    [c setString:  @"banach" inColumnWithIndex:StringCol];
    [c setBinary:  bin2      inColumnWithIndex:BinaryCol];
    [c setDate:    [NSDate date]   inColumnWithIndex:DateCol];
    [c setTable:   subtab2   inColumnWithIndex:TableCol];
    [c setMixed:   mixSubtab inColumnWithIndex:MixedCol];

    TDBRow* row1 = [table rowAtIndex:0];
    TDBRow* row2 = [table rowAtIndex:1];
    

    STAssertEquals([row1 boolInColumnWithIndex:BoolCol], NO, @"row1.BoolCol");
    STAssertEquals([row2 boolInColumnWithIndex:BoolCol], YES,                @"row2.BoolCol");
    STAssertEquals([row1 intInColumnWithIndex:IntCol], (int64_t)54,         @"row1.IntCol");
    STAssertEquals([row2 intInColumnWithIndex:IntCol], (int64_t)506,        @"row2.IntCol");
    STAssertEquals([row1 floatInColumnWithIndex:FloatCol], 0.7f,              @"row1.FloatCol");
    STAssertEquals([row2 floatInColumnWithIndex:FloatCol], 7.7f,              @"row2.FloatCol");
    STAssertEquals([row1 doubleInColumnWithIndex:DoubleCol], 0.8,              @"row1.DoubleCol");
    STAssertEquals([row2 doubleInColumnWithIndex:DoubleCol], 8.8,              @"row2.DoubleCol");
    STAssertTrue([[row1 stringInColumnWithIndex:StringCol] isEqual:@"foo"],    @"row1.StringCol");
    STAssertTrue([[row2 stringInColumnWithIndex:StringCol] isEqual:@"banach"], @"row2.StringCol");
    STAssertTrue([[row1 binaryInColumnWithIndex:BinaryCol] isEqual:bin1],      @"row1.BinaryCol");
    STAssertTrue([[row2 binaryInColumnWithIndex:BinaryCol] isEqual:bin2],      @"row2.BinaryCol");
    STAssertEqualsWithAccuracy([[row1 dateInColumnWithIndex:DateCol] timeIntervalSince1970], (NSTimeInterval)0, 0.99,               @"row1.DateCol");
    STAssertEqualsWithAccuracy([[row2 dateInColumnWithIndex:DateCol] timeIntervalSince1970], [timeNow timeIntervalSince1970], 0.99, @"row2.DateCol");
    STAssertTrue([[row1 tableInColumnWithIndex:TableCol] isEqual:subtab1],    @"row1.TableCol");
    STAssertTrue([[row2 tableInColumnWithIndex:TableCol] isEqual:subtab2],    @"row2.TableCol");
    STAssertTrue([[row1 mixedInColumnWithIndex:MixedCol] isEqual:mixInt1],    @"row1.MixedCol");
    STAssertTrue([[row2 mixedInColumnWithIndex:MixedCol] isEqual:mixSubtab],  @"row2.MixedCol");

    STAssertEquals([table minIntInColumnWithIndex:IntCol], (int64_t)54,                 @"IntCol min");
    STAssertEquals([table maxIntInColumnWithIndex:IntCol], (int64_t)506,                @"IntCol max");
    STAssertEquals([table sumIntColumnWithIndex:IntCol], (int64_t)560,                @"IntCol sum");
    STAssertEquals([table avgIntColumnWithIndex:IntCol], 280.0,                       @"IntCol avg");

    STAssertEquals([table minFloatInColumnWithIndex:FloatCol], 0.7f,                      @"FloatCol min");
    STAssertEquals([table maxFloatInColumnWithIndex:FloatCol], 7.7f,                      @"FloatCol max");
    STAssertEquals([table sumFloatColumnWithIndex:FloatCol], (double)0.7f + 7.7f,       @"FloatCol sum");
    STAssertEquals([table avgFloatColumnWithIndex:FloatCol], ((double)0.7f + 7.7f) / 2, @"FloatCol avg");

    STAssertEquals([table minDoubleInColumnWithIndex:DoubleCol], 0.8,                      @"DoubleCol min");
    STAssertEquals([table maxDoubleInColumnWithIndex:DoubleCol], 8.8,                      @"DoubleCol max");
    STAssertEquals([table sumDoubleColumnWithIndex:DoubleCol], 0.8 + 8.8,                @"DoubleCol sum");
    STAssertEquals([table avgDoubleColumnWithIndex:DoubleCol], (0.8 + 8.8) / 2,          @"DoubleCol avg");
}

- (void)testTableDynamic_Subscripting
{
    TDBTable* _table = [[TDBTable alloc] init];
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithName:@"first" andType:TDBIntType];
    [_table addColumnWithName:@"second" andType:TDBStringType];

    TDBRow* c;

    // Add some rows
    c = [_table addEmptyRow];
    [c setInt: 506 inColumnWithIndex:0];
    [c setString: @"test" inColumnWithIndex:1];

    c = [_table addEmptyRow];
    [c setInt: 4 inColumnWithIndex:0];
    [c setString: @"more test" inColumnWithIndex:1];

    // Get cursor by object subscripting
    c = _table[0];
    STAssertEquals([c intInColumnWithIndex:0], (int64_t)506, @"table[0].first");
    STAssertTrue([[c stringInColumnWithIndex:1] isEqual:@"test"], @"table[0].second");

    // Same but used directly
    STAssertEquals([_table[0] intInColumnWithIndex:0], (int64_t)506, @"table[0].first");
    STAssertTrue([[_table[0] stringInColumnWithIndex:1] isEqual:@"test"], @"table[0].second");
}

- (void)testFirstLastRow
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger col0 = [t addColumnWithName:@"col" andType:TDBStringType];
    
    STAssertNil([t firstRow], @"Table is empty");
    STAssertNil([t lastRow], @"Table is empty");
    
    NSString *value0 = @"value0";
    [t appendRow:@[value0]];
    
    NSString *value1 = @"value1";
    [t appendRow:@[value1]];
    
    STAssertEqualObjects([[t firstRow] stringInColumnWithIndex:col0], value0, nil);
    STAssertEqualObjects( [[t lastRow] stringInColumnWithIndex:col0], value1, nil);
}

- (void)testTableDynamic_Cursor_Subscripting
{
    TDBTable* _table = [[TDBTable alloc] init];
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithName:@"first" andType:TDBIntType];
    [_table addColumnWithName:@"second" andType:TDBStringType];

    TDBRow* c;

    // Add some rows
    c = [_table addEmptyRow];
    c[0] = @506;
    c[1] = @"test";
    STAssertEquals([_table[0] intInColumnWithIndex:0], (int64_t)506, @"table[0].first");
    STAssertTrue([[_table[0] stringInColumnWithIndex:1] isEqual:@"test"], @"table[0].second");

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
