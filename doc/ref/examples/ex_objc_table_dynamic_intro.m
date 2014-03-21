/* @@Example: ex_objc_table_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>

void ex_objc_table_dynamic_intro()
{
    @autoreleasepool {

        /* Create a new table dynamically. */
        TDBTable *table = [[TDBTable alloc] init];

        NSUInteger const NAME = [table addColumnWithName:@"Name" andType:TDBStringType];
        NSUInteger const AGE = [table addColumnWithName:@"Age" andType:TDBIntType];

        /* Add a row with values. */
        TDBRow *row;
        row = [table addEmptyRow];

        [row setInt:23 inColumnWithIndex:AGE];
        [row setString:@"Joe" inColumnWithIndex:NAME];

        /* And a few more rows - in a simpler manner */
        [table addRow:@[@32, @"Simon"]];
        [table addRow:@[@12, @"Steve"]];
        [table addRow:@[@100, @"Nick"]];

        /* Print using a cursor. */
        for (TDBRow *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite stringInColumnWithIndex:NAME], [ite intInColumnWithIndex:AGE]);
        
        /* Insert a row and print. */
        row = [table insertEmptyRowAtIndex:2];
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
