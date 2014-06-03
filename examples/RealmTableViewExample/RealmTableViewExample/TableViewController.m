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
@interface DemoObject : RLMObject
@property (nonatomic, copy)   NSString *title;
@property (nonatomic, strong) NSDate   *date;
@end

@implementation DemoObject
// None needed
@end

static NSString * const kCellID    = @"cell";
static NSString * const kTableName = @"table";

@interface TableViewController ()

@property (nonatomic, strong) RLMArray *array;
@property (nonatomic, strong) RLMNotificationBlock realmNotification;
@end

@implementation TableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];

    // Create and hold realm notification block
    self.realmNotification = ^(NSString *note, RLMRealm *realm, id context) {
        [context reloadData];
    };
    
    // Set notification block
    [RLMRealm.defaultRealm addNotificationBlock:self.realmNotification context:self];
    
    // Load initial data
    [self reloadData];
}

- (void)reloadData {
    self.array = [DemoObject objectsOrderedBy:@"date" where:nil];
    [self.tableView reloadData];
}

#pragma mark - UI

- (void)setupUI {
    self.title = @"TableViewExample";
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"BG Add"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(backgroundAdd)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(add)];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:kCellID];
    }
    
    DemoObject *object = self.array[indexPath.row];
    cell.textLabel.text = object.title;
    cell.detailTextLabel.text = object.date.description;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        [realm deleteObject:self.array[indexPath.row]];
        [realm commitWriteTransaction];
    }
}

#pragma mark - Actions

- (void)backgroundAdd {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // Import many items in a background thread
    dispatch_async(queue, ^{
        // Get new realm and table since we are in a new thread
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        for (NSInteger index = 0; index < 5; index++) {
            // Add row via dictionary. Order is ignored.
            [DemoObject createInRealm:realm withObject:@{@"title": [self randomString],
                                                         @"date": [self randomDate]}];
        }
        [realm commitWriteTransaction];
    });
}

- (void)add {
    RLMRealm *realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];
    [DemoObject createInRealm:realm withObject:@[[self randomString], [self randomDate]]];
    [realm commitWriteTransaction];
}

- (void)deleteAll {
    RLMRealm *realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];
    for (DemoObject *obj in self.array) {
        [realm deleteObject:obj];
    }
    [realm commitWriteTransaction];
}

#pragma - Helpers

- (NSString *)randomString {
    return [NSString stringWithFormat:@"Title %d", arc4random()];
}

- (NSDate *)randomDate {
    return [NSDate dateWithTimeIntervalSince1970:arc4random()];
}

@end
