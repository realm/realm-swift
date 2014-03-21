//  functional.m
//  TightDB
//
//  This test is aimed at verifying functionallity added by the binding.


#import <SenTestingKit/SenTestingKit.h>
#import <tightdb/objc/Tightdb.h>
#import <tightdb/objc/TDBTable.h>

TIGHTDB_TABLE_3(FuncPeopleTable,
                Name,  String,
                Age,   Int,
                Hired, Bool)

#define TABLE_SIZE 1000 // must be even number
#define INSERT_ROW 5

@interface MACtestFunctional: SenTestCase
@end
@implementation MACtestFunctional

- (void)testTypedRow
{

    /*
     *  Row in a table.
     */

    FuncPeopleTable *table = [[FuncPeopleTable alloc] init];

    FuncPeopleTableRow *cursor;

    // Add rows
    for (int i = 0; i < TABLE_SIZE; i++) {
        cursor = [table addEmptyRow];
        cursor.Name = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
        cursor.Age = i;
        cursor.Hired = i%2 == 0;
    };

    // Check the values
    int i= 0;
    for (cursor in table) {
        NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
        STAssertEquals([[NSString stringWithString:cursor.Name] isEqual:expected], YES, @"Check name");
        STAssertEquals([[NSNumber numberWithLong:cursor.Age] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
        STAssertEquals([[NSNumber numberWithBool:cursor.Hired] isEqual:[NSNumber numberWithBool:i%2 == 0]], YES, @"Check hired");
        i++;
    }

    // Insert a row
    cursor = [table insertEmptyRowAtIndex:INSERT_ROW];
    cursor.Name = @"Person_Inserted";
    cursor.Age = 99;
    cursor.Hired = YES;

    // Check inserted row
    cursor = [table rowAtIndex:INSERT_ROW];
    STAssertEquals([[NSString stringWithString:cursor.Name] isEqual:@"Person_Inserted"], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:cursor.Age] isEqual:[NSNumber numberWithInt:99]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:cursor.Hired] isEqual:[NSNumber numberWithBool:YES]], YES, @"Check hired");

    // Check row before
    cursor = [table rowAtIndex:INSERT_ROW-1];
    NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",INSERT_ROW-1]];
    STAssertEquals([[NSString stringWithString:cursor.Name] isEqual:expected], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:cursor.Age] isEqual:[NSNumber numberWithInt:INSERT_ROW-1]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:cursor.Hired] isEqual:[NSNumber numberWithBool:(INSERT_ROW-1)%2 == 0]], YES, @"Check hired");

    // Check row after (should be equal to the previous row at index INSERT_ROW).
    cursor = [table rowAtIndex:INSERT_ROW+1];
    NSString *expected2 = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",INSERT_ROW]];
    STAssertEquals([[NSString stringWithString:cursor.Name] isEqual:expected2], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:cursor.Age] isEqual:[NSNumber numberWithInt:INSERT_ROW]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:cursor.Hired] isEqual:[NSNumber numberWithBool:(INSERT_ROW)%2 == 0]], YES, @"Check hired");

    // Get a cursor at the last index
    cursor = [table rowAtLastIndex];
    NSString *expected3 = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",TABLE_SIZE-1]];
    STAssertEquals([[NSString stringWithString:cursor.Name] isEqual:expected3], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:cursor.Age] isEqual:[NSNumber numberWithInt:TABLE_SIZE-1]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:cursor.Hired] isEqual:[NSNumber numberWithBool:(TABLE_SIZE-1)%2 == 0]], YES, @"Check hired");

    // Remove the inserted. The query test check that the row was
    // removed correctly (that we're back to the original table).
    [table removeRowAtIndex:INSERT_ROW];
    [table removeLastRow];
    [table removeLastRow];
    STAssertEquals([NSNumber numberWithLong:[table rowCount]], [NSNumber numberWithLong:TABLE_SIZE-2], @"Check the size");

    // TODO: InsertRowAtIndex.. out-of-bounds check (depends on error handling strategy)
    // TODO: RowAtIndex.. out-of-bounds check (depends onerror handling strategy

    /*
     *  Row in a query.
     */

    FuncPeopleTableQuery *query = [[table where].Name columnIsNotEqualTo:@"Nothing is equal to this"];  // dummy query required right now
    STAssertEquals([query countRows], (NSUInteger)(TABLE_SIZE-2), @"Check the size");

    i=0;
    for (cursor in query) {
        NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
        STAssertEquals([[NSString stringWithString: cursor.Name] isEqual:expected], YES, @"Check name");
        STAssertEquals([[NSNumber numberWithLong:cursor.Age] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
        STAssertEquals([[NSNumber numberWithBool:cursor.Hired] isEqual:[NSNumber numberWithBool:i%2 == 0]], YES, @"Check hired");
        i++;
    }

    /*
     *  Row in table view.
     */

    FuncPeopleTableView *view = [[query.Hired columnIsEqualTo:YES] findAll];
    STAssertEquals([query countRows], (NSUInteger)(TABLE_SIZE-2)/2, @"Check the size");

    i=0;
    for (cursor in view) {
        NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
        STAssertEquals([[NSString stringWithString:cursor.Name] isEqual:expected], YES, @"Check name");
        STAssertEquals([[NSNumber numberWithLong:cursor.Age] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
        STAssertEquals([[NSNumber numberWithBool:cursor.Hired] isEqual:[NSNumber numberWithBool:YES]], YES, @"Check hired");
        i = i + 2; // note: +2
    }

    // Modify a row in the view

    cursor = [view rowAtIndex:[view rowCount]-1];  // last row in view (Hired = all YES)
    cursor.Name = @"Modified by view";

    // Check the effect on the table

    cursor = [table rowAtIndex:[table rowCount]-2];  // the second last row in the view (Hired = .....YES, NO, YES, NO)
    STAssertEquals([[NSString stringWithString:cursor.Name] isEqual:@"Modified by view"], YES, @"Check mod by view");

    // Now delete that row

    [view removeRowAtIndex:[view rowCount]-1];  // last row in view (Hired = all YES)

    // And check it's gone.

    STAssertEquals([NSNumber numberWithLong:[table rowCount]], [NSNumber numberWithLong:TABLE_SIZE-3], @"Check the size");

}

- (void)testDynamicRow
{


    /*
     *  Row in a table.
     */

    TDBTable *table = [[TDBTable alloc] init];

    size_t const NAME = [table addColumnWithName:@"Name" andType:TDBStringType];
    size_t const AGE = [table addColumnWithName:@"Age" andType:TDBIntType];
    size_t const HIRED = [table addColumnWithName:@"Hired" andType:TDBBoolType];

    TDBRow *cursor;

    // Add rows
    for (int i = 0; i < TABLE_SIZE; i++) {
        cursor = [table addEmptyRow];
        [cursor setString:[@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]] inColumnWithIndex:NAME];
        [cursor setInt:i inColumnWithIndex:AGE];
        [cursor setBool:i%2 == 0 inColumnWithIndex:HIRED];
    };

    // Check the values
    int i= 0;
    for (cursor in table) {
        NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
        STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
        STAssertEquals([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
        STAssertEquals([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:i%2 == 0]], YES, @"Check hired");
        i++;
    }

    // Insert a row
    cursor = [table insertEmptyRowAtIndex:INSERT_ROW];
    [cursor setString:@"Person_Inserted" inColumnWithIndex:NAME];
    [cursor setInt:99 inColumnWithIndex:AGE];
    [cursor setBool:YES inColumnWithIndex:HIRED];

    // Check inserted row
    cursor = [table rowAtIndex:INSERT_ROW];
    STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:@"Person_Inserted"], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:99]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:YES]], YES, @"Check hired");

    // Check row before
    cursor = [table rowAtIndex:INSERT_ROW-1];
    NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",INSERT_ROW-1]];
    STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:INSERT_ROW-1]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:(INSERT_ROW-1)%2 == 0]], YES, @"Check hired");

    // Check row after (should be equal to the previous row at index INSERT_ROW).
    cursor = [table rowAtIndex:INSERT_ROW+1];
    NSString *expected2 = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",INSERT_ROW]];
    STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected2], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:INSERT_ROW]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:(INSERT_ROW)%2 == 0]], YES, @"Check hired");

    // Get a cursor at the last index
    cursor = [table lastRow];
    NSString *expected3 = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",TABLE_SIZE-1]];
    STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected3], YES, @"Check name");
    STAssertEquals([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:TABLE_SIZE-1]], YES, @"Check age");
    STAssertEquals([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:(TABLE_SIZE-1)%2 == 0]], YES, @"Check hired");

    // Remove the inserted. The query test check that the row was
    // removed correctly (that we're back to the original table).
    [table removeRowAtIndex:INSERT_ROW];
    [table removeLastRow];
    [table removeLastRow];
    STAssertEquals([NSNumber numberWithLong:[table rowCount]], [NSNumber numberWithLong:TABLE_SIZE-2], @"Check the size");

    // TODO: InsertRowAtIndex.. out-of-bounds check (depends on error handling strategy)
    // TODO: RowAtIndex.. out-of-bounds check (depends onerror handling strategy

    /*
     *  Row in a query.
     */

    TDBQuery *query = [[table where] stringIsNotEqualTo:@"Nothing is equal to this" inColumnWithIndex:NAME ];  // dummy query required right now
    STAssertEquals([query countRows], (NSUInteger)(TABLE_SIZE-2), @"Check the size");

    i=0;
    for (cursor in query) {
        NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
        STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
        STAssertEquals([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
        STAssertEquals([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:i%2 == 0]], YES, @"Check hired");
        i++;
    }

    /*
     *  Row in table view.
     */

    TDBView *view = [[query boolIsEqualTo:YES inColumnWithIndex:HIRED] findAllRows];
    STAssertEquals([query countRows], (NSUInteger)(TABLE_SIZE-2)/2, @"Check the size");

    i=0;
    for (cursor in view) {
        NSString *expected = [@"Person_" stringByAppendingString: [NSString stringWithFormat:@"%d",i]];
        STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:expected], YES, @"Check name");
        STAssertEquals([[NSNumber numberWithLong:[cursor intInColumnWithIndex:AGE]] isEqual:[NSNumber numberWithInt:i]], YES, @"Check age");
        STAssertEquals([[NSNumber numberWithBool:[cursor boolInColumnWithIndex:HIRED]] isEqual:[NSNumber numberWithBool:YES]], YES, @"Check hired");
        i = i + 2; // note: +2
    }

    // Modify a row in the view

    cursor = [view rowAtIndex:[view rowCount]-1];  // last row in view (Hired = all YES)
    [cursor setString:@"Modified by view" inColumnWithIndex:NAME];

    // Check the effect on the table

    cursor = [table rowAtIndex:[table rowCount]-2];  // the second last row in the view (Hired = .....YES, NO, YES, NO)
    STAssertEquals([[NSString stringWithString:[cursor stringInColumnWithIndex:NAME]] isEqual:@"Modified by view"], YES, @"Check mod by view");

    // Now delete that row

    [view removeRowAtIndex:[view rowCount]-1];  // last row in view (Hired = all YES)

    // And check it's gone.

    STAssertEquals([NSNumber numberWithLong:[table rowCount]], [NSNumber numberWithLong:TABLE_SIZE-3], @"Check the size");

}




@end
