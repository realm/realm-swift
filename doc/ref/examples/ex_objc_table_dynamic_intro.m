/* @@Example: ex_objc_table_dynamic_intro @@ */

#import <tightdb/objc/tightdb.h>



int main()
{
    @autoreleasepool {

        /* Create a new table dynamically. */

        TDBTable *table = [[TDBTable alloc] init];

        NSUInteger const NAME = [table addColumnWithName:@"Name" andType:TDBStringType];
        NSUInteger const AGE = [table addColumnWithName:@"Age" andType:TDBIntType];

        /* Add rows and values. */

        TDBRow *row;

        /* Row 0 */

        row = [table addEmptyRow];

        [row setInt:23 inColumnWithIndex:AGE];
        [row setString:@"Joe" inColumnWithIndex:NAME];

        /* Row 1 */

        row = [table addEmptyRow];

        [row setInt:32 inColumnWithIndex:AGE];
        [row setString:@"Simon" inColumnWithIndex:NAME];

        /* Row 2 */

        row = [table addEmptyRow];

        [row setInt:12 inColumnWithIndex:AGE];
        [row setString:@"Steve" inColumnWithIndex:NAME];

        /* Row 3 */

        row = [table addEmptyRow];

        [row setInt:100 inColumnWithIndex:AGE];
        [row setString:@"Nick" inColumnWithIndex:NAME];

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

        row = [table rowAtIndex:2];
        [row setString:@"Now I'm UPDATED" inColumnWithIndex:NAME];

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
