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

@property (nonatomic, strong) TDBSmartContext *readContext;
@property (nonatomic, strong) TDBContext *writeContext;
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
}

#pragma mark - Table view data source

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
        
        if (!error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            });
        }
    }
}

#pragma mark - Actions

- (void)add {
    NSError *error = nil;
    
    __block NSUInteger rowCount = 0;
    
    [self.writeContext writeTable:kTableName usingBlock:^BOOL(TDBTable *table) {
        rowCount = table.rowCount;
        [table addRow:[RLMTableViewController rowDictWithCount:rowCount]];
        return YES;
    } error:&error];
    
    if (error) {
        NSLog(@"Error adding a new row: %@", error.localizedDescription);
    } else {
        // Perform on next run loop
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowCount inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        });
    }
}

#pragma mark - Helpers

+ (NSDictionary *)rowDictWithCount:(NSUInteger)count {
    return @{kTitleColumn: [NSString stringWithFormat:@"Title %lu", (unsigned long)count]};
}

- (TDBTable *)table {
    return [self.readContext tableWithName:kTableName];
}

@end
