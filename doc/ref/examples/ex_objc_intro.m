// @@Example: ex_objc_intro @@
#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import "people.h"

/*
 The classes People, PeopleQuery, PeopleView, and PeopleRow are declared
 (interfaces are generated) in people.h as

 REALM_TABLE_DEF_3(People,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

 and in people.m you must have

 REALM_TABLE_IMPL_3(People,
                      Name, String,
                      Age,  Int,
                      Hired, Bool)

 in order to generate the implementation of the classes.
*/

// Use it in a function
void ex_objc_intro() {
    // Remove old data file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:@"people.tightdb" error:&error];

    RLMContext *context = [RLMContext contextWithDefaultPersistence];

    // Start a write transaction
    [context writeUsingBlock:^(RLMTransaction *transaction) {
        // Get a specific table from the group
        People *table = [transaction createTableWithName:@"employees"
                                            asTableClass:[People class]];

        // Add rows
        [table addRow:@{@"Name": @"Mary", @"Age": @76, @"Hired": @NO}];
        [table addRow:@{@"Name": @"Lars", @"Age": @22, @"Hired": @YES}];
        [table addRow:@{@"Name": @"Phil", @"Age": @43, @"Hired": @NO}];
        [table addRow:@{@"Name": @"Anni", @"Age": @54, @"Hired": @YES}];

        return YES; // Commit!
    } error:nil];

    // Start a read transaction
    [context readUsingBlock:^(RLMTransaction *transaction) {
        // Get the table
        People *table = [transaction tableWithName:@"employees"
                                      asTableClass:[People class]];

        // Query the table
        PeopleQuery *query = [[table where].Age columnIsGreaterThan:30];
        PeopleView  *view  = [query findAll];

        // Iterate over all rows in view
        for (PeopleRow *row in view) {
            NSLog(@"Name: %@", row.Name);
        }
    }];
}
// @@EndExample@@
