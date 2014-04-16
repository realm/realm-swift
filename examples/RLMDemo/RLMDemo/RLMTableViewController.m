//
//  RLMTableViewController.m
//  RLMDemo
//
//  Created by JP Simard on 4/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTableViewController.h"
#import <Tightdb/Tightdb.h>

static NSString * const kCellID = @"cell";
static NSString * const kTableName = @"table";
static NSString * const kTitleColumn = @"title";

@interface RLMTableViewController ()

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
    // Write initial data to table
    [[TDBContext contextWithDefaultPersistence] writeUsingBlock:^BOOL(TDBTransaction *transaction){
        if (![transaction tableWithName:kTableName]) {
            TDBTable *table = [transaction createTableWithName:kTableName];
            [table addColumnWithName:kTitleColumn type:TDBStringType];
            [table addRow:[RLMTableViewController rowDictWithCount:table.rowCount]];
        }
        return YES;
    } error:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    __block NSInteger rowCount = 0;
    [[TDBContext contextWithDefaultPersistence] readTable:kTableName usingBlock:^(TDBTable *table) {
        rowCount = table.rowCount;
    }];
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    
    [[TDBContext contextWithDefaultPersistence] readTable:kTableName usingBlock:^(TDBTable *table) {
        cell.textLabel.text = table[indexPath.row][kTitleColumn];
    }];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSError *error = nil;
        [[TDBContext contextWithDefaultPersistence] writeTable:kTableName usingBlock:^BOOL(TDBTable *table) {
            [table removeRowAtIndex:indexPath.row];
            return YES;
        } error:&error];
        
        if (!error) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark - Actions

- (void)add {
    NSError *error = nil;
    
    __block NSUInteger rowCount = 0;
    
    [[TDBContext contextWithDefaultPersistence] writeTable:kTableName usingBlock:^BOOL(TDBTable *table) {
        rowCount = table.rowCount;
        [table addRow:[RLMTableViewController rowDictWithCount:rowCount]];
        return YES;
    } error:&error];
    
    if (error) {
        NSLog(@"Error adding a new row: %@", error.localizedDescription);
    } else {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowCount inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Helpers

+ (NSDictionary *)rowDictWithCount:(NSUInteger)count {
    return @{kTitleColumn: [NSString stringWithFormat:@"Title %lu", (unsigned long)count]};
}

@end
