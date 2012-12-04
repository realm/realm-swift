//
//  ViewController.m
//  TightDbExample
//

#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#import <tightdb/objc/tightdb.h>

#import "ViewController.h"
#import "Utils.h"
#import "Performance.h"

TIGHTDB_TABLE_4(MyTable,
                Name,  String,
                Age,   Int,
                Hired, Bool,
                Spare, Int)

TIGHTDB_TABLE_2(MyTable2,
                Hired, Bool,
                Age,   Int)


@interface ViewController ()
@end
@implementation ViewController
{
    Utils *_utils;
}

#pragma mark - View code
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.view = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _utils = [[Utils alloc] initWithView:(UIScrollView *)self.view];
    [self testGroup];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Performance *perf = [[Performance alloc] initWithUtils:_utils];
        [perf testInsert];
        [perf testFetch];
        [perf testFetchSparse];
        [perf testFetchAndIterate];
        [perf testUnqualifiedFetchAndIterate];
        [perf testWriteToDisk];
        [perf testReadTransaction];
        [perf testWriteTransaction];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    });

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
    row = [table.Name find:@"Philip"];              // row = (size_t)-1
    NSLog(@"Philip: %zu", row);
    [_utils Eval:row==-1 msg:@"Philip should not be there"];
    row = [table.Name find:@"Mary"];
    NSLog(@"Mary: %zu", row);
    [_utils Eval:row==1 msg:@"Mary should have been there"];

    TableView *view = [table.Age findAll:21];
    size_t cnt = [view count];                      // cnt = 2
    [_utils Eval:cnt == 2 msg:@"Should be two rows in view"];

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
    [_utils Eval:[q count] == 2 msg:@"Expected 2 rows in query"];

    // Get the average age - currently only a low-level interface!
    double avg = [q.Age avg];
    NSLog(@"Average: %f", avg);
    [_utils Eval:avg == 21.0 msg:@"Expected 20.5 average"];

    // Execute the query and return a table (view)
    TableView *res = [q findAll];
    for (size_t i = 0; i < [res count]; i++) {
        // cursor missing. Only low-level interface!
        NSLog(@"%zu: is %lld years old",i , [res get:1 ndx:i]);
    }

    //------------------------------------------------------

    // Write to disk
    [group write:[_utils pathForDataFile:@"employees.tightdb"]];

    // Load a group from disk (and print contents)
    Group *fromDisk = [Group groupWithFilename:[_utils pathForDataFile:@"employees.tightdb"]];
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

    // 1: Iterate over table
    for (MyTable_Cursor *row in diskTable) {
        [_utils Eval:YES msg:@"Enumerator running"];
        NSLog(@"%@ is %lld years old.", row.Name, row.Age);
    }

    // Do a query, and get all matches as TableView
    MyTable_View *v = [[[[diskTable getQuery].Hired equal:YES].Age between:20 to:30] findAll];
    NSLog(@"View count: %zu", [v count]);
    // 2: Iterate over the resulting TableView
    for (MyTable_Cursor *row in v) {
        NSLog(@"%@ is %lld years old.", row.Name, row.Age);
    }

    // 3: Iterate over query (lazy)

    MyTable_Query *qe = [[diskTable getQuery].Age equal:21];
    NSLog(@"Query lazy count: %zu", [qe count]);
    for (MyTable_Cursor *row in qe) {
        NSLog(@"%@ is %lld years old.", row.Name, row.Age);
    }


}


@end



