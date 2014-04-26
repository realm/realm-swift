//
//  RLMTableViewController.m
//  RLMDemo
//
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTableViewController.h"
#import <Realm/Realm.h>

// @@Example: declare_table @@
// Define object with two properties
@interface RLMDemoObject : RLMRow

@property (nonatomic, copy)   NSString *title;
@property (nonatomic, strong) NSDate   *date;

@end

@implementation RLMDemoObject

@end
// @@EndExample@@

static NSString * const kCellID    = @"cell";
static NSString * const kTableName = @"table";

@interface RLMTableViewController ()

@property (nonatomic, strong) RLMRealm   *realm;
@property (nonatomic, strong) RLMContext *context;
@property (nonatomic, strong) RLMTable   *table;

@end

@implementation RLMTableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupRealm];
}

#pragma mark - UI

- (void)setupUI {
    self.title = @"RLMDemo";
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
    // @@Example: setup_contexts @@
    // Set up realm and context
    self.realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
        // Create table if it doesn't exist
        if (realm.isEmpty) {
            [realm createTableWithName:kTableName objectClass:[RLMDemoObject class]];
        }
    }];
    self.context = [RLMContext contextWithDefaultPersistence];
    // @@EndExample@@
    
    // @@Example: get_table @@
    // Set table as strong reference with specified name and class from the realm
    self.table = [self.realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
    // @@EndExample@@
    
    // @@Example: setup_notifications @@
    // Observe Realm Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(realmContextDidChange)
                                                 name:RLMContextDidChangeNotification
                                               object:nil];
}

- (void)realmContextDidChange {
    [self.tableView reloadData];
}
// @@EndExample@@

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
    
    RLMDemoObject *object = self.table[indexPath.row];
    cell.textLabel.text = object.title;
    cell.detailTextLabel.text = object.date.description;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // @@Example: delete_row @@
        [self.context writeTable:kTableName usingBlock:^(RLMTable *table) {
            [table removeRowAtIndex:indexPath.row];
        }];
        // @@EndExample@@
    }
}

#pragma mark - Actions

- (void)bgAdd {
    // @@Example: bg_add @@
    // Import many items in a background thread
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
            RLMTable *table = [realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
            for (NSInteger idx = 0; idx < 10000; idx++) {
                // Add row via dictionary. Order is ignored.
                [table addRow:@{@"title": [self randomString], @"date": [self randomDate]}];
            }
        }];
    });
    // @@EndExample@@
}

- (void)add {
    // @@Example: add_row @@
    [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
        // Add row via array. Order matters.
        [table addRow:@[[self randomString], [self randomDate]]];
    }];
    // @@EndExample@@
}

- (void)deleteAll {
    // @@Example: delete_all @@
    [self.context writeTable:kTableName usingBlock:^(RLMTable *table) {
        [table removeAllRows];
    }];
    // @@EndExample@@
}

#pragma - Helpers

- (NSString *)randomString {
    return [NSString stringWithFormat:@"Title %@", @(arc4random())];
}

- (NSDate *)randomDate {
    return [NSDate dateWithTimeIntervalSince1970:arc4random()];
}

#pragma mark - Tutorial Examples

- (void)iteration {
    // @@Example: iteration @@
    for (RLMDemoObject *object in self.table) {
        NSLog(@"title: %@\ndate: %@", object.title, object.date);
    }
    // @@EndExample@@
}

- (void)query {
    // @@Example: query @@
    RLMDemoObject *object = [self.table find:@"checked = YES"];
    if (object) {
        NSLog(@"title: %@\ndate: %@", object.title, object.date);
    }
    // @@EndExample@@
}

@end
