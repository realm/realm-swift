/* @@Example: ex_objc_table_dynamic_intro @@ */
#import <Tightdb/Tightdb.h>

void ex_objc_table_dynamic_intro()
{
    // Create a new table dynamically
    TDBTable *table = [[TDBTable alloc] init];

    // Add two columns
    [table addColumnWithName:@"Name" type:TDBStringType];
    [table addColumnWithName:@"Age"  type:TDBIntType];

    // Add a row with dictionary style, with properties in any order
    [table addRow:@{@"Name":@"Simon", @"Age":@32}];

    // Add rows with array style, with properties in order of column definition
    [table addRow:@[@"Steve", @12]];
    [table addRow:@[@"Nick", @100]];

    // Iterate over all rows in the table
    for (TDBRow *row in table)
        NSLog(@"Name: %@ Age: %@", row[@"Name"], row[@"Age"]);

    // Insert a row
    [table insertRow:@[@"Jill", @21] atIndex:2];

    // Print table
    for (TDBRow *row in table)
        NSLog(@"Name: %@ Age: %@", row[@"Name"], row[@"Age"]);

    // Update two rows
    table[0][@"Name"] = @"John";

    TDBRow *row = [table lastRow];
    row[@"Name"] = @"Mary";

    //  And print again
    for (TDBRow *row in table)
        NSLog(@"Name: %@ Age: %@", row[@"Name"], row[@"Age"]);

    // Refer to non existing row
    TDBRow *row2 = [table rowAtIndex:table.rowCount];
    if (row2 == nil)
        NSLog(@"No row with this index. Indexes start at 0.");
}
/* @@EndExample@@ */

void ex_objc_table_dyn_table_sizes()
{
    // @@Example: ex_objc_table_dyn_table_size @@
    // Create a new table dynamically
    TDBTable *table = [[TDBTable alloc] init];

    // Add two columns
    [table addColumnWithName:@"Name" type:TDBStringType];
    [table addColumnWithName:@"Age"  type:TDBIntType];

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
    // @@Example: ex_objc_table_dyn_table_init_with_columns @@
    // Create a new table dynamically
    TDBTable *table = [[TDBTable alloc] initWithColumns:@[@"Name", @"string",
                                                           @"Age", @"int"]];

    // Add three rows
    [table addRow:@[@"Steve", @12]];
    [table addRow:@[@"Nick", @100]];
    [table addRow:@[@"Mary",  @27]];

    // Print the number of rows and columns
    NSLog(@"Number of rows: %lu",    (unsigned long)table.rowCount);
    NSLog(@"Number of columns: %lu", (unsigned long)table.columnCount);
    // @@EndExample@@
}
