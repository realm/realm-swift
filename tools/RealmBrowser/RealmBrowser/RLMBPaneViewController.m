//
//  RLMBPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBPaneViewController.h"

@interface RLMBPaneViewController () <NSTableViewDataSource, NSTableViewDelegate>

@end

@implementation RLMBPaneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 0;
}

#pragma mark - Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}

@end
