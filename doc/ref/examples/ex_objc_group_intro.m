// @@Example: ex_objc_group_intro @@

#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

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
        
        // IMPORTANT: do not overwrite the existing file!
        
        [group write:@"filename2.tightdb"];
        
        // Retrieves an in memory buffer from the group.

        size_t size;
        const char *buffer = [group writeToMem:&size];
        
        // Calling free(..) is required here.
        // An alternative using NSData (and ARC) will be provided
        // in a future release.
        
        free((char*)buffer);
        
        
    }
}



// @@EndExample@@