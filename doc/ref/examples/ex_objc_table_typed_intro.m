/* @@Example: ex_objc_table_typed_intro @@ */
#import <Tightdb/Tightdb.h>
#import "people.h"

/* PeopleTable is declared in people.h as

 TIGHTDB_TABLE_3(PeopleTable,
                 Name,  String,
                 Age,   Int,
                 Hired, Bool);
*/

void ex_objc_table_typed_intro()
{
    /* Create a new table of the type defined above. */
    PeopleTable *table = [[PeopleTable alloc] init];
    
    /* Append three rows. */
    [table addRow:@{@"Name":@"Brian",  @"Age":@10,  @"Hired":@NO}];
    [table addRow:@{@"Name":@"Sofie",  @"Age":@40,  @"Hired":@YES}];
    [table addRow:@{@"Name":@"Jesper", @"Age":@200, @"Hired":@NO}];
    NSLog(@"The size of the table is now %zd", table.rowCount);

    for (PeopleTableRow *ite in table) {
        NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
    }
    
    NSLog(@"Insert a new row");
    [table insertRow:@{@"Name":@"Sam", @"Age":@30, @"Hired":@YES}
             atIndex:1];
    
    for (PeopleTableRow *row in table) {
        NSLog(@"Name: %@ Age: %lli", row.Name, row.Age);
    }
    
    TDBRow *row2 = [table rowAtIndex:table.rowCount-1];
    if (row2 != nil)
        NSLog(@"Last row");
    
    TDBRow *row3 = [table rowAtIndex:table.rowCount];
    if (row3 == nil)
        NSLog(@"Index out of range.");
}
/* @@EndExample@@ */
