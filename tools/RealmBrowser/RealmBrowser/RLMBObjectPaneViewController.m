//
//  RLMBObjectPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 22/12/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBObjectPaneViewController.h"

@interface RLMBObjectPaneViewController ()

@end

@implementation RLMBObjectPaneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"RLMBObjectPaneViewController did load");
}

#pragma mark - Public Methods - Getters

-(BOOL)isObjectPane
{
    return YES;
}

@end
