//
//  TableViewController.m
//  TableViewExample
//
//  Copyright (c) 2014 Realm. All rights reserved.
//

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

@property (nonatomic, strong) RLMRealm   *realm;
@property (nonatomic, strong) RLMContext *context;
@property (nonatomic, strong) RLMTable   *table;

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
    self.realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
        // Create table if it doesn't exist
        if (realm.isEmpty) {
            [realm createTableWithName:kTableName objectClass:[DemoObject class]];
        }
    }];
    
    self.table = [self.realm tableWithName:kTableName objectClass:[DemoObject class]];
    
    self.context = [RLMContext contextWithDefaultPersistence];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(realmContextDidChange)
                                                 name:RLMContextDidChangeNotification
                                               object:nil];
}

- (void)realmContextDidChange {
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
        [self.context writeTable:kTableName usingBlock:^(RLMTable *table) {
            [table removeRowAtIndex:indexPath.row];
        }];
    }
}

#pragma mark - Actions

- (void)bgAdd {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // Import many items in a background thread
    dispatch_async(queue, ^{
        RLMContext *ctx = [RLMContext contextWithDefaultPersistence];
        for (NSInteger idx1 = 0; idx1 < 1000; idx1++) {
            // Break up the writing blocks into smaller portions
            [ctx writeUsingBlock:^(RLMRealm *realm) {
                RLMTable *table = [realm tableWithName:kTableName objectClass:[DemoObject class]];
                for (NSInteger idx2 = 0; idx2 < 1000; idx2++) {
                    // Add row via dictionary. Order is ignored.
                    [table addRow:@{@"title": [self randomString], @"date": [self randomDate]}];
                }
            }];
        }
    });
}

- (void)add {
    [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:kTableName objectClass:[DemoObject class]];
        // Add row via array. Order matters.
        [table addRow:@[[self randomString], [self randomDate]]];
    }];
}

- (void)deleteAll {
    [self.context writeTable:kTableName usingBlock:^(RLMTable *table) {
        [table removeAllRows];
    }];
}

#pragma - Helpers

- (NSString *)randomString {
    return [NSString stringWithFormat:@"Title %d", arc4random()];
}

- (NSDate *)randomDate {
    return [NSDate dateWithTimeIntervalSince1970:arc4random()];
}

@end
