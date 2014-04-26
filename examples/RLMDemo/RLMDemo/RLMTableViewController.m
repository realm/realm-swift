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
@property (nonatomic, assign) BOOL      checked;

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(add)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellID];
    
    [self setupRealm];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    
    RLMDemoObject *object = self.table[indexPath.row];
    
    cell.textLabel.text = object.title;
    cell.accessoryType = object.checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
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
        RLMTable *table = [realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
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
    for (RLMDemoObject *object in self.table) {
        NSLog(@"%@ is %@", object.title, object.checked ? @"checked" : @"unchecked");
    }
    // @@EndExample@@
}

- (void)query {
    // @@Example: query @@
    RLMDemoObject *object = [self.table find:@"checked = YES"];
    if (object) {
        NSLog(@"%@ is %@", object.title, object.checked ? @"checked" : @"unchecked");
    }
    // @@EndExample@@
}

@end
