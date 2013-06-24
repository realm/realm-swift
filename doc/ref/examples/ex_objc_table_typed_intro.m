// @@Example: ex_objc_table_typed_intro @@

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
        [table addName:@"Sam" Age:34];
        [table addName:@"Bob" Age:10];
        
        // Get the number of rows in the table.
        
        NSLog(@"The size of the table is %zd", [table count]);
        
        // Insert row at an index.

        [table insertAtIndex:2 Name:@"Brian" Age:20];
        
        // Get first row matching an input column value. Notice the method
        // is accessed on a specific column, not on the table.
        
        NSLog(@"Found match in row %zd", [table.Age find:20]);
        
        // Clear the table (remove all rows).
        
        [table clear];
        NSLog(@"The size of the table is now %zd", [table count]);
        
    }
}

// @@EndExample@@