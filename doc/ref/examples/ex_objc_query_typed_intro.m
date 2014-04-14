/* @@Example: ex_objc_query_typed_intro @@ */
#import <Tightdb/Tightdb.h>
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

void ex_objc_query_typed_intro()
{
    // Creates a new table of the type defined above
    People *table = [[People alloc] init];
    
    // Adds rows to the table.
    [table addRow:@{@"Name":@"Brian", @"Age":@14, @"Hired":@NO}];
    [table addRow:@{@"Name":@"Jack",  @"Age":@34, @"Hired":@YES}];
    [table addRow:@{@"Name":@"Bob",   @"Age":@10, @"Hired":@NO}];
    
    // Create a query
    PeopleQuery *query = [[[[table where].Age columnIsGreaterThan:20] Or].Name columnIsEqualTo:@"Bob"];
    
    // Iterate over the query result
    for (PeopleRow *row in query) {
        NSLog(@"Person matching query: %@", row.Name);
    }
}
/* @@EndExample@@ */
