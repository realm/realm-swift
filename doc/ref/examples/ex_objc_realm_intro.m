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
<<<<<<< HEAD
    // Create a realm and initialize by creating table and adding a row    
    RLMRealm *realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
        if (realm.isEmpty) {
            People *table = [realm createTableWithName:@"employees"
                                          asTableClass:[People class]];
            [table addRow:@{@"Name": @"Bill", @"Age": @53, @"Hired": @YES}];
        }
    }];
=======
    // Generate path for a writable .realm file
    NSString *realmFileName          = @"employees.realm";
    NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *realmFilePath          = [documentsDirectoryPath stringByAppendingPathComponent:realmFileName];
    
    // Remove any previous files
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    
    // Create a realm and initialize by creating table and adding a row
    RLMRealm *realm = [RLMRealm realmWithPath:realmFilePath
                                    initBlock:^(RLMRealm *realm) {
                                        if (realm.isEmpty) {
                                            PeopleTable *table = [realm tableWithName:@"employees" asTableClass:[PeopleTable class]];
                                            [table addRow:@{@"Name": @"Bill", @"Age": @53, @"Hired": @YES}];
                                        }
                                    }];
>>>>>>> 0c5befb1d95840f3a70236a56bf1fa62ddce2eb3
    
    // Read from the realm
    PeopleTable *table = [realm tableWithName:@"employees" asTableClass:[People class]];
    for (People *row in table) {
        NSLog(@"Name: %@", row.Name);
    }
}
/* @@EndExample@@ */
