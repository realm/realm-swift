// @@Example: ex_objc_table_dynamic_intro @@

#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

//#define NAME 0
//#define AGE 1

int main()
{
    @autoreleasepool {
        
        // Create a new table dynamically.
        
        TightdbTable *table = [[TightdbTable alloc]init];
        
        size_t const NAME = [table addColumnWithType:tightdb_String andName:@"Name"];
        size_t const AGE = [table addColumnWithType:tightdb_Int andName:@"Age"];
        
        // Add rows and values.
        
        TightdbCursor *cursor;
        
        cursor = [table addRowWithCursor];
        
            [cursor setInt:23 inColumn:AGE];
            [cursor setString:@"Joe" inColumn:NAME];
        
        cursor = [table addRowWithCursor];
        
            [cursor setInt:32 inColumn:AGE];
            [cursor setString:@"Simon" inColumn:NAME];

        cursor = [table addRowWithCursor];
        
            [cursor setInt:12 inColumn:AGE];
            [cursor setString:@"Steve" inColumn:NAME];
        
        cursor = [table addRowWithCursor];
        
            [cursor setInt:100 inColumn:AGE];
            [cursor setString:@"Nick" inColumn:NAME];
        
        // Print using a cursor.
        
        for (TightdbCursor *ite in table) {
            
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);
        
        }
        
        // Insert a row and print.
        
        cursor = [table insertRowWithCursor:3];
        
            [cursor setInt:21 inColumn:AGE];
            [cursor setString:@"Hello I'm INSERTED" inColumn:NAME];
        
        
        NSLog(@"--------");
        
        for (TightdbCursor *ite in table) {
            
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);
            
        }
        
        // Update a few rows and print again.
        
        cursor = [table cursorAtIndex:2];
        
            [cursor setString:@"Now I'm UPDATED" inColumn:NAME];
        
        cursor = [table cursorAtLastIndex];
        
            [cursor setString:@"I'm UPDATED" inColumn:NAME];
        
        NSLog(@"--------");
        
        for (TightdbCursor *ite in table) {
            
            NSLog(@"Name: %@ Age: %lld", [ite getStringInColumn:NAME], [ite getIntInColumn:AGE]);
            
        }
        
    }
}

// @@EndExample@@