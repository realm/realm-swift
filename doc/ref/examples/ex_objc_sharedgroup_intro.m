/* @@Example: ex_objc_sharedgroup_intro @@ */

#import <tightdb/objc/tightdb.h>


TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);




int main()
{
    @autoreleasepool {

        /* Creates a group and uses it to create a new table. */

        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:@"sharedgrouptest.tightdb" error:nil];
        [fm removeItemAtPath:@"sharedgrouptest.tightdb.lock" error:nil];

        TDBSharedGroup *shared = [TDBSharedGroup sharedGroupWithFile:@"sharedgrouptest.tightdb" withError:nil];
        if (!shared) {
            NSLog(@"Error");
        }
        else {
            NSLog(@"%@", shared);
        }

        /* A write transaction (with commit). */

        NSError *error = nil;
        BOOL success;

        success = [shared writeWithBlock:^(TDBGroup *group) {

            /* Write transactions with the shared group are possible via the provided variable binding named group. */

            PeopleTable *table = [group getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class] error:nil];

            if (table.rowCount) {
                NSLog(@"Not empty!");
                return NO; /* Rollback */
            }

            [table addName:@"Bill" Age:53 Hired:YES];
            NSLog(@"Commit!");
            return YES; /* Commit */
        } withError:&error];

        if(!success)
            NSLog(@"Error : %@", [error localizedDescription]);

        /* A write transaction (with rollback). */

        success = [shared writeWithBlock:^(TDBGroup *group) {

            /* Write transactions with the shared group are possible via the provided variable binding named group. */

           PeopleTable *table = [group getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class] error:nil];

           if (table.rowCount) {
               NSLog(@"Roll back!");
               return NO; /* Rollback */
           }

           [table addName:@"Bill" Age:53 Hired:YES];
           NSLog(@"Commit!");
           return YES; /* Commit */
       } withError:&error];

        if(!success)
            NSLog(@"Error : %@", [error localizedDescription]);


        /* A read transaction */

        [shared readWithBlock:^(TDBGroup *group) {

            /* Read transactions with the shared group are possible via the provided variable binding named group. */

            PeopleTable *table = [group getOrCreateTableWithName:@"employees" asTableClass:[PeopleTable class] error:nil];

            for (PeopleTable_Cursor *row in table) {
                NSLog(@"Name: %@", [row Name]);
            }
        }];

    }

}

/* @@EndExample@@ */
