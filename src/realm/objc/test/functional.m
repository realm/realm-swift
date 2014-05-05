//  functional.m
//  TightDB
//
//  This test is aimed at verifying functionallity added by the binding.


#import "RLMTestCase.h"
#import <realm/objc/RLMFast.h>
#import <realm/objc/RLMTable.h>
#import <realm/objc/RLMTableFast.h>
#import <realm/objc/RLMPrivateTableMacrosFast.h>

@interface RLMPerson : RLMRow

@property (nonatomic, copy)   NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL      hired;

@end

@implementation RLMPerson
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(RLMPersonTable, RLMPerson);

#define TABLE_SIZE 1000 // must be even number
#define INSERT_ROW 5

@interface MACtestFunctional: RLMTestCase
@end
@implementation MACtestFunctional

- (void)testTypedRow {
    
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMPersonTable *table = [RLMPersonTable tableInRealm:realm named:@"table"];
        
        // Add rows
        for (NSUInteger index = 0; index < TABLE_SIZE; index++) {
            [table addRow:nil];
            RLMPerson *person = [table lastRow];
            person.name = [@"Person_" stringByAppendingString:@(index).stringValue];
            person.age = index;
            person.hired = index % 2;
        }
        
        // Check values
        NSUInteger i = 0;
        for (RLMPerson *person in table) {
            NSString *expected = [@"Person_" stringByAppendingString:@(i).stringValue];
            XCTAssertTrue([person.name isEqualToString:expected], @"Check name");
            XCTAssertTrue([@(person.age) isEqual:@(i)], @"Check age");
            XCTAssertTrue([@(person.hired) isEqual:@(i % 2)], @"Check hired");
            i++;
        }
        
        // Insert a row
        [table insertRow:nil atIndex:INSERT_ROW];
        RLMPerson *person = [table rowAtIndex:INSERT_ROW];
        person.name = @"Person_Inserted";
        person.age = 99;
        person.hired = YES;
        
        // Check inserted row
        person = [table rowAtIndex:INSERT_ROW];
        XCTAssertTrue([person.name isEqualToString:@"Person_Inserted"], @"Check name");
        XCTAssertTrue([@(person.age) isEqual:@99], @"Check age");
        XCTAssertTrue([@(person.hired) isEqual:@YES], @"Check hired");
        
        // Check row before
        person = [table rowAtIndex:INSERT_ROW - 1];
        NSString *expected = [@"Person_" stringByAppendingString:@(INSERT_ROW - 1).stringValue];
        XCTAssertTrue([person.name isEqualToString:expected], @"Check name");
        XCTAssertTrue([@(person.age) isEqual:@(INSERT_ROW - 1)], @"Check age");
        XCTAssertTrue([@(person.hired) isEqual:@((INSERT_ROW - 1) % 2)], @"Check hired");
        
        // Check row after (should be equal to the previous row at index INSERT_ROW).
        person = [table rowAtIndex:INSERT_ROW + 1];
        expected = [@"Person_" stringByAppendingString:@(INSERT_ROW).stringValue];
        XCTAssertTrue([person.name isEqualToString:expected], @"Check name");
        XCTAssertTrue([@(person.age) isEqual:@(INSERT_ROW)], @"Check age");
        XCTAssertTrue([@(person.hired) isEqual:@(INSERT_ROW % 2)], @"Check hired");
        
        // Check last row
        person = [table lastRow];
        expected = [@"Person_" stringByAppendingString:@(TABLE_SIZE - 1).stringValue];
        XCTAssertTrue([person.name isEqualToString:expected], @"Check name");
        XCTAssertTrue([@(person.age) isEqual:@(TABLE_SIZE - 1)], @"Check age");
        XCTAssertTrue([@(person.hired) isEqual:@((TABLE_SIZE - 1) % 2)], @"Check hired");
        
        
        // Remove the inserted. The query test check that the row was
        // removed correctly (that we're back to the original table).
        [table removeRowAtIndex:INSERT_ROW];
        [table removeLastRow];
        [table removeLastRow];
        XCTAssertEqualObjects(@(table.rowCount), @(TABLE_SIZE - 2), @"Check the size");
        
        // TODO: InsertRowAtIndex.. out-of-bounds check (depends on error handling strategy)
        // TODO: RowAtIndex.. out-of-bounds check (depends onerror handling strategy
        
        /*
         *  Row in a view.
         */
        
        RLMView *view = [table allWhere:nil];
        XCTAssertEqual(view.rowCount, (NSUInteger)(TABLE_SIZE-2), @"Check the size");
        
        i = 0;
        for (person in view) {
            expected = [@"Person_" stringByAppendingString:@(i).stringValue];
            XCTAssertTrue([person.name isEqualToString:expected], @"Check name");
            XCTAssertTrue([@(person.age) isEqual:@(i)], @"Check age");
            XCTAssertTrue([@(person.hired) isEqual:@(i % 2)], @"Check hired");
            i++;
        }
        
        view = [table allWhere:@"hired == YES"];
        
        // Modify a row in the view
        
        person = (RLMPerson *)view.lastRow;
        person.name = @"Modified by view";
        
        // Check the effect on the table
        
        person = table.lastRow;
        XCTAssertTrue([person.name isEqualToString:@"Modified by view"], @"Check mod by view");
        
        // Now delete that row
        
        [view removeRowAtIndex:view.rowCount - 1];  // last row in view (hired = all YES)
        
        // And check it's gone.
        
        XCTAssertEqualObjects(@(table.rowCount), @(TABLE_SIZE-3), @"Check the size");
    }];
}

- (void)testDynamicRow {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        /*
         *  Row in a table.
         */
        
        NSUInteger const NAME = [table addColumnWithName:@"name" type:RLMTypeString];
        NSUInteger const AGE = [table addColumnWithName:@"age" type:RLMTypeInt];
        NSUInteger const HIRED = [table addColumnWithName:@"hired" type:RLMTypeBool];
        
        RLMRow *cursor;
        
        // Add rows
        for (int i = 0; i < TABLE_SIZE; i++) {
            [table addRow:nil];
            cursor = [table lastRow];
            [cursor setString:[@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]] inColumnWithIndex:NAME];
            [cursor setInt:i inColumnWithIndex:AGE];
            [cursor setBool:i%2 == 0 inColumnWithIndex:HIRED];
        };
        
        // Check the values
        int i= 0;
        for (cursor in table) {
            NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
            XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
            XCTAssertEqual([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
            XCTAssertEqual([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:i%2 == 0]], YES, @"Check hired");
            i++;
        }
        
        // Insert a row
        [table insertRow:nil atIndex:INSERT_ROW];
        cursor = [table rowAtIndex:INSERT_ROW];
        [cursor setString:@"Person_Inserted" inColumnWithIndex:NAME];
        [cursor setInt:99 inColumnWithIndex:AGE];
        [cursor setBool:YES inColumnWithIndex:HIRED];
        
        // Check inserted row
        cursor = [table rowAtIndex:INSERT_ROW];
        XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:@"Person_Inserted"], YES, @"Check name");
        XCTAssertEqual([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:99]], YES, @"Check age");
        XCTAssertEqual([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:YES]], YES, @"Check hired");
        
        // Check row before
        cursor = [table rowAtIndex:INSERT_ROW-1];
        NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",INSERT_ROW-1]];
        XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
        XCTAssertEqual([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:INSERT_ROW-1]], YES, @"Check age");
        XCTAssertEqual([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:(INSERT_ROW-1)%2 == 0]], YES, @"Check hired");
        
        // Check row after (should be equal to the previous row at index INSERT_ROW).
        cursor = [table rowAtIndex:INSERT_ROW+1];
        NSString *expected2 = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",INSERT_ROW]];
        XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected2], YES, @"Check name");
        XCTAssertEqual([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:INSERT_ROW]], YES, @"Check age");
        XCTAssertEqual([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:(INSERT_ROW)%2 == 0]], YES, @"Check hired");
        
        // Get a cursor at the last index
        cursor = [table lastRow];
        NSString *expected3 = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",TABLE_SIZE-1]];
        XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected3], YES, @"Check name");
        XCTAssertEqual([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:TABLE_SIZE-1]], YES, @"Check age");
        XCTAssertEqual([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:(TABLE_SIZE-1)%2 == 0]], YES, @"Check hired");
        
        // Remove the inserted. The query test check that the row was
        // removed correctly (that we're back to the original table).
        [table removeRowAtIndex:INSERT_ROW];
        [table removeLastRow];
        [table removeLastRow];
        XCTAssertEqual([NSNumber numberWithLong:[table rowCount]], [NSNumber numberWithLong:TABLE_SIZE-2], @"Check the size");
        
        // TODO: InsertRowAtIndex.. out-of-bounds check (depends on error handling strategy)
        // TODO: RowAtIndex.. out-of-bounds check (depends onerror handling strategy
        
        /*
         *  Row in a query.
         */
        
        RLMQuery *query = [[table where] stringIsNotEqualTo:@"Nothing is equal to this" inColumnWithIndex:NAME ];  // dummy query required right now
        XCTAssertEqual([query countRows], (NSUInteger)(TABLE_SIZE-2), @"Check the size");
        
        i=0;
        for (cursor in query) {
            NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
            XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
            XCTAssertEqual([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
            XCTAssertEqual([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:i%2 == 0]], YES, @"Check hired");
            i++;
        }
        
        /*
         *  Row in table view.
         */
        
        RLMView *view = [[query boolIsEqualTo:YES inColumnWithIndex:HIRED] findAllRows];
        XCTAssertEqual([query countRows], (NSUInteger)(TABLE_SIZE-2)/2, @"Check the size");
        
        i=0;
        for (cursor in view) {
            NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
            XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
            XCTAssertEqual([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
            XCTAssertEqual([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:YES]], YES, @"Check hired");
            i = i + 2; // note: +2
        }
        
        // Modify a row in the view
        
        cursor = [view rowAtIndex:[view rowCount]-1];  // last row in view (hired = all YES)
        [cursor setString:@"Modified by view" inColumnWithIndex:NAME];
        
        // Check the effect on the table
        
        cursor = [table rowAtIndex:[table rowCount]-2];  // the second last row in the view (hired = .....YES, NO, YES, NO)
        XCTAssertEqual([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:@"Modified by view"], YES, @"Check mod by view");
        
        // Now delete that row
        
        [view removeRowAtIndex:[view rowCount]-1];  // last row in view (hired = all YES)
        
        // And check it's gone.
        
        XCTAssertEqual([NSNumber numberWithLong:[table rowCount]], [NSNumber numberWithLong:TABLE_SIZE-3], @"Check the size");
    }];
}

- (void)testRowDescription {
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm createTableWithName:@"people" objectClass:[RLMPerson class]];
        [table addRow:@[@"John", @25, @YES]];
        NSString *rowDescription = [table.firstRow description];
        XCTAssertTrue([rowDescription rangeOfString:@"name"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMRow");
        XCTAssertTrue([rowDescription rangeOfString:@"John"].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMRow");
        
        XCTAssertTrue([rowDescription rangeOfString:@"age"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMRow");
        XCTAssertTrue([rowDescription rangeOfString:@"25"].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMRow");
    }];
}

@end
