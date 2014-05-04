/* @@Example: ex_objc_tableview_dynamic_intro @@ */
#import <Realm/Realm.h>

void ex_objc_tableview_dynamic_intro()
{
    [[RLMTransactionManager managerForDefaultRealm] writeUsingBlock:^(RLMRealm *realm) {
        /* Creates a new table dynamically. */
        RLMTable *table = [realm createTableWithName:@"Example"];
        
        /* Add some columns dynamically */
        [table addColumnWithName:@"Name"  type:RLMTypeString];
        [table addColumnWithName:@"Age"   type:RLMTypeInt];
        [table addColumnWithName:@"Hired" type:RLMTypeBool];
        
        /* Add people (rows). */
        [table addRow:@[@"Joe", @23, @YES]];
        [table addRow:@[@"Simon", @32, @YES]];
        [table addRow:@[@"Steve",@12, @NO]];
        [table addRow:@[@"Nick", @59, @YES]];
        
        /* Create a (table)view with the rows matching the query */
        RLMView *view = [table allWhere:@"Age >= 30 && Age <= 60 && Hired == YES"];
        
        /* Iterate over the matching rows */
        for (RLMRow *row in view) {
            NSLog(@"With fast enumerator. Name: %@",row[@"Name"]);
        }
        
        /* Take a row at index one in the view. */
        /* Note: the index of this row is different in the underlaying table. */
        
        RLMRow *row = [view rowAtIndex:1];
        if (row != nil)
            NSLog(@"With fixed index. Name: %@",row[@"Name"]);
        
        /* Try to get a row with an out-of-bounds index. */
        RLMRow *row2 = [view rowAtIndex:view.rowCount];
        if (row2 != nil)
            NSLog(@"Should not get here!");
    }];
}
/* @@EndExample@@ */
