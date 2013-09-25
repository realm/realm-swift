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
    
        // Insert using a cursor.

        TightdbCursor *c;

        c = [table addRowWithCursor];
        
            [c setInt:34 inColumn:AGE];
            [c setString:@"Steve" inColumn:NAME];
        
        c = [table addRowWithCursor];
        
            [c setInt:100 inColumn:AGE];
            [c setString:@"Nick" inColumn:NAME];
        
        c = [table insertRowWithCursor:3];
        
            [c setInt:21 inColumn:AGE];
            [c setString:@"Hello I'm INSERTED" inColumn:NAME];

        for (TightdbCursor *ite in table) {
            
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);
        
        }
        
        NSLog(@"--------");
        
        c = [table cursorAtIndex:3];
        
            [c setString:@"Now I'm UPDATED" inColumn:NAME];
        
        c = [table cursorAtLastIndex];
        
            [c setString:@"I'm UPDATED" inColumn:NAME];
        
        for (TightdbCursor *ite in table) {
            
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);
            
        }
        
    }
}

// @@EndExample@@