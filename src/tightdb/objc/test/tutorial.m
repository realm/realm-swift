//
//  tutorial.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/Tightdb.h>
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

    TDBTransaction *transaction = [TDBTransaction group];
    // Create new table in transaction
    PeopleTable *people = [transaction createTableWithName:@"employees" asTableClass:[PeopleTable class]];

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
    NSString * name = [people rowAtIndex:5].Name;   // => 'Anni'
    // Using a row
    PeopleTableRow *myRow = [people rowAtIndex:5];
    int64_t age = myRow.Age;                           // => 54
    BOOL hired  = myRow.Hired;                         // => true
    NSLog(@"%@ is %lld years old.", name, age);
    if (hired) NSLog(@"is hired.");

    // Setting values  (note: setter access will be made obsolete, use dot notation)
    [[people rowAtIndex:5] setAge:43];  // Getting younger
    
    // or with dot-syntax:
    myRow.Age += 1;                                    // Happy birthday!
    NSLog(@"%@ age is now %lld.   [44]", myRow.Name, myRow.Age);

    // Get last row
    NSString *lastname = [people rowAtLastIndex].Name;       // => "Anni"
    NSLog(@"Last name is %@.   [Anni]", lastname);

    // Change a row - not implemented yet
    // [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];

    // Delete row
    [people removeRowAtIndex:2];
    NSLog(@"%lu rows after remove.  [5]", [people rowCount]);  // 5
    STAssertEquals([people rowCount], (size_t)5,@"rows should be 5");

    // Iterating over rows:
    for (size_t i = 0; i < [people rowCount]; ++i) {
        PeopleTableRow *row = [people rowAtIndex:i];
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

    PeopleTableView *view = [[[people where].Age columnIsEqualTo:21] findAll];
    size_t cnt = [view rowCount];             // cnt = 2
    STAssertEquals(cnt, (size_t)2,@"Should be two rows in view", nil);

    //------------------------------------------------------
    NSLog(@"--- Queries ---");
    //------------------------------------------------------

    // Create query (current employees between 20 and 30 years old)
    PeopleTableQuery *q = [[[people where].Hired columnIsEqualTo:YES]            // Implicit AND
                                  .Age columnIsBetween:20 and_:30];

    // Get number of matching entries
    NSLog(@"Query count: %lu",[q countRows]);
    STAssertEquals([q countRows] , (size_t)2,@"Expected 2 rows in query", nil);

    // Get the average age - currently only a low-level interface!
    double avg = [q.Age avg] ;
    NSLog(@"Average: %f    [20.5]", avg);
    STAssertEquals(avg, 20.5,@"Expected 20.5 average", nil);

    // Execute the query and return a table (view)
    TDBView *res = [q findAll];
    for (size_t i = 0; i < [res rowCount]; ++i) {
        NSLog(@"%zu: %@ is %lld years old", i,
            [people rowAtIndex:i].Name,
            [people rowAtIndex:i].Age);
    }

    //------------------------------------------------------
    NSLog(@"--- Serialization ---");
    //------------------------------------------------------

    NSFileManager *fm = [NSFileManager defaultManager];

    // Write the transaction to disk
    [fm removeItemAtPath:@"employees.tightdb" error:nil];
    [transaction writeContextToFile:@"employees.tightdb" withError:nil];

    // Load a transaction from disk (and print contents)
    TDBTransaction *fromDisk = [TDBTransaction groupWithFile:@"employees.tightdb" withError:nil];
    PeopleTable *diskTable = [fromDisk getTableWithName:@"employees" asTableClass:[PeopleTable class]];

    [diskTable addName:@"Anni" Age:54 Hired:YES];

    NSLog(@"Disktable size: %zu", [diskTable rowCount]);

    for (size_t i = 0; i < [diskTable rowCount]; i++) {
        PeopleTableRow *row = [diskTable rowAtIndex:i];
        NSLog(@"%zu: %@", i, [row Name]);
        NSLog(@"%zu: %@", i, row.Name);
    }

    // Write same transaction to memory buffer
    NSData* buffer = [transaction writeContextToBuffer];

    // Load a transaction from memory (and print contents)
    TDBTransaction *fromMem = [TDBTransaction groupWithBuffer:buffer withError:nil];
    PeopleTable *memTable = [fromMem getTableWithName:@"employees" asTableClass:[PeopleTable class]];
    for (size_t i = 0; i < [memTable rowCount]; i++) {
        PeopleTableRow *row = [memTable rowAtIndex:i];
        NSLog(@"%zu: %@", i, row.Name);
    }
}

@end
