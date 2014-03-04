/* @@Example: ex_objc_table_dynamic_intro @@ */

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>



int main()
{
    @autoreleasepool {

        /* Create a new table dynamically. */

        TightdbTable *table = [[TightdbTable alloc] init];

        size_t const NAME = [table addColumnWithType:tightdb_String andName:@"Name"];
        size_t const AGE = [table addColumnWithType:tightdb_Int andName:@"Age"];

        /* Add rows and values. */

        TightdbCursor *cursor;

        /* Row 0 */

        cursor = [table addEmptyRow];

        [cursor setInt:23 inColumn:AGE];
        [cursor setString:@"Joe" inColumn:NAME];

        /* Row 1 */

        cursor = [table addEmptyRow];

        [cursor setInt:32 inColumn:AGE];
        [cursor setString:@"Simon" inColumn:NAME];

        /* Row 2 */

        cursor = [table addEmptyRow];

        [cursor setInt:12 inColumn:AGE];
        [cursor setString:@"Steve" inColumn:NAME];

        /* Row 3 */

        cursor = [table addEmptyRow];

        [cursor setInt:100 inColumn:AGE];
        [cursor setString:@"Nick" inColumn:NAME];

        /* Print using a cursor. */

        for (TightdbCursor *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);


        /* Insert a row and print. */

        cursor = [table insertRowAtIndex:2];
        [cursor setInt:21 inColumn:AGE];
        [cursor setString:@"Hello I'm INSERTED" inColumn:NAME];


        NSLog(@"--------");

        for (TightdbCursor *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);


        /* Update a few rows and print again. */

        cursor = [table cursorAtIndex:2];
        [cursor setString:@"Now I'm UPDATED" inColumn:NAME];

        cursor = [table cursorAtLastIndex];
        [cursor setString:@"I'm UPDATED" inColumn:NAME];

        NSLog(@"--------");

        for (TightdbCursor *ite in table)
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);

        /* Index not existing. */

        TightdbCursor *c2 = [table cursorAtIndex:[table count]];
        if (c2 != nil)
            NSLog(@"Should not get here.");
    }
}

/* @@EndExample@@ */
