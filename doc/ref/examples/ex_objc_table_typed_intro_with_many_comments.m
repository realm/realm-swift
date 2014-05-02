/* @@Example: not_used @@ */
#import <Realm/Realm.h>

/* Defines a new table with two columns Name and Age. 
 * This table definition triggers a macro defining the classes
 * PeopleTable, PeopleTableQuery, PeopleTableRow and PeopleTableView.
 * The column types must be Realm types (refer to the constructor
 * REALM_TABLE_* in the documentation. */

REALM_TABLE_2(PersonTable,    // Name of Table
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
    
    /* Creates a view to filter on age. */
    RLMView *view = [table allWhere:@"Age > 13 && Age < 19"];
    
    /* Iterate through RLMRows returned from view */
    for (RLMRow *row in view)
        NSLog(@"Name: %@", row[@"Name"]);
    
    /* Iterates over all rows in the result (view) 2 times based on the single
     * query executed above. */
    for (RLMRow *row in view)
        NSLog(@"Name: %@", row[@"Age"]);
}
/* @@EndExample@@ */
