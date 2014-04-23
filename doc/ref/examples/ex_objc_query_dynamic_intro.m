/* @@Example: ex_objc_query_dynamic_intro @@ */
#import <Realm/Realm.h>

void ex_objc_query_dynamic_intro()
{
    /* Creates a new table dynamically. */
    RLMTable *table = [[RLMTable alloc] init];
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
    
    /* Set up a view for employees. */
    RLMView *view = [table where:@"Age >= 0 && Age <= 60 && Hired == YES"];
    
    /* Iterate over query result */
    for (RLMRow *row in view) {
        NSLog(@"name: %@",row[NAME]);
    }
}
/* @@EndExample@@ */
