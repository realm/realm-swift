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
    // Create a realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // Get/Create a table
    [realm beginWriteTransaction];
    PeopleTable *table = [PeopleTable tableInRealm:realm named:@"employees"];
    if (!table.rowCount) {
        // Add rows
        [table addRow:@{@"Name": @"Mary", @"Age": @76, @"Hired": @NO}];
        [table addRow:@{@"Name": @"Lars", @"Age": @22, @"Hired": @YES}];
        [table addRow:@{@"Name": @"Phil", @"Age": @43, @"Hired": @NO}];
        [table addRow:@{@"Name": @"Anni", @"Age": @54, @"Hired": @YES}];
    }
    [realm commitWriteTransaction];
    
    // Query the table
    RLMView  *view  = [table allWhere:@"Age > 30"];
    
    // Iterate over all rows in view
    for (People *row in view) {
        NSLog(@"Name: %@", row.Name);
    }
}
// @@EndExample@@
