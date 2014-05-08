//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import "RLMTestCase.h"

#import <realm/objc/RLMFast.h>
#import <realm/objc/RLMTableFast.h>
#import <realm/objc/RLMViewFast.h>
#import <realm/objc/RLMRealm.h>

@interface RLMSharedObject : RLMRow

@property (nonatomic, assign) BOOL hired;
@property (nonatomic, assign) NSInteger age;

@end

@implementation RLMSharedObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(RLMSharedTable, RLMSharedObject);

@interface MACTestSharedGroup: RLMTestCase

@end

@implementation MACTestSharedGroup

- (void)testTransactionManager {
    
    // TODO: Update test to include more ASSERTS
    
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        // Create new table in realm
        RLMSharedTable *table = [RLMSharedTable tableInRealm:realm named:@"table"];
        
        // Add some rows
        [table addRow:@[@YES, @50]];
        [table addRow:@[@YES, @52]];
        [table addRow:@[@YES, @53]];
        [table addRow:@[@YES, @54]];
    }];
    
    RLMRealm *realm = [self realmWithTestPath];
    RLMSharedTable *diskTable = [RLMSharedTable tableInRealm:realm named:@"table"];
    for (NSUInteger i = 0; i < [diskTable rowCount]; i++) {
        RLMSharedObject *cursor = [diskTable rowAtIndex:i];
        NSLog(@"%zu: %ld", i, cursor.age);
        NSLog(@"%zu: %i", i, cursor.hired);
    }
    
    [realm writeUsingBlock:^(RLMRealm *realm) {
        RLMSharedTable *diskTable = [RLMSharedTable tableInRealm:realm named:@"table"];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (NSUInteger i = 0; i < 50; i++) {
            [diskTable addRow:@[@YES, @(i)]];
        }
    }];
    
    [realm beginWriteTransaction];
    diskTable = [RLMSharedTable tableInRealm:realm named:@"table"];
    NSLog(@"Disktable size: %zu", [diskTable rowCount]);
    for (NSUInteger i = 0; i < 50; i++) {
        [diskTable addRow:@[@YES, @(i)]];
    }
    [realm rollbackWriteTransaction];
    
    [realm writeUsingBlock:^(RLMRealm *realm) {
        RLMSharedTable *diskTable = [RLMSharedTable tableInRealm:realm named:@"table"];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (NSUInteger i = 0; i < 50; i++) {
            [diskTable addRow:@[@YES, @(i)]];
        }
        
        XCTAssertNil([realm tableWithName:@"Does not exist"], @"Table does not exist");
    }];
    
    diskTable = [RLMSharedTable tableInRealm:realm named:@"table"];
    NSLog(@"Disktable size: %zu", [diskTable rowCount]);
    
    XCTAssertThrows([diskTable removeAllRows], @"Not allowed in read transaction");
}

- (void)testTransactionManagerAtDefaultPath
{
    // Create a new transaction manager
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
    }];
    
    RLMTable *t = [realm tableWithName:@"table"];
    XCTAssertEqualObjects(t[0][0], @10);
}

- (void)testRealmCreateTableWithColumns
{
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        // Check if method throws exception
        XCTAssertNoThrow(([realm createTableWithName:@"Test" columns:@[@"id", @"int"]]), @"Table should not throw exception");
        
        // Test adding rows for single column table
        NSString* const RLMTableNameDepartment = @"Department";
        RLMTable* departmentTable = [realm createTableWithName:RLMTableNameDepartment columns:@[@"name", @"string"]];
        XCTAssertTrue(departmentTable.columnCount == 1, @"Table should have 1 column");
        XCTAssertTrue([[departmentTable nameOfColumnWithIndex:0] isEqualToString:@"name"], @"Column at index 0 should be name");
        XCTAssertNoThrow(([departmentTable addRow:@{@"name" : @"Engineering"}]), @"Adding row should not throw exception");
        
        // Test adding rows for multi-column table
        NSString* const RLMTableNameEmployee = @"Employee";
        RLMTable* employeeTable = [realm createTableWithName:RLMTableNameEmployee columns:@[@"id", @"int", @"name", @"string", @"position", @"string"]];
        XCTAssertTrue(employeeTable.columnCount == 3, @"Table should have 3 column");
        XCTAssertTrue([[employeeTable nameOfColumnWithIndex:0] isEqualToString:@"id"], @"Column at index 0 should be id");
        XCTAssertTrue([[employeeTable nameOfColumnWithIndex:1] isEqualToString:@"name"], @"Column at index 1 should be name");
        XCTAssertTrue([[employeeTable nameOfColumnWithIndex:2] isEqualToString:@"position"], @"Column at index 0 should be position");
        XCTAssertNoThrow(([employeeTable addRow:@{@"id" : @124312, @"name" : @"Fiel Guhit", @"position" : @"iOS Engineer"}]), @"Adding row should not throw exception");
    }];
}

- (void)testReadRealm
{
    RLMRealm * realm = [self realmWithTestPath];
    
    [realm writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
    }];
    
    RLMTable *t = [realm tableWithName:@"table"];
    
    XCTAssertThrows([t addRow:nil], @"Is in read transaction");
    XCTAssertThrows([t addRow:@[@1]], @"Is in read transaction");
    
    RLMQuery *q = [t where];
    XCTAssertThrows([q removeRows], @"Is in read transaction");
    
    RLMView *v = [q findAllRows];
    
    XCTAssertThrows([v removeAllRows], @"Is in read transaction");
    XCTAssertThrows([[v where] removeRows], @"Is in read transaction");
    
    XCTAssertEqual(t.rowCount,      (NSUInteger)1, @"No rows have been removed");
    XCTAssertEqual([q countRows],   (NSUInteger)1, @"No rows have been removed");
    XCTAssertEqual(v.rowCount,      (NSUInteger)1, @"No rows have been removed");
    
    XCTAssertNil([realm tableWithName:@"Does not exist"], @"Table does not exist");
}

- (void)testSingleTableTransactions
{
    RLMRealm * ctx = [self realmWithTestPath];
    
    [ctx writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
    }];
    
    RLMTable *table = [ctx tableWithName:@"table"];
    XCTAssertTrue([table rowCount] == 1, @"No rows have been removed");
    
    [ctx beginWriteTransaction];
    [table addRow:@[@10]];
    [ctx commitWriteTransaction];
    
    XCTAssertTrue([table rowCount] == 2, @"Rows were added");
}


- (void)testRealmExceptions
{
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm writeUsingBlock:^(RLMRealm *realm) {
        
        XCTAssertThrows([realm createTableWithName:nil], @"name is nil");
        XCTAssertThrows([realm createTableWithName:@""], @"name is empty");
        
        [realm createTableWithName:@"name"];
        XCTAssertThrows([realm createTableWithName:@"name"], @"name already exists");
    }];
    
    XCTAssertThrows([realm tableWithName:nil], @"name is nil");
    XCTAssertThrows([realm tableWithName:@""], @"name is empty");
    XCTAssertThrows([realm createTableWithName:@"same name"], @"creating table not allowed in read transaction");
    XCTAssertThrows([realm createTableWithName:@"name"], @"creating table not allowed in read transaction");
    XCTAssertNil([realm tableWithName:@"weird name"], @"get table that does not exists return nil");
}

@end
