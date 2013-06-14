// @@Example: ex_objc_table_dynamic_intro @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

// Defines a new table with two columns Name and Age. 
 


int main()
{
    @autoreleasepool {
        
        // Creates a new table of the type defined above.
        
        TightdbTable *table = [[TightdbTable alloc]init];
        
        
        table addColumn:Tightdb_Sub name:<#(NSString *)#>
        
        
    }
}

// @@EndExample@@