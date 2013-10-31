// @@Example: ex_objc_query_dynamic_intro @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>



int main()
{
    @autoreleasepool {
        // TODO: Update example to the cursor.
        
        // Creates a new table dynamically.
        
        TightdbTable *table = [[TightdbTable alloc] init];
        
        size_t const NAME = [table addColumnWithType:tightdb_String andName:@"Name"];
        size_t const AGE = [table addColumnWithType:tightdb_Int andName:@"Age"];
        size_t const HIRED = [table addColumnWithType:tightdb_Bool andName:@"Hired"];
        
        // Add some people.
        
        // Add rows and values.
        
        TightdbCursor *cursor;
        
        // Row 0
        
        cursor = [table addEmptyRow];
        
        [cursor setInt:23 inColumn:AGE];
        [cursor setString:@"Joe" inColumn:NAME];
        [cursor setBool:YES inColumn:HIRED];
        
        // Row 1
        
        cursor = [table addEmptyRow];
        
        [cursor setInt:32 inColumn:AGE];
        [cursor setString:@"Simon" inColumn:NAME];
        [cursor setBool:YES inColumn:HIRED];
        
        // Row 2
        
        cursor = [table addEmptyRow];
        
        [cursor setInt:12 inColumn:AGE];
        [cursor setString:@"Steve" inColumn:NAME];
        [cursor setBool:NO inColumn:HIRED];
        
        // Row 3
        
        cursor = [table addEmptyRow];
        
        [cursor setInt:59 inColumn:AGE];
        [cursor setString:@"Nick" inColumn:NAME];
        [cursor setBool:YES inColumn:HIRED];
        
        // Set up a query to search for employees.
        
        TightdbQuery *q =  [[[table where] column: AGE   isBetweenInt:0 and_:60]
                                           column: HIRED isEqualToBool:YES];
        
        // Execute the query.
        
        TightdbView *view = [q findAll];
        
        // Print the names.
        
        for (TightdbCursor *c in view) {
            
            NSLog(@"name: %@",[c getStringInColumn:NAME]);
            
        }
      
        
        
        
    }
}

// @@EndExample@@
