/* @@Example: ex_objc_tableview_typed_intro @@ */
#import <Realm/Realm.h>

// Simple person data object
@interface Person : RLMRow

@property NSString * name;
@property int age;
@property BOOL hired;

@end

void ex_objc_tableview_typed_intro()
{
    /* Creates a new table of the type defined above. */
    RLMTable *table = [[RLMTable alloc] initWithObjectClass:Person.class];
    
    /* Adds rows to the table. */
    [table addRow:@{@"name":@"Brian",  @"age":@10, @"hired":@NO}];
    [table addRow:@{@"name":@"Sofie",  @"age":@40, @"hired":@YES}];
    [table addRow:@{@"name":@"Sam",    @"age":@76, @"hired":@NO}];
    
    /* Get the result of a query in a table view. */
    RLMView *view = [table where:@"age > 20"];
    
    /* Iterate over the result in the table view. */
    for (Person *row in view) {
        NSLog(@"This person is over the age of 20: %@", row.name);
    }
}
/* @@EndExample@@ */
