#import <Realm/Realm.h>

#import "MyNewViewController.h"


@implementation MyNewViewController
{
    RLMTable *_table;
    int _numChangeTicks;
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
    self.tabBarItem.image = [UIImage imageNamed:@"new"];

    RLMRealm *realm = [RLMRealm realmWithPath:[self pathForName:@"demo.realm"]];

    _table = [realm tableWithName:@"demo"];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(realmDidChange:)
                               name:RLMRealmDidChangeNotification 
                             object:realm];

    return self;
}

- (void)realmDidChange:(NSNotification *)theNotification
{
    ++_numChangeTicks;
    changeCount.text = [[NSNumber numberWithInt:_numChangeTicks] stringValue];
    [tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _table.rowCount;
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
    cell.textLabel.text = _table[indexPath.row][0];
    return cell;
}

@end
