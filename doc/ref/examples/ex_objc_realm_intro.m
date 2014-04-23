/* @@Example: ex_objc_realm_intro @@ */
#import <Realm/Realm.h>
#import "people.h"

/*
 The classes People, PeopleQuery, PeopleView, and PeopleRow are declared
 (interfaces are generated) in people.h as

 REALM_TABLE_DEF_3(People,
                   Name,  String,
                   Age,   Int,
                   Hired, Bool)

 and in people.m you must have

 REALM_TABLE_IMPL_3(People,
                    Name, String,
                    Age,  Int,
                    Hired, Bool)

 in order to generate the implementation of the classes.
 */


void ex_objc_realm_intro()
{
    // Generate path for a writeable .realm file
    NSString *realmFileName          = @"employees.realm";
    NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *realmFilePath          = [documentsDirectoryPath stringByAppendingPathComponent:realmFileName];
    
    // Remove any previous files
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    
    NSError *writeContextCreationError = nil;
    
    // Create an RLMContext for writing (not yet supported in standalone RLMRealms)
    RLMContext *writeContext = [RLMContext contextPersistedAtPath:realmFilePath
                                                            error:&writeContextCreationError];
    
    if (writeContextCreationError) {
        NSLog(@"Error creating writeContext: %@", writeContextCreationError.localizedDescription);
    }
    
    // Perform a write transaction (with commit to file)
    [writeContext writeUsingBlock:^(RLMRealm *realm) {
        People *table = [realm createTableWithName:@"employees"
                                      asTableClass:[People class]];
        [table addRow:@{@"Name": @"Bill", @"Age": @53, @"Hired": @YES}];
    }];
    
    // Create a realm
    RLMRealm *realm = [RLMRealm realmWithPersistenceToFile:realmFilePath];
    
    // Read from the realm
    People *table = [realm tableWithName:@"employees" asTableClass:[People class]];
    for (PeopleRow *row in table) {
        NSLog(@"Name: %@", row.Name);
    }
}
/* @@EndExample@@ */
