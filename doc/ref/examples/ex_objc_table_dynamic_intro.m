/* @@Example: ex_objc_table_dynamic_intro @@ */
#import <Tightdb/Tightdb.h>

void ex_objc_table_dynamic_intro()
{
    /* Create a new table dynamically. */
    TDBTable *table = [[TDBTable alloc] init];
    /* First column added will get column index 0 */
    NSUInteger const NAME = [table addColumnWithName:@"Name"
                                                type:TDBStringType];
    /* Second column added will get column index 1 */
    NSUInteger const AGE  = [table addColumnWithName:@"Age"
                                                type:TDBIntType];
    /* Add an empty row and set column values. */
    NSUInteger rowIndex = [table addRow:nil];
    TDBRow *row = [table rowAtIndex:rowIndex];
    row[NAME] = @"Joe";
    row[AGE] = @23;
    
    /* And a row with dictionary style, with properties in any order */
    [table addRow:@{@"Name":@"Simon", @"Age":@32}];
    
    /* Add rows with array style, with properties in order of column definition */
    [table addRow:@[@"Steve", @12]];
    [table addRow:@[@"Nick", @100]];
    
    /* Iterate over all rows in the table */
    for (TDBRow *row in table)
        NSLog(@"Name: %@ Age: %@", row[NAME], row[AGE]);
    
    /* Insert a row*/
    [table insertRow: @[@"Inserted new", @21] atIndex:2];
    
    NSLog(@"--------");
    for (TDBRow *row in table)
        NSLog(@"Name: %@ Age: %@", row[NAME], row[AGE]);
    
    /* Update a few rows and print again. */
    table[2][@"Name"] = @"Now I'm UPDATED";
    
    row = [table lastRow];
    row[NAME] = @"I'm UPDATED";
    
    NSLog(@"--------");
    for (TDBRow *row in table)
        NSLog(@"Name: %@ Age: %@", row[NAME], row[AGE]);
    
    /* Refer to non existing row. */
    TDBRow *row2 = [table rowAtIndex:table.rowCount];
    if (row2 == nil)
        NSLog(@"No row with this index. Indexes start at 0.");
}
/* @@EndExample@@ */
