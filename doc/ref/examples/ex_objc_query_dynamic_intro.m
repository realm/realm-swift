/* @@Example: ex_objc_query_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>



int main()
{
    @autoreleasepool {
        /* TODO: Update example to the cursor. */

        /* Creates a new table dynamically. */

        TDBTable *table = [[TDBTable alloc] init];

        NSUInteger const NAME = [table addColumnWithName:@"Name" andType:TDBStringType];
        NSUInteger const AGE = [table addColumnWithName:@"Age" andType:TDBIntType];
        NSUInteger const HIRED = [table addColumnWithName:@"Hired" andType:TDBBoolType];

        /* Add some people. */

        /* Add rows and values. */

        TDBRow *row;

        /* Row 0 */

        row = [table addEmptyRow];

        [row setInt:23 inColumnWithIndex:AGE];
        [row setString:@"Joe" inColumnWithIndex:NAME];
        [row setBool:YES inColumnWithIndex:HIRED];

        /* Row 1 */

        row = [table addEmptyRow];

        [row setInt:32 inColumnWithIndex:AGE];
        [row setString:@"Simon" inColumnWithIndex:NAME];
        [row setBool:YES inColumnWithIndex:HIRED];

        /* Row 2 */

        row = [table addEmptyRow];

        [row setInt:12 inColumnWithIndex:AGE];
        [row setString:@"Steve" inColumnWithIndex:NAME];
        [row setBool:NO inColumnWithIndex:HIRED];

        /* Row 3 */

        row = [table addEmptyRow];

        [row setInt:59 inColumnWithIndex:AGE];
        [row setString:@"Nick" inColumnWithIndex:NAME];
        [row setBool:YES inColumnWithIndex:HIRED];

        /* Set up a query to search for employees. */

        TDBQuery *q =  [[[[table where] intIsGreaterThanOrEqualTo:0 inColumnWithIndex:AGE]
                                            intIsLessThanOrEqualTo:60 inColumnWithIndex:AGE ]
                                          boolIsEqualTo:YES inColumnWithIndex:HIRED];

        /* Execute the query. */

        TDBView *view = [q findAllRows];

        /* Print the names. */

        for (TDBRow *c in view) {

            NSLog(@"name: %@",[c stringInColumnWithIndex:NAME]);

        }




    }
}

/* @@EndExample@@ */
