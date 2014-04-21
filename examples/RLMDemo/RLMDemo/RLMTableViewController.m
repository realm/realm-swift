//
//  RLMTableViewController.m
//  RLMDemo
//
//  Created by JP Simard on 4/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTableViewController.h"
#import <Realm/Realm.h>

// @@Example: create_table @@
// Define table

REALM_TABLE_2(RLMDemoTable,
              title, String,
              checked, Bool)

// @@EndExample@@

static NSString * const kCellID    = @"cell";
static NSString * const kTableName = @"table";

@interface RLMTableViewController ()

@property (nonatomic, strong) RLMSmartContext *readContext;
@property (nonatomic, strong) RLMContext *writeContext;
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
    
    [self setupTightDB];
}

#pragma mark - TightDB

- (void)setupTightDB {
    // @@Example: setup_contexts @@
    // Set up read/write contexts
    self.readContext  = [RLMSmartContext contextWithDefaultPersistence];
    self.writeContext = [RLMContext contextWithDefaultPersistence];
    // @@EndExample@@
    
    // Create table if it doesn't exist
    NSError *error = nil;
    
    // @@Example: create_table @@
    [self.writeContext writeUsingBlock:^BOOL(RLMTransaction *transaction) {
        if (transaction.isEmpty) {
            [transaction createTableWithName:kTableName asTableClass:[RLMDemoTable class]];
        }
        return YES;
    } error:&error];
    // @@EndExample@@
    
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
    }
    
    // @@Example: setup_notifications @@
    // Observe TightDB Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tightDBContextDidChange)
                                                 name:RLMContextDidChangeNotification
                                               object:nil];
}

- (void)tightDBContextDidChange {
    [self.tableView reloadData];
}
// @@EndExample@@

- (RLMDemoTable *)table {
    if (!_table) {
        // @@Example: get_table @@
        // Get table with specified name and class from smart context
        _table = [self.readContext tableWithName:kTableName asTableClass:[RLMDemoTable class]];
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
        NSError *error = nil;
        
        // @@Example: delete_row @@
        [self.writeContext writeTable:kTableName usingBlock:^BOOL(RLMTable *table) {
            [table removeRowAtIndex:indexPath.row];
            return YES;
        } error:&error];
        // @@EndExample@@
        
        if (error) {
            NSLog(@"Error adding a new row: %@", error.localizedDescription);
        }
    }
}

#pragma mark - Actions

- (void)add {
    NSError *error = nil;
    
    // @@Example: add_row @@
    [self.writeContext writeUsingBlock:^BOOL(RLMTransaction *transaction) {
        RLMDemoTable *table = [transaction tableWithName:kTableName asTableClass:[RLMDemoTable class]];
        NSString *title = [NSString stringWithFormat:@"Title %lu", (unsigned long)table.rowCount];
        BOOL checked = table.rowCount % 2;
        [table addRow:@[title, @(checked)]];
        // Rows can also be added as dictionaries:
        // [table addRow:@{@"title": title, @"checked": @(checked)}];
        return YES;
    } error:&error];
    // @@EndExample@@
    
    if (error) {
        NSLog(@"Error adding a new row: %@", error.localizedDescription);
    }
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
        NSLog(@"%@ is %@", row[@"title"], [(NSNumber *)row[@"checked"] boolValue] ? @"checked" : @"unchecked");
    }
    // @@EndExample@@
}

@end
