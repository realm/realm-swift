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
    // Remove previous datafile
    [[NSFileManager defaultManager] removeItemAtPath:@"contextTest.realm" error:nil];

    // Create datafile with a new table
    RLMContext *context = [RLMContext contextPersistedAtPath:@"contextTest.realm"
                                                       error:nil];

    // Perform a write transaction (with commit to file)
    [context writeUsingBlock:^(RLMTransaction *transaction) {
        People *table = [transaction createTableWithName:@"employees"
                                            asTableClass:[People class]];
        [table addRow:@{@"Name":@"Bill", @"Age":@53, @"Hired":@YES}];
    }];

    // Perform a write transaction (with rollback)
    [context writeUsingBlockWithRollback:^(RLMTransaction *transaction, BOOL *rollback) {
        People *table = [transaction createTableWithName:@"employees"
                                            asTableClass:[People class]];
        if ([table rowCount] == 0) {
            NSLog(@"Roll back!");
            *rollback = YES;
            return;
        }
        [table addName:@"Bill" Age:53 Hired:YES];
        NSLog(@"Commit!");
    }];

    // Perform a read transaction
    [context readUsingBlock:^(RLMTransaction *transaction) {
        People *table = [transaction tableWithName:@"employees"
                                      asTableClass:[People class]];
        for (PeopleRow *row in table) {
            NSLog(@"Name: %@", row.Name);
        }
    }];
}
/* @@EndExample@@ */
