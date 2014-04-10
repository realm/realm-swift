// @@Example: ex_objc_intro @@
#import <Foundation/Foundation.h>
#import <Tightdb/Tightdb.h>

// Define table
TIGHTDB_TABLE_3(Person,
                Name, String,
                Age,  Int,
                Hired, Bool);

// Use it in a function
void ex_objc_intro() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:@"people.tightdb" error:&error];

    TDBContext *context = [TDBContext contextWithPersistenceToFile:@"people.tightdb"
                                                             error:nil];

    // Start a write transaction
    [context writeUsingBlock:^(TDBTransaction *transaction) {
        // Get a specific table from the group
        Person *table = [transaction createTableWithName:@"employees"
                                            asTableClass:[Person class]];

        // Add rows
        [table addRow:@{@"Name": @"Mary", @"Age": @76, @"Hired": @NO}];
        [table addRow:@{@"Name": @"Lars", @"Age": @22, @"Hired": @YES}];
        [table addRow:@{@"Name": @"Phil", @"Age": @43, @"Hired": @NO}];
        [table addRow:@{@"Name": @"Anni", @"Age": @54, @"Hired": @YES}];

        return YES; // Commit!
    } error:nil];

    // Start a read transaction
    [context readUsingBlock:^(TDBTransaction *transaction) {
        // Get the table
        Person *table = [transaction tableWithName:@"employees"
                                      asTableClass:[Person class]];

        // Query the table
        PersonQuery *query = [[table where].Age columnIsGreaterThan:30];
        PersonView  *view  = [query findAll];

        // Iterate over all rows in view
        for (PersonRow *row in view) {
            NSLog(@"Name: %@", row.Name);
        }
    }];
}
// @@EndExample@@