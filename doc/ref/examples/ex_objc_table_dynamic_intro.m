// @@Example: ex_objc_table_dynamic_intro @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

 


int main()
{
    @autoreleasepool {
        
        // Creates a new table dynamically.
        
        TightdbTable *table = [[TightdbTable alloc]init];
        
        // Add columns 0 (Name) and 1 (Age).
        
        [table addColumn:tightdb_String name:@"Name"];
        [table addColumn:tightdb_Int name:@"Age"];
        
        // Add row 0.
        
        [table addRows:5];
        
        // Set column 0 (Name:String) at row 0 (we only have one row).
        
        [table setString:0 ndx:0 value:@"Sam"];
        [table setString:0 ndx:1 value:@"Paul"];
        [table setString:0 ndx:2 value:@"Jack"];
        [table setString:0 ndx:3 value:@"Simon"];
        [table setString:0 ndx:4 value:@"Brian"];
        
        // Set column 1 (Age:Int) at row 0 (we only have one row).
        
        [table set:1 ndx:0 value:1];
        [table set:1 ndx:1 value:2];
        [table set:1 ndx:2 value:3];
        [table set:1 ndx:3 value:4];
        [table set:1 ndx:4 value:5];
        
        // Print the table contents.
        
        for(int row = 0; row<[table count]; row++) {
            NSLog(@"Name: %@",[table getString:0 ndx:row]);
            NSLog(@"Age: %lld",[table get:1 ndx:row]);
        }
    }
}

// @@EndExample@@