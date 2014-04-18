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

#import <XCTest/XCTest.h>
#import <Foundation/NSException.h>

#import <realm/objc/RLMFast.h>
#import <realm/objc/RLMTable_noinst.h>

#include <string.h>

using namespace std;
@interface TestClass : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *age;
@end

@implementation TestClass
// no needed
@end

@interface TDBDynamicTableTests: XCTestCase
  // Intentionally left blank.
  // No new public instance methods need be defined.
@end

@implementation TDBDynamicTableTests

- (void)testTable
{
    RLMTable* table = [[RLMTable alloc] init];
    NSLog(@"Table: %@", table);
    XCTAssertNotNil(table, @"Table is nil");

    // 1. Add two columns
    [table addColumnWithName:@"first" type:RLMTypeInt];
    [table addColumnWithName:@"second" type:RLMTypeInt];

    // Verify
    XCTAssertEqual(RLMTypeInt, [table columnTypeOfColumnWithIndex:0], @"First column not int");
    XCTAssertEqual(RLMTypeInt, [table columnTypeOfColumnWithIndex:1], @"Second column not int");
    XCTAssertTrue(([[table nameOfColumnWithIndex:0] isEqualToString:@"first"]), @"First not equal to first");
    XCTAssertTrue(([[table nameOfColumnWithIndex:1] isEqualToString:@"second"]), @"Second not equal to second");

    // 2. Add a row with data

    //const size_t ndx = [table addEmptyRow];
    //[table set:0 ndx:ndx value:0];
    //[table set:1 ndx:ndx value:10];

    RLMRow * row = [table addEmptyRow];
    size_t ndx = [row RLM_index];
    [row setInt:0 inColumnWithIndex:0];
    [row setInt:10 inColumnWithIndex:1];

    // Verify
    XCTAssertEqual((int64_t)0, ([table RLM_intInColumnWithIndex:0 atRowIndex:ndx]), @"First not zero");
    XCTAssertEqual((int64_t)10, ([table RLM_intInColumnWithIndex:1 atRowIndex:ndx]), @"Second not 10");
}

-(void)testAddColumn
{
    RLMTable *t = [[RLMTable alloc] init];
    NSUInteger stringColIndex = [t addColumnWithName:@"stringCol" type:RLMTypeString];
    RLMRow *row = [t addEmptyRow];
    [row setString:@"val" inColumnWithIndex:stringColIndex];
}

-(void)testAppendRowsIntColumn
{
    // Add row using object literate
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    XCTAssertNoThrow([t addRow:@[ @1 ]], @"Impossible!");
    XCTAssertEqual((size_t)1, [t rowCount], @"Expected 1 row");
    XCTAssertNoThrow([t addRow:@[ @2 ]], @"Impossible!");
    XCTAssertEqual((size_t)2, [t rowCount], @"Expected 2 rows");
    XCTAssertEqual((int64_t)1, [t RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 1 expected");
    XCTAssertEqual((int64_t)2, [t RLM_intInColumnWithIndex:0 atRowIndex:1], @"Value 2 expected");
    XCTAssertThrows([t addRow:@[@"Hello"]], @"Wrong type");
    XCTAssertThrows(([t addRow:@[@1, @"Hello"]]), @"Wrong number of columns");
}

-(void)testInsertRowsIntColumn
{
    // Add row using object literate
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    XCTAssertNoThrow([t insertRow:@[ @1 ] atIndex:0], @"Impossible!");
    XCTAssertEqual((size_t)1, [t rowCount], @"Expected 1 row");
    XCTAssertNoThrow([t insertRow:@[ @2 ] atIndex:0], @"Impossible!");
    XCTAssertEqual((size_t)2, [t rowCount], @"Expected 2 rows");
    XCTAssertEqual((int64_t)1, [t RLM_intInColumnWithIndex:0 atRowIndex:1], @"Value 1 expected");
    XCTAssertEqual((int64_t)2, [t RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
    XCTAssertThrows([t insertRow:@[@"Hello"] atIndex:0], @"Wrong type");
    XCTAssertThrows(([t insertRow:@[@1, @"Hello"] atIndex:0]), @"Wrong number of columns");
}

-(void)testUpdateRowIntColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    [t insertRow:@[@1] atIndex:0];
    t[0] = @[@2];
    XCTAssertEqual((int64_t)2, [t RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
}

-(void)testAppendRowGenericObject
{
    RLMTable* table1 = [[RLMTable alloc] init];
    [table1 addColumnWithName:@"name" type:RLMTypeString];
    [table1 addColumnWithName:@"age" type:RLMTypeInt];

    TestClass *person = [TestClass new];
    person.name = @"Joe";
    person.age = @11;
    XCTAssertNoThrow([table1 addRow:person], @"Cannot add person");
    XCTAssertEqual((NSUInteger)1, table1.rowCount, @"1 row excepted");
    XCTAssertEqual((long long)11, [(NSNumber *)table1[0][@"age"] longLongValue], @"11 excepted");
    XCTAssertTrue([((NSString *)table1[0][@"name"]) isEqualToString:@"Joe"], @"'Joe' excepted");

    RLMTable* table2 = [[RLMTable alloc] init];
    [table2 addColumnWithName:@"name" type:RLMTypeString];
    [table2 addColumnWithName:@"age" type:RLMTypeString];

    XCTAssertThrows([table2 addRow:person], @"Impossible");
    XCTAssertEqual((NSUInteger)0, table2.rowCount, @"0 rows excepted");
}

-(void)testUpdateRowWithLabelsIntColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    [t insertRow:@[@1] atIndex:0];
    t[0] = @{@"first": @2};
    XCTAssertEqual((int64_t)2, [t RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
}


-(void)testAppendRowWithLabelsIntColumn
{
    // Add row using object literate
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];

    XCTAssertNoThrow([t addRow:@{ @"first": @1 }], @"Impossible!");
    XCTAssertEqual((size_t)1, [t rowCount], @"Expected 1 row");

    XCTAssertNoThrow([t addRow:@{ @"first": @2 }], @"Impossible!");
    XCTAssertEqual((size_t)2, [t rowCount], @"Expected 2 rows");

    XCTAssertEqual((int64_t)1, [t RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 1 expected");
    XCTAssertEqual((int64_t)2, [t RLM_intInColumnWithIndex:0 atRowIndex:1], @"Value 2 expected");
    
    XCTAssertThrows([t addRow:@{ @"first": @"Hello" }], @"Wrong type");
    XCTAssertEqual((size_t)2, [t rowCount], @"Expected 2 rows");

    XCTAssertNoThrow(([t addRow:@{ @"first": @1, @"second": @"Hello" }]), @"dh");
    XCTAssertEqual((size_t)3, [t rowCount], @"Expected 3 rows");

    XCTAssertNoThrow(([t addRow:@{ @"second": @1 }]), @"This is impossible");
    XCTAssertEqual((size_t)4, [t rowCount], @"Expected 4 rows");

    XCTAssertEqual((int64_t)0, [t RLM_intInColumnWithIndex:0 atRowIndex:3], @"Value 0 expected");
}

-(void)testInsertRowWithLabelsIntColumn
{
    // Add row using object literate
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    
    XCTAssertNoThrow(([t insertRow:@{ @"first": @1 } atIndex:0]), @"Impossible!");
    XCTAssertEqual((size_t)1, [t rowCount], @"Expected 1 row");
    
    XCTAssertNoThrow(([t insertRow:@{ @"first": @2 } atIndex:0]), @"Impossible!");
    XCTAssertEqual((size_t)2, [t rowCount], @"Expected 2 rows");
    
    XCTAssertEqual((int64_t)1, ([t RLM_intInColumnWithIndex:0 atRowIndex:1]), @"Value 1 expected");
    XCTAssertEqual((int64_t)2, ([t RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 2 expected");
    
    XCTAssertThrows(([t insertRow:@{ @"first": @"Hello" } atIndex:0]), @"Wrong type");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"Expected 2 rows");
    
    XCTAssertNoThrow(([t insertRow:@{ @"first": @3, @"second": @"Hello"} atIndex:0]), @"Has 'first'");
    XCTAssertEqual((size_t)3, [t rowCount], @"Expected 3 rows");
    
    XCTAssertNoThrow(([t insertRow:@{ @"second": @4 } atIndex:0]), @"This is impossible");
    XCTAssertEqual((size_t)4, [t rowCount], @"Expected 4 rows");
    XCTAssertTrue((int64_t)0 == ([t RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 0 expected");
}


-(void)testAppendRowsIntStringColumns
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    [t addColumnWithName:@"second" type:RLMTypeString];

    XCTAssertNoThrow(([t addRow:@[@1, @"Hello"]]), @"addRow 1");
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
    XCTAssertEqual((int64_t)1, ([t RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 1 expected");
    XCTAssertTrue(([[t RLM_stringInColumnWithIndex:1 atRowIndex:0] isEqualToString:@"Hello"]), @"Value 'Hello' expected");
    XCTAssertThrows(([t addRow:@[@1, @2]]), @"addRow 2");
}


-(void)testAppendRowWithLabelsIntStringColumns
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    [t addColumnWithName:@"second" type:RLMTypeString];
    XCTAssertNoThrow(([t addRow:@{@"first": @1, @"second": @"Hello"}]), @"addRowWithLabels 1");
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
    XCTAssertEqual((int64_t)1, ([t RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 1 expected");
    XCTAssertTrue(([[t RLM_stringInColumnWithIndex:1 atRowIndex:0] isEqualToString:@"Hello"]), @"Value 'Hello' expected");
    XCTAssertThrows(([t addRow:@{@"first": @1, @"second": @2}]), @"addRowWithLabels 2");
}


-(void)testAppendRowsDoubleColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeDouble];
    XCTAssertNoThrow(([t addRow:@[@3.14]]), @"Cannot insert 'double'");  /* double is default */
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowWithLabelsDoubleColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeDouble];
    XCTAssertNoThrow(([t addRow:@{@"first": @3.14}]), @"Cannot insert 'double'");   /* double is default */
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowsFloatColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeFloat];
    XCTAssertNoThrow(([t addRow:@[@3.14F]]), @"Cannot insert 'float'"); /* F == float */
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowWithLabelsFloatColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeFloat];
    XCTAssertNoThrow(([t addRow:@{@"first": @3.14F}]), @"Cannot insert 'float'");   /* F == float */
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
}

-(void)testAppendRowsDateColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeDate];
    XCTAssertNoThrow(([t addRow:@[@1000000000]]), @"Cannot insert 'time_t'"); /* 2001-09-09 01:46:40 */
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");

    NSDate *d = [[NSDate alloc] initWithTimeIntervalSince1970:1396963324];   
    XCTAssertNoThrow(([t addRow:@[d]]), @"Cannot insert 'NSDate'");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");
}

-(void)testAppendRowWithLabelsDateColumn
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeDate];

    XCTAssertNoThrow(([t addRow:@{@"first": @1000000000}]), @"Cannot insert 'time_t'");   // 2001-09-09 01:46:40
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
    
    NSDate *d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
    XCTAssertNoThrow(([t addRow:@{@"first": d}]), @"Cannot insert 'NSDate'");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");

// The following tests were commented out because they fail for
// obviopus reasons. Oleks, please investigate.

/*
    XCTAssertNoThrow(([t addRow:@{@"first": @1000000000}]), @"Cannot insert 'time_t'");   // 2001-09-09 01:46:40
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");

    d = [[NSDate alloc] initWithTimeIntervalSince1970:1396963324];
    XCTAssertNoThrow(([t addRow:@{@"first": d}]), @"Cannot insert 'NSDate'");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");
    XCTAssertNoThrow(([t addRow:@{@"first": @1000000000}]), @"Cannot insert 'time_t'");   // 2001-09-09 01:46:40
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
    
    d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
    XCTAssertNoThrow(([t addRow:@{@"first": d}]), @"Cannot insert 'NSDate'");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");
*/
}

-(void)testAppendRowsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeBinary];
    XCTAssertNoThrow(([t addRow:@[bin2]]), @"Cannot insert 'binary'");
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");

    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    XCTAssertNoThrow(([t addRow:@[nsd]]), @"Cannot insert 'NSData'");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");
}


-(void)testAppendRowWithLabelsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeBinary];

    XCTAssertNoThrow(([t addRow:@{@"first": bin2}]), @"Cannot insert 'binary'");
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");

    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    XCTAssertNoThrow(([t addRow:@{@"first": nsd}]), @"Cannot insert 'NSData'");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");
}

-(void)testAppendRowsTooManyItems
{
    RLMTable *t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    XCTAssertThrows(([t addRow:@[@1, @1]]), @"Too many items for a row.");
}

-(void)testAppendRowsTooFewItems
{
    RLMTable *t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    XCTAssertThrows(([t addRow:@[]]),  @"Too few items for a row.");
}

-(void)testAppendRowsWrongType
{
    RLMTable *t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    XCTAssertThrows(([t addRow:@[@YES]]), @"Wrong type for column.");
    XCTAssertThrows(([t addRow:@[@""]]),  @"Wrong type for column.");
    XCTAssertThrows(([t addRow:@[@3.5]]), @"Wrong type for column.");
    XCTAssertThrows(([t addRow:@[@3.5F]]),  @"Wrong type for column.");
    XCTAssertThrows(([t addRow:@[@[]]]),  @"Wrong type for column.");
}

-(void)testAppendRowsBoolColumn
{
    RLMTable *t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeBool];
    XCTAssertNoThrow(([t addRow:@[@YES]]), @"Cannot append bool column.");
    XCTAssertNoThrow(([t addRow:@[@NO]]), @"Cannot append bool column.");
    XCTAssertEqual((size_t)2, [t rowCount], @"2 rows expected");
}

-(void)testAppendRowWithLabelsBoolColumn
{
    RLMTable *t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeBool];
    XCTAssertNoThrow(([t addRow:@{@"first": @YES}]), @"Cannot append bool column.");
    XCTAssertNoThrow(([t addRow:@{@"first": @NO}]), @"Cannot append bool column.");
    XCTAssertEqual((size_t)2, [t rowCount], @"2 rows expected");
}

-(void)testAppendRowsIntSubtableColumns
{
    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeInt];
    RLMDescriptor * descr = [t descriptor];
    RLMDescriptor * subdescr = [descr addColumnTable:@"second"];
    [subdescr addColumnWithName:@"TableCol_IntCol" type:RLMTypeInt];
    XCTAssertNoThrow(([t addRow:@[@1, @[]]]), @"1 row excepted");
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row expected");
    XCTAssertNoThrow(([t addRow:@[@2, @[ @[@3], @[@4] ] ]]), @"Wrong");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows expected");
}

-(void)testAppendRowsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];

    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeMixed];
    XCTAssertNoThrow(([t addRow:@[@1]]), @"Cannot insert 'int'");
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row excepted");
    XCTAssertNoThrow(([t addRow:@[@"Hello"]]), @"Cannot insert 'string'");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");
    XCTAssertNoThrow(([t addRow:@[@3.14f]]), @"Cannot insert 'float'");
    XCTAssertEqual((size_t)3, ([t rowCount]), @"3 rows excepted");
    XCTAssertNoThrow(([t addRow:@[@3.14]]), @"Cannot insert 'double'");
    XCTAssertEqual((size_t)4, ([t rowCount]), @"4 rows excepted");
    XCTAssertNoThrow(([t addRow:@[@YES]]), @"Cannot insert 'bool'");
    XCTAssertEqual((size_t)5, ([t rowCount]), @"5 rows excepted");
    XCTAssertNoThrow(([t addRow:@[bin2]]), @"Cannot insert 'binary'");
    XCTAssertEqual((size_t)6, ([t rowCount]), @"6 rows excepted");
}

-(void)testAppendRowWithLabelsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];

    RLMTable* t = [[RLMTable alloc] init];
    [t addColumnWithName:@"first" type:RLMTypeMixed];
    XCTAssertNoThrow(([t addRow:@{@"first": @1}]), @"Cannot insert 'int'");
    XCTAssertEqual((size_t)1, ([t rowCount]), @"1 row excepted");
    XCTAssertNoThrow(([t addRow:@{@"first": @"Hello"}]), @"Cannot insert 'string'$");
    XCTAssertEqual((size_t)2, ([t rowCount]), @"2 rows excepted");
    XCTAssertNoThrow(([t addRow:@{@"first": @3.14f}]), @"Cannot insert 'float'");
    XCTAssertEqual((size_t)3, ([t rowCount]), @"3 rows excepted");
    XCTAssertNoThrow(([t addRow:@{@"first": @3.14}]), @"Cannot insert 'double'");
    XCTAssertEqual((size_t)4, ([t rowCount]), @"4 rows excepted");
    XCTAssertNoThrow(([t addRow:@{@"first": @YES}]), @"Cannot insert 'bool'");
    XCTAssertEqual((size_t)5, ([t rowCount]), @"5 rows excepted");
    XCTAssertNoThrow(([t addRow:@{@"first": bin2}]), @"Cannot insert 'binary'");
    XCTAssertEqual((size_t)6, ([t rowCount]), @"6 rows excepted");
}

-(void)testRemoveColumns
{

    RLMTable *table = [[RLMTable alloc] init];
    [table addColumnWithName:@"col0" type:RLMTypeInt];
    XCTAssertTrue(table.columnCount == 1,@"1 column added" );

    [table removeColumnWithIndex:0];
    XCTAssertTrue(table.columnCount  == 0, @"Colum removed");

    for (int i=0;i<10;i++) {
        [table addColumnWithName:@"name" type:RLMTypeInt];
    }

    XCTAssertThrows([table removeColumnWithIndex:10], @"Out of bounds");
    XCTAssertThrows([table removeColumnWithIndex:-1], @"Less than zero colIndex");

    XCTAssertTrue(table.columnCount  == 10, @"10 columns added");

    for (int i=0;i<10;i++) {
        [table removeColumnWithIndex:0];
    }

    XCTAssertEqual(table.columnCount, (NSUInteger)0, @"Colums removed");
    XCTAssertThrows([table removeColumnWithIndex:1], @"No columns added");
    XCTAssertThrows([table removeColumnWithIndex:-1], @"Less than zero colIndex");
}

-(void)testRenameColumns
{
    RLMTable *table = [[RLMTable alloc] init];
    XCTAssertThrows([table renameColumnWithIndex:0 to:@"someName"], @"Out of bounds");
    
    [table addColumnWithName:@"oldName" type:RLMTypeInt];
    
    [table renameColumnWithIndex:0 to:@"newName"];
    XCTAssertEqualObjects([table nameOfColumnWithIndex:0], @"newName", @"Get column name");
    
    [table renameColumnWithIndex:0 to:@"evenNewerName"];
    XCTAssertEqualObjects([table nameOfColumnWithIndex:0], @"evenNewerName", @"Get column name");
    
    XCTAssertThrows([table renameColumnWithIndex:1 to:@"someName"], @"Out of bounds");
    XCTAssertThrows([table renameColumnWithIndex:-1 to:@"someName"], @"Less than zero colIndex");
    
    [table addColumnWithName:@"oldName2" type:RLMTypeInt];
    [table renameColumnWithIndex:1 to:@"newName2"];
    XCTAssertEqualObjects([table nameOfColumnWithIndex:1], @"newName2", @"Get column name");
    
    XCTAssertThrows([table renameColumnWithIndex:2 to:@"someName"], @"Out of bounds");
}


- (void)testColumnlessCount
{
    RLMTable* table = [[RLMTable alloc] init];
    XCTAssertEqual((size_t)0, [table rowCount], @"Columnless table has 0 rows.");
}



- (void)testColumnlessClear
{
    RLMTable* table = [[RLMTable alloc] init];
    [table removeAllRows];
    XCTAssertEqual((size_t)0, [table rowCount], @"Columnless table has 0 rows.");
}

- (void)testColumnlessOptimize
{
    RLMTable* table = [[RLMTable alloc] init];
    XCTAssertEqual((size_t)0, [table rowCount], @"Columnless table has 0 rows.");
    [table optimize];
    XCTAssertEqual((size_t)0, [table rowCount], @"Columnless table has 0 rows.");
}


- (void)testColumnlessIsEqual
{
    RLMTable* table1 = [[RLMTable alloc] init];
    RLMTable* table2 = [[RLMTable alloc] init];
    XCTAssertTrue([table1 isEqual:table1], @"Columnless table is equal to itself.");
    XCTAssertTrue([table1 isEqual:table2], @"Columnless table is equal to another columnless table.");
    XCTAssertTrue([table2 isEqual:table1], @"Columnless table is equal to another columnless table.");
}

- (void)testColumnlessColumnCount
{
    RLMTable* table = [[RLMTable alloc] init];
    XCTAssertEqual((size_t)0, [table columnCount], @"Columnless table has column count 0.");
}

/*
- (void)testColumnlessNameOfColumnWithIndex
{
    RLMTable* table = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([table nameOfColumnWithIndex:NSNotFound],
        NSException, NSRangeException,
        @"Columnless table has no column names.");
    XCTAssertThrowsSpecific([table nameOfColumnWithIndex:(0)],
        NSException, NSRangeException,
        @"Columnless table has no column names.");
    XCTAssertThrowsSpecific([table nameOfColumnWithIndex:1],
        NSException, NSRangeException,
        @"Columnless table has no column names.");
}

- (void)testColumnlessGetColumnType
{
    RLMTable* t = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([t getColumnType:((size_t)-1)],
        NSException, NSRangeException,
        @"Columnless table has no column types.");
    XCTAssertThrowsSpecific([t getColumnType:((size_t)0)],
        NSException, NSRangeException,
        @"Columnless table has no column types.");
    XCTAssertThrowsSpecific([t getColumnType:((size_t)1)],
        NSException, NSRangeException,
        @"Columnless table has no column types.");
}

- (void)testColumnlessCursorAtIndex
{
    RLMTable* t = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([t cursorAtIndex:((size_t)-1)],
        NSException, NSRangeException,
        @"Columnless table has no cursors.");
    XCTAssertThrowsSpecific([t cursorAtIndex:((size_t)0)],
        NSException, NSRangeException,
        @"Columnless table has no cursors.");
    XCTAssertThrowsSpecific([t cursorAtIndex:((size_t)1)],
        NSException, NSRangeException,
        @"Columnless table has no cursors.");
}

- (void)testColumnlessCursorAtLastIndex
{
    RLMTable* t = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([t cursorAtLastIndex],
        NSException, NSRangeException,
        @"Columnless table has no cursors."); 
}

- (void)testRemoveRowAtIndex
{
    RLMTable *t = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([t removeRowAtIndex:((size_t)-1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    XCTAssertThrowsSpecific([t removeRowAtIndex:((size_t)0)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    XCTAssertThrowsSpecific([t removeRowAtIndex:((size_t)1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}

- (void)testColumnlessRemoveLastRow
{
    RLMTable *t = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([t removeLastRow],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}

- (void)testColumnlessGetTableSize
{
    RLMTable *t = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([t getTableSize:((size_t)0) ndx:((size_t)-1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    XCTAssertThrowsSpecific([t getTableSize:((size_t)0) ndx:((size_t)0)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    XCTAssertThrowsSpecific([t getTableSize:((size_t)0) ndx:((size_t)1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}

- (void)testColumnlessClearSubtable
{
    RLMTable *t = [[RLMTable alloc] init];
    XCTAssertThrowsSpecific([t clearSubtable:((size_t)0) ndx:((size_t)-1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    XCTAssertThrowsSpecific([t clearSubtable:((size_t)0) ndx:((size_t)0)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
    XCTAssertThrowsSpecific([t clearSubtable:((size_t)0) ndx:((size_t)1)],
        NSException, NSRangeException,
        @"No rows in a columnless table.");
}
*/
- (void)testColumnlessSetIndex
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t setIndex:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t setIndex:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t setIndex:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessHasIndex
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t hasIndex:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t hasIndex:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t hasIndex:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithIntColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t countWithIntColumn:((size_t)-1) andValue: 0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithIntColumn:((size_t)0) andValue: 0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithIntColumn:((size_t)1) andValue: 0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithFloatColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t countWithFloatColumn:((size_t)-1) andValue: 0.0f],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithFloatColumn:((size_t)0) andValue: 0.0f],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithFloatColumn:((size_t)1) andValue: 0.0f],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithDoubleColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t countWithDoubleColumn:((size_t)-1) andValue: 0.0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithDoubleColumn:((size_t)0) andValue: 0.0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithDoubleColumn:((size_t)1) andValue: 0.0],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessCountWithStringColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t countWithStringColumn:((size_t)-1) andValue: @""],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithStringColumn:((size_t)0) andValue: @""],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t countWithStringColumn:((size_t)1) andValue: @""],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessSumWithIntColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t sumWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t sumWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t sumWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessSumWithFloatColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t sumWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t sumWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t sumWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessSumWithDoubleColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t sumWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t sumWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t sumWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMaximumWithIntColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t maximumWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t maximumWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t maximumWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMaximumWithFloatColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t maximumWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t maximumWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t maximumWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMaximumWithDoubleColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t maximumWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t maximumWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t maximumWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMinimumWithIntColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t minimumWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t minimumWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t minimumWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMinimumWithFloatColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t minimumWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t minimumWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t minimumWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessMinimumWithDoubleColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t minimumWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t minimumWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t minimumWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessAverageWithIntColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t averageWithIntColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t averageWithIntColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t averageWithIntColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessAverageWithFloatColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t averageWithFloatColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t averageWithFloatColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t averageWithFloatColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testColumnlessAverageWithDoubleColumn
{
// SEGFAULT
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t averageWithDoubleColumn:((size_t)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t averageWithDoubleColumn:((size_t)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t averageWithDoubleColumn:((size_t)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
}

- (void)testDataTypes_Dynamic
{
    RLMTable* table = [[RLMTable alloc] init];
    NSLog(@"Table: %@", table);
    XCTAssertNotNil(table, @"Table is nil");

    RLMDescriptor * desc = [table descriptor];

    [desc addColumnWithName:@"BoolCol" type:RLMTypeBool];    const size_t BoolCol = 0;
    [desc addColumnWithName:@"IntCol" type:RLMTypeInt];     const size_t IntCol = 1;
    [desc addColumnWithName:@"FloatCol" type:RLMTypeFloat];   const size_t FloatCol = 2;
    [desc addColumnWithName:@"DoubleCol" type:RLMTypeDouble];  const size_t DoubleCol = 3;
    [desc addColumnWithName:@"StringCol" type:RLMTypeString];  const size_t StringCol = 4;
    [desc addColumnWithName:@"BinaryCol" type:RLMTypeBinary];  const size_t BinaryCol = 5;
    [desc addColumnWithName:@"DateCol" type:RLMTypeDate];    const size_t DateCol = 6;
    RLMDescriptor * subdesc = [desc addColumnTable:@"TableCol"]; const size_t TableCol = 7;
    [desc addColumnWithName:@"MixedCol" type:RLMTypeMixed];   const size_t MixedCol = 8;

    [subdesc addColumnWithName:@"TableCol_IntCol" type:RLMTypeInt];

    // Verify column types
    XCTAssertEqual(RLMTypeBool,   [table columnTypeOfColumnWithIndex:0], @"First column not bool");
    XCTAssertEqual(RLMTypeInt,    [table columnTypeOfColumnWithIndex:1], @"Second column not int");
    XCTAssertEqual(RLMTypeFloat,  [table columnTypeOfColumnWithIndex:2], @"Third column not float");
    XCTAssertEqual(RLMTypeDouble, [table columnTypeOfColumnWithIndex:3], @"Fourth column not double");
    XCTAssertEqual(RLMTypeString, [table columnTypeOfColumnWithIndex:4], @"Fifth column not string");
    XCTAssertEqual(RLMTypeBinary, [table columnTypeOfColumnWithIndex:5], @"Sixth column not binary");
    XCTAssertEqual(RLMTypeDate,   [table columnTypeOfColumnWithIndex:6], @"Seventh column not date");
    XCTAssertEqual(RLMTypeTable,  [table columnTypeOfColumnWithIndex:7], @"Eighth column not table");
    XCTAssertEqual(RLMTypeMixed,  [table columnTypeOfColumnWithIndex:8], @"Ninth column not mixed");


    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate date];

    RLMTable* subtab1 = [[RLMTable alloc] init];
    [subtab1 addColumnWithName:@"TableCol_IntCol" type:RLMTypeInt];

    RLMTable* subtab2 = [[RLMTable alloc] init];
    [subtab2 addColumnWithName:@"TableCol_IntCol" type:RLMTypeInt];

    RLMRow * cursor;
    cursor = [subtab1 addEmptyRow];
    [cursor setInt:200 inColumnWithIndex:0];

    cursor = [subtab2 addEmptyRow];
    [cursor setInt:100 inColumnWithIndex:0];

    NSNumber *mixInt1   = [NSNumber numberWithInt:1];

    RLMRow * c;
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
    [c setDate:    timeNow   inColumnWithIndex:DateCol];
    [c setTable:   subtab2   inColumnWithIndex:TableCol];
    [c setMixed:   subtab2   inColumnWithIndex:MixedCol];

    RLMRow * row1 = [table rowAtIndex:0];
    RLMRow * row2 = [table rowAtIndex:1];
    

    XCTAssertEqual([row1 boolInColumnWithIndex:BoolCol], NO, @"row1.BoolCol");
    XCTAssertEqual([row2 boolInColumnWithIndex:BoolCol], YES,                   @"row2.BoolCol");
    XCTAssertEqual([row1 intInColumnWithIndex:IntCol], (int64_t)54,             @"row1.IntCol");
    XCTAssertEqual([row2 intInColumnWithIndex:IntCol], (int64_t)506,            @"row2.IntCol");
    XCTAssertEqual([row1 floatInColumnWithIndex:FloatCol], 0.7f,                @"row1.FloatCol");
    XCTAssertEqual([row2 floatInColumnWithIndex:FloatCol], 7.7f,                @"row2.FloatCol");
    XCTAssertEqual([row1 doubleInColumnWithIndex:DoubleCol], 0.8,               @"row1.DoubleCol");
    XCTAssertEqual([row2 doubleInColumnWithIndex:DoubleCol], 8.8,               @"row2.DoubleCol");
    XCTAssertTrue([[row1 stringInColumnWithIndex:StringCol] isEqual:@"foo"],    @"row1.StringCol");
    XCTAssertTrue([[row2 stringInColumnWithIndex:StringCol] isEqual:@"banach"], @"row2.StringCol");
    XCTAssertTrue([[row1 binaryInColumnWithIndex:BinaryCol] isEqual:bin1],      @"row1.BinaryCol");
    XCTAssertTrue([[row2 binaryInColumnWithIndex:BinaryCol] isEqual:bin2],      @"row2.BinaryCol");
    XCTAssertEqualWithAccuracy([[row1 dateInColumnWithIndex:DateCol] timeIntervalSince1970], (NSTimeInterval)0, 0.99, @"row1.DateCol");
    XCTAssertTrue((fabs([[row2 dateInColumnWithIndex:DateCol] timeIntervalSinceDate:timeNow]) < 1.0), @"row2.DateCol");
    XCTAssertTrue([[row1 tableInColumnWithIndex:TableCol] isEqual:subtab1],    @"row1.TableCol");
    XCTAssertTrue([[row2 tableInColumnWithIndex:TableCol] isEqual:subtab2],    @"row2.TableCol");
    XCTAssertTrue([[row1 mixedInColumnWithIndex:MixedCol] isEqual:mixInt1],    @"row1.MixedCol");
    XCTAssertTrue([[row2 mixedInColumnWithIndex:MixedCol] isKindOfClass:[RLMTable class]], @"RLMTable expected");
    XCTAssertTrue([[row2 mixedInColumnWithIndex:MixedCol] isEqual:subtab2],    @"row2.MixedCol");

    XCTAssertEqual([table minIntInColumnWithIndex:IntCol], (int64_t)54,                 @"IntCol min");
    XCTAssertEqual([table maxIntInColumnWithIndex:IntCol], (int64_t)506,                @"IntCol max");
    XCTAssertEqual([table sumIntColumnWithIndex:IntCol], (int64_t)560,                @"IntCol sum");
    XCTAssertEqual([table avgIntColumnWithIndex:IntCol], 280.0,                       @"IntCol avg");

    XCTAssertEqual([table minFloatInColumnWithIndex:FloatCol], 0.7f,                      @"FloatCol min");
    XCTAssertEqual([table maxFloatInColumnWithIndex:FloatCol], 7.7f,                      @"FloatCol max");
    XCTAssertEqual([table sumFloatColumnWithIndex:FloatCol], (double)0.7f + 7.7f,       @"FloatCol sum");
    XCTAssertEqual([table avgFloatColumnWithIndex:FloatCol], ((double)0.7f + 7.7f) / 2, @"FloatCol avg");

    XCTAssertEqual([table minDoubleInColumnWithIndex:DoubleCol], 0.8,                      @"DoubleCol min");
    XCTAssertEqual([table maxDoubleInColumnWithIndex:DoubleCol], 8.8,                      @"DoubleCol max");
    XCTAssertEqual([table sumDoubleColumnWithIndex:DoubleCol], 0.8 + 8.8,                @"DoubleCol sum");
    XCTAssertEqual([table avgDoubleColumnWithIndex:DoubleCol], (0.8 + 8.8) / 2,          @"DoubleCol avg");
}

- (void)testTableDynamic_Subscripting
{
    RLMTable* table = [[RLMTable alloc] init];
    XCTAssertNotNil(table, @"Table is nil");

    // 1. Add two columns
    [table addColumnWithName:@"first" type:RLMTypeInt];
    [table addColumnWithName:@"second" type:RLMTypeString];

    RLMRow * row;

    // Add some rows
    row = [table addEmptyRow];
    [row setInt: 506 inColumnWithIndex:0];
    [row setString: @"test" inColumnWithIndex:1];

    row = [table addEmptyRow];
    [row setInt: 4 inColumnWithIndex:0];
    [row setString: @"more test" inColumnWithIndex:1];

    // Get cursor by object subscripting
    row = table[0];
    XCTAssertEqual([row intInColumnWithIndex:0], (int64_t)506, @"table[0].first");
    XCTAssertTrue([[row stringInColumnWithIndex:1] isEqual:@"test"], @"table[0].second");

    // Same but used directly
    XCTAssertEqual([table[0] intInColumnWithIndex:0], (int64_t)506, @"table[0].first");
    XCTAssertTrue([[table[0] stringInColumnWithIndex:1] isEqual:@"test"], @"table[0].second");
}

- (void)testFirstLastRow
{
    RLMTable *table = [[RLMTable alloc] init];
    NSUInteger col0 = [table addColumnWithName:@"col" type:RLMTypeString];

    XCTAssertNil([table firstRow], @"Table is empty");
    XCTAssertNil([table lastRow], @"Table is empty");
    
    NSString *value0 = @"value0";
    [table addRow:@[value0]];
    
    NSString *value1 = @"value1";
    [table addRow:@[value1]];
    
    XCTAssertEqualObjects([[table firstRow] stringInColumnWithIndex:col0], value0, @"");
    XCTAssertEqualObjects( [[table lastRow] stringInColumnWithIndex:col0], value1, @"");
}

- (void)testTableDynamic_Cursor_Subscripting
{
    RLMTable *table = [[RLMTable alloc] init];
    XCTAssertNotNil(table, @"Table is nil");

    // 1. Add two columns
    [table addColumnWithName:@"first" type:RLMTypeInt];
    [table addColumnWithName:@"second" type:RLMTypeString];

    RLMRow * row;

    // Add some rows
    row = [table addEmptyRow];
    row[0] = @506;
    row[1] = @"test";
    XCTAssertEqual([table[0] intInColumnWithIndex:0], (int64_t)506, @"table[0].first");
    XCTAssertTrue([[table[0] stringInColumnWithIndex:1] isEqual:@"test"], @"table[0].second");

    row = [table addEmptyRow];
    row[@"first"]  = @4;
    row[@"second"] = @"more test";

    // Get values from cursor by object subscripting
    row = table[0];
    XCTAssertTrue([row[0] isEqual:@506], @"table[0].first");
    XCTAssertTrue([row[1] isEqual:@"test"], @"table[0].second");

    // Same but used with column name
    XCTAssertTrue([row[@"first"]  isEqual:@506], @"table[0].first");
    XCTAssertTrue([row[@"second"] isEqual:@"test"], @"table[0].second");

    // Combine with subscripting for rows
    XCTAssertTrue([table[0][0] isEqual:@506], @"table[0].first");
    XCTAssertTrue([table[0][1] isEqual:@"test"], @"table[0].second");
    XCTAssertTrue([table[0][@"first"] isEqual:@506], @"table[0].first");
    XCTAssertTrue([table[0][@"second"] isEqual:@"test"], @"table[0].second");

    XCTAssertTrue([table[1][0] isEqual:@4], @"table[1].first");
    XCTAssertTrue([table[1][1] isEqual:@"more test"], @"table[1].second");
    XCTAssertTrue([table[1][@"first"] isEqual:@4], @"table[1].first");
    XCTAssertTrue([table[1][@"second"] isEqual:@"more test"], @"table[1].second");
}

- (void)testTableDynamic_KeyedSubscripting
{
    RLMTable* table = [[RLMTable alloc] init];
    
    [table addColumnWithName:@"name" type:RLMTypeString];
    [table addColumnWithName:@"id" type:RLMTypeInt];
    
    [table addRow:@{@"name" : @"Test1", @"id" : @24}];
    [table addRow:@{@"name" : @"Test2", @"id" : @25}];
    
    XCTAssertNotNil(table[@"Test1"], @"table[@\"Test1\"] should not be nil");
    XCTAssertEqualObjects(table[@"Test1"][@"name"], @"Test1", @"table[@\"Test24\"][@\"name\"] should be equal to Test1");
    XCTAssertEqualObjects(table[@"Test1"][@"id"], @24, @"table[@\"Test24\"][@\"id\"] should be equal to @24");
    
    XCTAssertNotNil(table[@"Test2"], @"table[@\"Test2\"] should not be nil");
    XCTAssertEqualObjects(table[@"Test2"][@"name"], @"Test2", @"table[@\"Test24\"][@\"name\"] should be equal to Test2");
    XCTAssertEqualObjects(table[@"Test2"][@"id"], @25, @"table[@\"Test24\"][@\"id\"] should be equal to @25");
    
    XCTAssertNil(table[@"foo"], @"table[\"foo\"] should be nil");
    
    RLMTable* errTable = [[RLMTable alloc] init];
    
    XCTAssertThrows(errTable[@"X"], @"Accessing RLMRow via keyed subscript on undefined column should throw exception");
    
    [errTable addColumnWithName:@"id" type:RLMTypeInt];
    
    XCTAssertThrows(errTable[@"X"], @"Accessing RLMRow via keyed subscript on a column that is not of type RLMTypeString should throw exception");
}

-(void)testTableDynamic_Row_Set
{
    RLMTable *table = [[RLMTable alloc] init];
    XCTAssertNotNil(table, @"Table is nil");

    // Add two columns
    [table addColumnWithName:@"int"    type:RLMTypeInt];
    [table addColumnWithName:@"string" type:RLMTypeString];
    [table addColumnWithName:@"float"  type:RLMTypeFloat];
    [table addColumnWithName:@"double" type:RLMTypeDouble];
    [table addColumnWithName:@"bool" type:RLMTypeBool];
    [table addColumnWithName:@"date"   type:RLMTypeDate];
    [table addColumnWithName:@"binary" type:RLMTypeBinary];

    char bin4[] = {1, 2, 4, 4};
    // Add three rows
    [table addRow:@[@1, @"Hello", @3.1415f, @3.1415, @NO, [NSDate dateWithTimeIntervalSince1970:1], [NSData dataWithBytes:bin4 length:4]]];
    [table addRow:@[@2, @"World", @2.7182f, @2.7182, @NO, [NSDate dateWithTimeIntervalSince1970:2], [NSData dataWithBytes:bin4 length:4]]];
    [table addRow:@[@3, @"Hello World", @1.0f, @1.0, @NO, [NSDate dateWithTimeIntervalSince1970:3], [NSData dataWithBytes:bin4 length:4]]];

    RLMRow * col = table[1];
    col[0] = @4;
    col[1] = @"Universe";
    col[2] = @4.6692f;
    col[3] = @4.6692;
    col[4] = @YES;
    col[5] = [NSDate dateWithTimeIntervalSince1970:4];
    char bin5[] = {5, 6, 7, 8, 9};
    col[6] = [NSData dataWithBytes:bin5 length:5];

    XCTAssertTrue([table[1][@"int"] isEqualToNumber:@4], @"Value 4 expected");
    XCTAssertTrue([table[1][@"string"] isEqualToString:@"Universe"], @"Value 'Universe' expected");
    XCTAssertTrue([table[1][@"float"] isEqualToNumber:@4.6692f], @"Value '4.6692f' expected");
    XCTAssertTrue([table[1][@"double"] isEqualToNumber:@4.6692], @"Value '4.6692' expected");
    XCTAssertTrue([table[1][@"bool"] isEqual:@YES], @"Value 'YES' expected");
    XCTAssertTrue([table[1][@"date"] isEqualToDate:[NSDate dateWithTimeIntervalSince1970:4]], @"Wrong date");
    XCTAssertTrue([table[1][@"binary"] isEqualToData:[NSData dataWithBytes:bin5 length:5]], @"Wrong data");
}



-(void)testTableDynamic_Row_Set_Mixed
{
    RLMTable *table = [[RLMTable alloc] init];

    // Mixed column
    [table addColumnWithName:@"first" type:RLMTypeMixed];

    // Add row
    [table addRow:@[@1]];

    // Change value and check
    table[0][0] = @"Hello";
    XCTAssertTrue([table[0][@"first"] isKindOfClass:[NSString class]], @"string expected");
    XCTAssertTrue(([table[0][@"first"] isEqualToString:@"Hello"]), @"'Hello' expected");

    table[0][0] = @4.6692f;
    XCTAssertTrue([table[0][@"first"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertTrue((strcmp([(NSNumber *)table[0][@"first"] objCType], @encode(float)) == 0), @"'float' expected");
    XCTAssertEqualWithAccuracy([(NSNumber *)table[0][@"first"] floatValue], (float)4.6692, 0.0001, @"Value 4.6692 expected");
    XCTAssertEqualWithAccuracy([table[0][@"first"] floatValue], (float)4.6692, 0.0001, @"Value 4.6692 expected");

    table[0][0] = @4.6692;
    XCTAssertTrue([table[0][@"first"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertTrue((strcmp([(NSNumber *)table[0][@"first"] objCType], @encode(double)) == 0), @"'double' expected");
    XCTAssertEqualWithAccuracy([(NSNumber *)table[0][@"first"] doubleValue], 4.6692, 0.0001, @"Value 4.6692 expected");

    table[0][0] = @4;
    XCTAssertTrue([table[0][@"first"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertTrue((strcmp([(NSNumber *)table[0][@"first"] objCType], @encode(long long)) == 0), @"'long long' expected");
    XCTAssertEqual([(NSNumber *)table[0][@"first"] longLongValue], (long long)4, @"Value 1 expected");

    table[0][0] = @YES;
    XCTAssertTrue([table[0][@"first"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertTrue((strcmp([(NSNumber *)table[0][@"first"] objCType], @encode(BOOL)) == 0), @"'long long' expected");
    XCTAssertTrue([(NSNumber *)table[0][@"first"] boolValue], @"Value YES expected");
    XCTAssertTrue([table[0][@"first"] boolValue], @"Valye YES expected");

    NSDate* d = [NSDate dateWithTimeIntervalSince1970:10000];
    table[0][0] = d;
    XCTAssertTrue([table[0][@"first"] isKindOfClass:[NSDate class]], @"NSDate expected");
    XCTAssertTrue([(NSDate *)table[0][@"first"] isEqualToDate:d], @"Wrong date");

    char bin5[] = {5, 6, 7, 8, 9};
    table[0][0] = [NSData dataWithBytes:bin5 length:5];
    XCTAssertTrue([table[0][@"first"] isKindOfClass:[NSData class]], @"NSData expected");
    XCTAssertTrue([(NSData *)table[0][@"first"] isEqualToData:[NSData dataWithBytes:bin5 length:5]], @"Wrong data");
}

-(void)testTableDynamic_Row_Get
{
    RLMTable *table = [[RLMTable alloc] init];
    XCTAssertNotNil(table, @"Table is nil");

    // Add two columns
    [table addColumnWithName:@"first" type:RLMTypeInt];
    [table addColumnWithName:@"second" type:RLMTypeString];

    // Add three rows
    [table addRow:@[@1, @"Hello"]];
    [table addRow:@[@2, @"World"]];
    [table addRow:@[@3, @"Hello World"]];

    XCTAssertEqual([(NSNumber *)table[1][0] longLongValue], (int64_t)2, @"Value '2' expected");
}

-(void)testTableDynamic_Row_Get_Mixed
{
    RLMTable *table = [[RLMTable alloc] init];
    XCTAssertNotNil(table, @"Table is nil");

    // Add two columns
    [table addColumnWithName:@"first" type:RLMTypeMixed];

    // Add three rows
    [table addRow:@[@1]];
    [table addRow:@[@"World"]];
    [table addRow:@[@3.0f]];
    [table addRow:@[@3.0]];


    XCTAssertEqual([(NSNumber *)table[0][0] longLongValue], (long long)1, @"Value '1' expected");
    XCTAssertEqualWithAccuracy([(NSNumber *)table[2][0] floatValue], (float)3.0, 0.0001, @"Value 3.0 expected");
    XCTAssertEqualWithAccuracy([(NSNumber *)table[3][0] doubleValue], (double)3.0, 0.0001, @"Value 3.0 expected");
    XCTAssertTrue([(NSString *)table[1][0] isEqualToString:@"World"], @"'World' expected");
}

- (void)testTableDynamic_initWithColumns
{
    RLMTable *table = [[RLMTable alloc] initWithColumns:@[@"name",   @"string",
                                                          @"age",    @"int",
                                                          @"hired",  @"bool",
                                                          @"phones", @[@"type",   @"string",
                                                                       @"number", @"string"]]];

    XCTAssertEqual([table columnCount], (NSUInteger)4, @"four columns");

    // Try to append a row that has to comply with the schema
    [table addRow:@[@"joe", @34, @YES, @[@[@"home",   @"(650) 434-4342"],
                                         @[@"mobile", @"(650) 342-4243"]]]];
}

- (void)testDistinctView
{
    RLMTable *t = [[RLMTable alloc] init];
    
    NSUInteger nameIndex = [t addColumnWithName:@"name" type:RLMTypeString];
    NSUInteger ageIndex = [t addColumnWithName:@"age" type:RLMTypeInt];
    
    XCTAssertThrows([t distinctValuesInColumnWithIndex:ageIndex], @"Not a string column");
    XCTAssertThrows([t distinctValuesInColumnWithIndex:nameIndex], @"Index not set");
    [t createIndexInColumnWithIndex:nameIndex];

    
    [t addRow:@[@"name0", @0]];
    [t addRow:@[@"name0", @0]];
    [t addRow:@[@"name0", @0]];
    [t addRow:@[@"name1", @1]];
    [t addRow:@[@"name1", @1]];
    [t addRow:@[@"name2", @2]];
    
    // Distinct on string column
    RLMView *v = [t distinctValuesInColumnWithIndex:nameIndex];
    XCTAssertEqual(v.rowCount, (NSUInteger)3, @"Distinct values removed");
    XCTAssertEqualObjects(v[0][nameIndex], @"name0", @"");
    XCTAssertEqualObjects(v[1][nameIndex], @"name1", @"");
    XCTAssertEqualObjects(v[2][nameIndex], @"name2", @"");
    XCTAssertEqualObjects(v[0][ageIndex], @0, @"");
    XCTAssertEqualObjects(v[1][ageIndex], @1, @"");
    XCTAssertEqualObjects(v[2][ageIndex], @2, @"");
}

- (void)testPredicateFind
{
    RLMTable *t = [[RLMTable alloc] initWithColumns:@[@"name", @"string",
                                                      @"age",  @"int"]];
    [t addRow:@[@"name0", @0]];
    [t addRow:@[@"name1", @1]];
    [t addRow:@[@"name2", @1]];
    [t addRow:@[@"name3", @3]];
    [t addRow:@[@"name4", @4]];

    XCTAssertThrows([t find:@"garbage"], @"Garbage predicate");
    XCTAssertThrows([t find:@"name == notAValue"], @"Invalid expression");
    XCTAssertThrows([t find:@"naem == \"name0\""], @"Invalid column");
    XCTAssertThrows([t find:@"name == 30"], @"Invalid value type");
    XCTAssertThrows([t find:@1], @"Invalid condition");

    // Searching with no condition just finds first row
    RLMRow *r = [t find:nil];
    XCTAssertEqualObjects(r[@"name"], @"name0", @"first row");

    // Search with predicate string
    r = [t find:@"name == \"name10\""];
    XCTAssertEqualObjects(r, nil, @"no match");

    r = [t find:@"name == \"name0\""];
    XCTAssertEqualObjects(r[@"name"], @"name0");

    r = [t find:@"age == 4"];
    XCTAssertEqualObjects(r[@"name"], @"name4");

    // Search with predicate object
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
    r = [t find:predicate];
    XCTAssertEqualObjects(r[@"name"], @"name3");
}


- (void)testPredicateView
{
    RLMTable *t = [[RLMTable alloc] init];
    
    NSUInteger nameIndex = [t addColumnWithName:@"name" type:RLMTypeString];
    NSUInteger ageIndex = [t addColumnWithName:@"age" type:RLMTypeInt];

    [t addRow:@[@"name0", @0]];
    [t addRow:@[@"name1", @1]];
    [t addRow:@[@"name2", @1]];
    [t addRow:@[@"name3", @3]];
    [t addRow:@[@"name4", @4]];

    XCTAssertThrows([t where:@"garbage"], @"Garbage predicate");
    XCTAssertThrows([t where:@"name == notAValue"], @"Invalid expression");
    XCTAssertThrows([t where:@"naem == \"name0\""], @"Invalid column");
    XCTAssertThrows([t where:@"name == 30"], @"Invalid value type");

    // Filter with predicate string
    RLMView *v = [t where:@"name == \"name0\""];
    XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with single match");
    XCTAssertEqualObjects(v[0][nameIndex], @"name0");
    XCTAssertEqualObjects(v[0][ageIndex], @0);
    
    v = [t where:@"age == 1"];
    XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with two matches");
    XCTAssertEqualObjects(v[0][ageIndex], @1);
    
    v = [t where:@"1 == age"];
    XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with two matches");
    XCTAssertEqualObjects(v[0][ageIndex], @1);
    
    // test AND
    v = [t where:@"age == 1 AND name == \"name1\""];
    XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with one match");
    XCTAssertEqualObjects(v[0][nameIndex], @"name1");
    
    // test OR
    v = [t where:@"age == 1 OR age == 4"];
    XCTAssertEqual(v.rowCount, (NSUInteger)3, @"View with 3 matches");
    
    // test other numeric operators
    v = [t where:@"age > 3"];
    XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with 1 matches");
    
    v = [t where:@"age >= 3"];
    XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with 2 matches");
    
    v = [t where:@"age < 1"];
    XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with 1 matches");
    
    v = [t where:@"age <= 1"];
    XCTAssertEqual(v.rowCount, (NSUInteger)3, @"View with 3 matches");

    // Filter with predicate object
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @1];
    v = [t where:predicate];
    XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with two matches");
    XCTAssertEqualObjects(v[0][ageIndex], @1);
}

- (void)testPredicateSort
{
    RLMTable *t = [[RLMTable alloc] init];

    [t addColumnWithName:@"name" type:RLMTypeString];
    NSUInteger ageIndex = [t addColumnWithName:@"age" type:RLMTypeInt];
    [t addColumnWithName:@"hired" type:RLMTypeBool];
    
    [t addRow:@[@"name4", @4, [NSNumber numberWithBool:YES]]];
    [t addRow:@[@"name0",@0, [NSNumber numberWithBool:NO]]];

    RLMView *v = [t where:nil orderBy:nil];
    XCTAssertEqualObjects(v[0][ageIndex], @4);
    XCTAssertEqualObjects(v[1][ageIndex], @0);

    RLMView *vAscending = [t where:nil orderBy:@"age"];
    XCTAssertEqualObjects(vAscending[0][ageIndex], @0);
    XCTAssertEqualObjects(vAscending[1][ageIndex], @4);
    
    RLMView *vAscending2 = [t where:nil orderBy:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]];
    XCTAssertEqualObjects(vAscending2[0][ageIndex], @0);
    XCTAssertEqualObjects(vAscending2[1][ageIndex], @4);
    
    NSSortDescriptor * reverseSort = [NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO];
    RLMView *vDescending = [t where:nil orderBy:reverseSort];
    XCTAssertEqualObjects(vDescending[0][ageIndex], @4);
    XCTAssertEqualObjects(vDescending[1][ageIndex], @0);
    
    NSSortDescriptor * boolSort = [NSSortDescriptor sortDescriptorWithKey:@"hired" ascending:YES];
    RLMView *vBool = [t where:nil orderBy:boolSort];
    XCTAssertEqualObjects(vBool[0][ageIndex], @0);
    XCTAssertEqualObjects(vBool[1][ageIndex], @4);

    XCTAssertThrows([t where:nil orderBy:@1], @"Invalid order type");
    
    NSSortDescriptor * misspell = [NSSortDescriptor sortDescriptorWithKey:@"oge" ascending:YES];
    XCTAssertThrows([t where:nil orderBy:misspell], @"Invalid sort");
    
    NSSortDescriptor * wrongColType = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    XCTAssertThrows([t where:nil orderBy:wrongColType], @"Invalid column type");
}


-(void)testTableDynamic_find_int
{
    RLMTable *table = [[RLMTable alloc] init];
    [table addColumnWithName:@"first" type:RLMTypeInt];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSNumber numberWithInt:i]]];
    XCTAssertEqual((NSUInteger)5, [table findRowIndexWithInt:5 inColumnWithIndex:0], @"Cannot find element");
    XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithInt:11 inColumnWithIndex:0]), @"Found something");
}

-(void)testTableDynamic_find_float
{
    RLMTable *table = [[RLMTable alloc] init];
    [table addColumnWithName:@"first" type:RLMTypeFloat];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSNumber numberWithFloat:(float)i]]];
    XCTAssertEqual((NSUInteger)5, [table findRowIndexWithFloat:5.0 inColumnWithIndex:0], @"Cannot find element");
    XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithFloat:11.0 inColumnWithIndex:0]), @"Found something");
}

-(void)testTableDynamic_find_double
{
    RLMTable *table = [[RLMTable alloc] init];
    [table addColumnWithName:@"first" type:RLMTypeDouble];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSNumber numberWithDouble:(double)i]]];
    XCTAssertEqual((NSUInteger)5, [table findRowIndexWithDouble:5.0 inColumnWithIndex:0], @"Cannot find element");
    XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithDouble:11.0 inColumnWithIndex:0]), @"Found something");
}

-(void)testTableDynamic_find_bool
{
    RLMTable *table = [[RLMTable alloc] init];
    [table addColumnWithName:@"first" type:RLMTypeBool];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSNumber numberWithBool:YES]]];
    table[5][@"first"] = @NO;
    XCTAssertEqual((NSUInteger)5, [table findRowIndexWithBool:NO inColumnWithIndex:0], @"Cannot find element");
    table[5][@"first"] = @YES;
    XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithBool:NO inColumnWithIndex:0]), @"Found something");
}

-(void)testTableDynamic_find_string
{
    RLMTable *table = [[RLMTable alloc] init];
    [table addColumnWithName:@"first" type:RLMTypeString];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSString stringWithFormat:@"%d", i]]];
    XCTAssertEqual((NSUInteger)5, [table findRowIndexWithString:@"5" inColumnWithIndex:0], @"Cannot find element");
    XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithString:@"11" inColumnWithIndex:0]), @"Found something");
}

-(void)testTableDynamic_find_date
{
    RLMTable *table = [[RLMTable alloc] init];
    [table addColumnWithName:@"first" type:RLMTypeDate];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSDate dateWithTimeIntervalSince1970:i]]];
    XCTAssertEqual((NSUInteger)5, [table findRowIndexWithDate:[NSDate dateWithTimeIntervalSince1970:5] inColumnWithIndex:0], @"Cannot find element");
    XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithDate:[NSDate dateWithTimeIntervalSince1970:11] inColumnWithIndex:0]), @"Found something");
}


@end
