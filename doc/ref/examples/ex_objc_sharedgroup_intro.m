/* @@Example: ex_objc_sharedgroup_intro @@ */

#import <Tightdb/Tightdb.h>
#import "people.h"

/* PeopleTable is declared in people.h as
TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);
*/

void ex_objc_sharedgroup_intro()
{
    @autoreleasepool {

        /* Creates a group and uses it to create a new table. */
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:@"sharedgrouptest.tightdb" error:nil];
        [fm removeItemAtPath:@"sharedgrouptest.tightdb.lock" error:nil];

        TDBContext *context = [TDBContext contextWithPersistenceToFile:@"sharedgrouptest.tightdb" withError:nil];
        if (!context) {
            NSLog(@"Error");
        }
        else {
            NSLog(@"%@", context);
        }

        /* A write transaction (with commit). */
        NSError *error = nil;
        BOOL success;

        success = [context writeWithBlock:^(TDBTransaction *group) {
            /* Write transactions with the shared group are possible via the provided variable binding named group. */
            PeopleTable *table = [group getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class]];

            if ([table rowCount] == 0) {
                NSLog(@"Not empty!");
                return NO; /* Rollback */
            }

            [table appendRow:@{@"Name":@"Bill", @"Age":@53, @"Hired":@YES}];
            NSLog(@"Commit!");
            return YES; /* Commit */
        } withError:&error];

        if(!success)
            NSLog(@"Error : %@", [error localizedDescription]);

        /* A write transaction (with rollback). */
        success = [context writeWithBlock:^(TDBTransaction *group) {

            /* Write transactions with the shared group are possible via the provided variable binding named group. */
           PeopleTable *table = [group getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class]];

           if ([table rowCount] == 0) {
               NSLog(@"Roll back!");
               return NO; /* Rollback */
           }

           [table addName:@"Bill" Age:53 Hired:YES];
           NSLog(@"Commit!");
           return YES; /* Commit */
       } withError:&error];

        if (!success)
            NSLog(@"Error : %@", [error localizedDescription]);

        /* A read transaction */
        [context readWithBlock:^(TDBTransaction *group) {

            /* Read transactions with the shared group are possible via the provided variable binding named group. */
            PeopleTable *table = [group getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class]];

            for (PeopleTableRow *row in table) {
                NSLog(@"Name: %@", [row Name]);
            }
        }];
    }
}
/* @@EndExample@@ */
