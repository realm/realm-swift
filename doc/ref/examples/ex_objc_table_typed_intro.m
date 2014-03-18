/* @@Example: ex_objc_table_typed_intro @@ */

#import <tightdb/objc/tightdb.h>


/* Defines a new table with two columns Name and Age. */

TIGHTDB_TABLE_2(PeopleTable,
                Name, String,
                Age, Int)


int main()
{
    @autoreleasepool {

        /* Creates a new table of the type defined above. */

        PeopleTable *table = [[PeopleTable alloc] init];

        PeopleTable_Cursor *row = [table addEmptyRow];
        row.Name = @"Brian";
        row.Age = 10;

        row = [table addEmptyRow];
        row.Name = @"Sofie";
        row.Age = 40;

/*
        [table addOrInsertRowAtIndex:[table count]
                                Name:@"Jesper"
                                 Age:200];
*/
        row = [table addEmptyRow];
        row.Name = @"Jesper";
        row.Age = 200;

        NSLog(@"The size of the table is now %zd", table.rowCount);

        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
        }

        NSLog(@"Insert a new row");

        row = [table insertEmptyRowAtIndex:1];
        row.Name = @"Sam"; row.Age = 30;

        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
        }

        TDBRow *c2 = [table cursorAtIndex:table.rowCount-1];
        if (c2 != nil)
            NSLog(@"Last row");

        TDBRow *c3 = [table cursorAtIndex:table.rowCount];
        if (c3 != nil)
            NSLog(@"Should not get here.");
    }
}

/* @@EndExample@@ */
