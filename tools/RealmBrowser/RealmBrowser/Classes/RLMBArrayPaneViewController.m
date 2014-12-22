//
//  RLMBArrayPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 28/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBArrayPaneViewController.h"

@interface RLMBArrayPaneViewController ()

@property (nonatomic) RLMArray *objects;

@end


@implementation RLMBArrayPaneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"RLMBArrayPaneViewController did load");
}

#pragma mark - Public Methods - Setup


#pragma mark - Table View Delegate

#pragma mark - Public Methods - Getters

-(BOOL)isArrayPane
{
    return YES;
}

@end
