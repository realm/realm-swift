/* @@Example: ex_objc_query_typed_intro @@ */

#import <Tightdb/Tightdb.h>

/* Defines a new table with two columns Name and Age. */

TIGHTDB_TABLE_2(PeopleTable,
                Name, String,
                Age, Int);

int main()
{
    @autoreleasepool {

        /* Creates a new table of the type defined above. */

        PeopleTable *table = [[PeopleTable alloc] init];

        /* Adds rows to the table. */

        [table addName:@"Brian" Age:14];
        [table addName:@"Joe" Age:17];
        [table addName:@"Jack" Age:22];
        [table addName:@"Sam" Age:34];
        [table addName:@"Bob" Age:10];

        /* Create a query. */

        PeopleTable_Query *query = [[[[table where].Age columnIsGreaterThan:20] Or].Name columnIsEqualTo:@"Bob"];

        /* Iterate over the query result. */

        for (PeopleTable_Cursor *curser in query) {
            NSLog(@"Person matching query: %@", [curser Name]);
        }

    }
}

/* @@EndExample@@ */
