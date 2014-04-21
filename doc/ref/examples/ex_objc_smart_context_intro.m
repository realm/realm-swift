/* @@Example: ex_objc_smart_context_intro @@ */
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


void ex_objc_smart_context_intro()
{
    // Generate paths for .realm file and .realm.lock file
    NSString *realmFileName          = @"smartContextTest.realm";
    NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *realmFilePath          = [documentsDirectoryPath stringByAppendingPathComponent:realmFileName];
    NSString *realmFileLockPath      = [realmFilePath stringByAppendingPathExtension:@"lock"];
    
    // Remove any previous files
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:realmFilePath error:nil];
    [fm removeItemAtPath:realmFileLockPath error:nil];
    
    NSError *writeContextCreationError = nil;
    
    // Create an RLMContext for writing (not yet supported in RLMSmartContext)
    RLMContext *writeContext = [RLMContext contextPersistedAtPath:realmFilePath
                                                            error:&writeContextCreationError];
    
    if (writeContextCreationError) {
        NSLog(@"Error creating writeContext: %@", writeContextCreationError.localizedDescription);
    }
    
    // Perform a write transaction (with commit to file)
    NSError *error = nil;
    BOOL success;
    success = [writeContext writeUsingBlock:^(RLMTransaction *transaction) {
        People *table = [transaction createTableWithName:@"employees"
                                            asTableClass:[People class]];
        [table addRow:@{@"Name": @"Bill", @"Age": @53, @"Hired": @YES}];
        
        return YES; // Commit
    } error:&error];
    if (!success) {
        NSLog(@"write-transaction failed: %@", [error description]);
    }
    
    // Create a smart context
    RLMSmartContext *smartContext = [RLMSmartContext contextWithPersistenceToFile:realmFilePath];
    
    // Read from the smart context
    People *table = [smartContext tableWithName:@"employees"
                                   asTableClass:[People class]];
    for (PeopleRow *row in table) {
        NSLog(@"Name: %@", row.Name);
    }
}
/* @@EndExample@@ */
