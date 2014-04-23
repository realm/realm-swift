#import "AppDelegate.h"
#import <Realm/Realm.h>


// @@Example: create_table @@
// Define table

REALM_TABLE_3(PeopleTable,
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
    [people addRow:@[@"John", @21, @YES]];

    // Add more rows
    [people addRow:@{@"Name": @"Mary", @"Age": @76, @"Hired": @NO}];
    [people addRow:@{@"Name": @"Lars", @"Age": @22, @"Hired": @YES}];
    [people addRow:@{@"Name": @"Phil", @"Age": @43, @"Hired": @NO}];
    [people addRow:@{@"Name": @"Anni", @"Age": @54, @"Hired": @YES}];
    // @@EndExample@@

    // @@Example: insert_at_index @@
    [people insertRow:@{@"Name": @"Frank", @"Age": @34, @"Hired": @YES} atIndex:2];
    // @@EndExample@@

    // @@Example: number_of_rows @@
    NSUInteger cnt1 = people.rowCount;                 // =&gt; 6
    NSLog(@"RowCount: %i", cnt1);
    BOOL empty = people.rowCount == 0;                 // =&gt; NO
    NSLog(@"Table is empty? %d", empty);
    // @@EndExample@@

    // @@Example: accessing_rows @@
    // Getting values directly
    NSString* name = people[5].Name;                   // =&gt; 'Anni'
    NSLog(@"Name: %@", name);

    // Using a cursor
    PeopleTableRow *myRow = people[5];
    long long age = myRow.Age;                         // =&gt; 54
    NSLog(@"Age: %lli", age);
    BOOL hired  = myRow.Hired;                         // =&gt; YES
    NSLog(@"Hired? %d", hired);

    // Setting values
    people[5].Age = 43;                                // Getting younger
    myRow.Age += 1;                                    // Happy birthday!
    // @@EndExample@@

    // @@Example: last_row @@
    NSString *last = [people rowAtLastIndex].Name;     // =&gt; "Anni"
    NSLog(@"Last name: %@", last);
    // @@EndExample@@

    // @@Example: updating_entire_row @@
    people[4] = @{@"Name": @"Eric", @"Age": @50, @"Hired": @YES};
    // @@EndExample@@

    // @@Example: deleting_row @@
    [people removeRowAtIndex:2];
    NSUInteger cnt2 = people.rowCount;                  // =&gt; 5
    NSLog(@"RowCount: %i", cnt2);
    // @@EndExample@@

    // @@Example: iteration @@
    for (PeopleTableRow* row in people) {
        NSLog(@"%@ is %lld years old", row.Name, row.Age);
    }
    // @@EndExample@@

    // @@Example: simple_seach @@
    NSUInteger rowIndex;
    rowIndex = [people.Name find:@"Philip"];              // =&gt; NSNotFound
    rowIndex = [people.Name find:@"Mary"];                // =&gt; 1
    // @@EndExample@@

    // @@Example: advanced_search @@
    // Create query (current employees between 20 and 30 years old)
    
    RLMView* view = [people where:@"Age > 20 && Age < 35 && Hired == YES"];

    // Get number of matching entries
    NSUInteger cnt3 = [view rowCount];                 // =&gt; 2
    NSLog(@"RowCount: %i", cnt3);

    // fast emunaration on view
    for (RLMRow* row in view)
        NSLog(@"%@ is %@ years old", row[@"Name"], row[@"Age"]);
    // @@EndExample@@

}

void sharedGroupFunc() {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:@"people.tightdb" error:&error];

    // @@Example: transaction @@
    RLMContext *context = [RLMContext contextPersistedAtPath:@"people.tightdb"
                                                            error:nil];

    // Start a write transaction
    [context writeUsingBlock:^(RLMTransaction *transaction) {
        // Get a specific table from the group
        PeopleTable *table = [transaction createTableWithName:@"employees"
                                                asTableClass:[PeopleTable class]];

        // Add a row
        [table addRow:@{@"Name": @"Bill", @"Age":@53, @"Hired":@YES}];
        NSLog(@"Row added!");
        return YES; // Commit (NO would rollback)
    } error:nil];

    // Start a read transaction
    [context readUsingBlock:^(RLMTransaction *transaction) {
        // Get the table
        PeopleTable *table = [transaction tableWithName:@"employees"
                                                asTableClass:[PeopleTable class]];

        // Interate over all rows in table
        for (PeopleTableRow *row in table) {
            NSLog(@"Name: %@", row.Name);
        }
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
    return YES;
}

@end
