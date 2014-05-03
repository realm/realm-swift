/* @@Example: ex_objc_table_dynamic_intro @@ */
#import <Realm/Realm.h>

void ex_objc_table_dynamic_intro()
{
    [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
        // Create a new table dynamically
        RLMTable *table = [realm createTableWithName:@"Example"];
        
        // Add two columns
        [table addColumnWithName:@"Name" type:RLMTypeString];
        [table addColumnWithName:@"Age"  type:RLMTypeInt];
        
        // Add a row with dictionary style, with properties in any order
        [table addRow:@{@"Name":@"Simon", @"Age":@32}];
        
        // Add rows with array style, with properties in order of column definition
        [table addRow:@[@"Steve", @12]];
        [table addRow:@[@"Nick", @100]];
        
        // Iterate over all rows in the table
        for (RLMRow *row in table)
            NSLog(@"Name: %@ Age: %@", row[@"Name"], row[@"Age"]);
        
        // Insert a row
        [table insertRow:@[@"Jill", @21] atIndex:2];
        
        // Print table
        for (RLMRow *row in table)
            NSLog(@"Name: %@ Age: %@", row[@"Name"], row[@"Age"]);
        
        // Update two rows
        table[0][@"Name"] = @"John";
        
        RLMRow *row = [table lastRow];
        row[@"Name"] = @"Mary";
        
        //  And print again
        for (RLMRow *row in table)
            NSLog(@"Name: %@ Age: %@", row[@"Name"], row[@"Age"]);
        
        // Refer to non existing row
        RLMRow *row2 = [table rowAtIndex:table.rowCount];
        if (row2 == nil)
            NSLog(@"No row with this index. Indexes start at 0.");
    }];
}
/* @@EndExample@@ */

void ex_objc_table_dyn_table_sizes()
{
<<<<<<< HEAD
    [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
        // @@Example: ex_objc_table_dyn_table_size @@
        // Create a new table dynamically
        RLMTable *table = [realm createTableWithName:@"Example"];
        
        // Add two columns
        [table addColumnWithName:@"Name" type:RLMTypeString];
        [table addColumnWithName:@"Age"  type:RLMTypeInt];
        
        // Add three rows
        [table addRow:@[@"Steve", @12]];
        [table addRow:@[@"Nick", @100]];
        [table addRow:@[@"Mary",  @27]];
        
        // Print the number of rows and columns
        NSLog(@"Number of rows: %lu",    (unsigned long)table.rowCount);
        NSLog(@"Number of columns: %lu", (unsigned long)table.columnCount);
        // @@EndExample@@
    }];
=======
    // @@Example: ex_objc_table_dyn_table_size @@
    // Create a new table dynamically
    RLMTable *table = [[RLMTable alloc] init];

    // Add two columns
    [table addColumnWithName:@"Name" type:RLMTypeString];
    [table addColumnWithName:@"Age"  type:RLMTypeInt];

    // Add three rows
    [table addRow:@[@"Steve", @12]];
    [table addRow:@[@"Nick", @100]];
    [table addRow:@[@"Mary",  @27]];

    // Print the number of rows and columns
    NSLog(@"Number of rows: %lu",    (unsigned long)table.rowCount);
    NSLog(@"Number of columns: %lu", (unsigned long)table.columnCount);
    // @@EndExample@@
}

void ex_objc_table_dyn_table_init_with_columns()
{
//    // @@Example: ex_objc_table_dyn_table_init_with_columns @@
//    // Create a new table dynamically
//    RLMTable *table = [[RLMTable alloc] initWithColumns:@[@"Name", @"string",
//                                                           @"Age", @"int"]];
//
//    // Add three rows
//    [table addRow:@[@"Steve", @12]];
//    [table addRow:@[@"Nick", @100]];
//    [table addRow:@[@"Mary",  @27]];
//
//    // Print the number of rows and columns
//    NSLog(@"Number of rows: %lu",    (unsigned long)table.rowCount);
//    NSLog(@"Number of columns: %lu", (unsigned long)table.columnCount);
//    // @@EndExample@@
>>>>>>> 0c5befb1d95840f3a70236a56bf1fa62ddce2eb3
}
