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
    [people appendRow:@[@"Mary", @76, @NO]];
    [people appendRow:@[@"Lars", @22, @YES]];
    [people appendRow:@[@"Phil", @43, @NO]];
    [people appendRow:@[@"Anni", @54, @YES]];
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
    NSString* name = people[5].Name;                   // =&gt; 'Anni'
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
    // Coming soon!
    // [people setRowAtIndex:4 to:@[@"Eric", @50, @YES]];
    // @@EndExample@@

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

void groupFunc() {

    // @@Example: serialisation @@
    TightdbSharedGroup *sharedGroup = [TightdbSharedGroup sharedGroupWithFile:@"people.tightdb"
                                                              withError:nil];

    // Within a single read transaction we can write a copy of the entire db to a new file.
    // This is usefull both for backups and for transfering datasets to other machines.
    [sharedGroup readWithBlock:^(TightdbGroup *group) {
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
