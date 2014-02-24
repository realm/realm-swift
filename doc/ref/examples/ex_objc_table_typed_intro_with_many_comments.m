// @@Example: not_used @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

// Defines a new table with two columns Name and Age. IMPORTANT: the column
// names MUST begin with a capital. This table definition triggers a macro
// defining the classes PeopleTable, PeopleTable_Query, PeopleTable_Curser
// and PeopleTable_View. The column types must be TightDB types (refer to
// the constructor TIGHTDB_TABLE_* in the documentation.

TIGHTDB_TABLE_2(PeopleTable,
                Name, String,
                Age, Int)

int main()
{
    @autoreleasepool {

        // Creates a new table of the type defined above.

        PeopleTable *table = [[PeopleTable alloc] init];

        // Adds rows to the table. Notice that the signtaure of the method for
        // adding rows includes the custom defined column nammes.

        [table addName:@"Mary" Age:14];
        [table addName:@"Joe" Age:17];
        [table addName:@"Jack" Age:22];
        [table addName:@"Paul" Age:33];
        [table addName:@"Simon" Age:16];
        [table addName:@"Carol" Age:66];

        // Creates a query expression to filter on age. Note that the
        // quiry is defined but not executed here.

        PeopleTable_Query *query = [[table where].Age columnIsBetween:13 and_:19];

        // Accesses query result directly on the quiry object. The quiry is
        // executed once.

        for (PeopleTable_Cursor *curser in query)
            NSLog(@"Name: %@", [curser Name]);

        // For time consuming queries (in particular) the following is
        // inefficient becuase the quiry is executed again.

        for (PeopleTable_Cursor *curser in query)
            NSLog(@"Name: %lld", [curser Age]);

        // To avoid repeating the same query, the result may be stored in
        // a table view for multiple access. The following code executes the
        // query once and saves the result in a table view.

        PeopleTable_View *tableView = [query findAll];

        // Iterates over all rows in the result (view) 2 times based on the single
        // query executed above.

        for (PeopleTable_Cursor *curser in tableView)
            NSLog(@"Name: %@", [curser Name]);

        for (PeopleTable_Cursor *curser in tableView)
            NSLog(@"Name: %lld", [curser Age]);

    }
}

// @@EndExample@@
