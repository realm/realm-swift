/* @@Example: ex_objc_realm_intro @@ */
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


void ex_objc_realm_intro()
{
    // Create a realm and initialize by creating table and adding a row    
    RLMRealm *realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
        if (realm.isEmpty) {
            People *table = [realm createTableWithName:@"employees"
                                          asTableClass:[People class]];
            [table addRow:@{@"Name": @"Bill", @"Age": @53, @"Hired": @YES}];
        }
    }];
    
    // Read from the realm
    People *table = [realm tableWithName:@"employees" asTableClass:[People class]];
    for (PeopleRow *row in table) {
        NSLog(@"Name: %@", row.Name);
    }
}
/* @@EndExample@@ */
