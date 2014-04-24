/* @@Example: ex_objc_query_typed_intro @@ */
#import <Realm/Realm.h>

// Simple person data object
@interface Person : RLMRow

@property NSString * name;
@property int age;
@property BOOL hired;

@end

void ex_objc_query_typed_intro()
{
    // Creates a new table of the type defined above
    RLMTable *table = [[RLMTable alloc] initWithObjectClass:Person.class];
    
    // Adds rows to the table.
    [table addRow:@{@"name":@"Brian", @"age":@14, @"hired":@NO}];
    [table addRow:@{@"name":@"Jack",  @"age":@34, @"hired":@YES}];
    [table addRow:@{@"name":@"Bob",   @"age":@10, @"hired":@NO}];
    
    // Create a query
    RLMView *view  = [table where:@"age > 30"];
    
    // Iterate over the query result
    for (Person *row in view) {
        NSLog(@"Person matching query: %@", row.name);
    }
}
/* @@EndExample@@ */
