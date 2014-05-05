/* @@Example: ex_objc_sharedgroup_intro @@ */
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


void ex_objc_write_transaction_intro()
{

    // Remove previous datafile
    [[NSFileManager defaultManager] removeItemAtPath:@"transactionManagerTest.realm" error:nil];

    // Create datafile with a new table
    RLMRealm *realm = [RLMRealm realmWithPath:@"transactionManagerTest.realm"];
    
    // Perform a write transaction (with commit to file)
    [realm beginWriteTransaction];
    PeopleTable *table = [realm createTableWithName:@"employees" asTableClass:[PeopleTable class]];
    [table addRow:@{@"Name":@"Bill", @"Age":@53, @"Hired":@YES}];
    [realm commitWriteTransaction];
    
    // Perform a write transaction (with rollback)
    [realm beginWriteTransaction];
    [table addRow:@[@"Mary", @21, @NO]];
    [realm abandonWriteTransaction];

    // Perform a read transaction
    for (People *row in table) {
        NSLog(@"Name: %@", row.Name);
    }
}
/* @@EndExample@@ */
