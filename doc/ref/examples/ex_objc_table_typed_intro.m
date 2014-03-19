/* @@Example: ex_objc_table_typed_intro @@ */

#import <Tightdb/Tightdb.h>
#import "people.h"

/* PeopleTable is declared in people.h as
TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);
 */

void ex_objc_table_typed_intro()
{
    @autoreleasepool {

        /* Creates a new table of the type defined above. */
        PeopleTable *table = [[PeopleTable alloc] init];

        /* Append three rows. */
        [table appendRow:@{@"Name":@"Brian",  @"Age":@10,  @"Hired":@NO}];
        [table appendRow:@{@"Name":@"Sofie",  @"Age":@40,  @"Hired":@YES}];
        [table appendRow:@{@"Name":@"Jesper", @"Age":@200, @"Hired":@NO}];

        NSLog(@"The size of the table is now %zd", table.rowCount);

        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
        }

        NSLog(@"Insert a new row");

        [table insertRow:@{@"Name":@"Sam", @"Age":@30, @"Hired":@YES} atRowIndex:1];

        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
        }

        TDBRow *c2 = [table cursorAtIndex:table.rowCount-1];
        if (c2 != nil)
            NSLog(@"Last row");

        TDBRow *c3 = [table cursorAtIndex:table.rowCount];
        if (c3 != nil)
            NSLog(@"Should not get here.");
    }
}
/* @@EndExample@@ */
