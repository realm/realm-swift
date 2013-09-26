#import <tightdb/objc/group.h>
#import <tightdb/objc/group_shared.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>


// @@Example: create_table @@
// Define table

TIGHTDB_TABLE_3(PeopleTable,
                Name, String,
                Age,  Int,
                Hired, Bool);

// Use it in a function

void tableFunc() {
    PeopleTable *people = [[PeopleTable alloc] init];
    // (...)
    // @@EndExample@@
    
    // @@Example: insert_rows @@
    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];
    // @@EndExample@@
    
    // @@Example: insert_at_index @@
    [people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];
    // @@EndExample@@
    
    // @@Example: number_of_rows @@
    size_t cnt1 = [people count];                       // cnt = 6
    BOOL empty = [people isEmpty];                      // empty = NO
    // @@EndExample@@
    
    // @@Example: accessing_rows @@
    // Getting values directly
    NSString* name = [people objectAtIndex:5].Name;    // =&gt; 'Anni'
    // Using a cursor
    PeopleTable_Cursor *myRow = [people objectAtIndex:5];
    int64_t age = myRow.Age;                           // =&gt; 54
    BOOL hired  = myRow.Hired;                         // =&gt; true
    
    // Setting values
    [[people objectAtIndex:5] setAge:43];              // Getting younger
    // or with dot-syntax:
    myRow.Age += 1;                                    // Happy birthday!
    // @@EndExample@@
    
    // @@Example: last_row @@
    NSString *last = [people lastObject].Name;         // =&gt; "Anni"
    // @@EndExample@@
    
    // @@Example: updating_entire_row @@
    // (not yet implemented) [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];
    // @EndExample@@
    
    // @@Example: deleting_row @@
    [people remove:2];
    size_t cnt2 = [people count];                      // cnt = 5
    // @@EndExample@@
    
    // @@Example: iteration @@
    for (size_t i = 0; i < [people count]; ++i) {
        PeopleTable_Cursor *row = [people objectAtIndex:i];
        NSLog(@"%@ is %lld years old", row.Name, row.Age);
    }
    // @@EndExample@@
    
    // @@Example: simple_seach @@
    size_t row;
    row = [people.Name find:@"Philip"];	                // (size_t)-1. Not found
    row = [people.Name find:@"Mary"];	                  // row = 1
    // @@EndExample@@
    
    // @@Example: advanced_search @@
    // Create query (current employees between 20 and 30 years old)
    PeopleTable_Query *q = [[[people where].Hired columnIsEqualTo:YES]
                            .Age columnIsBetween:20 and_:30];

    
    // Get number of matching entries
    size_t cnt3 = [q count];                            // =&gt; 2
    
    // Get the average age (currently only a low-level interface)
    NSNumber *avg = [q.Age avg];
    
    // Execute the query and return a table (view)
    PeopleTable_View *res = [q findAll];
    for (size_t i = 0; i < [res count]; ++i) {
        NSLog(@"%zu: %@ is %lld years old", i,
              [people objectAtIndex:i].Name,
              [people objectAtIndex:i].Age);
    }
    // @@EndExample@@

}
    

void groupFunc() {
    
    // @@Example: serialisation @@
    // Create Table in Group
    TightdbGroup *group = [TightdbGroup group];
    PeopleTable *people = [group getTable:@"employees"
                                  withClass:[PeopleTable class]];
    
    // Add some rows
    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];
    
    // Write to disk
    [group write:@"employees.tightdb"];
    
    // Load a group from disk (and print contents)
    TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"employees.tightdb"];
    PeopleTable *diskTable = [fromDisk getTable:@"employees"
                                        withClass:[PeopleTable class]];
    
    NSLog(@"Disktable size: %zu", [diskTable count]);
    for (size_t i = 0; i < [diskTable count]; i++) {
        PeopleTable_Cursor *cursor = [diskTable objectAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);           // using std. method
    }
    
    // Write same group to memory buffer
    size_t len;
    const char* buffer = [group writeToMem:&len];
    
    // Load a group from memory (and print contents)
    TightdbGroup *fromMem = [TightdbGroup groupWithBuffer:buffer size:len];
    PeopleTable *memTable = [fromMem getTable:@"employees"
                                      withClass:[PeopleTable class]];
    for (size_t i = 0; i < [memTable count]; i++) {
        PeopleTable_Cursor *cursor = [memTable objectAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Name);            // using dot-syntax
    }
    // @@EndExample@@

    
}
   

void sharedGroupFunc() {
    
    // @@Example: transaction @@
    TightdbSharedGroup *sharedGroup = [TightdbSharedGroup groupWithFilename:@"people.tightdb"];

    // A write transaction (with rollback if not first writer to employees table).
 
    [sharedGroup writeTransaction:^(TightdbGroup *group) {
        
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
    
    [sharedGroup readTransaction:^(TightdbGroup *group) {
        
        // Read transactions with the shared group are possible via the provided variable binding named group.
        
        PeopleTable *table = [group getTable:@"employees" withClass:[PeopleTable class]];
        
        for (PeopleTable_Cursor *curser in table) {
            NSLog(@"Name: %@", [curser Name]);
        }
    }];
    // @@EndExample@@
}

int main()
{
    @autoreleasepool {
        tableFunc();
        groupFunc();
        sharedGroupFunc();
    }
}
