/* @@Example: ex_objc_query_dynamic_intro @@ */

#import <Tightdb/Tightdb.h>


void ex_objc_query_dynamic_intro()
{
    @autoreleasepool {
        /* Creates a new table dynamically. */
        TDBTable *table = [[TDBTable alloc] init];

        NSUInteger const NAME = [table addColumnWithName:@"Name" type:TDBStringType];
        NSUInteger const AGE = [table addColumnWithName:@"Age" type:TDBIntType];
        NSUInteger const HIRED = [table addColumnWithName:@"Hired" type:TDBBoolType];

        /* Add some people. */
        [table addRow:@[@"Joe", @23, @YES]];
        [table addRow:@[@"Simon", @32, @YES]];
        [table addRow:@[@"Steve", @12, @NO]];
        [table addRow:@[@"Nick", @59, @YES]];

        /* Set up a query to search for employees. */
        TDBQuery *q =  [[[[table where] intIsGreaterThanOrEqualTo:0 inColumnWithIndex:AGE]
                                            intIsLessThanOrEqualTo:60 inColumnWithIndex:AGE ]
                                          boolIsEqualTo:YES inColumnWithIndex:HIRED];

        /* Execute the query. */
        TDBView *view = [q findAllRows];

        /* Print the names. */
        for (TDBRow *c in view) {
            NSLog(@"name: %@",c[NAME]);
        }
    }
}

/* @@EndExample@@ */
