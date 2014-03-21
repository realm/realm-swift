/* @@Example: not_used @@ */

#import <Tightdb/Tightdb.h>

/* Defines a new table with two columns Name and Age. IMPORTANT: the column
 * names MUST begin with a capital. This table definition triggers a macro
 * defining the classes PeopleTable, PeopleTable_Query, PeopleTable_Curser
 * and PeopleTable_View. The column types must be TightDB types (refer to
 * the constructor TIGHTDB_TABLE_* in the documentation. */

TIGHTDB_TABLE_2(PersonTable,
                Name, String,
                Age, Int)

void ex_objc_table_typed_intro_with_many_comments()
{
    @autoreleasepool {

        /* Creates a new table of the type defined above. */
        PersonTable *table = [[PersonTable alloc] init];

        /* Appends rows to the table. Notice that the signtaure of the method for
         * appendig rows requires that the order the columns is exactly
         * as the declaration. */
        [table appendRow:@[@"Mary",  @14]];
        [table appendRow:@[@"Joe",   @17]];
        [table appendRow:@[@"Jack",  @22]];
        [table appendRow:@[@"Paul",  @33]];
        [table appendRow:@[@"Simon", @16]];
        [table appendRow:@[@"Carol", @66]];

        /* Creates a query expression to filter on age. Note that the
         * query is defined but not executed here. */
        PersonTableQuery *query = [[table where].Age columnIsBetween:13 and_:19];

        /* Accesses query result directly on the quiry object. The quiry is
         * executed once. */
        for (PersonTableRow *row in query)
            NSLog(@"Name: %@", [row Name]);

        /* For time consuming queries (in particular) the following is
         * inefficient because the query is executed again. */
        for (PersonTableRow *row in query)
            NSLog(@"Name: %lld", [row Age]);

        /* To avoid repeating the same query, the result may be stored in
         * a table view for multiple access. The following code executes the
         * query once and saves the result in a table view. */
        PersonTableView *tableView = [query findAll];

        /* Iterates over all rows in the result (view) 2 times based on the single
         * query executed above. */
        for (PersonTableRow *row in tableView)
            NSLog(@"Name: %@", [row Name]);

        for (PersonTableRow *row in tableView)
            NSLog(@"Name: %lld", [row Age]);
    }
}
/* @@EndExample@@ */
