/* @@Example: ex_objc_table_typed_intro @@ */
#import <Realm/Realm.h>

// Simple person data object
@interface Person : RLMRow

@property NSString * name;
@property int age;
@property BOOL hired;

@end

void ex_objc_table_typed_intro()
{
    // Create a new table of the type defined above
    RLMTable *table = [[RLMTable alloc] initWithObjectClass:Person.class];
    
    // Append three rows
    [table addRow:@{@"name":@"Brian",  @"age":@10,  @"hired":@NO}];
    [table addRow:@{@"name":@"Sofie",  @"age":@40,  @"hired":@YES}];
    [table addRow:@{@"name":@"Jesper", @"age":@200, @"hired":@NO}];
    NSLog(@"The size of the table is now %zd", table.rowCount);

    for (Person *row in table) {
        NSLog(@"Name: %@ Age: %i", row.name, row.age);
    }
    
    NSLog(@"Insert a new row");
    [table insertRow:@{@"name":@"Sam", @"age":@30, @"hired":@YES}
             atIndex:1];
    
    for (Person *row in table) {
        NSLog(@"Name: %@ Age: %i", row.name, row.age);
    }
    
    Person *row2 = [table lastRow];
    if (row2 != nil)
        NSLog(@"Last row");
    
    Person *row3 = [table rowAtIndex:42];
    if (row3 == nil)
        NSLog(@"Index out of range.");
}
/* @@EndExample@@ */
