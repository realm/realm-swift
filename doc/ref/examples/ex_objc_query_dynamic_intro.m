/* @@Example: ex_objc_query_dynamic_intro @@ */
#import <Realm/Realm.h>

void ex_objc_query_dynamic_intro()
{
    [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
        /* Creates a new table dynamically. */
        RLMTable *table = [realm createTableWithName:@"table"];
        NSUInteger const NAME  = [table addColumnWithName:@"Name"
                                                     type:RLMTypeString];
        NSUInteger const AGE   = [table addColumnWithName:@"Age"
                                                     type:RLMTypeInt];
        NSUInteger const HIRED = [table addColumnWithName:@"Hired"
                                                     type:RLMTypeBool];
        
        /* Add some people. */
        [table addRow:@[@"Joe", @23, @YES]];
        [table addRow:@[@"Simon", @32, @YES]];
        [table addRow:@[@"Steve", @12, @NO]];
        [table addRow:@[@"Nick", @59, @YES]];
        
        /* Set up a query to search for employees. */
        RLMQuery *q = [[[[table where]
                         intIsGreaterThanOrEqualTo:0 inColumnWithIndex:AGE]
                        intIsLessThanOrEqualTo:60 inColumnWithIndex:AGE ]
                       boolIsEqualTo:YES inColumnWithIndex:HIRED];
        
        /* Execute the query. */
        RLMView *view = [q findAllRows];
        
        /* Iterate over query result */
        for (RLMRow *row in view) {
            NSLog(@"name: %@",row[NAME]);
        }
    }];
}
/* @@EndExample@@ */
