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


void ex_objc_context_intro()
{
    // Remove any previous file
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:[RLMContext defaultPath] error:nil];

    // Create datafile with a new table
    RLMContext *context = [RLMContext contextWithDefaultPersistence];

    // Perform a write transaction (with commit to file)
    NSError *error = nil;
    BOOL success;
    success = [context writeUsingBlock:^(RLMRealm *realm) {
        People *table = [realm createTableWithName:@"employees"
                                      asTableClass:[People class]];
        [table addRow:@{@"Name":@"Bill", @"Age":@53, @"Hired":@YES}];

        return YES; // Commit
    } error:&error];
    if (!success) {
        NSLog(@"write-transaction failed: %@", [error description]);
    }

    // Perform a write transaction (with rollback)
    success = [context writeUsingBlock:^(RLMRealm *realm) {
        People *table = [realm createTableWithName:@"contractors"
                                      asTableClass:[People class]];
        if ([table rowCount] == 0) {
            NSLog(@"Roll back!");
            return NO;
        }
        [table addName:@"Bill" Age:53 Hired:YES];
        NSLog(@"Commit!");
        return YES;
    } error:&error];
    if (!success)
        NSLog(@"Transaction Rolled back : %@", [error description]);

    // Perform a read transaction
    [context readUsingBlock:^(RLMRealm *realm) {
        People *table = [realm tableWithName:@"employees"
                                asTableClass:[People class]];
        for (PeopleRow *row in table) {
            NSLog(@"Name: %@", row.Name);
        }
    }];
}
/* @@EndExample@@ */
