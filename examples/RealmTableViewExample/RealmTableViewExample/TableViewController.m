////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "TableViewController.h"
#import <Realm/Realm.h>

// Realm model object
@interface DemoObject : RLMRow

@property (nonatomic, copy)   NSString *title;
@property (nonatomic, strong) NSDate   *date;

@end

@implementation DemoObject
// None needed
@end

static NSString * const kCellID    = @"cell";
static NSString * const kTableName = @"table";

@interface TableViewController ()

@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, strong) RLMTable *table;

@end

@implementation TableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupRealm];
}

#pragma mark - UI

- (void)setupUI {
    self.title = @"TableViewExample";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"BG Add"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(bgAdd)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(add)];
    UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(deleteAll)];
    [self.navigationController.navigationBar addGestureRecognizer:g];
}

#pragma mark - Realm

- (void)setupRealm {
    // Get the realm
    self.realm = [RLMRealm defaultRealm];
    
    // Create table if it doesn't exist
    if (self.realm.isEmpty) {
        [self.realm beginWriteTransaction];
        [self.realm createTableWithName:kTableName objectClass:[DemoObject class]];
        [self.realm commitWriteTransaction];
    }
    
    // Get the table and hold onto it
    self.table = [self.realm tableWithName:kTableName objectClass:[DemoObject class]];
    
    // Register for notifications
    __weak TableViewController *weakSelf = self;
    [self.realm addNotification:^(NSString *note, RLMRealm *realm) {
        [weakSelf realmDidChange];
    }];
}

- (void)realmDidChange {
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.table.rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:kCellID];
    }
    
    DemoObject *object = self.table[indexPath.row];
    cell.textLabel.text = object.title;
    cell.detailTextLabel.text = object.date.description;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.realm beginWriteTransaction];
        [self.table removeRowAtIndex:indexPath.row];
        [self.realm commitWriteTransaction];
    }
}

#pragma mark - Actions

- (void)bgAdd {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // Import many items in a background thread
    dispatch_async(queue, ^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        for (NSInteger idx1 = 0; idx1 < 1000; idx1++) {
            // Break up the writing blocks into smaller portions
            RLMTable *table = [realm tableWithName:kTableName objectClass:[DemoObject class]];
            for (NSInteger idx2 = 0; idx2 < 1000; idx2++) {
                // Add row via dictionary. Order is ignored.
                [table addRow:@{@"title": [self randomString], @"date": [self randomDate]}];
            }
        }
        [realm commitWriteTransaction];
    });
}

- (void)add {
    [self.realm beginWriteTransaction];
    [self.table addRow:@[[self randomString], [self randomDate]]];
    [self.realm commitWriteTransaction];
}

- (void)deleteAll {
    [self.realm beginWriteTransaction];
    [self.table removeAllRows];
    [self.realm commitWriteTransaction];
}

#pragma - Helpers

- (NSString *)randomString {
    return [NSString stringWithFormat:@"Title %d", arc4random()];
}

- (NSDate *)randomDate {
    return [NSDate dateWithTimeIntervalSince1970:arc4random()];
}

@end
