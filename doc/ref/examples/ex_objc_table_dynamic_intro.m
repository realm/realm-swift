// @@Example: ex_objc_table_dynamic_intro @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

#define NAME 0
#define AGE 1

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
        
        [table setString:NAME ndx:0 value:@"Sam"];
        [table setString:NAME ndx:1 value:@"Paul"];
        [table setString:NAME ndx:2 value:@"Jack"];
        [table setString:NAME ndx:3 value:@"Simon"];
        [table setString:NAME ndx:4 value:@"Brian"];
        
        // Set column 1 (Age:Int) at row 0 (we only have one row).
        
        [table set:AGE ndx:0 value:1];
        [table set:AGE ndx:1 value:2];
        [table set:AGE ndx:2 value:3];
        [table set:AGE ndx:3 value:4];
        [table set:AGE ndx:4 value:5];
        
        
        
        // Print the table contents.
        
        for(int row = 0; row<[table count]; row++) {
            NSLog(@"Name: %@",[table getString:NAME ndx:row]);
            NSLog(@"Age: %lld",[table get:AGE ndx:row]);
        }
    }
}

// @@EndExample@@