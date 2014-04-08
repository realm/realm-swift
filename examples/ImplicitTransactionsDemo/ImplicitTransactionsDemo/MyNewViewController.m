#import <Tightdb/Tightdb.h>

#import "MyNewViewController.h"


@implementation MyNewViewController
{
    TDBTable *table;
    int numChangeTicks;
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

    self.title = NSLocalizedString(@"New", @"New");
    self.tabBarItem.image = [UIImage imageNamed:@"second"];

    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    TDBSmartContext *context =
        [TDBSmartContext contextWithPersistenceToFile:[self pathForName:@"demo.tightdb"]
                                              runLoop:runLoop
                                   notificationCenter:notificationCenter
                                                error:nil];
    table = [context tableWithName:@"demo"];

    [notificationCenter addObserver:self selector:@selector(contextDidChange:)
                               name:@"TDBContextDidChangeNotification"
                             object:context];

    return self;
}

- (void)contextDidChange:(NSNotification *)theNotification
{
    ++numChangeTicks;
    changeCount.text = [[NSNumber numberWithInt:numChangeTicks] stringValue];
    [tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return table.rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView2
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    UITableViewCell *cell = [tableView2 dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:simpleTableIdentifier];
    }
    cell.textLabel.text = table[indexPath.row][0];
    return cell;
}

@end
