//
//  tutorial.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_DEF_3(PeopleTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool)

TIGHTDB_TABLE_DEF_2(PeopleTable2,
                    Hired, Bool,
                    Age,   Int)

TIGHTDB_TABLE_IMPL_3(PeopleTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

TIGHTDB_TABLE_IMPL_2(PeopleTable2,
                     Hired, Bool,
                     Age,   Int)

@interface MACTestTutorial: SenTestCase
@end
@implementation MACTestTutorial

- (void)testTutorial
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------

    TightdbGroup *group = [TightdbGroup group];
    // Create new table in group
    PeopleTable *people = [group getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class] error:nil];

    // Add some rows
    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];

    // Insert at specific position
    [people insertEmptyRowAtIndex:2 Name:@"Frank" Age:34 Hired:YES];

    // Getting the size of the table
    NSLog(@"PeopleTable Size: %lu - is %@.    [6 - not empty]", [people rowCount],
        people.rowCount == 0 ? @"empty" : @"not empty");

    //------------------------------------------------------
    NSLog(@"--- Working with individual rows ---");
    //------------------------------------------------------

    // Getting values
    NSString * name = [people cursorAtIndex:5].Name;   // => 'Anni'
    // Using a cursor
    PeopleTable_Cursor *myRow = [people cursorAtIndex:5];
    int64_t age = myRow.Age;                           // => 54
    BOOL hired  = myRow.Hired;                         // => true
    NSLog(@"%@ is %lld years old.", name, age);
    if (hired) NSLog(@"is hired.");

    // Setting values  (note: setter access will be made obsolete, use dot notation)
    [[people cursorAtIndex:5] setAge:43];  // Getting younger
    
    // or with dot-syntax:
    myRow.Age += 1;                                    // Happy birthday!
    NSLog(@"%@ age is now %lld.   [44]", myRow.Name, myRow.Age);

    // Get last row
    NSString *lastname = [people cursorAtLastIndex].Name;       // => "Anni"
    NSLog(@"Last name is %@.   [Anni]", lastname);

    // Change a row - not implemented yet
    // [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];

    // Delete row
    [people removeRowAtIndex:2];
    NSLog(@"%lu rows after remove.  [5]", [people rowCount]);  // 5
    STAssertEquals([people rowCount], (size_t)5,@"rows should be 5");

    // Iterating over rows:
    for (size_t i = 0; i < [people rowCount]; ++i) {
        PeopleTable_Cursor *row = [people cursorAtIndex:i];
        NSLog(@"(Rows) %@ is %lld years old.", row.Name, row.Age);
    }

    //------------------------------------------------------
    NSLog(@"--- Simple Searching ---");
    //------------------------------------------------------

    size_t row;
    row = [people.Name find:@"Philip"];    // row = (size_t)-1
    NSLog(@"Philip: %zu  [-1]", row);
    STAssertEquals(row, (size_t)-1,@"Philip should not be there", nil);

    row = [people.Name find:@"Mary"];
    NSLog(@"Mary: %zu", row);
    STAssertEquals(row, (size_t)1,@"Mary should have been there", nil);

    PeopleTable_View *view = [[[people where].Age columnIsEqualTo:21] findAll];
    size_t cnt = [view rowCount];             // cnt = 2
    STAssertEquals(cnt, (size_t)2,@"Should be two rows in view", nil);

    //------------------------------------------------------
    NSLog(@"--- Queries ---");
    //------------------------------------------------------

    // Create query (current employees between 20 and 30 years old)
    PeopleTable_Query *q = [[[people where].Hired columnIsEqualTo:YES]            // Implicit AND
                                  .Age columnIsBetween:20 and_:30];

    // Get number of matching entries
    NSLog(@"Query count: %lu",[q countRows]);
    STAssertEquals([q countRows] , (size_t)2,@"Expected 2 rows in query", nil);

    // Get the average age - currently only a low-level interface!
    double avg = [q.Age average] ;
    NSLog(@"Average: %f    [20.5]", avg);
    STAssertEquals(avg, 20.5,@"Expected 20.5 average", nil);

    // Execute the query and return a table (view)
    TightdbView *res = [q findAll];
    for (size_t i = 0; i < [res rowCount]; ++i) {
        NSLog(@"%zu: %@ is %lld years old", i,
            [people cursorAtIndex:i].Name,
            [people cursorAtIndex:i].Age);
    }

    //------------------------------------------------------
    NSLog(@"--- Serialization ---");
    //------------------------------------------------------

    NSFileManager *fm = [NSFileManager defaultManager];

    // Write the group to disk
    [fm removeItemAtPath:@"employees.tightdb" error:nil];
    [group writeToFile:@"employees.tightdb" withError:nil];

    // Load a group from disk (and print contents)
    TightdbGroup *fromDisk = [TightdbGroup groupWithFile:@"employees.tightdb" withError:nil];
    PeopleTable *diskTable = [fromDisk getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class] error:nil];

    [diskTable addName:@"Anni" Age:54 Hired:YES];

    NSLog(@"Disktable size: %zu", [diskTable rowCount]);

    for (size_t i = 0; i < [diskTable rowCount]; i++) {
        PeopleTable_Cursor *cursor = [diskTable cursorAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);
        NSLog(@"%zu: %@", i, cursor.Name);
    }

    // Write same group to memory buffer
    TightdbBinary* buffer = [group writeToBuffer];

    // Load a group from memory (and print contents)
    TightdbGroup *fromMem = [TightdbGroup groupWithBuffer:buffer withError:nil];
    PeopleTable *memTable = [fromMem getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class] error:nil];
    for (size_t i = 0; i < [memTable rowCount]; i++) {
        PeopleTable_Cursor *cursor = [memTable cursorAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Name);
    }
}

@end
