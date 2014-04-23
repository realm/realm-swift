//
//  RLMTableViewController.m
//  RLMDemo
//
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTableViewController.h"
#import <Realm/Realm.h>

// @@Example: declare_table @@
// Define table with two columns

REALM_TABLE_2(RLMDemoTable,
              title,   String,
              checked, Bool)

// @@EndExample@@

static NSString * const kCellID    = @"cell";
static NSString * const kTableName = @"table";


@interface RLMTableViewController ()

@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, strong) RLMContext *context;
@property (nonatomic, strong) RLMDemoTable *table;

@end

@implementation RLMTableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(add)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellID];
    
    [self setupRealm];
}

#pragma mark - Realm

- (void)setupRealm {
    // @@Example: setup_contexts @@
    // Set up read/write contexts
    self.realm   = [RLMRealm realmWithDefaultPersistence];
    self.context = [RLMContext contextWithDefaultPersistence];
    // @@EndExample@@
    
    // @@Example: create_table @@
    // Create table if it doesn't exist
    [self.context writeUsingBlock:^(RLMRealm *realm) {
        if (realm.isEmpty) {
            [realm createTableWithName:kTableName asTableClass:[RLMDemoTable class]];
        }
    }];
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

- (RLMDemoTable *)table {
    if (!_table) {
        // @@Example: get_table @@
        // Get table with specified name and class from the realm
        _table = [self.realm tableWithName:kTableName asTableClass:[RLMDemoTable class]];
        // @@EndExample@@
    }
    return _table;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.table.rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    
    RLMDemoTableRow *row = self.table[indexPath.row];
    
    cell.textLabel.text = row.title;
    cell.accessoryType = row.checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
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

- (void)add {
    // @@Example: add_row @@
    [self.context writeUsingBlock:^(RLMRealm *realm) {
        RLMDemoTable *table = [realm tableWithName:kTableName asTableClass:[RLMDemoTable class]];
        NSString *title = [NSString stringWithFormat:@"Title %@", @(table.rowCount)];
        BOOL checked = table.rowCount % 2;
        [table addRow:@[title, @(checked)]];
        // Rows can also be added as dictionaries:
        // [table addRow:@{@"title": title, @"checked": @(checked)}];
    }];
    // @@EndExample@@
}

#pragma mark - Tutorial Examples

- (void)iteration {
    // @@Example: iteration @@
    for (RLMDemoTableRow *row in self.table) {
        NSLog(@"%@ is %@", row.title, row.checked ? @"checked" : @"unchecked");
    }
    // @@EndExample@@
}

- (void)query {
    // @@Example: query @@
    RLMRow *row = [self.table find:[NSPredicate predicateWithFormat:@"checked = %@", @YES]];
    if (row) {
        NSLog(@"%@ is %@", row[@"title"],
              [(NSNumber *)row[@"checked"] boolValue] ? @"checked" : @"unchecked");
    }
    // @@EndExample@@
}

@end
