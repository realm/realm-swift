/* @@Example: ex_objc_tableview_typed_intro @@ */

#import <Tightdb/Tightdb.h>
#import "people.h"

/* PeopleTable is declared in people.h as
TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);
 */

void ex_objc_tableview_typed_intro()
{
    @autoreleasepool {

        /* Creates a new table of the type defined above. */
        PeopleTable *table = [[PeopleTable alloc] init];

        /* Adds rows to the table. */
        [table appendRow:@{@"Name":@"Brian",  @"Age":@10, @"Hired":@NO}];
        [table appendRow:@{@"Name":@"Sofie",  @"Age":@40, @"Hired":@YES}];
        [table appendRow:@{@"Name":@"Sam",    @"Age":@76, @"Hired":@NO}];

        /* Place the result of a query in a table view. */
        PeopleTable_View *tableView = [[[table where].Age columnIsGreaterThan:20] findAll];

        /* Iterate over the result in the table view. */
        for (PeopleTable_Row *row in tableView) {
            NSLog(@"This person is over the age of 20: %@", row.Name);
        }
    }
}

/* @@EndExample@@ */
