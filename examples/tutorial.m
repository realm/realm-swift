// @@Example: create_table @@
// Define table
TDB_TABLE_3(PeopleTable,
    String, Name,
    Int,    Age,
    Bool,   Hired)

// Use it in a function
- (void)func {
    PeopleTable *people = [[PeopleTable alloc] init];
    ...
}
// @@EndExample@@


// @@Example: insert_rows @@
[people addName:@"John" Age:20 Hired:YES];
[people addName:@"Mary" Age:21 Hired:NO];
[people addName:@"Lars" Age:21 Hired:YES];
[people addName:@"Phil" Age:43 Hired:NO];
[people addName:@"Anni" Age:54 Hired:YES];
// @@EndExample@@

// @@Example: insert_at_index@@
[people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];
// @@EndExample@@

// @@Example: number_of_rows @@
size_t cnt = [people count];                   // cnt = 6
BOOL empty = [people isEmpty];     			   // empty = NO
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
NSString* = [people lastObject].Name;              // =&gt; "Anni"
// @@EndExample@@

// @@Example: updating_entire_row @@
[people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];
// @EndExample@@

// @@Example: deleting_row @@
[people deleteRow:2];                                          
size_t cnt = [people count];                     // cnt = 5
// @@EndExample@@

// @@Example: iteration @@
for (size_t i = 0; i < [people count]; ++i) {
    PeopleTable_Cursor *row = [people objectAtIndex:i];
    NSLog(@"%s is %lld years old", row.Name, row.Age);
}
// @@EndExample@@

// @@Example: simple_seach @@
size_t row; 
row = [people.Name find:@"Philip"];	    // (size_t)-1. Not found
row = [people.Name find:@"Mary"];	    // row = 1
// @@EndExample@@

// @@Example: advanced_search @@
// Create query (current employees between 20 and 30 years old)
PeopleTable_Query *q = [[[people getQuery].Hired equal:YES]  
                                          .Age between:20 to:30];

// Get number of matching entries
size_t cnt = [q count];                                   // =&gt; 2

// Get the average age (currently only a low-level interface)
double avg = [q.Age avg];

// Execute the query and return a table (view)
TableView *res = [q findAll];
for (size_t i = 0; i < [res count]; ++i) {
    NSLog(@"%zu: %@ is %lld years old", i, 
        [people objectAtIndex:i].Name, 
        [people objectAtIndex:i].Age);
}
// @@EndExample@@

// @@Example: serialisation @@
TDB_TABLE_3(PeopleTable,
 	    String, Name,
 	    Int,    Age,
	    Bool,   Hired)
 
// Create Table in Group
Group *group = [Group group];
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
Group *fromDisk = [Group groupWithFilename:@"employees.tightdb"];
PeopleTable *diskTable = [fromDisk getTable:@"employees" 
				    withClass:[PeopleTable class]];
NSLog(@"Disktable size: %zu", [diskTable count]);
for (size_t i = 0; i < [diskTable count]; i++) {
   MyTable_Cursor *cursor = [diskTable objectAtIndex:i];
   NSLog(@"%zu: %@", i, [cursor Name]);             // using std. method
}

// Write same group to memory buffer
size_t len;
const char* const buffer = [group writeToMem:&amp;len];

// Load a group from memory (and print contents)
Group *fromMem = [Group groupWithBuffer: buffer len:len];
PeopleTable *memTable = [fromMem getTable:@"employees" 
 			          withClass:[PeopleTable class]];
for (size_t i = 0; i < [memTable count]; i++) {
    PeopleTable_Cursor *cursor = [memTable objectAtIndex:i];
    NSLog(@"%zu: %@", i, cursor.Name);              // using dot-syntax
}
// @@EndExample@@
