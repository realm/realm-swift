/* @@Example: ex_objc_realm_intro @@ */
#import <Realm/Realm.h>

// Simple person data object
@interface Person : RLMRow

@property NSString * name;
@property int age;
@property BOOL hired;

@end


void ex_objc_realm_intro()
{
    // Generate path for a writable .realm file
    NSString *realmFileName          = @"employees.realm";
    NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *realmFilePath          = [documentsDirectoryPath stringByAppendingPathComponent:realmFileName];
    
    // Remove any previous files
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    
    // Create a realm and initialize by creating table and adding a row
    RLMRealm *realm = [RLMRealm realmWithPersistenceToFile:realmFilePath
                                                 initBlock:^(RLMRealm *realm) {
        if (realm.isEmpty) {
            RLMTable *table = [realm createTableWithName:@"employees"
                                             objectClass:Person.class];
            [table addRow:@{@"name": @"Bill", @"age": @53, @"hired": @YES}];
        }
    }];
    
    // Read from the realm
    RLMTable *table = [realm tableWithName:@"employees" objectClass:Person.class];
    for (Person *row in table) {
        NSLog(@"Name: %@", row.name);
    }
}
/* @@EndExample@@ */
