// @@Example: ex_objc_sharedgroup_intro @@

#import <tightdb/objc/group.h>
#import <tightdb/objc/group_shared.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);

int main()
{
    @autoreleasepool {
        
        // Creates a group and uses it to create a new table.
        
        TightdbSharedGroup *shared = [TightdbSharedGroup groupWithFilename:@"sharedgroup.tightdb"];
        
        // A write transaction (with rollback if not first writer to employees table).
        
        [shared writeTransaction:^(TightdbGroup *group) {
            
            // Write transactions with the shared group are possible via the provided variable binding named group.
            
            PeopleTable *table = [group getTable:@"employees" withClass:[PeopleTable class]];
            if ([table count] > 0) {
                NSLog(@"Not empty!");
                return NO; // Rollback
            }
            
            [table addName:@"Bill" Age:53 Hired:YES];
            NSLog(@"Row added!");
            return YES; // Commit
            
        }];
        
        // A read transaction
        
        [shared readTransaction:^(TightdbGroup *group) {
            
            // Read transactions with the shared group are possible via the provided variable binding named group.
            
            PeopleTable *table = [group getTable:@"employees" withClass:[PeopleTable class]];
            
            for (PeopleTable_Cursor *curser in table) {
                NSLog(@"Name: %@", [curser Name]);
            }
        }];
        // @@EndExample@@
        
    }

}
// @@EndExample@@