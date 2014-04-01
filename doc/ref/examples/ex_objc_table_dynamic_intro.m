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

        [row setString:@"Joe" inColumnWithIndex:NAME];
        [row setInt:23 inColumnWithIndex:AGE];

        /* And a few more rows - in a simpler manner */
        [table addRow:@[@"Simon", @32]];
        [table addRow:@[@"Steve", @12]];
        [table addRow:@[@"Nick", @100]];

        /* Print using a cursor. */
        for (TDBRow *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite stringInColumnWithIndex:NAME], [ite intInColumnWithIndex:AGE]);
        
        /* Insert a row and print. */
        [table insertRow: nil atIndex:2];
        row = [table rowAtIndex:2];
        [row setInt:21 inColumnWithIndex:AGE];
        [row setString:@"Hello I'm INSERTED" inColumnWithIndex:NAME];

        NSLog(@"--------");

        for (TDBRow *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite stringInColumnWithIndex:NAME], [ite intInColumnWithIndex:AGE]);


        /* Update a few rows and print again. */
        table[2][@"Name"] = @"Now I'm UPDATED";

        row = [table lastRow];
        [row setString:@"I'm UPDATED" inColumnWithIndex:NAME];

        NSLog(@"--------");

        for (TDBRow *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite stringInColumnWithIndex:NAME], [ite intInColumnWithIndex:AGE]);

        /* Index not existing. */
        TDBRow *c2 = [table rowAtIndex:table.rowCount];
        if (c2 != nil)
            NSLog(@"Should not get here.");
    }
}

/* @@EndExample@@ */
