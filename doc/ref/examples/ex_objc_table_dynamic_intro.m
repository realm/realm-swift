/* @@Example: ex_objc_table_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>



int main()
{
    @autoreleasepool {

        /* Create a new table dynamically. */

        TightdbTable *table = [[TightdbTable alloc] init];

        size_t const NAME = [table addColumnWithName:@"Name" andType:tightdb_String];
        size_t const AGE = [table addColumnWithName:@"Age" andType:tightdb_Int];

        /* Add rows and values. */

        TightdbCursor *cursor;

        /* Row 0 */

        cursor = [table addEmptyRow];

        [cursor setInt:23 inColumnWithIndex:AGE];
        [cursor setString:@"Joe" inColumnWithIndex:NAME];

        /* Row 1 */

        cursor = [table addEmptyRow];

        [cursor setInt:32 inColumnWithIndex:AGE];
        [cursor setString:@"Simon" inColumnWithIndex:NAME];

        /* Row 2 */

        cursor = [table addEmptyRow];

        [cursor setInt:12 inColumnWithIndex:AGE];
        [cursor setString:@"Steve" inColumnWithIndex:NAME];

        /* Row 3 */

        cursor = [table addEmptyRow];

        [cursor setInt:100 inColumnWithIndex:AGE];
        [cursor setString:@"Nick" inColumnWithIndex:NAME];

        /* Print using a cursor. */

        for (TightdbCursor *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite stringInColumnWithIndex:NAME], [ite intInColumnWithIndex:AGE]);


        /* Insert a row and print. */

        cursor = [table insertEmptyRowAtIndex:2];
        [cursor setInt:21 inColumnWithIndex:AGE];
        [cursor setString:@"Hello I'm INSERTED" inColumnWithIndex:NAME];


        NSLog(@"--------");

        for (TightdbCursor *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite stringInColumnWithIndex:NAME], [ite intInColumnWithIndex:AGE]);


        /* Update a few rows and print again. */

        cursor = [table rowAtIndex:2];
        [cursor setString:@"Now I'm UPDATED" inColumnWithIndex:NAME];

        cursor = [table lastRow];
        [cursor setString:@"I'm UPDATED" inColumnWithIndex:NAME];

        NSLog(@"--------");

        for (TightdbCursor *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite stringInColumnWithIndex:NAME], [ite intInColumnWithIndex:AGE]);

        /* Index not existing. */

        TightdbCursor *c2 = [table rowAtIndex:table.rowCount];
        if (c2 != nil)
            NSLog(@"Should not get here.");
    }
}

/* @@EndExample@@ */
