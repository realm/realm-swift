////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"

#import <realm/objc/RLMFast.h>
#import <realm/objc/RLMTableFast.h>
#import <realm/objc/RLMTable_noinst.h>
#import <realm/objc/RLMDescriptor.h>

using namespace std;
@interface TestClass : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *age;
@end

@implementation TestClass
// no needed
@end

@interface TestObject : NSObject

@property (strong, nonatomic) NSNumber *objID;
@property (strong, nonatomic) NSString *name;

@end

@implementation TestObject

@end

@interface RLMDynamicTableTests : RLMTestCase

@end

@implementation RLMDynamicTableTests

- (void)testTable
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        XCTAssertNotNil(table, @"Table is nil");
        
        // 1. Add two columns
        [table addColumnWithName:@"first" type:RLMTypeInt];
        [table addColumnWithName:@"second" type:RLMTypeInt];
        
        // Verify
        XCTAssertEqual((RLMType)RLMTypeInt, [table columnTypeOfColumnWithIndex:0], @"First column not int");
        XCTAssertEqual((RLMType)RLMTypeInt, [table columnTypeOfColumnWithIndex:1], @"Second column not int");
        XCTAssertTrue(([[table nameOfColumnWithIndex:0] isEqualToString:@"first"]), @"First not equal to first");
        XCTAssertTrue(([[table nameOfColumnWithIndex:1] isEqualToString:@"second"]), @"Second not equal to second");
        
        // 2. Add a row with data
        RLMRow * row = [table addEmptyRow];
        NSUInteger ndx = [row RLM_index];
        [row setInt:0 inColumnWithIndex:0];
        [row setInt:10 inColumnWithIndex:1];
        
        // Verify
        XCTAssertEqual((int64_t)0, ([table RLM_intInColumnWithIndex:0 atRowIndex:ndx]), @"First not zero");
        XCTAssertEqual((int64_t)10, ([table RLM_intInColumnWithIndex:1 atRowIndex:ndx]), @"Second not 10");
    }];
}

-(void)testAddColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger stringColIndex = [table addColumnWithName:@"stringCol" type:RLMTypeString];
        RLMRow *row = [table addEmptyRow];
        [row setString:@"val" inColumnWithIndex:stringColIndex];
    }];
}

-(void)testAppendRowsIntColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        // Add row using object literal
        [table addColumnWithName:@"first" type:RLMTypeInt];
        XCTAssertNoThrow([table addRow:@[ @1 ]], @"Impossible!");
        XCTAssertEqual((NSUInteger)1, [table rowCount], @"Expected 1 row");
        XCTAssertNoThrow([table addRow:@[ @2 ]], @"Impossible!");
        XCTAssertEqual((NSUInteger)2, [table rowCount], @"Expected 2 rows");
        XCTAssertEqual((int64_t)1, [table RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 1 expected");
        XCTAssertEqual((int64_t)2, [table RLM_intInColumnWithIndex:0 atRowIndex:1], @"Value 2 expected");
        XCTAssertThrows([table addRow:@[@"Hello"]], @"Wrong type");
        XCTAssertThrows(([table addRow:@[@1, @"Hello"]]), @"Wrong number of columns");
    }];
}

-(void)testInsertRowsIntColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        // Add row using object literal
        [table addColumnWithName:@"first" type:RLMTypeInt];
        XCTAssertNoThrow([table insertRow:@[ @1 ] atIndex:0], @"Impossible!");
        XCTAssertEqual((NSUInteger)1, [table rowCount], @"Expected 1 row");
        XCTAssertNoThrow([table insertRow:@[ @2 ] atIndex:0], @"Impossible!");
        XCTAssertEqual((NSUInteger)2, [table rowCount], @"Expected 2 rows");
        XCTAssertEqual((int64_t)1, [table RLM_intInColumnWithIndex:0 atRowIndex:1], @"Value 1 expected");
        XCTAssertEqual((int64_t)2, [table RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
        XCTAssertThrows([table insertRow:@[@"Hello"] atIndex:0], @"Wrong type");
        XCTAssertThrows(([table insertRow:@[@1, @"Hello"] atIndex:0]), @"Wrong number of columns");
    }];
}

-(void)testUpdateRowIntColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        [table insertRow:@[@1] atIndex:0];
        table[0] = @[@2];
        XCTAssertEqual((int64_t)2, [table RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
    }];
}

-(void)testAppendRowGenericObject
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable* table1 = [realm createTableWithName:@"table1"];
        [table1 addColumnWithName:@"name" type:RLMTypeString];
        [table1 addColumnWithName:@"age" type:RLMTypeInt];
        
        TestClass *person = [TestClass new];
        person.name = @"Joe";
        person.age = @11;
        XCTAssertNoThrow([table1 addRow:person], @"Cannot add person");
        XCTAssertEqual((NSUInteger)1, table1.rowCount, @"1 row excepted");
        XCTAssertEqual((long long)11, [(NSNumber *)table1[0][@"age"] longLongValue], @"11 excepted");
        XCTAssertTrue([((NSString *)table1[0][@"name"]) isEqualToString:@"Joe"], @"'Joe' excepted");
        
        RLMTable* table2 = [realm createTableWithName:@"table2"];
        [table2 addColumnWithName:@"name" type:RLMTypeString];
        [table2 addColumnWithName:@"age" type:RLMTypeString];
        
        XCTAssertThrows([table2 addRow:person], @"Impossible");
        XCTAssertEqual((NSUInteger)0, table2.rowCount, @"0 rows excepted");
    }];
}

-(void)testUpdateRowWithLabelsIntColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        [table insertRow:@[@1] atIndex:0];
        table[0] = @{@"first": @2};
        XCTAssertEqual((int64_t)2, [table RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 2 expected");
    }];
}


-(void)testAppendRowWithLabelsIntColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        // Add row using object literal
        [table addColumnWithName:@"first" type:RLMTypeInt];
        
        XCTAssertNoThrow([table addRow:@{ @"first": @1 }], @"Impossible!");
        XCTAssertEqual((NSUInteger)1, [table rowCount], @"Expected 1 row");
        
        XCTAssertNoThrow([table addRow:@{ @"first": @2 }], @"Impossible!");
        XCTAssertEqual((NSUInteger)2, [table rowCount], @"Expected 2 rows");
        
        XCTAssertEqual((int64_t)1, [table RLM_intInColumnWithIndex:0 atRowIndex:0], @"Value 1 expected");
        XCTAssertEqual((int64_t)2, [table RLM_intInColumnWithIndex:0 atRowIndex:1], @"Value 2 expected");
        
        XCTAssertThrows([table addRow:@{ @"first": @"Hello" }], @"Wrong type");
        XCTAssertEqual((NSUInteger)2, [table rowCount], @"Expected 2 rows");
        
        XCTAssertNoThrow(([table addRow:@{ @"first": @1, @"second": @"Hello" }]), @"dh");
        XCTAssertEqual((NSUInteger)3, [table rowCount], @"Expected 3 rows");
        
        XCTAssertNoThrow(([table addRow:@{ @"second": @1 }]), @"This is impossible");
        XCTAssertEqual((NSUInteger)4, [table rowCount], @"Expected 4 rows");
        
        XCTAssertEqual((int64_t)0, [table RLM_intInColumnWithIndex:0 atRowIndex:3], @"Value 0 expected");
    }];
}

-(void)testInsertRowWithLabelsIntColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        // Add row using object literal
        [table addColumnWithName:@"first" type:RLMTypeInt];
        
        XCTAssertNoThrow(([table insertRow:@{ @"first": @1 } atIndex:0]), @"Impossible!");
        XCTAssertEqual((NSUInteger)1, [table rowCount], @"Expected 1 row");
        
        XCTAssertNoThrow(([table insertRow:@{ @"first": @2 } atIndex:0]), @"Impossible!");
        XCTAssertEqual((NSUInteger)2, [table rowCount], @"Expected 2 rows");
        
        XCTAssertEqual((int64_t)1, ([table RLM_intInColumnWithIndex:0 atRowIndex:1]), @"Value 1 expected");
        XCTAssertEqual((int64_t)2, ([table RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 2 expected");
        
        XCTAssertThrows(([table insertRow:@{ @"first": @"Hello" } atIndex:0]), @"Wrong type");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"Expected 2 rows");
        
        XCTAssertNoThrow(([table insertRow:@{ @"first": @3, @"second": @"Hello"} atIndex:0]), @"Has 'first'");
        XCTAssertEqual((NSUInteger)3, [table rowCount], @"Expected 3 rows");
        
        XCTAssertNoThrow(([table insertRow:@{ @"second": @4 } atIndex:0]), @"This is impossible");
        XCTAssertEqual((NSUInteger)4, [table rowCount], @"Expected 4 rows");
        XCTAssertTrue((int64_t)0 == ([table RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 0 expected");
    }];
}


-(void)testAppendRowsIntStringColumns
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        [table addColumnWithName:@"second" type:RLMTypeString];
        
        XCTAssertNoThrow(([table addRow:@[@1, @"Hello"]]), @"addRow 1");
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
        XCTAssertEqual((int64_t)1, ([table RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 1 expected");
        XCTAssertTrue(([[table RLM_stringInColumnWithIndex:1 atRowIndex:0] isEqualToString:@"Hello"]), @"Value 'Hello' expected");
        XCTAssertThrows(([table addRow:@[@1, @2]]), @"addRow 2");
    }];
}


-(void)testAppendRowWithLabelsIntStringColumns
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        [table addColumnWithName:@"second" type:RLMTypeString];
        XCTAssertNoThrow(([table addRow:@{@"first": @1, @"second": @"Hello"}]), @"addRowWithLabels 1");
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
        XCTAssertEqual((int64_t)1, ([table RLM_intInColumnWithIndex:0 atRowIndex:0]), @"Value 1 expected");
        XCTAssertTrue(([[table RLM_stringInColumnWithIndex:1 atRowIndex:0] isEqualToString:@"Hello"]), @"Value 'Hello' expected");
        XCTAssertThrows(([table addRow:@{@"first": @1, @"second": @2}]), @"addRowWithLabels 2");
    }];
}


-(void)testAppendRowsDoubleColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeDouble];
        XCTAssertNoThrow(([table addRow:@[@3.14]]), @"Cannot insert 'double'");  // double is default
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
    }];
}

-(void)testAppendRowWithLabelsDoubleColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeDouble];
        XCTAssertNoThrow(([table addRow:@{@"first": @3.14}]), @"Cannot insert 'double'");   // double is default
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
    }];
}

-(void)testAppendRowsFloatColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeFloat];
        XCTAssertNoThrow(([table addRow:@[@3.14F]]), @"Cannot insert 'float'"); // F == float
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
    }];
}

-(void)testAppendRowWithLabelsFloatColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeFloat];
        XCTAssertNoThrow(([table addRow:@{@"first": @3.14F}]), @"Cannot insert 'float'");   // F == float
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
    }];
}

-(void)testAppendRowsDateColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeDate];
        XCTAssertNoThrow(([table addRow:@[@1000000000]]), @"Cannot insert 'time_t'"); // 2001-09-09 01:46:40
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
        
        NSDate *d = [[NSDate alloc] initWithTimeIntervalSince1970:1396963324];
        XCTAssertNoThrow(([table addRow:@[d]]), @"Cannot insert 'NSDate'");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"2 rows excepted");
    }];
}

-(void)testAppendRowWithLabelsDateColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeDate];
        
        XCTAssertNoThrow(([table addRow:@{@"first": @1000000000}]), @"Cannot insert 'time_t'");   // 2001-09-09 01:46:40
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
        
        NSDate *d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
        XCTAssertNoThrow(([table addRow:@{@"first": d}]), @"Cannot insert 'NSDate'");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"2 rows excepted");
        
        XCTAssertNoThrow(([table addRow:@{@"first": @1000000000}]), @"Cannot insert 'time_t'");   // 2001-09-09 01:46:40
        XCTAssertEqual((NSUInteger)3, ([table rowCount]), @"1 row expected");
        
        d = [[NSDate alloc] initWithTimeIntervalSince1970:1396963324];
        XCTAssertNoThrow(([table addRow:@{@"first": d}]), @"Cannot insert 'NSDate'");
        XCTAssertEqual((NSUInteger)4, ([table rowCount]), @"2 rows excepted");
        XCTAssertNoThrow(([table addRow:@{@"first": @1000000000}]), @"Cannot insert 'time_t'");   // 2001-09-09 01:46:40
        XCTAssertEqual((NSUInteger)5, ([table rowCount]), @"1 row expected");
        
        d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
        XCTAssertNoThrow(([table addRow:@{@"first": d}]), @"Cannot insert 'NSDate'");
        XCTAssertEqual((NSUInteger)6, ([table rowCount]), @"2 rows excepted");
    }];
}

-(void)testAppendRowsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];
    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeBinary];
        XCTAssertNoThrow(([table addRow:@[bin2]]), @"Cannot insert 'binary'");
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
        
        XCTAssertNoThrow(([table addRow:@[nsd]]), @"Cannot insert 'NSData'");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"2 rows excepted");
    }];
}


-(void)testAppendRowWithLabelsBinaryColumn
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];
    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeBinary];
        
        XCTAssertNoThrow(([table addRow:@{@"first": bin2}]), @"Cannot insert 'binary'");
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
        
        XCTAssertNoThrow(([table addRow:@{@"first": nsd}]), @"Cannot insert 'NSData'");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"2 rows excepted");
    }];
}

-(void)testAppendRowsTooManyItems
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        XCTAssertThrows(([table addRow:@[@1, @1]]), @"Too many items for a row.");
    }];
}

-(void)testAppendRowsTooFewItems
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        XCTAssertThrows(([table addRow:@[]]),  @"Too few items for a row.");
    }];
}

-(void)testAppendRowsWrongType
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        XCTAssertThrows(([table addRow:@[@YES]]), @"Wrong type for column.");
        XCTAssertThrows(([table addRow:@[@""]]),  @"Wrong type for column.");
        XCTAssertThrows(([table addRow:@[@3.5]]), @"Wrong type for column.");
        XCTAssertThrows(([table addRow:@[@3.5F]]),  @"Wrong type for column.");
        XCTAssertThrows(([table addRow:@[@[]]]),  @"Wrong type for column.");
    }];
}

-(void)testAppendRowsBoolColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeBool];
        XCTAssertNoThrow(([table addRow:@[@YES]]), @"Cannot append bool column.");
        XCTAssertNoThrow(([table addRow:@[@NO]]), @"Cannot append bool column.");
        XCTAssertEqual((NSUInteger)2, [table rowCount], @"2 rows expected");
    }];
}

-(void)testAppendRowWithLabelsBoolColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeBool];
        XCTAssertNoThrow(([table addRow:@{@"first": @YES}]), @"Cannot append bool column.");
        XCTAssertNoThrow(([table addRow:@{@"first": @NO}]), @"Cannot append bool column.");
        XCTAssertEqual((NSUInteger)2, [table rowCount], @"2 rows expected");
    }];
}

-(void)testAppendRowsIntSubtableColumns
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        RLMDescriptor * descr = [table descriptor];
        RLMDescriptor * subdescr = [descr addColumnTable:@"second"];
        [subdescr addColumnWithName:@"TableCol_IntCol" type:RLMTypeInt];
        XCTAssertNoThrow(([table addRow:@[@1, @[]]]), @"1 row excepted");
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row expected");
        XCTAssertNoThrow(([table addRow:@[@2, @[ @[@3], @[@4] ] ]]), @"Wrong");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"2 rows expected");
    }];
}

-(void)testAppendRowsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:(const void *)bin length:sizeof bin];

    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeMixed];
        XCTAssertNoThrow(([table addRow:@[@1]]), @"Cannot insert 'int'");
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row excepted");
        XCTAssertNoThrow(([table addRow:@[@"Hello"]]), @"Cannot insert 'string'");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"2 rows excepted");
        XCTAssertNoThrow(([table addRow:@[@3.14f]]), @"Cannot insert 'float'");
        XCTAssertEqual((NSUInteger)3, ([table rowCount]), @"3 rows excepted");
        XCTAssertNoThrow(([table addRow:@[@3.14]]), @"Cannot insert 'double'");
        XCTAssertEqual((NSUInteger)4, ([table rowCount]), @"4 rows excepted");
        XCTAssertNoThrow(([table addRow:@[@YES]]), @"Cannot insert 'bool'");
        XCTAssertEqual((NSUInteger)5, ([table rowCount]), @"5 rows excepted");
        XCTAssertNoThrow(([table addRow:@[bin2]]), @"Cannot insert 'binary'");
        XCTAssertEqual((NSUInteger)6, ([table rowCount]), @"6 rows excepted");
    }];
}

-(void)testAppendRowWithLabelsMixedColumns
{
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];

    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeMixed];
        XCTAssertNoThrow(([table addRow:@{@"first": @1}]), @"Cannot insert 'int'");
        XCTAssertEqual((NSUInteger)1, ([table rowCount]), @"1 row excepted");
        XCTAssertNoThrow(([table addRow:@{@"first": @"Hello"}]), @"Cannot insert 'string'$");
        XCTAssertEqual((NSUInteger)2, ([table rowCount]), @"2 rows excepted");
        XCTAssertNoThrow(([table addRow:@{@"first": @3.14f}]), @"Cannot insert 'float'");
        XCTAssertEqual((NSUInteger)3, ([table rowCount]), @"3 rows excepted");
        XCTAssertNoThrow(([table addRow:@{@"first": @3.14}]), @"Cannot insert 'double'");
        XCTAssertEqual((NSUInteger)4, ([table rowCount]), @"4 rows excepted");
        XCTAssertNoThrow(([table addRow:@{@"first": @YES}]), @"Cannot insert 'bool'");
        XCTAssertEqual((NSUInteger)5, ([table rowCount]), @"5 rows excepted");
        XCTAssertNoThrow(([table addRow:@{@"first": bin2}]), @"Cannot insert 'binary'");
        XCTAssertEqual((NSUInteger)6, ([table rowCount]), @"6 rows excepted");
    }];
}

-(void)testRemoveColumns
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
    }];
}

-(void)testRenameColumns
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
    }];
}


- (void)testColumnlessCount
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        XCTAssertEqual((NSUInteger)0, [table rowCount], @"Columnless table has 0 rows.");
    }];
}



- (void)testColumnlessClear
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table removeAllRows];
        XCTAssertEqual((NSUInteger)0, [table rowCount], @"Columnless table has 0 rows.");
    }];
}

- (void)testColumnlessOptimize
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        XCTAssertEqual((NSUInteger)0, [table rowCount], @"Columnless table has 0 rows.");
        [table optimize];
        XCTAssertEqual((NSUInteger)0, [table rowCount], @"Columnless table has 0 rows.");
    }];
}


- (void)testColumnlessIsEqual
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable* table1 = [realm createTableWithName:@"table1"];
        RLMTable* table2 = [realm createTableWithName:@"table2"];
        XCTAssertTrue([table1 isEqual:table1], @"Columnless table is equal to itself.");
        XCTAssertTrue([table1 isEqual:table2], @"Columnless table is equal to another columnless table.");
        XCTAssertTrue([table2 isEqual:table1], @"Columnless table is equal to another columnless table.");
    }];
}

- (void)testColumnlessColumnCount
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        XCTAssertEqual((NSUInteger)0, [table columnCount], @"Columnless table has column count 0.");
    }];
}


//- (void)testColumnlessNameOfColumnWithIndex
//{
//    RLMTable* table = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([table nameOfColumnWithIndex:NSNotFound],
//        NSException, NSRangeException,
//        @"Columnless table has no column names.");
//    XCTAssertThrowsSpecific([table nameOfColumnWithIndex:(0)],
//        NSException, NSRangeException,
//        @"Columnless table has no column names.");
//    XCTAssertThrowsSpecific([table nameOfColumnWithIndex:1],
//        NSException, NSRangeException,
//        @"Columnless table has no column names.");
//}
//
//- (void)testColumnlessGetColumnType
//{
//    RLMTable* t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t getColumnType:((NSUInteger)-1)],
//        NSException, NSRangeException,
//        @"Columnless table has no column types.");
//    XCTAssertThrowsSpecific([t getColumnType:((NSUInteger)0)],
//        NSException, NSRangeException,
//        @"Columnless table has no column types.");
//    XCTAssertThrowsSpecific([t getColumnType:((NSUInteger)1)],
//        NSException, NSRangeException,
//        @"Columnless table has no column types.");
//}
//
//- (void)testColumnlessCursorAtIndex
//{
//    RLMTable* t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t cursorAtIndex:((NSUInteger)-1)],
//        NSException, NSRangeException,
//        @"Columnless table has no cursors.");
//    XCTAssertThrowsSpecific([t cursorAtIndex:((NSUInteger)0)],
//        NSException, NSRangeException,
//        @"Columnless table has no cursors.");
//    XCTAssertThrowsSpecific([t cursorAtIndex:((NSUInteger)1)],
//        NSException, NSRangeException,
//        @"Columnless table has no cursors.");
//}
//
//- (void)testColumnlessCursorAtLastIndex
//{
//    RLMTable* t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t cursorAtLastIndex],
//        NSException, NSRangeException,
//        @"Columnless table has no cursors."); 
//}
//
//- (void)testRemoveRowAtIndex
//{
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t removeRowAtIndex:((NSUInteger)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t removeRowAtIndex:((NSUInteger)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t removeRowAtIndex:((NSUInteger)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//}
//
//- (void)testColumnlessRemoveLastRow
//{
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t removeLastRow],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//}
//
//- (void)testColumnlessGetTableSize
//{
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t getTableSize:((NSUInteger)0) ndx:((NSUInteger)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t getTableSize:((NSUInteger)0) ndx:((NSUInteger)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t getTableSize:((NSUInteger)0) ndx:((NSUInteger)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//}
//
//- (void)testColumnlessClearSubtable
//{
//    RLMTable *t = [[RLMTable alloc] init];
//    XCTAssertThrowsSpecific([t clearSubtable:((NSUInteger)0) ndx:((NSUInteger)-1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t clearSubtable:((NSUInteger)0) ndx:((NSUInteger)0)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//    XCTAssertThrowsSpecific([t clearSubtable:((NSUInteger)0) ndx:((NSUInteger)1)],
//        NSException, NSRangeException,
//        @"No rows in a columnless table.");
//}

- (void)testDataTypes_Dynamic
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm createTableWithName:@"table"];
        XCTAssertNotNil(table, @"Table is nil");
        
        RLMDescriptor * desc = [table descriptor];
        
        [desc addColumnWithName:@"BoolCol" type:RLMTypeBool];    const NSUInteger BoolCol = 0;
        [desc addColumnWithName:@"IntCol" type:RLMTypeInt];     const NSUInteger IntCol = 1;
        [desc addColumnWithName:@"FloatCol" type:RLMTypeFloat];   const NSUInteger FloatCol = 2;
        [desc addColumnWithName:@"DoubleCol" type:RLMTypeDouble];  const NSUInteger DoubleCol = 3;
        [desc addColumnWithName:@"StringCol" type:RLMTypeString];  const NSUInteger StringCol = 4;
        [desc addColumnWithName:@"BinaryCol" type:RLMTypeBinary];  const NSUInteger BinaryCol = 5;
        [desc addColumnWithName:@"DateCol" type:RLMTypeDate];    const NSUInteger DateCol = 6;
        RLMDescriptor * subdesc = [desc addColumnTable:@"TableCol"]; const NSUInteger TableCol = 7;
        [desc addColumnWithName:@"MixedCol" type:RLMTypeMixed];   const NSUInteger MixedCol = 8;
        
        [subdesc addColumnWithName:@"TableCol_IntCol" type:RLMTypeInt];
        
        // Verify column types
        XCTAssertEqual((RLMType)RLMTypeBool,   [table columnTypeOfColumnWithIndex:0], @"First column not bool");
        XCTAssertEqual((RLMType)RLMTypeInt,    [table columnTypeOfColumnWithIndex:1], @"Second column not int");
        XCTAssertEqual((RLMType)RLMTypeFloat,  [table columnTypeOfColumnWithIndex:2], @"Third column not float");
        XCTAssertEqual((RLMType)RLMTypeDouble, [table columnTypeOfColumnWithIndex:3], @"Fourth column not double");
        XCTAssertEqual((RLMType)RLMTypeString, [table columnTypeOfColumnWithIndex:4], @"Fifth column not string");
        XCTAssertEqual((RLMType)RLMTypeBinary, [table columnTypeOfColumnWithIndex:5], @"Sixth column not binary");
        XCTAssertEqual((RLMType)RLMTypeDate,   [table columnTypeOfColumnWithIndex:6], @"Seventh column not date");
        XCTAssertEqual((RLMType)RLMTypeTable,  [table columnTypeOfColumnWithIndex:7], @"Eighth column not table");
        XCTAssertEqual((RLMType)RLMTypeMixed,  [table columnTypeOfColumnWithIndex:8], @"Ninth column not mixed");
        
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
        NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        NSDate *timeNow = [NSDate date];
        
        RLMTable* subtab1 = [realm createTableWithName:@"subtab1"];
        [subtab1 addColumnWithName:@"TableCol_IntCol" type:RLMTypeInt];
        
        RLMTable* subtab2 = [realm createTableWithName:@"subtab2"];
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
    }];
}

- (void)testTableDynamic_Subscripting
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
    }];
}

- (void)testFirstLastRow
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger col0 = [table addColumnWithName:@"col" type:RLMTypeString];
        
        XCTAssertNil([table firstRow], @"Table is empty");
        XCTAssertNil([table lastRow], @"Table is empty");
        
        NSString *value0 = @"value0";
        [table addRow:@[value0]];
        
        NSString *value1 = @"value1";
        [table addRow:@[value1]];
        
        XCTAssertEqualObjects([[table firstRow] stringInColumnWithIndex:col0], value0, @"");
        XCTAssertEqualObjects( [[table lastRow] stringInColumnWithIndex:col0], value1, @"");
    }];
}

- (void)testTableDynamic_Cursor_Subscripting
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
    }];
}

- (void)testTableDynamic_KeyedSubscripting
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm createTableWithName:@"table"];
        [table addColumnWithName:@"name" type:RLMTypeString];
        [table addColumnWithName:@"id" type:RLMTypeInt];
        
        [table addRow:@{@"name" : @"Test1", @"id" : @24}];
        [table addRow:@{@"name" : @"Test2", @"id" : @25}];
        
        // Test first row
        XCTAssertNotNil(table[@"Test1"], @"table[@\"Test1\"] should not be nil");
        XCTAssertEqualObjects(table[@"Test1"][@"name"], @"Test1", @"table[@\"Test24\"][@\"name\"] should be equal to Test1");
        XCTAssertEqualObjects(table[@"Test1"][@"id"], @24, @"table[@\"Test24\"][@\"id\"] should be equal to @24");
        
        // Test second row
        XCTAssertNotNil(table[@"Test2"], @"table[@\"Test2\"] should not be nil");
        XCTAssertEqualObjects(table[@"Test2"][@"name"], @"Test2", @"table[@\"Test24\"][@\"name\"] should be equal to Test2");
        XCTAssertEqualObjects(table[@"Test2"][@"id"], @25, @"table[@\"Test24\"][@\"id\"] should be equal to @25");
        
        // Test nil row
      //  XCTAssertNil(table[@"foo"], @"table[\"foo\"] should be nil");
        
        
        RLMTable* errTable = [realm createTableWithName:@"errTable"];
        
        XCTAssertThrows(errTable[@"X"], @"Accessing RLMRow via keyed subscript on undefined column should throw exception");
        
        [errTable addColumnWithName:@"id" type:RLMTypeInt];
        
        XCTAssertThrows(errTable[@"X"], @"Accessing RLMRow via keyed subscript on a column that is not of type RLMTypeString should throw exception");
        
        
        // Test keyed subscripting setters
        
        // No exisiting for table
        NSUInteger previousRowCount = [table rowCount];
        NSString* nonExistingKey = @"Test10123903784293";
        table[nonExistingKey] = @{@"name" : nonExistingKey, @"id" : @1};
        
        XCTAssertEqual(previousRowCount, [table rowCount], @"Row count should be equal to previous row count + 1 after inserting a non-existing RLMRow");
        XCTAssertNil(table[nonExistingKey], @"table[nonExistingKey] should be nil");
        // Commenting out until set row method transitioned from update row
        //XCTAssertEqualObjects(table[nonExistingKey][@"id"], @1, @"table[nonExistingKey][@\"id\"] should be equal to @1");
        //XCTAssertEqualObjects(table[nonExistingKey][@"name"], nonExistingKey, @"table[nonExistingKey][@\"name\"] should be equal to nonExistingKey");
        
        // Set non-existing row to nil for table
        previousRowCount = [table rowCount];
        NSString* anotherNonExistingKey = @"sdalfjhadskfja";
        table[anotherNonExistingKey] = nil; // Adds an empty row
        
        XCTAssertEqual(previousRowCount, [table rowCount], @"previousRowCount + 1 should equal current rowCount");
        XCTAssertNil(table[anotherNonExistingKey], @"table[anotherNonExistingKey] should be nil");
        
        // Has existing for table
        previousRowCount = [table rowCount];
        table[@"Test2"] = @{@"name" : @"Test3" , @"id" : @123};
        
        XCTAssertEqual(previousRowCount, [table rowCount], @"Row count should still equal previous row count after inserting an existing RLMRow");
        XCTAssertNil(table[@"Test2"], @"table[@\"Test2\"] should be nil");
        XCTAssertNotNil(table[@"Test3"], @"table[@\"Test3\"] should not be nil");
        XCTAssertEqualObjects(table[@"Test3"][@"id"], @123, @"table[\"Test3\"][@\"id\"] should be equal to @123");
        XCTAssertEqualObjects(table[@"Test3"][@"name"], @"Test3", @"table[\"Test3\"][@\"name\"] should be equal to @\"Test3\"");
        
        // Set existing row to nil for table
        previousRowCount = [table rowCount];
        table[@"Test3"] = nil;
        
        XCTAssertEqual(previousRowCount, [table rowCount], @"[table rowCount] should be equal to previousRowCount");
        XCTAssertNotNil(table[@"Test3"], @"table[\"Test3\"] should return an untouched row");
        
        // No existing for errTable
        previousRowCount = [errTable rowCount];
        XCTAssertThrows((errTable[@"SomeKey"] = @{@"id" : @821763}), @"Calling keyed subscriptor on errTable should throw exception");
        XCTAssertEqual(previousRowCount, [errTable rowCount], @"errTable should have same count as previous");
    }];
}

-(void)testTableDynamic_Row_Set
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
    }];
}

-(void)testTableDynamic_Row_Set_Mixed
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
    }];
}

-(void)testTableDynamic_Row_Get
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        XCTAssertNotNil(table, @"Table is nil");
        
        // Add two columns
        [table addColumnWithName:@"first" type:RLMTypeInt];
        [table addColumnWithName:@"second" type:RLMTypeString];
        
        // Add three rows
        [table addRow:@[@1, @"Hello"]];
        [table addRow:@[@2, @"World"]];
        [table addRow:@[@3, @"Hello World"]];
        
        XCTAssertEqual([(NSNumber *)table[1][0] longLongValue], (int64_t)2, @"Value '2' expected");
    }];
}

-(void)testTableDynamic_Row_Get_Mixed
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
    }];
}

- (void)testTableDynamic_initWithColumns
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        NSArray *columns = @[@"name",   @"string",
                             @"age",    @"int",
                             @"hired",  @"bool",
                             @"phones", @[@"type",   @"string",
                                          @"number", @"string"]];
        RLMTable *table = [realm createTableWithName:@"table" columns:columns];
        
        XCTAssertEqual([table columnCount], (NSUInteger)4, @"four columns");
        
        // Try to append a row that has to comply with the schema
        [table addRow:@[@"joe", @34, @YES, @[@[@"home",   @"(650) 434-4342"],
                                             @[@"mobile", @"(650) 342-4243"]]]];
    }];
}

- (void)testDistinctView
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger nameIndex = [table addColumnWithName:@"name" type:RLMTypeString];
        NSUInteger ageIndex = [table addColumnWithName:@"age" type:RLMTypeInt];
        
        XCTAssertThrows([table distinctValuesInColumnWithIndex:ageIndex], @"Not a string column");
        XCTAssertThrows([table distinctValuesInColumnWithIndex:nameIndex], @"Index not set");
        [table createIndexInColumnWithIndex:nameIndex];
        
        
        [table addRow:@[@"name0", @0]];
        [table addRow:@[@"name0", @0]];
        [table addRow:@[@"name0", @0]];
        [table addRow:@[@"name1", @1]];
        [table addRow:@[@"name1", @1]];
        [table addRow:@[@"name2", @2]];
        
        // Distinct on string column
        RLMView *v = [table distinctValuesInColumnWithIndex:nameIndex];
        XCTAssertEqual(v.rowCount, (NSUInteger)3, @"Distinct values removed");
        XCTAssertEqualObjects(v[0][nameIndex], @"name0", @"");
        XCTAssertEqualObjects(v[1][nameIndex], @"name1", @"");
        XCTAssertEqualObjects(v[2][nameIndex], @"name2", @"");
        XCTAssertEqualObjects(v[0][ageIndex], @0, @"");
        XCTAssertEqualObjects(v[1][ageIndex], @1, @"");
        XCTAssertEqualObjects(v[2][ageIndex], @2, @"");
    }];
}

- (void)testPredicateFind
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        NSArray *columns = @[@"name", @"string",
                             @"age",  @"int"];
        RLMTable *table = [realm createTableWithName:@"table" columns:columns];
        [table addRow:@[@"name0", @0]];
        [table addRow:@[@"name1", @1]];
        [table addRow:@[@"name2", @1]];
        [table addRow:@[@"name3", @3]];
        [table addRow:@[@"name4", @4]];
        
        XCTAssertThrows([table firstWhere:@"garbage"], @"Garbage predicate");
        XCTAssertThrows([table firstWhere:@"name == notAValue"], @"Invalid expression");
        XCTAssertThrows([table firstWhere:@"naem == \"name0\""], @"Invalid column");
        XCTAssertThrows([table firstWhere:@"name == 30"], @"Invalid value type");
        XCTAssertThrows([table firstWhere:@1], @"Invalid condition");
        
        // Searching with no condition just finds first row
        RLMRow *r = [table firstWhere:nil];
        XCTAssertEqualObjects(r[@"name"], @"name0", @"first row");
        
        // Search with predicate string
        r = [table firstWhere:@"name == \"name10\""];
        XCTAssertEqualObjects(r, nil, @"no match");
        
        r = [table firstWhere:@"name == \"name0\""];
        XCTAssertEqualObjects(r[@"name"], @"name0");
        
        r = [table firstWhere:@"age == 4"];
        XCTAssertEqualObjects(r[@"name"], @"name4");
        
        // Search with predicate object
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
        r = [table firstWhere:predicate];
        XCTAssertEqualObjects(r[@"name"], @"name3");
    }];
}


- (void)testPredicateView
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger nameIndex = [table addColumnWithName:@"name" type:RLMTypeString];
        NSUInteger ageIndex = [table addColumnWithName:@"age" type:RLMTypeInt];
        
        [table addRow:@[@"name0", @0]];
        [table addRow:@[@"name1", @1]];
        [table addRow:@[@"name2", @1]];
        [table addRow:@[@"name3", @3]];
        [table addRow:@[@"name4", @4]];
        
        XCTAssertThrows([table allWhere:@"garbage"], @"Garbage predicate");
        XCTAssertThrows([table allWhere:@"name == notAValue"], @"Invalid expression");
        XCTAssertThrows([table allWhere:@"naem == \"name0\""], @"Invalid column");
        XCTAssertThrows([table allWhere:@"name == 30"], @"Invalid value type");
        
        // Filter with predicate string
        RLMView *v = [table allWhere:@"name == \"name0\""];
        XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with single match");
        XCTAssertEqualObjects(v[0][nameIndex], @"name0");
        XCTAssertEqualObjects(v[0][ageIndex], @0);
        
        v = [table allWhere:@"age == 1"];
        XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with two matches");
        XCTAssertEqualObjects(v[0][ageIndex], @1);
        
        v = [table allWhere:@"1 == age"];
        XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with two matches");
        XCTAssertEqualObjects(v[0][ageIndex], @1);
        
        // test AND
        v = [table allWhere:@"age == 1 AND name == \"name1\""];
        XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with one match");
        XCTAssertEqualObjects(v[0][nameIndex], @"name1");
        
        // test OR
        v = [table allWhere:@"age == 1 OR age == 4"];
        XCTAssertEqual(v.rowCount, (NSUInteger)3, @"View with 3 matches");
        
        // test other numeric operators
        v = [table allWhere:@"age > 3"];
        XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with 1 matches");
        
        v = [table allWhere:@"age >= 3"];
        XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with 2 matches");
        
        v = [table allWhere:@"age < 1"];
        XCTAssertEqual(v.rowCount, (NSUInteger)1, @"View with 1 matches");
        
        v = [table allWhere:@"age <= 1"];
        XCTAssertEqual(v.rowCount, (NSUInteger)3, @"View with 3 matches");
        
        // Filter with predicate object
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @1];
        v = [table allWhere:predicate];
        XCTAssertEqual(v.rowCount, (NSUInteger)2, @"View with two matches");
        XCTAssertEqualObjects(v[0][ageIndex], @1);
    }];
}

- (void)testPredicateSort
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"name" type:RLMTypeString];
        NSUInteger ageIndex = [table addColumnWithName:@"age" type:RLMTypeInt];
        [table addColumnWithName:@"hired" type:RLMTypeBool];
        
        [table addRow:@[@"name4", @4, [NSNumber numberWithBool:YES]]];
        [table addRow:@[@"name0",@0, [NSNumber numberWithBool:NO]]];
        
        RLMView *v = [table allWhere:nil orderBy:nil];
        XCTAssertEqualObjects(v[0][ageIndex], @4);
        XCTAssertEqualObjects(v[1][ageIndex], @0);
        
        RLMView *vAscending = [table allWhere:nil orderBy:@"age"];
        XCTAssertEqualObjects(vAscending[0][ageIndex], @0);
        XCTAssertEqualObjects(vAscending[1][ageIndex], @4);
        
        RLMView *vAscending2 = [table allWhere:nil orderBy:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]];
        XCTAssertEqualObjects(vAscending2[0][ageIndex], @0);
        XCTAssertEqualObjects(vAscending2[1][ageIndex], @4);
        
        NSSortDescriptor * reverseSort = [NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO];
        RLMView *vDescending = [table allWhere:nil orderBy:reverseSort];
        XCTAssertEqualObjects(vDescending[0][ageIndex], @4);
        XCTAssertEqualObjects(vDescending[1][ageIndex], @0);
        
        NSSortDescriptor * boolSort = [NSSortDescriptor sortDescriptorWithKey:@"hired" ascending:YES];
        RLMView *vBool = [table allWhere:nil orderBy:boolSort];
        XCTAssertEqualObjects(vBool[0][ageIndex], @0);
        XCTAssertEqualObjects(vBool[1][ageIndex], @4);
        
        XCTAssertThrows([table allWhere:nil orderBy:@1], @"Invalid order type");
        
        NSSortDescriptor * misspell = [NSSortDescriptor sortDescriptorWithKey:@"oge" ascending:YES];
        XCTAssertThrows([table allWhere:nil orderBy:misspell], @"Invalid sort");
        
        NSSortDescriptor * wrongColType = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        XCTAssertThrows([table allWhere:nil orderBy:wrongColType], @"Invalid column type");
    }];
}


-(void)testTableDynamic_find_int
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        for (int i=0; i<10; ++i) {
            [table addRow:@[[NSNumber numberWithInt:i]]];
        }
        XCTAssertEqual((NSUInteger)5, [table findRowIndexWithInt:5 inColumnWithIndex:0], @"Cannot find element");
        XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithInt:11 inColumnWithIndex:0]), @"Found something");
    }];
}

-(void)testTableDynamic_find_float
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeFloat];
        for (int i=0; i<10; ++i) {
            [table addRow:@[[NSNumber numberWithFloat:(float)i]]];
        }
        XCTAssertEqual((NSUInteger)5, [table findRowIndexWithFloat:5.0 inColumnWithIndex:0], @"Cannot find element");
        XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithFloat:11.0 inColumnWithIndex:0]), @"Found something");
    }];
}

-(void)testTableDynamic_find_double
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeDouble];
        for(int i=0; i<10; ++i) {
            [table addRow:@[[NSNumber numberWithDouble:(double)i]]];
        }
        XCTAssertEqual((NSUInteger)5, [table findRowIndexWithDouble:5.0 inColumnWithIndex:0], @"Cannot find element");
        XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithDouble:11.0 inColumnWithIndex:0]), @"Found something");
    }];
}

-(void)testTableDynamic_find_bool
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeBool];
        for (int i=0; i<10; ++i) {
            [table addRow:@[[NSNumber numberWithBool:YES]]];
        }
        table[5][@"first"] = @NO;
        XCTAssertEqual((NSUInteger)5, [table findRowIndexWithBool:NO inColumnWithIndex:0], @"Cannot find element");
        table[5][@"first"] = @YES;
        XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithBool:NO inColumnWithIndex:0]), @"Found something");
    }];
}

-(void)testTableDynamic_find_string
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeString];
        for (int i=0; i<10; ++i) {
            [table addRow:@[[NSString stringWithFormat:@"%d", i]]];
        }
        XCTAssertEqual((NSUInteger)5, [table findRowIndexWithString:@"5" inColumnWithIndex:0], @"Cannot find element");
        XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithString:@"11" inColumnWithIndex:0]), @"Found something");
    }];
}

-(void)testTableDynamic_find_date
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeDate];
        for (int i=0; i<10; ++i) {
            [table addRow:@[[NSDate dateWithTimeIntervalSince1970:i]]];
        }
        XCTAssertEqual((NSUInteger)5, [table findRowIndexWithDate:[NSDate dateWithTimeIntervalSince1970:5] inColumnWithIndex:0], @"Cannot find element");
        XCTAssertEqual((NSUInteger)NSNotFound, ([table findRowIndexWithDate:[NSDate dateWithTimeIntervalSince1970:11] inColumnWithIndex:0]), @"Found something");
    }];
}

- (void)testTableDynamic_update_row
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"objID" type:RLMTypeInt];
        [table addColumnWithName:@"name" type:RLMTypeString];
        
        [table addRow:@{@"objID" : @89213, @"name" : @"Fiel"}];
        [table addRow:@{@"objID" : @45132, @"name" : @"Paul"}];
        
        // Test set NSObject for valid index
        NSUInteger previousRowCount = [table rowCount];
        TestObject* object = [[TestObject alloc] init];
        object.objID = @1;
        object.name = @"Alex";
        
        XCTAssertNoThrow([table updateRow:object atIndex:0], @"Setting object for valid index should not throw exception");
        XCTAssertTrue(previousRowCount == [table rowCount], @"previousRowCount should be equal to current rowCount");
        XCTAssertTrue([table[0][@"objID"] isEqualToNumber:object.objID], @"Object at index 0 should have newly set objID");
        XCTAssertTrue([table[0][@"name"] isEqualToString:object.name], @"Object at index 0 should have newly set name");
        
        // Test set NSDictionary for valid index
        previousRowCount = [table rowCount];
        NSDictionary* testDictionary = @{@"objID" : @2, @"name" : @"Tim"};
        
        XCTAssertNoThrow([table updateRow:testDictionary atIndex:0], @"Setting object for valid index should not throw exception");
        XCTAssertTrue(previousRowCount == [table rowCount], @"previousRowCount should be equal to current rowCount");
        XCTAssertTrue([table[0][@"objID"] isEqualToNumber:testDictionary[@"objID"]], @"Object at index 0 should have newly set objID");
        XCTAssertTrue([table[0][@"name"] isEqualToString:testDictionary[@"name"]], @"Object at index 0 should have newly set name");
        
        // Test set NSArray for valid index
        previousRowCount = [table rowCount];
        NSArray* testArray = @[@3, @"Ari"];
        
        XCTAssertNoThrow([table updateRow:testArray atIndex:0], @"Setting object for valid index should not throw exception");
        XCTAssertTrue(previousRowCount == [table rowCount], @"previousRowCount should be equal to current rowCount");
        XCTAssertTrue([table[0][@"objID"] isEqualToNumber:testArray[0]], @"Object at index 0 should have newly set objID");
        XCTAssertTrue([table[0][@"name"] isEqualToString:testArray[1]], @"Object at index 0 should have newly set name");
        
        // Test set valid object for invalid index
        previousRowCount = [table rowCount];
        XCTAssertThrows([table updateRow:object atIndex:12], @"Setting object for invalid index should throw exception");
        XCTAssertTrue(previousRowCount == [table rowCount], @"previousRowCount should be equal to current rowCount");
        XCTAssertTrue([table[0][@"objID"] isEqualToNumber:testArray[0]], @"Object at index 0 should have newly set objID");
        XCTAssertTrue([table[0][@"name"] isEqualToString:testArray[1]], @"Object at index 0 should have newly set name");
        
        // Test set nil for valid index
        previousRowCount = [table rowCount];
        XCTAssertNoThrow(([table updateRow:nil atIndex:0]), @"Setting object to nil should not throw exception");
        XCTAssertTrue(previousRowCount == [table rowCount], @"rowCount should be equal to previousRowCount");
        XCTAssertTrue([table[0][@"objID"] isEqualToNumber:testArray[0]], @"table[0][@\"objID\"] should be equal to last next object's objID after setting row to nil");
        XCTAssertTrue([table[0][@"name"] isEqualToString:testArray[1]], @"table[0][@\"name\"] should be equal to last next object's objID after setting row to nil");
    }];
}

-(void)testTableDynamic_init_exception
{
    XCTAssertThrows(([[RLMTable alloc] init]), @"Initializing table outside of context should throw exception");
}

- (void)testTableDynamic_countWhere
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        [table addColumnWithName:@"BoolCol" type:RLMTypeBool];
        
        [table addRow:@[@1231, @NO]];
        [table addRow:@[@1232, @YES]];
        [table addRow:@[@1233, @YES]];
        [table addRow:@[@1234, @NO]];
        [table addRow:@[@1235, @NO]];
        
        XCTAssertEqual([table countWhere:@"BoolCol == NO"], (NSUInteger)3, @"countWhere should return 3");
        XCTAssertEqual([table countWhere:@"BoolCol == YES"], (NSUInteger)2, @"countWhere should return 2");
        XCTAssertEqual([table countWhere:@"IntCol == 1232"], (NSUInteger)1, @"countWhere should return 1");
        XCTAssertEqual([table countWhere:@"IntCol == 89172"], (NSUInteger)0, @"countWhere should return 0");
    }];
}

- (void)testTableDynamic_sumOfColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        [table addColumnWithName:@"FloatCol" type:RLMTypeFloat];
        [table addColumnWithName:@"DoubleCol" type:RLMTypeDouble];
        [table addColumnWithName:@"BoolCol" type:RLMTypeBool];
        
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];

        
        // Test int sum
        XCTAssertEqual([[table sumOfProperty:@"IntCol" where:@"BoolCol == NO"] integerValue], (NSInteger)4, @"Sum should be 4");
        XCTAssertEqual([[table sumOfProperty:@"IntCol" where:@"BoolCol == YES"] integerValue], (NSInteger)0, @"Sum should be 0");
        
        // Test float sum
        XCTAssertEqualWithAccuracy([[table sumOfProperty:@"FloatCol" where:@"BoolCol == NO"] floatValue], (float)0.0f, 0.1f, @"Sum should be 0");
        XCTAssertEqualWithAccuracy([[table sumOfProperty:@"FloatCol" where:@"BoolCol == YES"] floatValue], (float)7.2f, 0.1f, @"Sum should be 7.2");
        
        // Test double sum
        XCTAssertEqualWithAccuracy([[table sumOfProperty:@"DoubleCol" where:@"BoolCol == NO"] doubleValue], (double)10.0, 0.1f, @"Sum should be 10.0");
        XCTAssertEqualWithAccuracy([[table sumOfProperty:@"DoubleCol" where:@"BoolCol == YES"] doubleValue], (double)0.0, 0.1f, @"Sum should be 0.0");
        
        // Test invalid column name
        XCTAssertThrows([table sumOfProperty:@"foo" where:@"BoolCol == YES"], @"Should throw exception");
        
        // Test operation not supported
        XCTAssertThrows([table sumOfProperty:@"BoolCol" where:@"IntCol == 1"], @"Should throw exception");
    }];
}

- (void)testTableDynamic_averageOfColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        [table addColumnWithName:@"FloatCol" type:RLMTypeFloat];
        [table addColumnWithName:@"DoubleCol" type:RLMTypeDouble];
        [table addColumnWithName:@"BoolCol" type:RLMTypeBool];
        
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@1, @0.0f, @2.5, @NO]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        [table addRow:@[@0, @1.2f, @0.0, @YES]];
        
        
        // Test int average
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"IntCol" where:@"BoolCol == NO"] doubleValue], (double)1.0, 0.1f, @"Average should be 1.0");
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"IntCol" where:@"BoolCol == YES"] doubleValue], (double)0.0, 0.1f, @"Average should be 0.0");
        
        // Test float average
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"FloatCol" where:@"BoolCol == NO"] doubleValue], (double)0.0f, 0.1f, @"Average should be 0.0");
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"FloatCol" where:@"BoolCol == YES"] doubleValue], (double)1.2f, 0.1f, @"Average should be 1.2");
        
        // Test double average
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"DoubleCol" where:@"BoolCol == NO"] doubleValue], (double)2.5, 0.1f, @"Average should be 2.5");
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"DoubleCol" where:@"BoolCol == YES"] doubleValue], (double)0.0, 0.1f, @"Average should be 0.0");
        
        // Test invalid column name
        XCTAssertThrows([table averageOfProperty:@"foo" where:@"BoolCol == YES"], @"Should throw exception");
        
        // Test operation not supported
        XCTAssertThrows([table averageOfProperty:@"BoolCol" where:@"IntCol == 1"], @"Should throw exception");
    }];
}

- (void)testTableDynamic_minMaxInColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        [table addColumnWithName:@"FloatCol" type:RLMTypeFloat];
        [table addColumnWithName:@"DoubleCol" type:RLMTypeDouble];
        [table addColumnWithName:@"BoolCol" type:RLMTypeBool];
        
        [table addRow:@[@1, @1.1f, @0.0, @YES]];
        [table addRow:@[@2, @1.2f, @1.5, @NO]];
        [table addRow:@[@3, @1.3f, @3.0, @YES]];
        [table addRow:@[@4, @1.4f, @4.5, @NO]];
        [table addRow:@[@5, @1.5f, @6.0, @YES]];
        [table addRow:@[@6, @1.6f, @7.5, @NO]];
        [table addRow:@[@7, @1.7f, @9.0, @YES]];
        [table addRow:@[@8, @1.8f, @10.5, @NO]];
        [table addRow:@[@9, @1.9f, @12.0, @YES]];
        [table addRow:@[@10, @2.0f, @13.5, @YES]];
        
        
        // Test int min
        XCTAssertEqual([[table minOfProperty:@"IntCol" where:@"BoolCol == NO"] integerValue], (NSInteger)2, @"Minimum should be 2");
        XCTAssertEqual([[table minOfProperty:@"IntCol" where:@"BoolCol == YES"] integerValue], (NSInteger)1, @"Minimum should be 1");
        
        // Test float min
        XCTAssertEqualWithAccuracy([[table minOfProperty:@"FloatCol" where:@"BoolCol == NO"] floatValue], (float)1.2f, 0.1f, @"Minimum should be 1.2f");
        XCTAssertEqualWithAccuracy([[table minOfProperty:@"FloatCol" where:@"BoolCol == YES"] floatValue], (float)1.1f, 0.1f, @"Minimum should be 1.1f");
        
        // Test double min
        XCTAssertEqualWithAccuracy([[table minOfProperty:@"DoubleCol" where:@"BoolCol == NO"] doubleValue], (double)1.5, 0.1f, @"Minimum should be 1.5");
        XCTAssertEqualWithAccuracy([[table minOfProperty:@"DoubleCol" where:@"BoolCol == YES"] doubleValue], (double)0.0, 0.1f, @"Minimum should be 0.0");
        
        // Test invalid column name
        XCTAssertThrows([table minOfProperty:@"foo" where:@"BoolCol == YES"], @"Should throw exception");
        
        // Test operation not supported
        XCTAssertThrows([table minOfProperty:@"BoolCol" where:@"IntCol == 1"], @"Should throw exception");
        
        // Test int max
        XCTAssertEqual([[table maxOfProperty:@"IntCol" where:@"BoolCol == NO"] integerValue], (NSInteger)8, @"Maximum should be 8");
        XCTAssertEqual([[table maxOfProperty:@"IntCol" where:@"BoolCol == YES"] integerValue], (NSInteger)10, @"Maximum should be 10");
        
        // Test float max
        XCTAssertEqualWithAccuracy([[table maxOfProperty:@"FloatCol" where:@"BoolCol == NO"] floatValue], (float)1.8f, 0.1f, @"Maximum should be 1.8f");
        XCTAssertEqualWithAccuracy([[table maxOfProperty:@"FloatCol" where:@"BoolCol == YES"] floatValue], (float)2.0f, 0.1f, @"Maximum should be 2.0f");
        
        // Test double max
        XCTAssertEqualWithAccuracy([[table maxOfProperty:@"DoubleCol" where:@"BoolCol == NO"] doubleValue], (double)10.5, 0.1f, @"Maximum should be 10.5");
        XCTAssertEqualWithAccuracy([[table maxOfProperty:@"DoubleCol" where:@"BoolCol == YES"] doubleValue], (double)13.5, 0.1f, @"Maximum should be 13.5");
    }];
}

- (void)testSubtableEmptyArray
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"Subtable" type:RLMTypeTable];

        [table addRow:@[@[]]];

        XCTAssertTrue(table.rowCount == 1, @"1 row excepted");
        XCTAssertTrue(((RLMTable *)table[0][@"Subtable"]).rowCount == 0, @"0 rows excepted");
    }];
}

- (void)testSubtableEmptyArrayUsingDictionary
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"Subtable" type:RLMTypeTable];

        [table addRow:@{@"Subtable": @[]}];

        XCTAssertTrue(table.rowCount == 1, @"1 row excepted");
        XCTAssertTrue(((RLMTable *)table[0][@"Subtable"]).rowCount == 0, @"0 rows excepted");
    }];

}

@end
