/* @@Example: ex_objc_group_intro @@ */

#import <Tightdb/Tightdb.h>
#import "people.h"

/* PeopleTable is declared in people.h as
TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);
 */



void ex_objc_group_intro()
{
    @autoreleasepool {
        
        #ifdef TDB_GROUP_IMPLEMENTED

        /* Creates a group and uses it to create a new table. */

        TDBGroup* group = [TDBGroup group];
        PeopleTable* table = [group getOrCreateTableWithName:@"people" asTableClass:[PeopleTable class]];

        /* Adds values to the table. */
        [table appendRow:@{@"Name":@"Mary", @"Age":@14, @"Hired":@YES}];
        [table appendRow:@{@"Name":@"Joe",  @"Age":@17, @"Hired": @NO}];

        /* Write the group (and the contained table) to a specified file. */
        [[NSFileManager defaultManager] removeItemAtPath:@"filename.tightdb" error:nil];
        [group writeToFile:@"filename.tightdb" withError:nil];

        /* Adds another row to the table. Note the update is NOT persisted
           automatically (delete the old file and use write again). */

        [table appendRow:@{@"Name":@"Sam", @"Age":@17, @"Hired":@NO}];

        [[NSFileManager defaultManager] removeItemAtPath:@"filename.tightdb" error:nil];
        [group writeToFile:@"filename.tightdb" withError:nil];

        /* Retrieves an in memory buffer from the group. */
        TDBBinary* buffer = [group writeToBuffer];

        /* Creates a group from an im memory buffer */
        TDBGroup* groupFromMemory = [TDBGroup groupWithBuffer:buffer withError:nil];
        PeopleTable* tableFromMemery = [groupFromMemory getOrCreateTableWithName:@"people" asTableClass:[PeopleTable class]];

        for (PeopleTable_Roq *row in tableFromMemery) {
            NSLog(@"Name: %@", row.Name);
        }

        /* Caution: Calling free(..) on the "buffer" is sometimes required to avoid leakage. However,
           the group that retrieves data from memeory takes responsibilty for the memory allocation in this example. */

        /* free((char*)buffer); */ /* not needed in this particular situation. */
        
        #endif
    }
}





/* @@EndExample@@ */
