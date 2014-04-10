#import <Tightdb/Tightdb.h>

#import "MyAppDelegate.h"
#import "MyOldViewController.h"


@implementation MyOldViewController
{
    NSTimer *_refreshTimer;
    int _numRefreshTicks;
    TDBContext *_context;
}

- (NSString *)pathForName:(NSString *)name
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@", [dirs objectAtIndex:0], name];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    self.title = NSLocalizedString(@"Old", @"Old");
    self.tabBarItem.image = [UIImage imageNamed:@"old"];

    _context = [TDBContext contextWithPersistenceToFile:[self pathForName:@"demo.tightdb"]
                                                  error:nil];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    refreshSwitch.on = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)refreshSwitchChanged:(UISwitch *)theSwitch
{
    if (theSwitch.on) {
        if (_refreshTimer)
            return;
        // Start
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self
                                                       selector:@selector(tick:)
                                                       userInfo:nil repeats:YES];
    }
    else {
        if (!_refreshTimer)
            return;
        // Stop
        [_refreshTimer invalidate];
        _refreshTimer = nil;
    }
}

- (void)tick:(NSTimer *)theTimer
{
    ++_numRefreshTicks;
    refreshCount.text = [[NSNumber numberWithInt:_numRefreshTicks] stringValue];
    [tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    __block NSUInteger numRows = 0;
    [_context readUsingBlock:^(TDBTransaction *transact) {
        TDBTable *table = [transact tableWithName:@"demo"];
        numRows = table.rowCount;
    }];
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView2
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";

    __block UITableViewCell *cell =
        [tableView2 dequeueReusableCellWithIdentifier:simpleTableIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:simpleTableIdentifier];
    }

    [_context readUsingBlock:^(TDBTransaction *transact) {
        TDBTable *table = [transact tableWithName:@"demo"];
        cell.textLabel.text = table[indexPath.row][0];
    }];

    return cell;
}

@end
