// @@Example: ex_objc_group_intro @@

#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

TIGHTDB_TABLE_2(PeopleTable,
                Name, String,
                Age, Int)

int main()
{
    @autoreleasepool {
        
        // Creates a group and uses it to create a new table.

        TightdbGroup *group = [TightdbGroup group];
        PeopleTable *table = [group getTable:@"people" withClass:[PeopleTable class]];
        
        // Adds values to the table.
        
        [table addName:@"Mary" Age:14];
        [table addName:@"Joe" Age:17];
        
        // Write the group (and the contained table) to a specified file.
        
        [group write:@"filename.tightdb"];
        
        // Adds another row to the table. Note the update is NOT persisted
        // automatically.
        
        [table addName:@"Sam" Age:17];
        
        // To save this update to disk write the group to a different file.
        // IMPORTANT: do not overwrite the old file this will corrupt the table.
        // This issue will be resolved in TightDB build XX.
        
        [group write:@"filename2.tightdb"];
        
        // Retrieves a byte array from the group and uses it to create an
        // NSData object.
        
        size_t size;
        const char *buffer = [group writeToMem:&size];
        NSData *myData = [NSData dataWithBytes:buffer length:size];
        
        // call free() here on buffer?
        
    }
}
// @@EndExample@@