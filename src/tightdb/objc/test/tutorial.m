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
    PeopleTable *people = [group getTable:@"employees" withClass:[PeopleTable class]];

    // Add some rows
    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];

    // Insert at specific position
    [people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];

    // Getting the size of the table
    NSLog(@"PeopleTable Size: %lu - is %@.    [6 - not empty]", [people count],
        [people isEmpty] ? @"empty" : @"not empty");

    //------------------------------------------------------
    NSLog(@"--- Working with individual rows ---");
    //------------------------------------------------------

    // Getting values
    NSString * name = [people objectAtIndex:5].Name;   // => 'Anni'
    // Using a cursor
    PeopleTable_Cursor *myRow = [people objectAtIndex:5];
    int64_t age = myRow.Age;                           // => 54
    BOOL hired  = myRow.Hired;                         // => true
    NSLog(@"%@ is %lld years old.", name, age);
    if (hired) NSLog(@"is hired.");

    // Setting values
    [[people objectAtIndex:5] setAge:43];               // Getting younger
    // or with dot-syntax:
    myRow.Age += 1;                                    // Happy birthday!
    NSLog(@"%@ age is now %lld.   [44]", myRow.Name, myRow.Age);

    // Get last row
    NSString *lastname = [people lastObject].Name;       // => "Anni"
    NSLog(@"Last name is %@.   [Anni]", lastname);

    // Change a row - not implemented yet
    // [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];

    // Delete row
    [people deleteRow:2];
    NSLog(@"%lu rows after delete.  [5]", [people count]);  // 5
    STAssertEquals([people count], (size_t)5,@"rows should be 5");

    // Iterating over rows:
    for (size_t i = 0; i < [people count]; ++i) {
        PeopleTable_Cursor *row = [people objectAtIndex:i];
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

    TightdbView *view = [people.Age findAll:21];
    size_t cnt = [view count];             // cnt = 2
    STAssertEquals(cnt, (size_t)2,@"Should be two rows in view", nil);

    //------------------------------------------------------
    NSLog(@"--- Queries ---");
    //------------------------------------------------------

    // Create query (current employees between 20 and 30 years old)
    PeopleTable_Query *q = [[[people where].Hired equal:YES]            // Implicit AND
                                  .Age between:20 to:30];

    // Get number of matching entries
    NSLog(@"Query count: %zu", [q count]);
    STAssertEquals([q count], (size_t)2,@"Expected 2 rows in query", nil);

    // Get the average age - currently only a low-level interface!
    double avg = [q.Age avg];
    NSLog(@"Average: %f    [20.5]", avg);
    STAssertEquals(avg, 20.5,@"Expected 20.5 average", nil);

    // Execute the query and return a table (view)
    TightdbView *res = [q findAll];
    for (size_t i = 0; i < [res count]; ++i) {
        NSLog(@"%zu: %@ is %lld years old", i,
            [people objectAtIndex:i].Name,
            [people objectAtIndex:i].Age);
    }

    //------------------------------------------------------
    NSLog(@"--- Serialization ---");
    //------------------------------------------------------

    // Write the group to disk
    [group write:@"employees.tightdb"];

    // Load a group from disk (and print contents)
    TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"employees.tightdb"];
    PeopleTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleTable class]];

    [diskTable addName:@"Anni" Age:54 Hired:YES];

    NSLog(@"Disktable size: %zu", [diskTable count]);

    for (size_t i = 0; i < [diskTable count]; i++) {
        PeopleTable_Cursor *cursor = [diskTable objectAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);
        NSLog(@"%zu: %@", i, cursor.Name);
    }

    // Write same group to memory buffer
    size_t size;
    const char* const data = [group writeToMem:&size];

    // Load a group from memory (and print contents)
    TightdbGroup *fromMem = [TightdbGroup groupWithBuffer:data size:size];
    PeopleTable *memTable = [fromMem getTable:@"employees" withClass:[PeopleTable class]];
    for (size_t i = 0; i < [memTable count]; i++) {
        PeopleTable_Cursor *cursor = [memTable objectAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Name);
    }
}

@end
