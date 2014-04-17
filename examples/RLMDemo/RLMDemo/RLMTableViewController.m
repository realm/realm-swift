//
//  RLMTableViewController.m
//  RLMDemo
//
//  Created by JP Simard on 4/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTableViewController.h"
#import <Tightdb/Tightdb.h>

TIGHTDB_TABLE_1(RLMTitles, title, String)

static NSString * const kCellID      = @"cell";
static NSString * const kTableName   = @"table";
static NSString * const kTitleColumn = @"title";

@interface RLMTableViewController ()

@property (nonatomic, strong) TDBSmartContext *readContext;
@property (nonatomic, strong) TDBContext *writeContext;
@property (nonatomic, strong) TDBTable *table;

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
    // Set up read/write contexts
    self.readContext  = [TDBSmartContext contextWithDefaultPersistence];
    self.writeContext = [TDBContext contextWithDefaultPersistence];
    
    // Create table if it doesn't exist
    NSError *error = nil;
    
    [self.writeContext writeUsingBlock:^BOOL(TDBTransaction *transaction) {
        if (transaction.isEmpty) {
            [transaction createTableWithName:kTableName asTableClass:[RLMTitles class]];
        }
        return YES;
    } error:&error];
    
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
    }
    
    // Observe TightDB Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tightDBContextDidChange)
                                                 name:TDBContextDidChangeNotification
                                               object:nil];
}

- (void)tightDBContextDidChange {
    [self.tableView reloadData];
}

- (TDBTable *)table {
    if (!_table) {
        _table = [self.readContext tableWithName:kTableName];
    }
    return _table;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.table.rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    
    cell.textLabel.text = self.table[indexPath.row][kTitleColumn];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSError *error = nil;
        
        [self.writeContext writeTable:kTableName usingBlock:^BOOL(TDBTable *table) {
            [table removeRowAtIndex:indexPath.row];
            return YES;
        } error:&error];
        
        if (error) {
            NSLog(@"Error adding a new row: %@", error.localizedDescription);
        }
    }
}

#pragma mark - Actions

- (void)add {
    NSError *error = nil;
    
    [self.writeContext writeTable:kTableName usingBlock:^BOOL(TDBTable *table) {
        [table addRow:@{kTitleColumn: [NSString stringWithFormat:@"Title %lu", (unsigned long)table.rowCount]}];
        return YES;
    } error:&error];
    
    if (error) {
        NSLog(@"Error adding a new row: %@", error.localizedDescription);
    }
}

@end
