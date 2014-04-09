/* @@Example: ex_objc_sharedgroup_intro @@ */
#import <Tightdb/Tightdb.h>
#import "people.h"

/* PeopleTable is declared in people.h as
TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);
*/

void ex_objc_context_intro()
{
    /* Remove any previous file */
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:@"contextTest.tightdb" error:nil];
    [fm removeItemAtPath:@"contextTest.tightdb.lock" error:nil];
    
    /* Create datafile with a new table. */
    TDBContext *context = [TDBContext contextAtPath:@"contextTest.tightdb"
                                                             error:nil];

    /* Perform a write transaction (with commit to file). */
    NSError *error = nil;
    BOOL success;
    success = [context writeUsingBlock:^(TDBTransaction *transaction) {
        PeopleTable *table = [transaction createTableWithName:@"employees"
                                                 asTableClass:[PeopleTable class]];
        [table addRow:@{@"Name":@"Bill", @"Age":@53, @"Hired":@YES}];
        
        return YES; /* Commit */
    } error:&error];
    if (!success)
        NSLog(@"write-transaction failed: %@", [error description]);

    
    /* Perform a write transaction (with rollback). */
    success = [context writeUsingBlock:^(TDBTransaction *transaction) {
        PeopleTable *table = [transaction createTableWithName:@"employees"
                                                 asTableClass:[PeopleTable class]];
        if ([table rowCount] == 0) {
            NSLog(@"Roll back!");
            return NO; /* Rollback */
        }
        [table addName:@"Bill" Age:53 Hired:YES];
        NSLog(@"Commit!");
        return YES; /* Commit */
    } error:&error];
    if (!success)
        NSLog(@"Transaction Rolled back : %@", [error description]);

    
    /* Perfrom a read transaction */
    [context readUsingBlock:^(TDBTransaction *group) {
        PeopleTable *table = [group tableWithName:@"employees"
                                     asTableClass:[PeopleTable class]];
        for (PeopleTableRow *row in table) {
            NSLog(@"Name: %@", row.Name);
        }
    }];
}
/* @@EndExample@@ */
