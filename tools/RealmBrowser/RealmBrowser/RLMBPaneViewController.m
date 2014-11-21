//
//  RLMBPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBPaneViewController.h"

@interface RLMBPaneViewController () <NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *tableView;

//@property (nonatomic) RLMBNode *node;

@end

@implementation RLMBPaneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - NSTableViewDataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 1;
}

@end
