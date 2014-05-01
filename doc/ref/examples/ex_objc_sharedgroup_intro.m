/* @@Example: ex_objc_sharedgroup_intro @@ */
#import <Realm/Realm.h>

// Simple person data object
@interface Person : RLMRow

@property NSString * name;
@property int age;
@property BOOL hired;

@end

void ex_objc_context_intro()
{
    // Remove previous datafile
    [[NSFileManager defaultManager] removeItemAtPath:@"contextTest.realm" error:nil];

    // Create datafile with a new table
    RLMContext *context = [RLMContext contextPersistedAtPath:@"contextTest.realm"
                                                       error:nil];
    // Perform a write transaction (with commit to file)
    [context writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm createTableWithName:@"employees"
                                         objectClass:Person.class];
        [table addRow:@{@"name":@"Bill", @"age":@53, @"hired":@YES}];
    }];

    // Perform a write transaction (with rollback)
    [context writeUsingBlockWithRollback:^(RLMRealm *realm, BOOL *rollback) {
        RLMTable *table = [realm createTableWithName:@"employees"
                                      objectClass:Person.class];
        if ([table rowCount] == 0) {
            NSLog(@"Roll back!");
            *rollback = YES;
            return;
        }
        [table addRow:@[@"Mary", @76, @NO]];
    }];

    // Perform a read transaction
    [context readUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:@"employees"
                                   objectClass:Person.class];
        for (Person *row in table) {
            NSLog(@"Name: %@", row.name);
        }
    }];
}
/* @@EndExample@@ */
