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

    // Add a row
    PeopleTable_Cursor *cursor;
    cursor = [people addEmptyRow];
    cursor.Name  = @"John";
    cursor.Age   = 21;
    cursor.Hired = YES;

    // Add more rows
    [people appendRow:@{@"Name": @"Mary", @"Age": @76, @"Hired": @NO}];
    [people appendRow:@{@"Name": @"Lars", @"Age": @22, @"Hired": @YES}];
    [people appendRow:@{@"Name": @"Phil", @"Age": @43, @"Hired": @NO}];
    [people appendRow:@{@"Name": @"Anni", @"Age": @54, @"Hired": @YES}];

    // @@EndExample@@

    // @@Example: insert_at_index @@
    [people insertRow:@{@"Name": @"Frank", @"Age": @34, @"Hired": @YES} atRowIndex:2];

    // @@EndExample@@

    // @@Example: number_of_rows @@
    size_t cnt1 = people.rowCount;                     // cnt = 6
    BOOL empty  = people.rowCount;                     // empty = NO
    // @@EndExample@@

    // @@Example: accessing_rows @@
    // Getting values directly
    NSString* name = people[5].Name;                   // =&gt; 'Anni'

    // Using a cursor
    PeopleTable_Cursor *myRow = people[5];
    int64_t age = myRow.Age;                           // =&gt; 54
    BOOL hired  = myRow.Hired;                         // =&gt; true

    // Setting values
    people[5].Age = 43;                                // Getting younger
    myRow.Age += 1;                                    // Happy birthday!
    // @@EndExample@@

    // @@Example: last_row @@
    NSString *last = [people cursorAtLastIndex].Name;  // =&gt; "Anni"
    // @@EndExample@@

    // @@Example: updating_entire_row @@
    people[4] = @{@"Name": @"Eric", @"Age": @50, @"Hired": @YES};
    // @@EndExample@@

    // @@Example: deleting_row @@
    [people removeRowAtIndex:2];
    size_t cnt2 = [people rowCount];                      // cnt = 5
    // @@EndExample@@

    // @@Example: iteration @@
    for (size_t i = 0; i < people.rowCount; ++i) {
        PeopleTable_Cursor *row = people[i];
        NSLog(@"%@ is %lld years old", row.Name, row.Age);
    }
    // @@EndExample@@

    // @@Example: simple_seach @@
    size_t row_id;
    row_id = [people.Name find:@"Philip"];                 // (size_t)-1. Not found
    row_id = [people.Name find:@"Mary"];                   // row = 1
    // @@EndExample@@

    // @@Example: advanced_search @@
    // Create query (current employees between 20 and 30 years old)
    PeopleTable_Query *q = [[[people where].Hired columnIsEqualTo:YES]
                                           .Age   columnIsBetween:20 and_:30];

    // Get number of matching entries
    size_t cnt3 = [q countRows];                            // =&gt; 2

    // Get the average age (currently only a low-level interface)
    double avg = [q.Age avg];

    // Execute the query and return a table (view)
    PeopleTable_View *res = [q findAll];
    for (size_t i = 0; i < res.rowCount; ++i) {
        NSLog(@"%zu: %@ is %lld years old", i, people[i].Name, people[i].Age);
    }

    // Alternatively with fast emunaration
    for (PeopleTable_Cursor *c in res)
        NSLog(@"%@ is %lld years old", c.Name, c.Age);

    // @@EndExample@@

}

void sharedGroupFunc() {

    // @@Example: transaction @@
    TDBSharedGroup *sharedGroup = [TDBSharedGroup sharedGroupWithFile:@"people.tightdb"
                                                            withError:nil];

    // Start a write transaction
    [sharedGroup writeWithBlock:^(TDBGroup *group) {
        // Get a specific table from the group
        PeopleTable *table = [group getOrCreateTableWithName:@"employees"
                                                asTableClass:[PeopleTable class]
                                                       error:nil];

        // Add a row
        [table addName:@"Bill" Age:53 Hired:YES];
        NSLog(@"Row added!");
        return YES; // Commit (NO would rollback)
    } withError:nil];

    // Start a read transaction
    [sharedGroup readWithBlock:^(TDBGroup *group) {
        // Get the table
        PeopleTable *table = [group getOrCreateTableWithName:@"employees"
                                                asTableClass:[PeopleTable class]
                                                       error:nil];

        // Interate over all rows in table
        for (PeopleTable_Cursor *row in table) {
            NSLog(@"Name: %@", row.Name);
        }
    }];
    // @@EndExample@@
}

void groupFunc() {

    // @@Example: serialisation @@
    TDBSharedGroup *sharedGroup = [TDBSharedGroup sharedGroupWithFile:@"people.tightdb"
                                                              withError:nil];

    // Within a single read transaction we can write a copy of the entire db to a new file.
    // This is usefull both for backups and for transfering datasets to other machines.
    [sharedGroup readWithBlock:^(TDBGroup *group) {
        // Write entire db to disk (in a new file)
        [group writeToFile:@"people_backup.tightdb" withError:nil];
    }];
    // @@EndExample@@
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /* We want to clear out old state before running tutorial */
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:@"people.tightdb" error:nil];
    [manager removeItemAtPath:@"people_backup.tightdb" error:nil];

    tableFunc();
    sharedGroupFunc();
    groupFunc();
    return YES;
}

@end
