#import "AppDelegate.h"
#import <Tightdb/Tightdb.h>


// @@Example: create_table @@
// Define table

TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);

// Use it in a function

void tableFunc() {
    PeopleTable *people = [[PeopleTable alloc] init];
    // (...)
    // @@EndExample@@

    // @@Example: insert_rows @@

    PeopleTable_Cursor *cursor;

    // Row 1
    cursor = [people addEmptyRow];
    cursor.Name  = @"John";
    cursor.Age   = 21;
    cursor.Hired = YES;

    // Row 2
    cursor = [people addEmptyRow];
    cursor.Name  = @"Mary";
    cursor.Age   = 76;
    cursor.Hired = NO;

    // Row 3
    cursor = [people addEmptyRow];
    cursor.Name  = @"Lars";
    cursor.Age   = 22;
    cursor.Hired = YES;

    // Row 4
    cursor = [people addEmptyRow];
    cursor.Name  = @"Phil";
    cursor.Age   = 43;
    cursor.Hired = NO;

    // Row 5
    cursor = [people addEmptyRow];
    cursor.Name  = @"Anni";
    cursor.Age   = 54;
    cursor.Hired = YES;
    // @@EndExample@@

    // @@Example: insert_at_index @@
    cursor = [people insertRowAtIndex:2];
    cursor.Name = @"Frank";
    cursor.Age = 34;
    cursor.Hired = YES;

    // @@EndExample@@

    // @@Example: number_of_rows @@
    size_t cnt1 = [people count];                       // cnt = 6
    BOOL empty = [people isEmpty];                      // empty = NO
    // @@EndExample@@

    // @@Example: accessing_rows @@
    // Getting values directly
    NSString* name = [people cursorAtIndex:5].Name;    // =&gt; 'Anni'
    // Using a cursor
    PeopleTable_Cursor *myRow = [people cursorAtIndex:5];
    int64_t age = myRow.Age;                           // =&gt; 54
    BOOL hired  = myRow.Hired;                         // =&gt; true

    // Setting values
    [[people cursorAtIndex:5] setAge:43];              // Getting younger
    // or with dot-syntax:
    myRow.Age += 1;                                    // Happy birthday!
    // @@EndExample@@

    // @@Example: last_row @@
    NSString *last = [people cursorAtLastIndex].Name;         // =&gt; "Anni"
    // @@EndExample@@

    // @@Example: updating_entire_row @@
    // (TODO: a curser should be used here) [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];
    // @EndExample@@

    // @@Example: deleting_row @@
    [people removeRowAtIndex:2];
    size_t cnt2 = [people count];                      // cnt = 5
    // @@EndExample@@

    // @@Example: iteration @@
    for (size_t i = 0; i < [people count]; ++i) {
        PeopleTable_Cursor *row = [people cursorAtIndex:i];
        NSLog(@"%@ is %lld years old", row.Name, row.Age);
    }
    // @@EndExample@@

    // @@Example: simple_seach @@
    size_t row;
    row = [people.Name find:@"Philip"];                 // (size_t)-1. Not found
    row = [people.Name find:@"Mary"];                     // row = 1
    // @@EndExample@@

    // @@Example: advanced_search @@
    // Create query (current employees between 20 and 30 years old)
    PeopleTable_Query *q = [[[people where].Hired columnIsEqualTo:YES]
                                           .Age   columnIsBetween:20 and_:30];

    // Get number of matching entries
    size_t cnt3 = [q count];                            // =&gt; 2

    // Get the average age (currently only a low-level interface)
    NSNumber *avg = [q.Age average];

    // Execute the query and return a table (view)
    PeopleTable_View *res = [q findAll];
    for (size_t i = 0; i < [res count]; ++i) {
        NSLog(@"%zu: %@ is %lld years old", i,
              [people cursorAtIndex:i].Name,
              [people cursorAtIndex:i].Age);
    }

    // Alternatively with fast emunaration
    for (PeopleTable_Cursor *c in res)
        NSLog(@"%@ is %lld years old", c.Name, c.Age);

    // @@EndExample@@

}


void groupFunc() {

    // @@Example: serialisation @@
    // Create Table in Group
    TightdbGroup *group = [TightdbGroup group];
    PeopleTable *people = [group getTable:@"employees" withClass:[PeopleTable class] error:nil];

    // Add some rows
    PeopleTable_Cursor *cursor;

    // Row 1
    cursor = [people addEmptyRow];
    cursor.Name  = @"John";
    cursor.Age   = 21;
    cursor.Hired = YES;

    // Row 2
    cursor = [people addEmptyRow];
    cursor.Name  = @"Mary";
    cursor.Age   = 21;
    cursor.Hired = NO;

    // Row 3
    cursor = [people addEmptyRow];
    cursor.Name  = @"Lars";
    cursor.Age   = 21;
    cursor.Hired = YES;

    // Row 4
    cursor = [people addEmptyRow];
    cursor.Name  = @"Phil";
    cursor.Age   = 43;
    cursor.Hired = NO;

    // Row 5
    cursor = [people addEmptyRow];
    cursor.Name  = @"Anni";
    cursor.Age   = 54;
    cursor.Hired = YES;

    // Delete any old file by same name
    // IMPORTANT: write will fail if the file exists.
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:@"employees.tightdb" error:nil];

    // Write to disk
    [group writeToFile:@"employees.tightdb" withError:nil];

    // Load a group from disk (and print contents)
    TightdbGroup *fromDisk = [TightdbGroup groupWithFile:@"employees.tightdb" withError:nil];
    PeopleTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleTable class] error:nil];

    NSLog(@"Disktable size: %zu", [diskTable count]);
    for (size_t i = 0; i < [diskTable count]; i++) {
        PeopleTable_Cursor *cursor = [diskTable cursorAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);           // using std. method
    }

    // Write same group to memory buffer
    TightdbBinary *buffer = [group writeToBuffer];

    // Load a group from memory (and print contents)
    TightdbGroup *fromMem = [TightdbGroup groupWithBuffer:buffer withError:nil];
    PeopleTable *memTable = [fromMem getTable:@"employees" withClass:[PeopleTable class] error:nil];

    for (size_t i = 0; i < [memTable count]; i++) {
    PeopleTable_Cursor *cursor = [memTable cursorAtIndex:i];
    NSLog(@"%zu: %@", i, cursor.Name);            // using dot-syntax
}

    // @@EndExample@@


}

void sharedGroupFunc() {

    // @@Example: transaction @@
    TightdbSharedGroup *sharedGroup = [TightdbSharedGroup sharedGroupWithFile:@"people.tightdb"
                                                          withError:nil];

    // Start a write transaction
    [sharedGroup writeWithBlock:^(TightdbGroup *group) {

        // Get a specific table from the group
        PeopleTable *table = [group getTable:  @"employees"
                                    withClass: [PeopleTable class]
                                    error:     nil];

        // Rollback if the table is not empty
        if ([table count] > 0) {
            NSLog(@"Not empty!");
            return NO; // Rollback
        }

        // Otherwise add a row
        [table addName:@"Bill" Age:53 Hired:YES];
        NSLog(@"Row added!");
        return YES; // Commit

    } withError:nil];

    // Start a read transaction
    [sharedGroup readWithBlock:^(TightdbGroup *group) {

        // Get the table
        PeopleTable *table = [group getTable:  @"employees"
                                    withClass: [PeopleTable class]
                                    error:     nil];

        // Interate over all rows in table
        for (PeopleTable_Cursor *curser in table) {
            NSLog(@"Name: %@", [curser Name]);
        }
    }];
    // @@EndExample@@
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    tableFunc();
    groupFunc();
    sharedGroupFunc();
    return YES;
}

@end
