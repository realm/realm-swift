/* @@Example: ex_objc_query_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>



int main()
{
    @autoreleasepool {
        /* TODO: Update example to the cursor. */

        /* Creates a new table dynamically. */

        TightdbTable *table = [[TightdbTable alloc] init];

        size_t const NAME = [table addColumnWithName:@"Name" andType:tightdb_String];
        size_t const AGE = [table addColumnWithName:@"Age" andType:tightdb_Int];
        size_t const HIRED = [table addColumnWithName:@"Hired" andType:tightdb_Bool];

        /* Add some people. */

        /* Add rows and values. */

        TightdbCursor *cursor;

        /* Row 0 */

        cursor = [table addEmptyRow];

        [cursor setInt:23 inColumnWithIndex:AGE];
        [cursor setString:@"Joe" inColumnWithIndex:NAME];
        [cursor setBool:YES inColumnWithIndex:HIRED];

        /* Row 1 */

        cursor = [table addEmptyRow];

        [cursor setInt:32 inColumnWithIndex:AGE];
        [cursor setString:@"Simon" inColumnWithIndex:NAME];
        [cursor setBool:YES inColumnWithIndex:HIRED];

        /* Row 2 */

        cursor = [table addEmptyRow];

        [cursor setInt:12 inColumnWithIndex:AGE];
        [cursor setString:@"Steve" inColumnWithIndex:NAME];
        [cursor setBool:NO inColumnWithIndex:HIRED];

        /* Row 3 */

        cursor = [table addEmptyRow];

        [cursor setInt:59 inColumnWithIndex:AGE];
        [cursor setString:@"Nick" inColumnWithIndex:NAME];
        [cursor setBool:YES inColumnWithIndex:HIRED];

        /* Set up a query to search for employees. */

        TightdbQuery *q =  [[[[table where] intIsGreaterThanOrEqualTo:0 inColumnWithIndex:AGE]
                                            intIsLessThanOrEqualTo:60 inColumnWithIndex:AGE ]
                                          boolIsEqualTo:YES inColumnWithIndex:HIRED];

        /* Execute the query. */

        TightdbView *view = [q findAllRows];

        /* Print the names. */

        for (TightdbCursor *c in view) {

            NSLog(@"name: %@",[c stringInColumnWithIndex:NAME]);

        }




    }
}

/* @@EndExample@@ */
