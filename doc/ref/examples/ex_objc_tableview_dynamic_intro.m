/* @@Example: ex_objc_tableview_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>


void ex_objc_tableview_dynamic_intro()
{
    @autoreleasepool {

        /* Creates a new table dynamically. */
        TDBTable *table = [[TDBTable alloc] init];

        /* Add some colomns (obsolete style, see typed table example). */
        NSUInteger const NAME  = [table addColumnWithName:@"Name" andType:TDBStringType];
        NSUInteger const AGE   = [table addColumnWithName:@"Age" andType:TDBIntType];
        NSUInteger const HIRED = [table addColumnWithName:@"Hired" andType:TDBBoolType];

        /* Add people (rows). */
        [table addRow:@[@23, @"Joe", @YES]];
        [table addRow:@[@32, @"Simon", @YES]];
        [table addRow:@[@12, @"Steve", @NO]];
        [table addRow:@[@59, @"Nick", @YES]];
        
        /* Set up a query to search for employees. */
        TDBQuery *q =  [[[[table where] intIsGreaterThanOrEqualTo:30 inColumnWithIndex:AGE]
                                           intIsLessThanOrEqualTo:60 inColumnWithIndex:AGE ]
                                           boolIsEqualTo:YES inColumnWithIndex:HIRED];

        /* Execute the query. */
        TDBView *view = [q findAllRows];

        /* Print the names. */
        for (TDBRow *ite in view) {
            NSLog(@"With iterator.......name: %@",[ite stringInColumnWithIndex:NAME]);
        }

        /* Take a curser at index one in the view. */
        /* Note: the index of this row is different in the underlaying table. */

        TDBRow *c = [view rowAtIndex:1];
        if (c != nil)
            NSLog(@"With fixed index....name: %@",[c stringInColumnWithIndex:NAME]);


        /* Index out-of-bounds index. */
        TDBRow *c2 = [view rowAtIndex:view.rowCount];
        if (c2 != nil)
            NSLog(@"Should not get here.");
    }
}
/* @@EndExample@@ */
