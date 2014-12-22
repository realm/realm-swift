//
//  RLMBRootPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 27/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBRootPaneViewController.h"

@interface RLMBRootPaneViewController ()

@property (nonatomic) RLMResults *objects;

@end


@implementation RLMBRootPaneViewController

#pragma mark - Lifetime Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"RLMBRootPaneViewController did load");
}

#pragma mark - Public Methods - Update


#pragma mark - Table View Delegate


#pragma mark - Private Methods - Accessors

#pragma mark - Public Methods - Getters

-(BOOL)isRootPane
{
    return YES;
}

@end