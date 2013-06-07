// @@Example: ex_objc_typed_table_intro @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

// Defines a new table with two columns Name and Age. 
 
TIGHTDB_TABLE_2(PeopleTable,
                Name, String,
                Age, Int)

int main()
{
    @autoreleasepool {
        
        // Creates a new table of the type defined above.

        PeopleTable *table = [[PeopleTable alloc] init];
        
        // Adds rows to the table.
        
        [table addName:@"Mary" Age:14];
        [table addName:@"Joe" Age:17];
        [table addName:@"Jack" Age:22];
        
        // Get the number of rows in the table.
        
        size_t size = [table count];
        
        
        

    }
}

// @@EndExample@@