/* @@Example: ex_objc_table_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>

void ex_objc_table_dynamic_intro()
{
    @autoreleasepool {

        /* Create a new table dynamically. */
        TDBTable *table = [[TDBTable alloc] init];

        NSUInteger const NAME = [table addColumnWithName:@"Name" type:TDBStringType];
        NSUInteger const AGE = [table addColumnWithName:@"Age" type:TDBIntType];

        /* Add a row with values. */
        NSUInteger rowIndex = [table addRow:nil];
        TDBRow *row = [table rowAtIndex:rowIndex];

        row[NAME] = @"Joe";
        row[AGE] = @23;

        /* And a few more rows - in a simpler manner */
        [table addRow:@[@"Simon", @32]];
        [table addRow:@[@"Steve", @12]];
        [table addRow:@[@"Nick", @100]];

        /* Print using a cursor. */
        for (TDBRow *ite in table)
            NSLog(@"Name: %@ Age: %@", ite[NAME], ite[AGE]);
        
        /* Insert a row and print. */
        [table insertRow: nil atIndex:2];
        row = [table rowAtIndex:2];
        row[AGE] = @21;
        row[NAME] = @"Hello I'm INSERTED";

        NSLog(@"--------");

        for (TDBRow *ite in table)
            NSLog(@"Name: %@ Age: %@", ite[NAME], ite[AGE]);


        /* Update a few rows and print again. */
        table[2][@"Name"] = @"Now I'm UPDATED";

        row = [table lastRow];
        row[NAME] = @"I'm UPDATED";

        NSLog(@"--------");

        for (TDBRow *ite in table)
            NSLog(@"Name: %@ Age: %@", ite[NAME], ite[AGE]);

        /* Index not existing. */
        TDBRow *c2 = [table rowAtIndex:table.rowCount];
        if (c2 != nil)
            NSLog(@"Should not get here.");
    }
}

/* @@EndExample@@ */
