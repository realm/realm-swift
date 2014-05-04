/* @@Example: ex_objc_query_dynamic_intro @@ */
#import <Realm/Realm.h>

void ex_objc_query_dynamic_intro()
{
    [[RLMTransactionManager managerForDefaultRealm] writeUsingBlock:^(RLMRealm *realm) {
        /* Creates a new table dynamically. */
        RLMTable *table = [realm createTableWithName:@"table"];
        [table addColumnWithName:@"Name" type:RLMTypeString];
        [table addColumnWithName:@"Age" type:RLMTypeInt];
        [table addColumnWithName:@"Hired" type:RLMTypeBool];
        
        /* Add some people. */
        [table addRow:@[@"Joe", @23, @YES]];
        [table addRow:@[@"Simon", @32, @YES]];
        [table addRow:@[@"Steve", @12, @NO]];
        [table addRow:@[@"Nick", @59, @YES]];
        
        /* Set up a view for employees. */
        RLMView *view = [table allWhere:@"Age >= 0 && Age <= 60 && Hired == YES"];
        
        /* Iterate over query result */
        for (RLMRow *row in view) {
            NSLog(@"name: %@", row[@"Name"]);
        }
    }];
}
/* @@EndExample@@ */
