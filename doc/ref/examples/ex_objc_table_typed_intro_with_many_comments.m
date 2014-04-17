/* @@Example: not_used @@ */
#import <Realm/Realm.h>

/* Defines a new table with two columns Name and Age. 
 * This table definition triggers a macro defining the classes
 * PeopleTable, PeopleTableQuery, PeopleTableRow and PeopleTableView.
 * The column types must be Realm types (refer to the constructor
 * TIGHTDB_TABLE_* in the documentation. */

TIGHTDB_TABLE_2(PersonTable,    // Name of Table
                Name, String,   // First column with Strings
                Age, Int)       // Second column with Integers

void ex_objc_table_typed_intro_with_many_comments()
{
    /* Creates a new table of the type defined above. */
    PersonTable *table = [[PersonTable alloc] init];
    
    /* Appends rows to the table. Notice that the signature of the method for
     * appendig rows requires that the order of the columns is exactly
     * as in the declaration. */
    [table addRow:@[@"Mary",  @14]];
    [table addRow:@[@"Joe",   @17]];
    [table addRow:@[@"Jack",  @22]];
    [table addRow:@[@"Paul",  @33]];
    [table addRow:@[@"Simon", @16]];
    [table addRow:@[@"Carol", @66]];
    
    /* Creates a query expression to filter on age. Note that the
     * query is defined but not executed here. */
    PersonTableQuery *query = [[table where].Age columnIsBetween:13 :19];
    
    /* Accesses query result directly on the query object.
     * The query is only executed once and iterated lazily */
    for (PersonTableRow *row in query)
        NSLog(@"Name: %@", row.Name);
    
    /* To avoid repeating the same query, the result may be stored in
     * a table view for multiple accesses. The following code executes the
     * query once and creates a table view which refers to the rows that 
     * matches the query. */
    PersonTableView *tableView = [query findAll];
    
    /* Iterates over all rows in the result (view) 2 times based on the single
     * query executed above. */
    for (PersonTableRow *row in tableView)
        NSLog(@"Name: %@", row.Name);
    
    for (PersonTableRow *row in tableView)
        NSLog(@"Name: %lld", row.Age);
}
/* @@EndExample@@ */
