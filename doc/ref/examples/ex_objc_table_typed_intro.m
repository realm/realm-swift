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

        PeopleTable_Cursor *cursor = [table addRow];
        cursor.Name = @"Brian";
        cursor.Age = 10;

        cursor = [table addRow];
        cursor.Name = @"Sofie";
        cursor.Age = 40;

        NSLog(@"The size of the table is now %zd", [table count]);

        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
        }

        NSLog(@"Insert a new row");

        cursor = [table insertRowAtIndex:1];
        cursor.Name = @"Sam"; cursor.Age = 30;

        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
        }

        TightdbCursor *c2 = [table cursorAtIndex:[table count]-1];
        if (c2 != nil)
            NSLog(@"Last row");

        TightdbCursor *c3 = [table cursorAtIndex:[table count]];
        if (c3 != nil)
            NSLog(@"Should not get here.");


    }
}




// @@EndExample@@
