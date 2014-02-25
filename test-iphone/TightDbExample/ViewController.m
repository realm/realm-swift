//
//  ViewController.m
//  TightDbExample
//

#import <Tightdb/Tightdb.h>
#import <Tightdb/group_shared.h>

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
    TightdbGroup *group = [TightdbGroup group];
    // Create new table in group
    MyTable *table = [group getTable:@"employees" withClass:[MyTable class] error:nil];

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

    MyTable_View *view = [[[table where].Age columnIsEqualTo:21] findAll];
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
    MyTable2_Query *q = [[[table2 where].Hired columnIsEqualTo:YES]
                                        .Age   columnIsBetween:20 and_:30];

    // Get number of matching entries
    NSLog(@"Query count: %@", [q count]);
    [_utils Eval:[[q count] intValue] == 2 msg:@"Expected 2 rows in query"];


    // Get the average age - currently only a low-level interface!
    NSNumber *avg = [q.Age average];
    NSLog(@"Average: %i", [avg intValue]);
    [_utils Eval:[avg intValue]== 21.0 msg:@"Expected 20.5 average"];

    // Execute the query and return a table (view)
    TightdbView *res = [q findAll];
    for (size_t i = 0; i < [res count]; i++) {
        // cursor missing. Only low-level interface!
        NSLog(@"%zu: is %lld years old",i , [res get:1 ndx:i]);
    }

    //------------------------------------------------------

    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:[_utils pathForDataFile:@"employees.tightdb"] error:nil];

    // Write to disk
    [group writeToFile:[_utils pathForDataFile:@"employees.tightdb"] withError:nil];

    // Load a group from disk (and print contents)
    TightdbGroup *fromDisk = [TightdbGroup groupWithFile:[_utils pathForDataFile:@"employees.tightdb"] withError:nil];
    MyTable *diskTable = [fromDisk getTable:@"employees" withClass:[MyTable class] error:nil];

    [diskTable addName:@"Anni" Age:54 Hired:YES Spare:0];
    [diskTable insertRowAtIndex:2 Name:@"Thomas" Age:41 Hired:NO Spare:1];
    NSLog(@"Disktable size: %zu", [diskTable count]);
    for (size_t i = 0; i < [diskTable count]; i++) {
        MyTable_Cursor *cursor = [diskTable cursorAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);
        NSLog(@"%zu: %@", i, cursor.Name);
        NSLog(@"%zu: %@", i, [diskTable getStringInColumn:0 atRow:i]);
    }

    // Write same group to memory buffer
    TightdbBinary* buffer = [group writeToBuffer];

    // Load a group from memory (and print contents)
    TightdbGroup *fromMem = [TightdbGroup groupWithBuffer:buffer withError:nil];
    MyTable *memTable = [fromMem getTable:@"employees" withClass:[MyTable class] error:nil];

    for (MyTable_Cursor *row in memTable)
    {
        NSLog(@"From mem: %@ is %lld years old.", row.Name, row.Age);
    }

    // 1: Iterate over table
    for (MyTable_Cursor *row in diskTable)
    {
        [_utils Eval:YES msg:@"Enumerator running"];
        NSLog(@"From disk: %@ is %lld years old.", row.Name, row.Age);
    }

    // Do a query, and get all matches as TableView
    MyTable_View *v = [[[[diskTable where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 and_:30] findAll];
    NSLog(@"View count: %zu", [v count]);
    // 2: Iterate over the resulting TableView
    for (MyTable_Cursor *row in v) {
        NSLog(@"%@ is %lld years old.", row.Name, row.Age);
    }

    // 3: Iterate over query (lazy)

    MyTable_Query *qe = [[diskTable where].Age columnIsEqualTo:21];
    NSLog(@"Query lazy count: %u", [[qe count] intValue]);
    for (MyTable_Cursor *row in qe) {
        NSLog(@"%@ is %lld years old.", row.Name, row.Age);
    }

}


@end



