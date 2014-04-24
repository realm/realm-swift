// @@Example: ex_objc_intro @@
#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

// Simple person data object
@interface Person : RLMRow

@property NSString * name;
@property int age;
@property BOOL hired;

@end

// Use it in a function
void ex_objc_intro() {
    // Create a realm and initialize with a table and rows
    RLMRealm *realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
        if (realm.isEmpty) {
            // Create a table
            RLMTable *table = [realm createTableWithName:@"employees"
                                             objectClass:Person.class];
            // Add rows
            [table addRow:@{@"name": @"Mary", @"age": @76, @"hired": @NO}];
            [table addRow:@{@"name": @"Lars", @"age": @22, @"hired": @YES}];
            [table addRow:@{@"name": @"Phil", @"age": @43, @"hired": @NO}];
            [table addRow:@{@"name": @"Anni", @"age": @54, @"hired": @YES}];
        }
    }];
    
    // Get the table
    RLMTable *table = [realm tableWithName:@"employees" objectClass:Person.class];
    
    // Query the table
    RLMView *view  = [table where:@"age > 30"];
    
    // Iterate over all rows in view
    for (Person *row in view) {
        NSLog(@"Name: %@", row.name);
    }
}
// @@EndExample@@
