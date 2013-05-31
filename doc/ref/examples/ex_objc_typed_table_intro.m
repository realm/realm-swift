// @@Example: ex_objc_typed_table_intro @@

#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

TIGHTDB_TABLE_2(PeopleTable,
                Name, String,
                Age, Int)

int main()
{
    @autoreleasepool {
       
        PeopleTable *table = [[PeopleTable alloc] init];
        
        [table addname:@"Mary" Age:14];
        //[table addName:@"Joe" Age:17];
        //[table addName:@"Jack" Age:22];
        //[table addName:@"Paul" Age:33];
        //[table addName:@"Simon" Age:17];
        //[table addName:@"Carol" Age:22];
        
        PeopleTable_Query *query = [[table where].Age between:13 to:19];
  
        NSLog(@"People of age between 13 and 19:");
        for (PeopleTable_Cursor *curser in query)
            NSLog(@"Name: %@", [curser name]);

    }
}
// @@EndExample@@
