/* @@Example: ex_objc_tableview_typed_intro @@ */
#import <Tightdb/Realm.h>
#import "people.h"

/*
 The classes People, PeopleQuery, PeopleView, and PeopleRow are declared
 (interfaces are generated) in people.h as

 TIGHTDB_TABLE_DEF_3(People,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

 and in people.m you must have

 TIGHTDB_TABLE_IMPL_3(People,
                      Name, String,
                      Age,  Int,
                      Hired, Bool)

 in order to generate the implementation of the classes.
*/

void ex_objc_tableview_typed_intro()
{
    /* Creates a new table of the type defined above. */
    People *table = [[People alloc] init];
    
    /* Adds rows to the table. */
    [table addRow:@{@"Name":@"Brian",  @"Age":@10, @"Hired":@NO}];
    [table addRow:@{@"Name":@"Sofie",  @"Age":@40, @"Hired":@YES}];
    [table addRow:@{@"Name":@"Sam",    @"Age":@76, @"Hired":@NO}];
    
    /* Get the result of a query in a table view. */
    PeopleView *view = [[[table where].Age columnIsGreaterThan:20] findAll];
    
    /* Iterate over the result in the table view. */
    for (PeopleRow *row in view) {
        NSLog(@"This person is over the age of 20: %@", row.Name);
    }
}
/* @@EndExample@@ */
