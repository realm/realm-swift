// @@Example: ex_objc_tableview_dynamic_intro @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

#define NAME 0
#define AGE 1
#define HIRED 2

int main()
{
    @autoreleasepool {
        
        // Creates a new table dynamically.
        
        TightdbTable *table = [[TightdbTable alloc] init];
        
        // Add some colomns.
        
        [table addColumn:tightdb_String name:@"Name"];
        [table addColumn:tightdb_Int name:@"Age"];
        [table addColumn:tightdb_Bool name:@"Hired"];
        
        // Add some people.
        
        [table addRows:5];
        
        [table setString:NAME ndx:0 value:@"Sam"];
        [table setString:NAME ndx:1 value:@"Paul"];
        [table setString:NAME ndx:2 value:@"Jack"];
        [table setString:NAME ndx:3 value:@"Simon"];
        [table setString:NAME ndx:4 value:@"Brian"];
        
        [table set:AGE ndx:0 value:10];
        [table set:AGE ndx:1 value:20];
        [table set:AGE ndx:2 value:30];
        [table set:AGE ndx:3 value:45];
        [table set:AGE ndx:4 value:56];
        
        [table set:HIRED ndx:0 value:YES];
        [table set:HIRED ndx:1 value:NO];
        [table set:HIRED ndx:2 value:NO];
        [table set:HIRED ndx:3 value:YES];
        [table set:HIRED ndx:4 value:NO];
        
        // Set up a query to search for employees.
        
        TightdbQuery *q =  [[[table where] column: AGE   isBetweenInt:0 and_:60]
                            column: HIRED isEqualToBool:YES];
        
        // Execute the query.
        
        TightdbView *view = [q findAll];
        
        // Print the names.
        
        for (int i = 0; i < [view count]; i++) {
            NSLog(@"name: %@",[view getString:NAME ndx:i]);
            
        }
    }
}

// @@EndExample@@