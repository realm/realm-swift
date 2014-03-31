/* @@Example: ex_objc_query_typed_intro @@ */

#import <Tightdb/Tightdb.h>
#import "people.h"

/* PeopleTable is declared in people.h as
TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);
 */

void ex_objc_query_typed_intro()
{
    @autoreleasepool {

        /* Creates a new table of the type defined above. */
        PeopleTable *table = [[PeopleTable alloc] init];

        /* Adds rows to the table. */
        [table addRow:@{@"Name":@"Brian", @"Age":@14, @"Hired":@NO}];
        [table addRow:@{@"Name":@"Joe",   @"Age":@17, @"Hired":@YES}];
        [table addRow:@{@"Name":@"Jack",  @"Age":@22, @"Hired":@YES}];
        [table addRow:@{@"Name":@"Sam",   @"Age":@22, @"Hired":@YES}];
        [table addRow:@{@"Name":@"Jack",  @"Age":@34, @"Hired":@YES}];
        [table addRow:@{@"Name":@"Bob",   @"Age":@10, @"Hired":@NO}];

        /* Create a query. */
        PeopleTableQuery *query = [[[[table where].Age columnIsGreaterThan:20] Or].Name columnIsEqualTo:@"Bob"];

        /* Iterate over the query result. */
        for (PeopleTableRow *row in query) {
            NSLog(@"Person matching query: %@", row.Name);
        }
    }
}

/* @@EndExample@@ */
