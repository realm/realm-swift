/* @@Example: not_used @@ */
#import <Realm/Realm.h>

/* Defines a regulare objective c interface that derives from RLMRow
 * The properties types must be types supported by Realm, or excluded
 * using the RLMObject protocol */

// Simple person data object
@interface Person : RLMRow

@property NSString * name;  // generates a string column in a table
@property int age;          // generates an int column in a table
@property BOOL hired;          // generates a BOOL column in a table

@end

void ex_objc_table_typed_intro_with_many_comments()
{
    /* Creates a new table and initialized column for
     * ame and age */
    RLMTable *table = [[RLMTable alloc] initWithObjectClass:Person.class];
    
    /* Appends rows to the table. Notice that the signature of the method for
     * appendig rows requires that the order of the columns is exactly
     * as in the declaration. */
    [table addRow:@[@"Mary",  @14, @YES]];
    [table addRow:@[@"Joe",   @17, @YES]];
    [table addRow:@[@"Jack",  @22, @YES]];
    [table addRow:@[@"Paul",  @33, @NO]];
    [table addRow:@[@"Simon", @16, @NO]];
    [table addRow:@[@"Carol", @66, @YES]];
    
    /* Creates a query expression and filters on the age column. */
    RLMView *view = [table where:@"age >= 13 and age <= 19"];
    
    /* Iterates over all rows in the result view. */
    for (Person *row in view)
        NSLog(@"Name: %@", row.name);
    
    for (Person *row in view)
        NSLog(@"Name: %d", row.age);
}
/* @@EndExample@@ */
