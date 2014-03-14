/* @@Example: ex_objc_group_intro @@ */

#import <Tightdb/Tightdb.h>

TIGHTDB_TABLE_2(PeopleTable,
                Name, String,
                Age, Int)


TIGHTDB_TABLE_3(PeopleErrTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

int main()
{
    @autoreleasepool {

        /* Creates a group and uses it to create a new table. */

        TDBGroup* group = [TDBGroup group];
        PeopleTable* table = [group getOrCreateTableWithName:@"people" asTableClass:[PeopleTable class] error:nil];

        /* Adds values to the table. */

        [table addName:@"Mary" Age:14];
        [table addName:@"Joe" Age:17];

        /* Write the group (and the contained table) to a specified file. */

        [[NSFileManager defaultManager] removeItemAtPath:@"filename.tightdb" error:nil];
        [group writeToFile:@"filename.tightdb" withError:nil];

        /* Adds another row to the table. Note the update is NOT persisted
           automatically (delete the old file and use write again). */

        [table addName:@"Sam" Age:17];

        [[NSFileManager defaultManager] removeItemAtPath:@"filename.tightdb" error:nil];
        [group writeToFile:@"filename.tightdb" withError:nil];

        /* Retrieves an in memory buffer from the group. */

        TDBBinary* buffer = [group writeToBuffer];

        /* Creates a group from an im memory buffer */
        TDBGroup* groupFromMemory = [TDBGroup groupWithBuffer:buffer withError:nil];
        PeopleTable* tableFromMemery = [groupFromMemory getOrCreateTableWithName:@"people" asTableClass:[PeopleTable class] error:nil];

        for (PeopleTable_Cursor* cursor in tableFromMemery) {
            NSLog(@"Name: %@", cursor.Name);
        }

        /* Caution: Calling free(..) on the "buffer" is sometimes required to avoid leakage. However,
           the group that retrieves data from memeory takes responsibilty for the memory allocation in this example. */

        /* free((char*)buffer); */ /* not needed in this particular situation. */
    }
}



/* @@EndExample@@ */
