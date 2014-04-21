/* @@Example: ex_objc_sharedgroup_intro @@ */
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


void ex_objc_context_intro()
{
    // Generate paths for .realm file and .realm.lock file
    NSString *realmFileName          = @"contextTest.realm";
    NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *realmFilePath          = [documentsDirectoryPath stringByAppendingPathComponent:realmFileName];
    NSString *realmFileLockPath      = [realmFilePath stringByAppendingPathExtension:@"lock"];
    
    // Remove any previous files
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:realmFilePath error:nil];
    [fm removeItemAtPath:realmFileLockPath error:nil];

    NSError *contextCreationError = nil;
    
    // Create an RLMContext
    RLMContext *context = [RLMContext contextPersistedAtPath:realmFilePath
                                                       error:&contextCreationError];
    
    if (contextCreationError) {
        NSLog(@"Error creating context: %@", contextCreationError.localizedDescription);
    }

    // Perform a write transaction (with commit to file)
    NSError *error = nil;
    BOOL success;
    success = [context writeUsingBlock:^(RLMTransaction *transaction) {
        People *table = [transaction createTableWithName:@"employees"
                                            asTableClass:[People class]];
        [table addRow:@{@"Name":@"Bill", @"Age":@53, @"Hired":@YES}];

        return YES; // Commit
    } error:&error];
    if (!success)
        NSLog(@"write-transaction failed: %@", [error description]);

    // Perform a write transaction (with rollback)
    success = [context writeUsingBlock:^(RLMTransaction *transaction) {
        People *table = [transaction tableWithName:@"employees"
                                      asTableClass:[People class]];
        if ([table rowCount] == 0) {
            NSLog(@"Roll back!");
            return NO;
        }
        [table addName:@"Mary" Age:76 Hired:NO];
        return YES; // Commit
    } error:&error];
    if (!success)
        NSLog(@"Transaction Rolled back : %@", [error description]);

    // Perform a read transaction
    [context readUsingBlock:^(RLMTransaction *transaction) {
        People *table = [transaction tableWithName:@"employees"
                                      asTableClass:[People class]];
        for (PeopleRow *row in table) {
            NSLog(@"Name: %@", row.Name);
        }
    }];
}
/* @@EndExample@@ */
