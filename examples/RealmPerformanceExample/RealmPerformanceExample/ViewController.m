////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import <Realm/Realm.h>

#import "ViewController.h"
#import "Utils.h"
#import "Performance.h"

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
    //[self testGroup];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@""]];
        });
        
        Performance *perf = [[Performance alloc] initWithUtils:_utils];
        [perf testInsert];
        [perf testLinearInt];
        [perf testLinearString];
        [perf testMultipleConditions];
        [perf testFetchAndIterate];
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

 /*
- (void)testGroup
{

    RLMTransactionManager *manager = [RLMTransactionManager managerForRealmWithPath:@"employees.realm" error:nil];
   
    [manager writeUsingBlock:^BOOL(RLMRealm *realm) {
    
        MyTable *table = [realm createTableWithName:@"employees" asTableClass:[MyTable class]];
        
        // Add some rows
        [table addName:@"John" Age:20 Hired:YES Spare:0];
        [table addName:@"Mary" Age:21 Hired:NO Spare:0];
        [table addName:@"Lars" Age:21 Hired:YES Spare:0];
        [table addName:@"Phil" Age:43 Hired:NO Spare:0];
        [table addName:@"Anni" Age:54 Hired:YES Spare:0];
        
        NSLog(@"MyTable Size: %lu", (unsigned long)table.rowCount);
        
        //------------------------------------------------------
        
        size_t row;
        row = [table.Name find:@"Philip"];              // row = (size_t)-1
        NSLog(@"Philip: %zu", row);
        [_utils Eval:row==-1 msg:@"Philip should not be there"];
        row = [table.Name find:@"Mary"];
        NSLog(@"Mary: %zu", row);
        [_utils Eval:row==1 msg:@"Mary should have been there"];
        
        MyTableView *view = [[[table where].Age columnIsEqualTo:21] findAll];
        size_t cnt = [view rowCount];                      // cnt = 2
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
        MyTable2Query *q = [[[table2 where].Hired columnIsEqualTo:YES]
                             .Age   columnIsBetween:20 :30];
        
        // Get number of matching entries
        NSLog(@"Query count: %lu", (unsigned long)[q countRows]);
        [_utils Eval:[q countRows] == 2 msg:@"Expected 2 rows in query"];
        
        
        // Get the average age - currently only a low-level interface!
        double avg = [q.Age avg];
        NSLog(@"Average: %f", avg);
        [_utils Eval: avg== 21.0 msg:@"Expected 20.5 average"];
        
        // Execute the query and return a table (view)
        RLMView *res = [q findAll];
        for (size_t i = 0; i < [res rowCount]; i++) {
            // cursor missing. Only low-level interface!
            NSLog(@"%zu: is %lld years old",i , [res RLM_intInColumnWithIndex:i atRowIndex:i]);
        }
        
        //------------------------------------------------------
        
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager removeItemAtPath:[_utils pathForDataFile:@"employees.realm"] error:nil];
        
        // Write to disk
        //[group writeContextToFile:[_utils pathForDataFile:@"employees.realm"] withError:nil];
        
        return YES;

    } error:nil];
   
    // Load a group from disk (and print contents)
    
    manager = [RLMTransactionManager managerForRealmWithPath:[_utils pathForDataFile:@"employees.realm"] error:nil];
    
    [manager writeUsingBlock:^BOOL(RLMRealm *realm) {
        MyTable *diskTable = [realm tableWithName:@"employees" asTableClass:[MyTable class]];
        
        [diskTable addName:@"Anni" Age:54 Hired:YES Spare:0];
        [diskTable insertEmptyRowAtIndex:2 Name:@"Thomas" Age:41 Hired:NO Spare:1];
        NSLog(@"Disktable size: %lu", (unsigned long)diskTable.rowCount);
        for (size_t i = 0; i < [diskTable rowCount]; i++) {
            MyTableRow *row = [diskTable rowAtIndex:i];
            NSLog(@"%zu: %@", i, row.Name);
            NSLog(@"%zu: %@", i, [diskTable RLM_stringInColumnWithIndex:0 atRowIndex:i]);
        }
        
        // Write same group to memory buffer
       //buffer = [transaction writeContextToBuffer];
        return YES;
    } error:nil];


    
    [manager readUsingBlock:^(RLMRealm *realm) {
        
        MyTable *diskTable = [realm tableWithName:@"employees" asTableClass:[MyTable class]];
        
        // 1: Iterate over table
        for (MyTableRow *row in diskTable)
        {
            [_utils Eval:YES msg:@"Enumerator running"];
            NSLog(@"From disk: %@ is %lld years old.", row.Name, row.Age);
        }
        
        // Do a query, and get all matches as TableView
        MyTableView *v = [[[[diskTable where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 :30] findAll];
        NSLog(@"View count: %lu", (unsigned long)v.rowCount);
        // 2: Iterate over the resulting TableView
        for (MyTableRow *row in v) {
            NSLog(@"%@ is %lld years old.", row.Name, row.Age);
        }
        
        // 3: Iterate over query (lazy)
        
        MyTableQuery *qe = [[diskTable where].Age columnIsEqualTo:21];
        NSLog(@"Query lazy count: %lu", (unsigned long)[qe countRows]);
        for (MyTableRow *row in qe) {
            NSLog(@"%@ is %lld years old.", row.Name, row.Age);
        }
    }];

  

}
*/

@end



