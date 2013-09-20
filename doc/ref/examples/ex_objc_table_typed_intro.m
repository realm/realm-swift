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
        
        PeopleTable_Cursor *curser = [table addRow];
        curser.Name = @"Brian"; curser.Age = 10;
        
        curser = [table addRow];
        curser.Name = @"Sofie"; curser.Age = 40;
      
        NSLog(@"The size of the table is now %zd", [table count]);
        
        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
            
        }
        
        NSLog(@"Let's insert a new row");
        
        curser = [table insertRow:1];
        curser.Name = @"Sam"; curser.Age = 30;
    
        for (PeopleTable_Cursor *ite in table) {
            NSLog(@"Name: %@ Age: %lli", ite.Name, ite.Age);
        
        }
    
    
    }
}
 



// @@EndExample@@