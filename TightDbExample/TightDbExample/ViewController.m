//
//  ViewController.m
//  TightDbExample
//

#import "ViewController.h"
#import "Group.h"
#import "Table.h"
#import "TightDb.h"

TDB_TABLE_4(MyTable,
            String, Name,
            Int,    Age,
            Bool,   Hired,
            Int,	Spare)

TDB_TABLE_2(MyTable2,
Bool,   Hired,
Int,    Age)


@interface ViewController ()

@end

@implementation ViewController
{
    float y;
}
#define LineHeight 31

- (NSString *) pathForDataFile:(NSString *)filename {
    NSArray*	documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*	path = nil;
 	
    if (documentDir) {
        path = [documentDir objectAtIndex:0];    
    }
 	
    return [NSString stringWithFormat:@"%@/%@", path, filename];
}

#pragma mark - View code
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    y = 0;
	[self testGroup];
}

-(void)Eval:(BOOL)good msg:(NSString *)msg
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, y, self.view.bounds.size.width, LineHeight)];
    label.text = [NSString stringWithFormat:@"%@ - %@", good?@"OK":@"Fail", msg];
    if (!good)
        label.backgroundColor = [UIColor redColor];
    [self.view addSubview:label];
    y += LineHeight;
    ((UIScrollView *)self.view).contentSize = CGSizeMake(self.view.bounds.size.width, y);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Example code


- (void)testGroup
{
    Group *group = [Group group];
    // Create new table in group
    MyTable *table = [group getTable:@"employees" withClass:[MyTable class]];
    
    // Add some rows
    [table addName:@"John" Age:20 Hired:YES Spare:0];
    [table addName:@"Mary" Age:21 Hired:NO Spare:0];
    [table addName:@"Lars" Age:21 Hired:YES Spare:0];
    [table addName:@"Phil" Age:43 Hired:NO Spare:0];
    [table addName:@"Anni" Age:54 Hired:YES Spare:0];
    
    NSLog(@"MyTable Size: %lu", [table count]);
    
    //------------------------------------------------------
    
    size_t row; 
    row = [table.Name find:@"Philip"];		    	// row = (size_t)-1
    NSLog(@"Philip: %zu", row);
    [self Eval:row==-1 msg:@"Philip should not be there"];
    row = [table.Name find:@"Mary"];		
    NSLog(@"Mary: %zu", row);
    [self Eval:row==1 msg:@"Mary should have been there"];
    
    TableView *view = [table.Age findAll:21];
    size_t cnt = [view count];  					// cnt = 2
    [self Eval:cnt == 2 msg:@"Should be two rows in view"];
    
    //------------------------------------------------------
    
    MyTable2 *table2 = [[MyTable2 alloc] init];
    
    // Add some rows
    [table2 addHired:YES Age:20];
    [table2 addHired:NO Age:21];
    [table2 addHired:YES Age:22];
    [table2 addHired:NO Age:43];
    [table2 addHired:YES Age:54];
    
    // Create query (current employees between 20 and 30 years old)
    MyTable2_Query *q = [[[table2 getQuery].Hired equal:YES].Age between:20 to:30];
    
    // Get number of matching entries
    NSLog(@"Query count: %zu", [q count]);
    [self Eval:[q count] == 2 msg:@"Expected 2 rows in query"];
    
    // Get the average age - currently only a low-level interface!
    double avg = [q.Age avg];
    NSLog(@"Average: %f", avg);
    [self Eval:avg == 21.0 msg:@"Expected 20.5 average"];
    
    // Execute the query and return a table (view)
    TableView *res = [q findAll];
    for (size_t i = 0; i < [res count]; i++) {
        // cursor missing. Only low-level interface!
        NSLog(@"%zu: is %lld years old",i , [res get:1 ndx:i]);
    }
    
    //------------------------------------------------------
    
    // Write to disk
    [group write:[self pathForDataFile:@"employees.tightdb"]];
    
    // Load a group from disk (and print contents)
    Group *fromDisk = [Group groupWithFilename:[self pathForDataFile:@"employees.tightdb"]];
    MyTable *diskTable = [fromDisk getTable:@"employees" withClass:[MyTable class]];
    
    [diskTable addName:@"Anni" Age:54 Hired:YES Spare:0];
    [diskTable insertAtIndex:2 Name:@"Thomas" Age:41 Hired:NO Spare:1];
    NSLog(@"Disktable size: %zu", [diskTable count]);
    for (size_t i = 0; i < [diskTable count]; i++) {
        MyTable_Cursor *cursor = [diskTable objectAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);
        NSLog(@"%zu: %@", i, cursor.Name);
        NSLog(@"%zu: %@", i, [diskTable getString:0 ndx:i]);
    }
    
    // Write same group to memory buffer
    size_t len;
    const char* const buffer = [group writeToMem:&len];
    
    // Load a group from memory (and print contents)
    Group *fromMem = [Group groupWithBuffer:buffer len:len];
    MyTable *memTable = [fromMem getTable:@"employees" withClass:[MyTable class]];
    for (size_t i = 0; i < [memTable count]; i++) {
        // ??? cursor
        NSLog(@"%zu: %@", i, memTable.Name);
    }
}


@end



