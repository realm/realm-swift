/* @@Example: ex_objc_query_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>


void ex_objc_query_dynamic_intro()
{
    @autoreleasepool {
        /* Creates a new table dynamically. */
        TDBTable *table = [[TDBTable alloc] init];

        NSUInteger const NAME = [table addColumnWithName:@"Name" andType:TDBStringType];
        NSUInteger const AGE = [table addColumnWithName:@"Age" andType:TDBIntType];
        NSUInteger const HIRED = [table addColumnWithName:@"Hired" andType:TDBBoolType];

        /* Add some people. */
        [table addRow:@[@23, @"Joe", @YES]];
        [table addRow:@[@32, @"Simon", @YES]];
        [table addRow:@[@12, @"Steve", @NO]];
        [table addRow:@[@59, @"Nick", @YES]];

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
