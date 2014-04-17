//
//  RLMTableViewController.m
//  RLMDemo
//
//  Created by JP Simard on 4/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTableViewController.h"
#import <Tightdb/Tightdb.h>

static NSString * const kCellID      = @"cell";
static NSString * const kTableName   = @"table";
static NSString * const kTitleColumn = @"title";

@interface RLMTableViewController ()

@property (nonatomic, strong)   TDBSmartContext *readContext;
@property (nonatomic, strong)   TDBContext *writeContext;
@property (nonatomic, readonly) TDBTable *table;

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
    self.readContext = [TDBSmartContext contextWithPersistenceToFile:[TDBContext defaultPath]];
    self.writeContext = [TDBContext contextWithDefaultPersistence];
    
    if (!self.table) {
        // Create table if it doesn't exist
        NSError *error = nil;
        [self.writeContext writeUsingBlock:^BOOL(TDBTransaction *transaction) {
            TDBTable *table = [transaction createTableWithName:kTableName];
            [table addColumnWithName:kTitleColumn type:TDBStringType];
            return YES;
        } error:&error];
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
    return [self.readContext tableWithName:kTableName];
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
